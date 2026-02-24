"""
해원의 문 — AI 기반 이미지 배경 제거 스크립트 (rembg + U2Net)
Pillow 기반보다 훨씬 정확한 딥러닝 배경 제거를 수행합니다.

사용법: python scripts/remove_bg_ai.py
"""

import os
import sys
from pathlib import Path
from PIL import Image
from rembg import remove
import numpy as np
import shutil

# 설정
ASSETS_DIR = Path(__file__).parent.parent / "assets" / "images"
BACKUP_DIR = Path(__file__).parent.parent / "assets" / "images_backup"

# 처리 대상 폴더 (fx 포함 — 마스터 요청)
TARGET_FOLDERS = ["enemies", "heroes", "towers", "projectiles", "objects", "fx"]


def process_image(filepath: Path) -> bool:
    """rembg AI로 배경 제거"""
    try:
        with open(filepath, "rb") as f:
            input_data = f.read()
        
        # rembg AI 배경 제거 실행
        output_data = remove(
            input_data,
            alpha_matting=True,           # 알파 매팅으로 가장자리 부드럽게
            alpha_matting_foreground_threshold=240,
            alpha_matting_background_threshold=10,
            alpha_matting_erode_size=10,
        )
        
        # 결과 저장
        output_img = Image.open(__import__("io").BytesIO(output_data))
        
        # 비교: 개선이 있었는지 확인
        original_img = Image.open(filepath).convert("RGBA")
        orig_arr = np.array(original_img)
        out_arr = np.array(output_img.convert("RGBA"))
        
        total_pixels = orig_arr.shape[0] * orig_arr.shape[1]
        orig_transparent = (orig_arr[:, :, 3] == 0).sum()
        new_transparent = (out_arr[:, :, 3] == 0).sum()
        
        improvement = (new_transparent - orig_transparent) / total_pixels
        
        if improvement > 0.005:  # 0.5% 이상 개선 시 저장
            output_img.save(filepath, "PNG", optimize=True)
            print(f"  ✅ {filepath.name} (투명 +{improvement:.1%})")
            return True
        else:
            print(f"  ⏭ {filepath.name} (이미 충분히 투명)")
            return False
        
    except Exception as e:
        print(f"  ❌ {filepath.name} — {e}")
        return False


def main():
    print("🦉 해원의 문 — AI 배경 제거 시작! (rembg + U2Net)")
    print(f"   에셋 경로: {ASSETS_DIR}")
    print()
    
    if not ASSETS_DIR.exists():
        print(f"❌ 에셋 디렉토리 없음: {ASSETS_DIR}")
        sys.exit(1)
    
    # 백업에서 원본 복원 (이전 Pillow 처리 결과를 되돌림)
    if BACKUP_DIR.exists():
        print("🔄 백업에서 원본 복원 중...")
        for folder in TARGET_FOLDERS:
            src = BACKUP_DIR / folder
            dst = ASSETS_DIR / folder
            if src.exists() and dst.exists():
                for png in src.glob("*.png"):
                    shutil.copy2(png, dst / png.name)
                print(f"   ✅ {folder}/ 원본 복원")
        print()
    
    # 폴더별 AI 처리
    total_processed = 0
    total_skipped = 0
    
    for folder in TARGET_FOLDERS:
        folder_path = ASSETS_DIR / folder
        if not folder_path.exists():
            print(f"⚠  {folder}/ 없음. 스킵.")
            continue
        
        png_files = sorted(folder_path.glob("*.png"))
        print(f"📁 {folder}/ ({len(png_files)}개)")
        
        for filepath in png_files:
            if process_image(filepath):
                total_processed += 1
            else:
                total_skipped += 1
        
        print()
    
    print("=" * 50)
    print(f"✅ AI 처리 완료! 처리: {total_processed}개 | 스킵: {total_skipped}개")
    print(f"📦 원본 백업: {BACKUP_DIR}")
    print("🎮 'flutter run -d windows'로 결과를 확인하세요!")


if __name__ == "__main__":
    main()
