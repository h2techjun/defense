import os
import time
import requests
from dotenv import load_dotenv

# 환경 변수 로드 (.env 파일에서 HUGGINGFACE_API_KEY 읽기)
load_dotenv()
API_KEY = os.getenv("HUGGINGFACE_API_KEY")

# HuggingFace Inference API 엔드포인트
# AudioGen-Medium 모델 사용 (SFX 및 짧은 오디오 생성 특화)
API_URL = "https://api-inference.huggingface.co/models/facebook/audiogen-medium"
headers = {"Authorization": f"Bearer {API_KEY}"}

# 저장 경로 매핑 (SoundManager.dart 기반 모든 SFX)
SFX_DIR = "assets/audio/sfx"

SFX_PROMPTS = {
    # 타워 무기음
    "Arrow.wav": "A sharp, fast sound of a wooden arrow being shot from a bow",
    "cannon_fire.wav": "A loud, echoing medieval cannon blast with heavy bass and smoke",
    "Magical.wav": "A mystical, glowing magical chime with a swift whoosh",
    "sotdae_purify.wav": "A bright, resonant holy bell chime, followed by a soft airy whoosh",
    
    # 적 관련
    "enemy_hit.wav": "A fleshy impact sound mixed with a metallic armor clink",
    "enemy_death.wav": "A supernatural guttural shriek of a monster dying and fading into ash",
    "boss_appear.wav": "A terrifying, low-pitched dark monster roar echoing loudly",
    
    # 영웅 관련
    "hero_skill.wav": "An epic, energetic magical burst sound for a hero ultimate skill",
    "hero_death.wav": "A dramatic, solemn sound of a warrior falling, magical energy dissipating",
    "hero_revive.wav": "A glorious, uplifting ascending magical chime, holy resurrection light",
    
    # 타워 분기 (4티어) 특수 효과음
    "branch_select.wav": "A majestic, epic orchestral brass fanfare for class upgrade success",
    "branch_thunder.wav": "A sudden, violent crackling lightning strike and loud thunder clap",
    "branch_fire.wav": "A massive, powerful roaring fire blast and burning whoosh",
    "branch_grapple.wav": "A heavy, meaty slam with a bone-crunching grapple thud",
    
    # 시스템
    "wave_start.wav": "A deep, ominous ancient war horn blowing across a foggy battlefield",
}

def generate_audio(filename, prompt):
    if not API_KEY:
        print("[오류] .env 파일에 HUGGINGFACE_API_KEY가 설정되지 않았습니다!")
        return False
        
    print(f"🎙️ '{filename}' 생성 중... (프롬프트: {prompt})")
    
    payload = {"inputs": prompt}
    try:
        response = requests.post(API_URL, headers=headers, json=payload)
        
        if response.status_code == 200:
            filepath = os.path.join(SFX_DIR, filename)
            with open(filepath, 'wb') as f:
                f.write(response.content)
            print(f"✅ 생성 성공: {filepath}")
            return True
        else:
            print(f"❌ 생성 실패 ({response.status_code}): {response.text}")
            return False
    except Exception as e:
        print(f"🚨 네트워크 오류: {str(e)}")
        return False

def main():
    print("==================================================")
    print("   🦉 해원의 문 - AI SFX 팩토리 (AudioGen) 가동   ")
    print("==================================================")
    
    if not os.path.exists(SFX_DIR):
        os.makedirs(SFX_DIR)
        print(f"디렉토리 생성: {SFX_DIR}")

    success_count = 0
    total = len(SFX_PROMPTS)
    
    for i, (filename, prompt) in enumerate(SFX_PROMPTS.items(), 1):
        print(f"\n[{i}/{total}]")
        
        # 파일이 이미 존재하면 건너뛰기 로직 (원하면 해제)
        filepath = os.path.join(SFX_DIR, filename)
        if os.path.exists(filepath):
            print(f"⏭️ {filename} 은(는) 이미 존재하여 건너뜁니다.")
            success_count += 1
            continue

        if generate_audio(filename, prompt):
            success_count += 1
            
        # HuggingFace API 무료 티어 리미트(Rate Limit) 방지를 위한 딜레이 (15초)
        if i < total:
            print("⏳ API 리미트 회피를 위해 20초 대기 중...")
            time.sleep(20)

    print("\n==================================================")
    print(f"🎉 모든 작업 완료! ({success_count}/{total} 성공)")
    print("생성된 .wav 파일들에 맞게 SoundManager.dart의 매핑을 변경하거나")
    print("pydub 등으로 .mp3 변환을 권장합니다.")
    print("==================================================")

if __name__ == "__main__":
    main()
