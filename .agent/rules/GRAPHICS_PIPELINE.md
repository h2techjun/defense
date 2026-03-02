# 🎨 그래픽 파이프라인 규칙 (Graphics Pipeline Standard)

> **확정 v9** — 2026-03-03 | 이전 실패: 크로마키(초록/회색/마젠타) 모두 부적합

## 핵심 원칙

**에셋 유형별 배경+투명화 방법을 반드시 분리**

| 에셋 유형 | 배경색 | 투명화 방법 | 이유 |
|-----------|--------|-------------|------|
| 캐릭터(영웅/적) | 흰 배경 | **rembg** (AI, isnet-anime) | 캐릭터 형태를 의미적으로 인식 |
| 이펙트(VFX) | **검정 배경** | **밝기 기반** (어둠→투명) | 이펙트는 발광체, rembg 사용 금지 |
| 배경/UI | 없음 | 투명화 안 함 | 배경은 불투명 유지 |

---

## 1. 캐릭터 파이프라인 (영웅/적/타워)

### 프롬프트
```
배경: "On clean solid white background, NO shadow, NO drop shadow, NO ground, character floating in pure white space"
```

### 투명화: `make_transparent()` — rembg AI
```python
from rembg import remove
def make_transparent(img):
    img = img.convert("RGBA")
    return remove(img)
```

### 정밀 재처리: `reprocess_bg.py` — rembg isnet-anime + alpha_matting
```python
from rembg import remove, new_session
SESSION = new_session("isnet-anime")  # 애니/게임 캐릭터 최적화

def make_transparent(img):
    return remove(img, session=SESSION,
        alpha_matting=True,
        alpha_matting_foreground_threshold=240,
        alpha_matting_background_threshold=20,
        alpha_matting_erode_size=10)
```

### 의존성
```
pip install rembg onnxruntime pillow
# onnxruntime >= 1.24.2 (NumPy 2.x 호환 필수)
```

---

## 2. 이펙트 파이프라인 (VFX)

### 프롬프트
```
스타일: "Abstract stylized 2D game VFX effect, clean vector shapes, vibrant glowing neon, soft bloom, premium. ONLY the effect itself, absolutely NO character, NO person, NO creature, NO animal, NO figure. Pure abstract energy/particle effect"
배경: "On solid pure black (#000000) background, pitch black void, nothing else"
```

### 투명화: `make_transparent_fx()` — 밝기 기반
```python
def make_transparent_fx(img):
    """이펙트는 발광체 → 어두운 부분 = 배경"""
    img = img.convert("RGBA")
    d = np.array(img)
    r, g, b = d[:,:,0].astype(int), d[:,:,1].astype(int), d[:,:,2].astype(int)
    brightness = (r + g + b) / 3
    # 어두운 픽셀(밝기 < 40) → 투명
    dark = brightness < 40
    d[:,:,3][dark] = 0
    # 경계(40~80) → 반투명 (부드러운 전환)
    semi = (brightness >= 40) & (brightness < 80)
    alpha_ratio = (brightness[semi] - 40) / 40
    d[:,:,3][semi] = (alpha_ratio * 255).astype(np.uint8)
    return Image.fromarray(d)
```

> ⚠️ rembg는 이펙트에 사용 금지! 캐릭터를 '주체'로 인식하여 이펙트를 배경으로 잘못 제거함

---

## 3. 실패 이력 (ANTI-PATTERNS)

| 방식 | 실패 이유 | 날짜 |
|------|-----------|------|
| 크로마키 초록 (#00FF00) | 캐릭터의 녹색 요소 손상, 다리 사이 잔여 | 2026-03-02 |
| 크로마키 회색 (#808080) | 캐릭터 갑옷/금속이 회색이라 내부 손상 | 2026-03-02 |
| 크로마키 마젠타 (#FF00FF) | 근본적으로 같은 문제 반복 가능 | 2026-03-02 |
| 순수 회색 직접 삭제 | 위치 무관 삭제로 캐릭터 내부 훼손 | 2026-03-02 |
| rembg로 이펙트 처리 | 캐릭터를 주체로 인식, 이펙트 제거됨 | 2026-03-02 |

---

## 4. 생성 도구

| 도구 | 경로 | 용도 |
|------|------|------|
| `bulk_imagen_v2.py` | `tools/` | 전체 에셋 일괄 생성 (Imagen API + rembg/FX 투명화) |
| `reprocess_bg.py` | `tools/` | 기존 에셋 정밀 재처리 (isnet-anime + alpha_matting) |

### 실행 명령
```powershell
# 전체 생성
python tools/bulk_imagen_v2.py

# 카테고리별 생성
python tools/bulk_imagen_v2.py --only heroes
python tools/bulk_imagen_v2.py --only effects
python tools/bulk_imagen_v2.py --only enemies

# 정밀 재처리
python tools/reprocess_bg.py heroes
python tools/reprocess_bg.py effects enemies
```
