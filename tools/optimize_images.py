"""이미지 최적화 스크립트: PNG → WebP(투명) / JPG(불투명), 리사이즈 포함"""
from PIL import Image
import os
import sys

BASE = "assets/images"

# 카테고리별 최대 해상도 설정
MAX_SIZES = {
    "bg": 1408,          # 배경은 원본 유지 (게임 화면 크기)
    "portraits": 512,    # 초상화: 512px
    "effects": 256,      # 이펙트: 256px
    "enemies": 256,      # 적: 256px
    "heroes": 256,       # 영웅: 256px (스프라이트)
    "towers": 256,       # 타워: 256px
    "objects": 512,      # 맵 오브젝트: 512px
    "soldiers": 256,     # 병사: 256px
    "ui": 512,           # UI 아이콘: 512px
    "fx": 128,           # 작은 이펙트: 128px (이미 128이므로 유지)
    "assets": 512,       # app_icon 등
}

total_before = 0
total_after = 0
converted = 0
errors = []

for root, dirs, files in os.walk(BASE):
    for f in files:
        if not f.lower().endswith(".png"):
            continue

        path = os.path.join(root, f)
        rel = root.replace(BASE + "/", "").replace(BASE + "\\", "")
        cat = rel.split("/")[0].split("\\")[0]
        max_size = MAX_SIZES.get(cat, 512)

        orig_size = os.path.getsize(path)
        total_before += orig_size

        try:
            img = Image.open(path)

            # 리사이즈 (가로/세로 중 큰 쪽 기준)
            w, h = img.size
            if max(w, h) > max_size:
                ratio = max_size / max(w, h)
                new_w = int(w * ratio)
                new_h = int(h * ratio)
                img = img.resize((new_w, new_h), Image.LANCZOS)

            # 투명도 확인
            has_alpha = img.mode in ("RGBA", "LA", "PA")
            uses_alpha = False
            if has_alpha:
                alpha = img.getchannel("A")
                extrema = alpha.getextrema()
                uses_alpha = extrema[0] < 255

            name = os.path.splitext(f)[0]

            if uses_alpha:
                # 투명 → WebP
                out_path = os.path.join(root, name + ".webp")
                img.save(out_path, "WEBP", quality=80, method=4)
            else:
                # 불투명 → JPG
                out_path = os.path.join(root, name + ".jpg")
                if img.mode != "RGB":
                    img = img.convert("RGB")
                img.save(out_path, "JPEG", quality=85, optimize=True)

            new_size = os.path.getsize(out_path)
            total_after += new_size

            # 원본 PNG 삭제
            os.remove(path)

            ext = "webp" if uses_alpha else "jpg"
            reduction = (1 - new_size / orig_size) * 100
            converted += 1

            if orig_size > 500_000:  # 500KB 이상만 출력
                print(f"  {orig_size//1024:>6}KB → {new_size//1024:>4}KB  [{ext}] {reduction:>5.1f}%  {cat}/{f}")

        except Exception as e:
            errors.append(f"{path}: {e}")
            total_after += orig_size  # 실패 시 원본 크기 유지

print(f"\n{'='*50}")
print(f"변환: {converted}개")
print(f"전체: {total_before/1048576:.1f} MB → {total_after/1048576:.1f} MB")
print(f"절감: {(total_before-total_after)/1048576:.1f} MB ({(1-total_after/total_before)*100:.1f}%)")

if errors:
    print(f"\n에러 {len(errors)}건:")
    for e in errors:
        print(f"  {e}")
