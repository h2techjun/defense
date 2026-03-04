"""
해원의 문 — Vertex AI (Lyria RealTime) 배경음악 생성 스크립트
Google Gemini API의 Lyria RealTime 모델을 사용하여
한국 설화 기반 타워 디펜스 게임에 어울리는 K-pop/국악 퓨전 BGM을 생성합니다.

인증 방법 (우선순위 순):
  1. GCP 서비스 계정 키 (GOOGLE_APPLICATION_CREDENTIALS 환경변수 또는 프로젝트 루트 json 키)
  2. GOOGLE_API_KEY 환경변수 (AI Studio 키)
  3. .env 파일의 GOOGLE_API_KEY
  4. 수동 입력

사용법:
  python scripts/generate_bgm_vertex.py

출력: assets/audio/bgm/ 디렉토리에 WAV 파일 10개 생성
"""

import asyncio
import json
import os
import sys
import wave
from pathlib import Path

# google-genai SDK
try:
    from google import genai
    from google.genai import types
except ImportError:
    print("❌ google-genai 패키지가 필요합니다. 설치: pip install google-genai")
    sys.exit(1)

# ── 설정 ──────────────────────────────────────────────────
PROJECT_ROOT = Path(__file__).parent.parent
OUTPUT_DIR = PROJECT_ROOT / "assets" / "audio" / "bgm"
SAMPLE_RATE = 48000       # Lyria RealTime 출력 사양
CHANNELS = 2              # 스테레오
SAMPLE_WIDTH = 2          # 16-bit PCM
TRACK_DURATION_SEC = 60   # 각 트랙 길이 (초)
MODEL_NAME = "models/lyria-realtime-exp"

# 서비스 계정 키 파일 경로 (프로젝트 루트에서 자동 탐색)
SERVICE_ACCOUNT_KEY_PATH = PROJECT_ROOT / "autotrade-engine-key.json"

# 10개 트랙 — 한국 설화 x K-pop 퓨전 프롬프트
TRACK_CONFIGS = [
    {
        "name": "joseon_kpop_battle",
        "prompts": [
            types.WeightedPrompt(text="K-pop, Trap Beat, Koto, Shamisen, intense battle music, epic drums, fast tempo", weight=1.0),
        ],
        "bpm": 140,
        "temperature": 1.0,
    },
    {
        "name": "spirit_realm_ambience",
        "prompts": [
            types.WeightedPrompt(text="Korean traditional, ethereal ambience, Gayageum, mystical, haunting vocals, ambient synth pads", weight=1.0),
        ],
        "bpm": 75,
        "temperature": 0.9,
    },
    {
        "name": "tower_defense_hype",
        "prompts": [
            types.WeightedPrompt(text="EDM, K-pop dance, energetic, synth drops, 808 drums, upbeat gaming music", weight=1.0),
        ],
        "bpm": 128,
        "temperature": 1.0,
    },
    {
        "name": "moonlit_strategy",
        "prompts": [
            types.WeightedPrompt(text="Lo-Fi Hip Hop, chill, Korean traditional flute, Rhodes Piano, relaxed night mood, smooth beats", weight=1.0),
        ],
        "bpm": 85,
        "temperature": 0.8,
    },
    {
        "name": "boss_wave_fury",
        "prompts": [
            types.WeightedPrompt(text="Orchestral Score, epic boss battle, heavy drums, brass, intense strings, cinematic action, Korean war drums", weight=1.0),
        ],
        "bpm": 160,
        "temperature": 1.1,
    },
    {
        "name": "folk_village_peace",
        "prompts": [
            types.WeightedPrompt(text="Korean folk, acoustic instruments, peaceful village, Gayageum, bamboo flute, warm acoustic guitar, gentle", weight=1.0),
        ],
        "bpm": 90,
        "temperature": 0.7,
    },
    {
        "name": "neon_hanbok_groove",
        "prompts": [
            types.WeightedPrompt(text="Synthpop, K-pop, futuristic, neon vibes, danceable, bright tones, electronic beats, groovy bassline", weight=1.0),
        ],
        "bpm": 120,
        "temperature": 1.0,
    },
    {
        "name": "dark_shaman_ritual",
        "prompts": [
            types.WeightedPrompt(text="Dark ambient, tribal drums, ominous drone, shamanic ritual, deep bass, unsettling, mysterious Korean percussion", weight=1.0),
        ],
        "bpm": 70,
        "temperature": 0.9,
    },
    {
        "name": "victory_celebration",
        "prompts": [
            types.WeightedPrompt(text="K-pop, upbeat celebration, brass fanfare, disco funk, bright tones, happy, triumphant, energetic", weight=1.0),
        ],
        "bpm": 130,
        "temperature": 1.0,
    },
    {
        "name": "ancient_gateway_epic",
        "prompts": [
            types.WeightedPrompt(text="Epic orchestral, Korean traditional fusion, Gayageum with strings, cinematic adventure, emotional, rich orchestration, heroic theme", weight=1.0),
        ],
        "bpm": 100,
        "temperature": 0.9,
    },
]


def save_pcm_to_wav(pcm_data: bytes, filepath: Path) -> None:
    """Raw PCM 데이터를 WAV 파일로 저장합니다."""
    with wave.open(str(filepath), "wb") as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(SAMPLE_WIDTH)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm_data)
    file_size_mb = filepath.stat().st_size / (1024 * 1024)
    print(f"  💾 저장 완료: {filepath.name} ({file_size_mb:.1f} MB)")


def create_client() -> genai.Client:
    """인증 방식을 자동 감지하여 genai.Client를 생성합니다.

    ⚠️ Lyria RealTime은 Vertex AI 미지원 → AI Studio API 키 우선!
    우선순위:
    1. GOOGLE_API_KEY 환경변수 (AI Studio) ← Lyria 지원!
    2. .env 파일의 GOOGLE_API_KEY
    3. GCP 서비스 계정 키 (Vertex AI — Lyria 미지원 주의)
    4. 수동 입력
    """
    # ── 방법 1: GOOGLE_API_KEY 환경변수 (AI Studio) ──
    api_key = os.environ.get("GOOGLE_API_KEY")
    if api_key:
        print("🔑 인증: AI Studio API 키 (환경변수)")
        return genai.Client(
            api_key=api_key,
            http_options={"api_version": "v1alpha"},
        )

    # ── 방법 2: .env 파일 ──
    env_path = PROJECT_ROOT / ".env"
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8").splitlines():
            if line.startswith("GOOGLE_API_KEY="):
                api_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                if api_key:
                    print("🔑 인증: AI Studio API 키 (.env 파일)")
                    return genai.Client(
                        api_key=api_key,
                        http_options={"api_version": "v1alpha"},
                    )

    # ── 방법 3: 서비스 계정 (Vertex AI — Lyria 미지원 경고) ──
    sa_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not sa_path and SERVICE_ACCOUNT_KEY_PATH.exists():
        sa_path = str(SERVICE_ACCOUNT_KEY_PATH)
    if sa_path and Path(sa_path).exists():
        print(f"⚠️  서비스 계정 키 발견, 하지만 Lyria RealTime은 Vertex AI 미지원!")
        print("   AI Studio API 키를 사용해주세요: https://aistudio.google.com/apikey")
        print("   그래도 Vertex AI로 시도하시겠습니까? (다른 모델 사용 시)")
        # Vertex AI 폴백 (Lyria 외 다른 용도)
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = sa_path
        with open(sa_path, "r", encoding="utf-8") as f:
            sa_info = json.load(f)
        project_id = sa_info.get("project_id", "")
        return genai.Client(
            vertexai=True,
            project=project_id,
            location="us-central1",
            http_options={"api_version": "v1alpha"},
        )

    # ── 방법 4: 수동 입력 ──
    print("\n⚠️  인증 정보를 찾을 수 없습니다.")
    print("   Lyria RealTime은 AI Studio API 키가 필요합니다!")
    print("   발급: https://aistudio.google.com/apikey")
    api_key = input("\n   API 키를 직접 입력: ").strip()
    if not api_key:
        print("❌ 인증 정보가 필요합니다. 종료합니다.")
        sys.exit(1)
    return genai.Client(
        api_key=api_key,
        http_options={"api_version": "v1alpha"},
    )


async def generate_single_track(
    client: genai.Client,
    config: dict,
    track_index: int,
) -> None:
    """단일 트랙을 Lyria RealTime API로 생성합니다."""
    name = config["name"]
    print(f"\n🎵 [{track_index + 1}/10] '{name}' 생성 중...")
    print(f"   프롬프트: {config['prompts'][0].text[:80]}...")
    print(f"   BPM: {config['bpm']}, 길이: {TRACK_DURATION_SEC}초")

    pcm_buffer = bytearray()
    target_bytes = SAMPLE_RATE * CHANNELS * SAMPLE_WIDTH * TRACK_DURATION_SEC

    try:
        async with client.aio.live.music.connect(model=MODEL_NAME) as session:
            # 프롬프트 및 설정 전송
            await session.set_weighted_prompts(prompts=config["prompts"])
            await session.set_music_generation_config(
                config=types.LiveMusicGenerationConfig(
                    bpm=config["bpm"],
                    temperature=config.get("temperature", 1.0),
                )
            )

            # 음악 스트리밍 시작
            await session.play()

            # 오디오 청크 수신
            async for message in session.receive():
                try:
                    audio_data = message.server_content.audio_chunks[0].data
                    pcm_buffer.extend(audio_data)

                    # 진행률 표시
                    progress = min(len(pcm_buffer) / target_bytes * 100, 100)
                    sys.stdout.write(f"\r   📊 진행률: {progress:.0f}%")
                    sys.stdout.flush()

                    if len(pcm_buffer) >= target_bytes:
                        break
                except (AttributeError, IndexError):
                    # 오디오가 아닌 메시지는 건너뜀
                    continue

        print()  # 줄바꿈

        # 정확한 길이로 자르기
        pcm_buffer = pcm_buffer[:target_bytes]

        # WAV 파일로 저장
        output_path = OUTPUT_DIR / f"{name}.wav"
        save_pcm_to_wav(bytes(pcm_buffer), output_path)

    except Exception as e:
        print(f"\n  ❌ '{name}' 생성 실패: {e}")
        raise


async def main() -> None:
    """메인 실행 함수"""
    print("=" * 60)
    print("🎶 해원의 문 — Lyria RealTime BGM 생성기")
    print("=" * 60)

    # 인증 및 클라이언트 초기화
    client = create_client()

    # 출력 디렉토리 확인
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"\n📁 출력 디렉토리: {OUTPUT_DIR}")
    print(f"🔗 모델: {MODEL_NAME}")
    print(f"🎼 트랙 수: {len(TRACK_CONFIGS)}")
    print(f"⏱️  트랙 길이: {TRACK_DURATION_SEC}초")

    # 기존 BGM 파일 안내
    existing_files = list(OUTPUT_DIR.glob("*.mp3")) + list(OUTPUT_DIR.glob("*.wav"))
    if existing_files:
        print(f"\n⚠️  기존 BGM 파일 {len(existing_files)}개 발견:")
        for f in existing_files:
            print(f"   - {f.name}")

    # 트랙 순차 생성 (API 부하 분산)
    success_count = 0
    for i, config in enumerate(TRACK_CONFIGS):
        try:
            await generate_single_track(client, config, i)
            success_count += 1
        except Exception as e:
            print(f"  ⚠️  트랙 {i + 1} 건너뜀: {e}")
            continue

        # 다음 트랙 전 짧은 대기 (API 속도 제한 회피)
        if i < len(TRACK_CONFIGS) - 1:
            print("   ⏳ 다음 트랙 준비 중 (3초 대기)...")
            await asyncio.sleep(3)

    print("\n" + "=" * 60)
    print(f"✅ 완료! {success_count}/{len(TRACK_CONFIGS)} 트랙 생성 성공")
    print(f"📁 저장 위치: {OUTPUT_DIR}")
    print("=" * 60)

    if success_count > 0:
        print("\n💡 다음 단계:")
        print("   1. WAV → MP3 변환이 필요하면 ffmpeg를 사용하세요:")
        print("      ffmpeg -i input.wav -b:a 192k output.mp3")
        print("   2. sound_manager.dart에서 새 BGM 목록을 업데이트하세요")


if __name__ == "__main__":
    asyncio.run(main())
