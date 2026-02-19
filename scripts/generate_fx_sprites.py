"""
폭발 이펙트 스프라이트 생성기
4프레임 물리 히트 이펙트 (fx_hit_physical_0 ~ fx_hit_physical_3)
카툰 스타일 — 오렌지/레드/옐로우 폭발
"""

from PIL import Image, ImageDraw, ImageFilter
import math
import random
import os

# 시드 고정 (재현성)
random.seed(42)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images', 'fx')
os.makedirs(OUTPUT_DIR, exist_ok=True)

SIZE = 128  # 각 프레임 크기


def radial_gradient(draw, center, radius, color_inner, color_outer, alpha_inner=255, alpha_outer=0):
    """방사형 그라데이션 원 그리기"""
    for r in range(int(radius), 0, -1):
        ratio = r / radius
        # 색상 보간
        red = int(color_outer[0] * ratio + color_inner[0] * (1 - ratio))
        green = int(color_outer[1] * ratio + color_inner[1] * (1 - ratio))
        blue = int(color_outer[2] * ratio + color_inner[2] * (1 - ratio))
        alpha = int(alpha_outer * ratio + alpha_inner * (1 - ratio))
        
        bbox = [center[0] - r, center[1] - r, center[0] + r, center[1] + r]
        draw.ellipse(bbox, fill=(red, green, blue, alpha))


def draw_spike(draw, cx, cy, angle, length, width, color):
    """방사형 스파이크 (뾰족한 광선)"""
    end_x = cx + math.cos(angle) * length
    end_y = cy + math.sin(angle) * length
    perp_angle = angle + math.pi / 2
    half_w = width / 2
    
    points = [
        (cx + math.cos(perp_angle) * half_w, cy + math.sin(perp_angle) * half_w),
        (end_x, end_y),
        (cx - math.cos(perp_angle) * half_w, cy - math.sin(perp_angle) * half_w),
    ]
    draw.polygon(points, fill=color)


def draw_debris(draw, cx, cy, count, max_dist, size_range=(2, 5)):
    """파편/잔해 점 그리기"""
    colors = [
        (255, 100, 30, 230),
        (200, 60, 20, 200),
        (255, 160, 50, 180),
        (180, 40, 10, 160),
    ]
    for _ in range(count):
        angle = random.uniform(0, math.pi * 2)
        dist = random.uniform(max_dist * 0.4, max_dist)
        x = cx + math.cos(angle) * dist
        y = cy + math.sin(angle) * dist
        s = random.randint(size_range[0], size_range[1])
        color = random.choice(colors)
        draw.ellipse([x - s, y - s, x + s, y + s], fill=color)


def generate_frame_0():
    """프레임 0: 초기 임팩트 — 밝은 별 모양 섬광"""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    
    # 외곽 글로우
    radial_gradient(draw, (cx, cy), 30, (255, 200, 50), (255, 100, 0), 200, 0)
    
    # 스파이크 (8방향)
    for i in range(8):
        angle = (i / 8) * math.pi * 2
        length = 25 + random.uniform(0, 15)
        width = 4 + random.uniform(0, 3)
        color = (255, 220, 80, 220) if i % 2 == 0 else (255, 160, 30, 200)
        draw_spike(draw, cx, cy, angle, length, width, color)
    
    # 중심 밝은 핵
    radial_gradient(draw, (cx, cy), 12, (255, 255, 255), (255, 230, 100), 255, 180)
    
    # 약간의 블러
    img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
    
    return img


def generate_frame_1():
    """프레임 1: 확장 — 오렌지 불꽃 구름 + 스파크"""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    
    # 외곽 오렌지 구름
    for _ in range(6):
        ox = cx + random.randint(-15, 15)
        oy = cy + random.randint(-15, 15)
        r = random.randint(18, 28)
        radial_gradient(draw, (ox, oy), r, (255, 140, 40), (200, 60, 10), 200, 30)
    
    # 스파이크 (짧고 많은)
    for i in range(12):
        angle = (i / 12) * math.pi * 2 + random.uniform(-0.2, 0.2)
        length = 20 + random.uniform(0, 20)
        width = 3 + random.uniform(0, 2)
        draw_spike(draw, cx, cy, angle, length, width, (255, 180, 50, 180))
    
    # 중심 밝은 핵
    radial_gradient(draw, (cx, cy), 16, (255, 255, 230), (255, 200, 60), 255, 100)
    
    # 파편
    draw_debris(draw, cx, cy, 12, 35)
    
    img = img.filter(ImageFilter.GaussianBlur(radius=1.0))
    
    return img


def generate_frame_2():
    """프레임 2: 최대 크기 — 큰 불꽃 구름"""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    
    # 큰 외곽 구름 (다크 레드)
    for _ in range(8):
        ox = cx + random.randint(-18, 18)
        oy = cy + random.randint(-18, 18)
        r = random.randint(22, 35)
        radial_gradient(draw, (ox, oy), r, (220, 100, 30), (150, 40, 10), 220, 20)
    
    # 중간 오렌지 레이어
    for _ in range(5):
        ox = cx + random.randint(-10, 10)
        oy = cy + random.randint(-10, 10)
        r = random.randint(15, 22)
        radial_gradient(draw, (ox, oy), r, (255, 180, 60), (255, 120, 30), 230, 60)
    
    # 스파이크 (방사형)
    for i in range(10):
        angle = (i / 10) * math.pi * 2 + random.uniform(-0.15, 0.15)
        length = 25 + random.uniform(0, 25)
        width = 3 + random.uniform(0, 3)
        draw_spike(draw, cx, cy, angle, length, width, (255, 150, 30, 160))
    
    # 밝은 핵
    radial_gradient(draw, (cx, cy), 14, (255, 255, 240), (255, 200, 80), 255, 80)
    
    # 파편 (더 많이, 멀리)
    draw_debris(draw, cx, cy, 18, 45, (2, 6))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=1.2))
    
    return img


def generate_frame_3():
    """프레임 3: 최대 확장 — 가장 큰 폭발 + 흩어지는 파편"""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    
    # 가장 큰 외곽 폭발 구름
    for _ in range(10):
        ox = cx + random.randint(-22, 22)
        oy = cy + random.randint(-22, 22)
        r = random.randint(25, 40)
        radial_gradient(draw, (ox, oy), r, (200, 80, 20), (120, 30, 5), 200, 10)
    
    # 오렌지 불꽃 중간층
    for _ in range(6):
        ox = cx + random.randint(-12, 12)
        oy = cy + random.randint(-12, 12)
        r = random.randint(18, 25)
        radial_gradient(draw, (ox, oy), r, (255, 160, 50), (230, 100, 20), 210, 40)
    
    # 스파이크 (많고 길게)
    for i in range(14):
        angle = (i / 14) * math.pi * 2 + random.uniform(-0.3, 0.3)
        length = 30 + random.uniform(0, 25)
        width = 2 + random.uniform(0, 3)
        draw_spike(draw, cx, cy, angle, length, width, (255, 130, 20, 150))
    
    # 밝은 핵 (약간 작아짐 — 소멸 시작)
    radial_gradient(draw, (cx, cy), 12, (255, 240, 200), (255, 180, 60), 240, 60)
    
    # 파편 (가장 많이, 가장 멀리)
    draw_debris(draw, cx, cy, 25, 55, (1, 5))
    
    img = img.filter(ImageFilter.GaussianBlur(radius=1.5))
    
    return img


if __name__ == '__main__':
    generators = [generate_frame_0, generate_frame_1, generate_frame_2, generate_frame_3]
    
    for i, gen in enumerate(generators):
        frame = gen()
        path = os.path.join(OUTPUT_DIR, f'fx_hit_physical_{i}.png')
        frame.save(path)
        print(f'✅ 저장: {path} ({frame.size[0]}x{frame.size[1]})')
    
    print(f'\n🎉 물리 히트 이펙트 4프레임 생성 완료! → {OUTPUT_DIR}')
