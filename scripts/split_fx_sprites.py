"""
스프라이트 시트 4분할 스크립트
Downloads에서 복사된 2x2 그리드 스프라이트 시트를 4개의 개별 프레임으로 분리.

대상 (히트/사망 이펙트):
- fx_hit_physical.png → fx_hit_physical_0~3.png
- fx_hit_magic.png → fx_hit_magic_0~3.png
- fx_hit_purify.png → fx_hit_purify_0~3.png
- fx_death_ghost.png → fx_death_ghost_0~3.png

대상 (스킬 이펙트):
- fx_kkaebi_flip.png → fx_kkaebi_flip_0~3.png
- fx_miho_foxfire.png → fx_miho_foxfire_0~3.png
- fx_gangrim_summon.png → fx_gangrim_summon_0~3.png
- fx_sua_grab.png → fx_sua_grab_0~3.png
- fx_bari_ritual.png → fx_bari_ritual_0~3.png
"""

from PIL import Image
import os
import shutil

FX_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images', 'fx')
DOWNLOADS_DIR = os.path.join(os.path.expanduser('~'), 'Downloads')

# 분할 대상 목록
SPRITE_SHEETS = [
    # 히트/사망 이펙트 (기존)
    'fx_hit_physical',
    'fx_hit_magic',
    'fx_hit_purify',
    'fx_death_ghost',
    # 스킬 이펙트 (추가)
    'fx_kkaebi_flip',
    'fx_miho_foxfire',
    'fx_gangrim_summon',
    'fx_sua_grab',
    'fx_bari_ritual',
]


def copy_from_downloads(name: str) -> bool:
    """Downloads 폴더에서 FX 디렉토리로 복사 (없으면 스킵)"""
    src = os.path.join(DOWNLOADS_DIR, f'{name}.png')
    dst = os.path.join(FX_DIR, f'{name}.png')

    if os.path.exists(dst):
        return True  # 이미 존재

    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f'📥 복사: {src} → {dst}')
        return True

    return False


def split_sprite_sheet(name: str):
    """2x2 그리드 스프라이트 시트를 4개 개별 프레임으로 분할"""
    src_path = os.path.join(FX_DIR, f'{name}.png')

    if not os.path.exists(src_path):
        print(f'⚠️  건너뜀: {src_path} (파일 없음)')
        return False

    # 이미 분할된 프레임이 있으면 스킵
    first_frame = os.path.join(FX_DIR, f'{name}_0.png')
    if os.path.exists(first_frame):
        print(f'⏭️  건너뜀: {name} (이미 분할됨)')
        return True

    img = Image.open(src_path).convert('RGBA')
    w, h = img.size
    half_w = w // 2
    half_h = h // 2

    print(f'📐 {name}.png — 원본 크기: {w}x{h}, 프레임 크기: {half_w}x{half_h}')

    # 2x2 그리드 순서: 좌상, 우상, 좌하, 우하
    frames = [
        img.crop((0, 0, half_w, half_h)),           # 프레임 0: 좌상
        img.crop((half_w, 0, w, half_h)),            # 프레임 1: 우상
        img.crop((0, half_h, half_w, h)),             # 프레임 2: 좌하
        img.crop((half_w, half_h, w, h)),             # 프레임 3: 우하
    ]

    for i, frame in enumerate(frames):
        out_path = os.path.join(FX_DIR, f'{name}_{i}.png')
        frame.save(out_path)
        print(f'  ✅ {name}_{i}.png ({frame.size[0]}x{frame.size[1]})')

    return True


if __name__ == '__main__':
    # FX 디렉토리 보장
    os.makedirs(FX_DIR, exist_ok=True)

    # 1단계: Downloads에서 복사
    print('=' * 50)
    print('📥 1단계: Downloads → assets/images/fx/ 복사')
    print('=' * 50)
    for sheet_name in SPRITE_SHEETS:
        copy_from_downloads(sheet_name)

    # 2단계: 분할
    print()
    print('=' * 50)
    print('✂️  2단계: 스프라이트 시트 분할 (2x2 → 4프레임)')
    print('=' * 50)
    success_count = 0

    for sheet_name in SPRITE_SHEETS:
        if split_sprite_sheet(sheet_name):
            success_count += 1

    print(f'\n🎉 {success_count}/{len(SPRITE_SHEETS)} 스프라이트 시트 처리 완료! → {FX_DIR}')
