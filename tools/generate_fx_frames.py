"""
fx/ 디렉토리에 이펙트 프레임 에셋 생성
기존 effects/ 에셋에서 4프레임 애니메이션 세트를 생성합니다.

프레임 구조: 원본 이미지를 약간씩 회전/스케일/투명도 변화를 주어 4프레임 애니메이션 생성
"""

import os
from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter
import math

ASSETS_DIR = Path(r"e:\defense\assets\images")
EFFECTS_DIR = ASSETS_DIR / "effects"
FX_DIR = ASSETS_DIR / "fx"

# 출력 크기 (게임 코드에서 48~64px로 사용)
OUTPUT_SIZE = 128

# 이펙트 타입별 소스 매핑
EFFECT_MAPPING = {
    # 피격/사망 이펙트 (멀티 프레임 소스 활용)
    "fx_hit_physical": {
        "sources": ["fx_hit_1.png", "fx_hit_2.png", "fx_hit_3.png", "fx_hit_4.png"],
        "mode": "multi_source"
    },
    "fx_hit_magic": {
        "sources": ["fx_lightning_1.png", "fx_lightning_2.png", "fx_lightning_3.png", "fx_lightning_4.png"],
        "mode": "multi_source"
    },
    "fx_hit_purify": {
        "sources": ["fx_fire_1.png", "fx_fire_2.png", "fx_fire_3.png", "fx_fire_4.png"],
        "mode": "multi_source"
    },
    "fx_death_ghost": {
        "sources": ["fx_hit_1.png", "fx_hit_2.png", "fx_hit_3.png", "fx_hit_4.png"],
        "mode": "multi_source_fade"  # 점점 투명해지는 사망 효과
    },
    # 영웅 스킬 이펙트 (단일 소스 → 4프레임 생성)
    "fx_kkaebi_flip": {
        "sources": ["fx_skill_kkaebi.png", "fx_attack_kkaebi.png"],
        "mode": "single_animate"
    },
    "fx_miho_foxfire": {
        "sources": ["fx_skill_guMiho.png", "fx_attack_guMiho.png"],
        "mode": "single_animate"
    },
    "fx_gangrim_summon": {
        "sources": ["fx_skill_gangrim.png", "fx_attack_gangrim.png"],
        "mode": "single_animate"
    },
    "fx_sua_grab": {
        "sources": ["fx_skill_sua.png", "fx_attack_sua.png"],
        "mode": "single_animate"
    },
    "fx_bari_ritual": {
        "sources": ["fx_skill_bari.png", "fx_attack_bari.png"],
        "mode": "single_animate"
    },
}


def load_and_resize(path: Path, size: int = OUTPUT_SIZE) -> Image.Image:
    """이미지를 로드하고 정사각형으로 리사이즈"""
    img = Image.open(path).convert("RGBA")
    # 가로세로 비율 유지하며 정사각형에 맞추기
    img.thumbnail((size, size), Image.Resampling.LANCZOS)
    # 정사각형 캔버스에 중앙 배치
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset_x = (size - img.width) // 2
    offset_y = (size - img.height) // 2
    canvas.paste(img, (offset_x, offset_y), img)
    return canvas


def generate_multi_source(prefix: str, sources: list[str]):
    """여러 소스 이미지를 각각 하나의 프레임으로 사용"""
    for i, src_name in enumerate(sources):
        src_path = EFFECTS_DIR / src_name
        if not src_path.exists():
            print(f"  ⚠️ 소스 없음: {src_name}")
            continue
        img = load_and_resize(src_path)
        out_path = FX_DIR / f"{prefix}_{i}.png"
        img.save(out_path)
        print(f"  ✅ {out_path.name}")


def generate_multi_source_fade(prefix: str, sources: list[str]):
    """소스를 사용하되 점점 투명해지는 사망 이펙트"""
    alphas = [255, 200, 130, 60]  # 프레임별 투명도
    for i, src_name in enumerate(sources):
        src_path = EFFECTS_DIR / src_name
        if not src_path.exists():
            print(f"  ⚠️ 소스 없음: {src_name}")
            continue
        img = load_and_resize(src_path)
        # 투명도 조절
        r, g, b, a = img.split()
        a = a.point(lambda x: min(x, alphas[i]))
        img = Image.merge("RGBA", (r, g, b, a))
        # 약간 확대 (분해 효과)
        scale = 1.0 + (i * 0.15)
        new_size = int(OUTPUT_SIZE * scale)
        img = img.resize((new_size, new_size), Image.Resampling.LANCZOS)
        # 다시 원래 크기 캔버스에 중앙 배치
        canvas = Image.new("RGBA", (OUTPUT_SIZE, OUTPUT_SIZE), (0, 0, 0, 0))
        offset = (OUTPUT_SIZE - new_size) // 2
        canvas.paste(img, (offset, offset), img)
        out_path = FX_DIR / f"{prefix}_{i}.png"
        canvas.save(out_path)
        print(f"  ✅ {out_path.name} (alpha={alphas[i]})")


def generate_single_animate(prefix: str, sources: list[str]):
    """단일 소스 이미지에서 4프레임 애니메이션 생성 (스케일+회전 변화)"""
    # 첫 번째 소스를 기본으로, 두 번째가 있으면 교차 사용
    src_path = EFFECTS_DIR / sources[0]
    if not src_path.exists():
        # 대체 소스 시도
        if len(sources) > 1:
            src_path = EFFECTS_DIR / sources[1]
        if not src_path.exists():
            print(f"  ⚠️ 소스 없음: {sources}")
            return

    base_img = load_and_resize(src_path)

    # 프레임별 변형: 스케일, 회전, 밝기
    transforms = [
        {"scale": 0.7, "rotate": 0, "brightness": 0.9},    # 시작 (작게)
        {"scale": 1.0, "rotate": 5, "brightness": 1.2},    # 확대
        {"scale": 1.1, "rotate": -5, "brightness": 1.4},   # 최대
        {"scale": 0.9, "rotate": 0, "brightness": 0.8},    # 수축
    ]

    for i, t in enumerate(transforms):
        img = base_img.copy()

        # 밝기 조절
        enhancer = ImageEnhance.Brightness(img)
        img = enhancer.enhance(t["brightness"])

        # 회전
        if t["rotate"] != 0:
            img = img.rotate(t["rotate"], expand=False, resample=Image.Resampling.BICUBIC)

        # 스케일
        new_size = int(OUTPUT_SIZE * t["scale"])
        img = img.resize((new_size, new_size), Image.Resampling.LANCZOS)

        # 캔버스에 중앙 배치
        canvas = Image.new("RGBA", (OUTPUT_SIZE, OUTPUT_SIZE), (0, 0, 0, 0))
        offset = (OUTPUT_SIZE - new_size) // 2
        canvas.paste(img, (offset, offset), img)

        out_path = FX_DIR / f"{prefix}_{i}.png"
        canvas.save(out_path)
        print(f"  ✅ {out_path.name} (scale={t['scale']}, rot={t['rotate']}°)")


def main():
    """메인: fx/ 디렉토리에 36개 이펙트 프레임 생성"""
    FX_DIR.mkdir(parents=True, exist_ok=True)
    print(f"🎨 이펙트 프레임 생성 시작 → {FX_DIR}")
    print(f"📁 소스 디렉토리: {EFFECTS_DIR}")
    print()

    total = 0
    for prefix, config in EFFECT_MAPPING.items():
        mode = config["mode"]
        sources = config["sources"]
        print(f"▶ {prefix} ({mode})")

        if mode == "multi_source":
            generate_multi_source(prefix, sources)
        elif mode == "multi_source_fade":
            generate_multi_source_fade(prefix, sources)
        elif mode == "single_animate":
            generate_single_animate(prefix, sources)

        total += 4
        print()

    print(f"🎉 총 {total}개 프레임 생성 완료!")

    # 결과 확인
    generated = list(FX_DIR.glob("*.png"))
    print(f"📂 fx/ 디렉토리에 {len(generated)}개 파일")


if __name__ == "__main__":
    main()
