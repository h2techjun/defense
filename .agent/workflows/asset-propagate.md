---
description: 에셋/그래픽 변경 시 전체 코드베이스에서 연관된 모든 사용처를 찾아 일괄 교체
---

# 🔍 Asset Propagation Protocol — 에셋 연관 전파

> 한 곳의 에셋/그래픽 변경을 언급하면, **관련된 모든 사용처를 자동으로 탐색하고 일괄 교체**한다.

## 트리거

- "이미지 교체해줘", "그래픽 적용해줘", "아이콘 바꿔줘" 등 에셋 변경 요청
- 이모지 → 실제 이미지, 플레이스홀더 → 실제 에셋, 색상 사각형 → 스프라이트 등

## 워크플로우

### Phase 1: 영향 범위 스캔 (30초)

1. **키워드 식별**: 변경 대상의 핵심 키워드 추출
   - 예: "타워 이미지" → `tower`, `icon`, `emoji`, `Image.asset`, `tower_`
   - 예: "영웅 그래픽" → `hero`, `emoji`, `_getHeroEmoji`, `Image.asset`, `hero_`

2. **전체 코드 검색**: `grep_search`로 lib/ 전체에서 관련 사용처 탐색

   ```
   grep_search("이모지_함수명_또는_변수", "lib/")
   grep_search("관련_에셋경로_패턴", "lib/")
   ```

3. **파일 분류**: 발견된 파일을 역할별로 분류

   | 카테고리 | 설명 | 예시 |
   |---------|------|------|
   | **HUD** | 게임 중 표시되는 UI | `tower_select_panel.dart`, `hero_skill_panel.dart` |
   | **메뉴** | 관리/설정 화면 | `tower_manage_screen.dart`, `hero_manage_screen.dart` |
   | **게임 내** | 실제 게임 오브젝트 렌더링 | `tower_renderer.dart`, `base_hero.dart` |
   | **데이터** | 메타데이터/설정 | `enums.dart`, `game_data_loader.dart` |

4. **영향 보고**: 모든 사용처를 마스터에게 보고 (바로 수정 진행, Always Run)

### Phase 2: 일괄 교체 실행

1. **공통 헬퍼 확인/생성**: 이미지 경로 매핑 함수가 없으면 생성
   - `_getTowerImagePath(TowerType type, int tier)` → `'assets/images/towers/tower_{type}_t{tier}.png'`
   - `_getHeroImagePath(HeroId id, int tier)` → `'assets/images/heroes/hero_{id}_{tier}.png'`

2. **파일별 교체**: 각 파일에서 이모지/플레이스홀더를 `Image.asset`으로 교체
   - 반드시 `errorBuilder`를 포함하여 이미지 미존재 시 폴백 제공
   - 기존 크기/레이아웃 유지

3. **티어 연동 확인**: 업그레이드/진화 시 이미지가 자동 변경되는지 확인
   - 타워: `tower_{type}_t{1~4}.png`
   - 영웅: `hero_{name}_{1~3}.png`

### Phase 3: 검증

// turbo
8. 핫 리로드 또는 빌드 확인
9. 변경된 모든 화면 리스트와 함께 완료 보고

## 체크리스트 템플릿

변경 요청 시 아래 체크리스트를 자동 생성:

```markdown
# [에셋명] 연관 전파 체크리스트

## 발견된 사용처
- [ ] [파일명:라인] — [용도 설명]
- [ ] [파일명:라인] — [용도 설명]
...

## 교체 현황
- [ ] 파일1 — N곳 교체
- [ ] 파일2 — N곳 교체
...

## 검증
- [ ] 빌드 성공
- [ ] 시각 확인
```

## 핵심 원칙

1. **놓치지 않기**: `grep_search`로 전체 스캔, 한 곳도 빠뜨리지 않는다
2. **폴백 안전망**: 모든 `Image.asset`에 `errorBuilder` 포함
3. **티어 연동**: 에셋 변경이 레벨/티어 시스템과 연동되는지 반드시 확인
4. **Always Run**: 스캔 → 분류 → 교체 → 검증까지 자율 실행
