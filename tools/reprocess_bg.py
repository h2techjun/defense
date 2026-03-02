"""reprocess_bg.py v9: rembg AI 기반 정밀 배경 제거
isnet-anime 모델 (애니/게임 캐릭터 최적화) + alpha_matting (경계면 매끄럽게)"""
import os, glob, sys
from PIL import Image
from rembg import remove, new_session

BASE = r"e:\defense\assets\images"

# isnet-anime: 애니/게임 캐릭터에 최적화된 모델
print("🦉 rembg isnet-anime 모델 로딩 중...")
SESSION = new_session("isnet-anime")
print("✅ 모델 로딩 완료!")

def make_transparent(img):
    """rembg AI 기반 정밀 배경 제거"""
    img = img.convert("RGBA")
    result = remove(
        img,
        session=SESSION,
        alpha_matting=True,
        alpha_matting_foreground_threshold=240,
        alpha_matting_background_threshold=20,
        alpha_matting_erode_size=10,
    )
    return result

# 처리할 폴더 (인자로 지정 가능)
if len(sys.argv) > 1:
    folders = sys.argv[1:]
else:
    folders = ["heroes"]

count = 0
for folder in folders:
    path = os.path.join(BASE, folder)
    if not os.path.exists(path):
        print(f"⚠️ {folder} 폴더 없음, 스킵")
        continue
    files = sorted(glob.glob(os.path.join(path, "*.png")))
    print(f"\n📂 {folder} ({len(files)}개)")
    for f in files:
        name = os.path.relpath(f, BASE)
        print(f"  재처리: {name}", end=" ... ", flush=True)
        try:
            img = Image.open(f)
            img = make_transparent(img)
            img.save(f, "PNG")
            print("✅")
            count += 1
        except Exception as e:
            print(f"❌ {e}")

print(f"\n🎉 {count}개 파일 재처리 완료!")
