# 영웅 및 타워 스프라이트 생성 가이드

마스터, 고품질 스프라이트 에셋 생성을 위한 프롬프트와 파일명 가이드를 정리해 드려요! ✨
이 가이드를 활용해 외부 도구(Midjourney, DALL-E 등)에서 이미지를 생성하시면 됩니다.

---

## 1. 공통 스타일 가이드 (Prompt Base)

모든 이미지는 다음 스타일 키워드를 포함하는 것이 좋습니다:
> **Style**: "High-quality 2D game sprite, Korean traditional fantasy style, clean cel-shaded, vibrant colors, neutral lighting, white background (for easy transparency), full body, character centered."

---

## 2. 영웅 (Heroes) - 5종 x 3티어

영웅은 레벨에 따라 외형이 화려해집니다.

### 영웅 목록 및 프롬프트 핵심

| 영웅 ID | 이름 | 특징 (티어별 변화) |
| :--- | :--- | :--- |
| `kkaebi` | **깨비** | **T1**: 어린 도깨비, 나무 방망이 <br> **T2**: 늠름한 전사, 철퇴 <br> **T3**: 도깨비 왕, 번개 이펙트가 서린 황금 방망이 |
| `miho` | **미호** | **T1**: 소녀 모습, 꼬리 1개 <br> **T2**: 성숙한 여인, 꼬리 5개, 푸른 불꽃 <br> **T3**: 구미호 본연의 자태, 꼬리 9개, 화려한 한복 |
| `gangrim` | **강림** | **T1**: 수습 차사, 검은 도포 <br> **T2**: 노련한 차사, 명부와 거대한 검 <br> **T3**: 저승 총관, 영혼의 기운이 감도는 화려한 도포 |
| `sua` | **수아** | **T1**: 물의 아이, 간단한 장신구 <br> **T2**: 물의 정령, 화려한 물결 드레스 <br> **T3**: 동해 용궁의 공주, 용의 장식, 신비로운 오라 |
| `bari` | **바리** | **T1**: 무속인 소녀, 방울 <br> **T2**: 성화(聖花)를 든 무녀, 화려한 무복 <br> **T3**: 생명과 죽음의 신, 꽃들이 만개한 신성한 옷 |

### 파일 네이밍 규칙

- `assets/images/heroes/` 경로에 저장해 주세요.
- 형식: `hero_[영웅ID]_t[티어넘버].png` (예: `hero_kkaebi_t1.png`)

---

## 3. 병사 (Soldiers) - 2종

병영(Barracks) 타워에서 소환되는 지원군입니다.

- **일반 병사 (`normal`)**:
  - **Prompt**: "Korean Joseon era soldier, holding a spear, leather armor, basic military uniform."
  - **Filename**: `soldier_normal.png`
- **갑사 (`grappler`)**:
  - **Prompt**: "Heavy armored Korean soldier, holding a huge shield and mace, muscular, badass."
  - **Filename**: `soldier_grappler.png`

---

## 4. 타워 (Towers) - 5종 x 3티어

이미 `TowerRenderer`가 이 파일명들을 찾고 있어요!
파일명: `assets/images/towers/tower_[타워명]_t[티어].png`

| 타워 ID | 설명 | 핵심 키워드 |
| :--- | :--- | :--- |
| `archer` | **궁수** | 전통 정자(Pavilion) 느낌의 망루, 갈수록 층수가 높아지고 화살통 장식 추가 |
| `barracks` | **병영** | 훈련소 건물, 방패와 검 장식, 갈수록 거대한 성채 느낌 |
| `shaman` | **서당** | 무속적인 장식(오색 깃발, 방울)이 달린 신당, 신비로운 보라색 아우라 |
| `artillery` | **화포** | 화차(Hwacha) 기반 디자인, 포신 개수가 늘어나고 금속 장식 강화 |
| `sotdae` | **솟대** | 나무 솟대, 갈수록 봉황 장식과 황금빛 광원 효과 추가 |

---

> [!TIP]
> **해상도 제안**: 원본은 512x512 이상으로 생성하시되, 게임에 적용할 때는 256x256 정도로 리사이징하면 메모리 효율이 좋습니다! 🦉✨
