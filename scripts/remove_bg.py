"""
해원의 문 — 이미지 배경 투명화 스크립트
AI 생성 이미지에서 반투명 배경(안개/흰색 그라데이션)을 완전 투명으로 변환합니다.

사용법: python scripts/remove_bg.py
"""

import os
import sys
from pathlib import Path
from PIL import Image
import numpy as np
import shutil

# 설정
ASSETS_DIR = Path(__file__).parent.parent / "assets" / "images"
BACKUP_DIR = Path(__file__).parent.parent / "assets" / "images_backup"

# 처리 대상 폴더 (fx 포함 — 마스터 요청)
TARGET_FOLDERS = ["enemies", "heroes", "towers", "projectiles", "objects", "fx"]

# 배경 판별 임계값
ALPHA_THRESHOLD = 200       # 이 이상 불투명한 픽셀만 보존
EDGE_SAMPLE_SIZE = 15       # 가장자리에서 샘플링할 픽셀 수
COLOR_TOLERANCE = 60        # 배경색과의 차이 허용 범위


def get_dominant_bg_color(img_array: np.ndarray) -> np.ndarray:
    """이미지 코너에서 배경색 추정"""
    h, w = img_array.shape[:2]
    
    # 코너 4곳 + 가장자리 중앙에서 픽셀 샘플링
    samples = []
    edge = EDGE_SAMPLE_SIZE
    
    # 코너 영역
    corners = [
        img_array[0:edge, 0:edge],           # 좌상
        img_array[0:edge, w-edge:w],          # 우상
        img_array[h-edge:h, 0:edge],          # 좌하
        img_array[h-edge:h, w-edge:w],        # 우하
    ]
    
    for corner in corners:
        # RGBA에서 알파가 낮은(투명에 가까운) 픽셀만 수집
        flat = corner.reshape(-1, 4)
        # 반투명 픽셀 (alpha < 250) 수집 → 배경 후보
        semi_transparent = flat[flat[:, 3] < 250]
        if len(semi_transparent) > 0:
            samples.append(semi_transparent)
    
    if not samples:
        # 모든 코너가 완전 불투명 → 코너 RGB 평균을 배경으로 간주
        corner_pixels = np.concatenate([c.reshape(-1, 4) for c in corners])
        return corner_pixels[:, :3].mean(axis=0).astype(np.uint8)
    
    all_samples = np.concatenate(samples)
    return all_samples[:, :3].mean(axis=0).astype(np.uint8)


def remove_semi_transparent_bg(img: Image.Image) -> Image.Image:
    """반투명 배경을 완전 투명으로 변환"""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    
    arr = np.array(img, dtype=np.float32)
    alpha = arr[:, :, 3]
    rgb = arr[:, :, :3]
    
    # 방법 1: 매우 낮은 알파(거의 투명) → 완전 투명으로
    very_low_alpha = alpha < 30
    arr[very_low_alpha, 3] = 0
    
    # 방법 2: 중간 알파(반투명 영역) 분석
    # 빈 공간(내용이 없는 영역)의 반투명 픽셀을 투명으로
    # 핵심: 밝고 채도 낮은 반투명 픽셀 = 배경 안개
    medium_alpha = (alpha >= 30) & (alpha < ALPHA_THRESHOLD)
    
    if medium_alpha.any():
        # 해당 영역의 RGB 분석
        medium_rgb = rgb[medium_alpha]
        
        # 밝기 계산 (0~255)
        brightness = medium_rgb.mean(axis=1)
        
        # 채도 계산 (max-min)
        saturation = medium_rgb.max(axis=1) - medium_rgb.min(axis=1)
        
        # 밝고 채도 낮은 = 배경 안개 (흰색/회색 계열)
        is_bg_fog = (brightness > 180) & (saturation < 50)
        
        # 해당 픽셀 투명화
        medium_indices = np.where(medium_alpha)
        fog_mask = is_bg_fog
        
        arr[medium_indices[0][fog_mask], medium_indices[1][fog_mask], 3] = 0
        
        # 나머지 중간 알파: 밝기에 비례해서 약간 투명하게
        remaining = ~fog_mask
        remaining_brightness = brightness[remaining]
        # 매우 밝은 반투명 → 더 투명하게
        fade_factor = np.clip((remaining_brightness - 150) / 105, 0, 0.7)
        current_alpha = arr[medium_indices[0][remaining], medium_indices[1][remaining], 3]
        new_alpha = current_alpha * (1.0 - fade_factor)
        arr[medium_indices[0][remaining], medium_indices[1][remaining], 3] = new_alpha
    
    # 방법 3: 가장자리 정리 — 이미지 테두리의 불투명 배경도 처리
    # 이미지 경계에서 안쪽으로 flood-fill식 투명화
    h, w = arr.shape[:2]
    border = 5
    
    # 테두리 영역에서 밝고 불투명한 픽셀도 투명화
    for region in [
        arr[0:border, :],        # 상단
        arr[h-border:h, :],      # 하단
        arr[:, 0:border],        # 좌측
        arr[:, w-border:w],      # 우측
    ]:
        region_alpha = region[:, :, 3]
        region_rgb = region[:, :, :3]
        region_brightness = region_rgb.mean(axis=2)
        region_saturation = region_rgb.max(axis=2) - region_rgb.min(axis=2)
        
        # 밝고 채도 낮은 불투명 테두리 → 투명화
        bg_mask = (region_brightness > 200) & (region_saturation < 40) & (region_alpha > 100)
        region[bg_mask, 3] = 0
    
    # 알파 값 정수로 클램핑
    arr[:, :, 3] = np.clip(arr[:, :, 3], 0, 255)
    
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def process_image(filepath: Path) -> bool:
    """단일 이미지 처리 (투명 배경 적용)"""
    try:
        img = Image.open(filepath)
        if img.mode != "RGBA":
            img = img.convert("RGBA")
        
        # 원본 분석: 이미 완전 투명 배경이면 스킵
        arr = np.array(img)
        total_pixels = arr.shape[0] * arr.shape[1]
        transparent_pixels = (arr[:, :, 3] == 0).sum()
        transparent_ratio = transparent_pixels / total_pixels
        
        # 60% 이상 투명이면 이미 처리됨으로 간주
        if transparent_ratio > 0.60:
            print(f"  ⏭ 이미 투명: {filepath.name} ({transparent_ratio:.0%})")
            return False
        
        # 배경 제거 적용
        processed = remove_semi_transparent_bg(img)
        
        # 처리 결과 확인
        processed_arr = np.array(processed)
        new_transparent = (processed_arr[:, :, 3] == 0).sum()
        improvement = (new_transparent - transparent_pixels) / total_pixels
        
        if improvement > 0.01:  # 1% 이상 개선 시에만 저장
            processed.save(filepath, "PNG", optimize=True)
            print(f"  ✅ 처리: {filepath.name} (투명 +{improvement:.1%})")
            return True
        else:
            print(f"  ⏭ 변화 미미: {filepath.name}")
            return False
            
    except Exception as e:
        print(f"  ❌ 오류: {filepath.name} — {e}")
        return False


def main():
    """메인 실행"""
    print("🦉 해원의 문 — 이미지 배경 투명화 시작!")
    print(f"   에셋 경로: {ASSETS_DIR}")
    print(f"   백업 경로: {BACKUP_DIR}")
    print()
    
    if not ASSETS_DIR.exists():
        print(f"❌ 에셋 디렉토리를 찾을 수 없어요: {ASSETS_DIR}")
        sys.exit(1)
    
    # 백업 생성
    if not BACKUP_DIR.exists():
        print("📦 원본 백업 생성 중...")
        for folder in TARGET_FOLDERS:
            src = ASSETS_DIR / folder
            dst = BACKUP_DIR / folder
            if src.exists():
                shutil.copytree(src, dst)
                print(f"   ✅ {folder}/ 백업 완료")
        print()
    else:
        print("📦 백업이 이미 존재합니다. 스킵.\n")
    
    # 폴더별 처리
    total_processed = 0
    total_skipped = 0
    
    for folder in TARGET_FOLDERS:
        folder_path = ASSETS_DIR / folder
        if not folder_path.exists():
            print(f"⚠  {folder}/ 폴더 없음. 스킵.")
            continue
        
        png_files = list(folder_path.glob("*.png"))
        print(f"📁 {folder}/ ({len(png_files)}개 파일)")
        
        for filepath in sorted(png_files):
            if process_image(filepath):
                total_processed += 1
            else:
                total_skipped += 1
        
        print()
    
    # 결과 요약
    print("=" * 50)
    print(f"✅ 완료! 처리: {total_processed}개 | 스킵: {total_skipped}개")
    print(f"📦 원본 백업: {BACKUP_DIR}")
    print("🎮 'flutter run -d windows'로 결과를 확인하세요!")


if __name__ == "__main__":
    main()
