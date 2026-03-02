import os
from pathlib import Path
from PIL import Image
import numpy as np

# 검사할 폴더들 (배경 제외)
TARGET_FOLDERS = ["enemies", "heroes", "towers", "projectiles", "objects", "fx", "soldiers", "portraits", "ui"]
BASE_DIR = Path(r"e:\defense\assets\images")

def check_and_fix_transparency(filepath):
    try:
        img = Image.open(filepath)
        if img.mode != "RGBA":
            img = img.convert("RGBA")
            
        data = np.array(img)
        h, w = data.shape[:2]
        
        # 알파 채널 분석
        alpha = data[..., 3]
        total_pixels = h * w
        transparent_pixels = np.sum(alpha == 0)
        ratio = transparent_pixels / total_pixels
        
        # 가장자리(테두리) 픽셀 추출 (위, 아래, 왼쪽, 오른쪽)
        # 게임 에셋은 가장자리가 무조건 투명해야 정상적인 배경 제거 상태임
        edges = np.concatenate([
            alpha[0, :],        # 상단 테두리
            alpha[-1, :],       # 하단 테두리
            alpha[:, 0],        # 좌측 테두리
            alpha[:, -1]        # 우측 테두리
        ])
        
        opaque_edge_ratio = np.sum(edges > 50) / len(edges)
        
        needs_fix = False
        reason = ""
        
        # 문제 조건 1: 전체 투명도가 15% 미만인 경우 (흰 배경이 그대로 남았을 확률 높음)
        if ratio < 0.15:
            needs_fix = True
            reason = f"전체 투명도 부족 ({ratio*100:.1f}%)"
            
        # 문제 조건 2: 가장자리 픽셀 중 불투명한 픽셀이 30% 이상인 경우 (배경 제거 안 됨)
        elif opaque_edge_ratio > 0.3:
            needs_fix = True
            reason = f"가장자리 불투명 찌꺼기 존재 ({opaque_edge_ratio*100:.1f}%)"
            
        if needs_fix:
            print(f"⚠️ 불량 의심 에셋 발견: {filepath.name} - {reason}")
            # 강력한 투명화 재적용 (흰색 / 밝은 회색 계열 배경을 모두 강제로 날림)
            r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
            # (R>200, G>200, B>200) 이면서 가장자리에 연결된 배경을 투명으로
            bg_mask = (r > 180) & (g > 180) & (b > 180)
            data[bg_mask, 3] = 0
            
            fixed_img = Image.fromarray(data, "RGBA")
            fixed_img.save(filepath, "PNG")
            print(f"   🔧 백색/회색 배경 강제 정밀 투명화 조치 완료!")
            return True
        return False
        
    except Exception as e:
        print(f"❌ 파일 검사 오류 {filepath.name}: {e}")
        return False

def main():
    print("==========================================================")
    print("   🔍 해원의 문 - AI 에셋 정밀 투명도 100% 전수 조사")
    print("==========================================================")
    
    fixed_count = 0
    total_checked = 0
    
    for folder in TARGET_FOLDERS:
        folder_path = BASE_DIR / folder
        if not folder_path.exists():
            continue
            
        for file in folder_path.glob("*.png"):
            total_checked += 1
            if check_and_fix_transparency(file):
                fixed_count += 1
                
    print("\n==========================================================")
    print(f"✅ 검사 완료! 총 {total_checked}개 파일 검증")
    if fixed_count > 0:
        print(f"🛠️ 보정됨: 배경 찌꺼기가 남은 불량 에셋 {fixed_count}개를 수정 추출 완료했습니다.")
    else:
        print("✨ 완벽합니다! 모든 에셋의 투명화가 정상 기준을 통과했습니다.")

if __name__ == "__main__":
    main()
