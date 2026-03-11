# 🏯 Gateway of Regrets — 프로젝트 현황 문서

> **최종 업데이트**: 2026-03-11
> **기술 스택**: Flutter + Flame Engine (Dart) + Riverpod + Supabase
> **핵심 문서**: `game_design_bible.md` (루트 디렉토리)

---

## 📂 프로젝트 구조

```
d:\00_Project\05_Defense\
├── lib/                          # 99 Dart 파일
│   ├── main.dart                 # 앱 진입점 (~120줄)
│   ├── game_screen.dart          # 메인 게임 화면 (메뉴↔게임 전환)
│   ├── common/                   # 공통 유틸
│   │   ├── enums.dart            # TowerType, HeroId, EnemyId, Chapter 등
│   │   ├── constants.dart        # DamageCalculator, 색상, 경로 설정
│   │   └── responsive.dart       # 반응형 UI 스케일 유틸
│   ├── data/                     # 정적 데이터
│   │   ├── game_data_loader.dart # 하드코딩 폴백 데이터
│   │   ├── json_data_loader.dart # JSON 기반 데이터 로더
│   │   ├── bark_database.dart    # 영웅 대사 DB
│   │   ├── wave_builder.dart     # 웨이브 빌더
│   │   └── models/               # 14개 데이터 모델
│   ├── game/                     # Flame 게임 코어
│   │   ├── defense_game.dart     # 게임 루프 (937줄)
│   │   ├── components/
│   │   │   ├── actors/           # base_enemy, base_hero
│   │   │   ├── towers/           # base_tower, projectile, barracks, rally_flag
│   │   │   ├── items/            # spirit_component
│   │   │   ├── objects/          # map_object_component
│   │   │   ├── effects/          # particle, sprite, sprite_hit
│   │   │   ├── renderers/        # enemy_renderer, tower_renderer
│   │   │   └── ui/               # bark_bubble
│   │   ├── systems/              # wave_manager, resentment, projectile
│   │   └── world/                # game_map, day_night_system
│   ├── ui/                       # Flutter UI (30파일)
│   │   ├── menus/                # 15개 스크린
│   │   ├── hud/                  # 5개 HUD 위젯
│   │   ├── dialogs/              # 7개 다이얼로그
│   │   ├── theme/                # 3개 테마
│   │   ├── widgets/              # notification_badge, touch_button
│   │   └── common/               # hero_sprite_viewer
│   ├── state/                    # 14개 Riverpod Provider
│   ├── services/                 # save_manager, cloud_save, ad_manager
│   ├── audio/                    # sound_manager, web_audio_synth
│   └── l10n/                     # app_strings (다국어)
├── assets/                       # 이미지, JSON, i18n
├── game_design_bible.md          # GDD v4.0
├── PROJECT_STATUS.md             # ← 이 문서
└── pubspec.yaml
```

---

## ✅ 구현 완료 항목

### 코어 시스템
- [x] 5종 타워 시스템 (궁수/병영/마법/화포/솟대) + Tier 4 분기 (10개 분기)
- [x] 5종 영웅 시스템 (깨비/미호/강림/수아/바리) + 자동 전투 + 스킬 + 레벨업
- [x] 18종 적 데이터 (챕터 1~3, 각 6종) + 보스
- [x] 웨이브 시스템 + JSON 데이터 분리
- [x] 상성 시스템 (물리/마법/정화 × 물리형/영혼형/요괴형)
- [x] 타워 건설/업그레이드/판매/분기 선택 UI
- [x] 랠리 포인트 드래그 이동 (병영 병사 위치 지정)
- [x] 낮/밤 전환 시스템 (시야/상성 변화)
- [x] 한(恨) 곡소리 게이지 + 경고 오버레이 + 광폭화
- [x] 원혼 정화 시스템 (솟대 연동, 원혼 드롭/흡수)
- [x] 배속 시스템 (1×/2×/3× 순환)
- [x] 맵 오브젝트 (성황당/횃불/우물/솟대/봉분/당산나무)

### 메타 시스템
- [x] 별 판정 + 세이브/로드 (SharedPreferences)
- [x] 영웅 해금 시스템 + 소환
- [x] 유물/장비 시스템
- [x] 스킨 시스템 (7등급 타워/영웅)
- [x] 무한의 탑 + 일일 도전
- [x] 시즌 패스
- [x] 업적 시스템 + 일일 미션
- [x] 패키지 상점 + 스킨 상점
- [x] 설화 도감
- [x] 클라우드 세이브 (Supabase)
- [x] 다국어 (한/영)
- [x] 미수령 보상 시스템

### 연출/UI
- [x] 웨이브 전환 배너 + 쿨다운 인디케이터
- [x] 승리/패배 화면 (별 획득 애니메이션)
- [x] 파티클 + 스프라이트 이펙트 시스템
- [x] 스토리 컷씬 (5개 챕터 전환점)
- [x] 튜토리얼 오버레이 (3단계)
- [x] 사운드 시스템 (BGM + SFX + Web Audio Synth)
- [x] 보스 체력바 + 다음 웨이브 미리보기
- [x] 영웅 대사(Bark) 시스템
- [x] 글래스모피즘 UI 테마
- [x] 반응형 UI (phone/tablet/desktop)
- [x] 스프라이트 에셋 (AI 생성)

---

## ❌ 미구현 / 앞으로 할 작업

### 🔴 높은 우선순위
- [ ] 에피소드 1 풀 스테이지 확장 (20스테이지)
- [ ] 에피소드 2~5 스테이지 확장
- [ ] 모바일 소형 화면 HUD 최적화

### 🟡 중간 우선순위
- [ ] 광고 시스템 실제 SDK 연동 (현재 시뮬레이터)
- [ ] 인앱 결제 연동
- [ ] 클라우드 세이브 완전 연동
- [ ] 테스트 코드 작성

### 🟢 낮은 우선순위
- [ ] 실제 사운드/BGM 에셋 교체
- [ ] 추가 스프라이트 폴리싱
- [ ] 성능 프로파일링 및 최적화

---

## 📋 알려진 이슈

1. **defense_game.dart 937줄** — 서브매니저 분리 필요
2. **game_hud.dart 859줄** — 위젯별 파일 분리 필요
3. **test/ 디렉토리 비어있음** — 테스트 코드 미작성

---

## 🔑 핵심 참조 파일

| 용도                | 파일 경로                                          |
| ------------------- | -------------------------------------------------- |
| 게임 디자인 바이블  | `game_design_bible.md`                             |
| 앱 진입점           | `lib/main.dart`                                    |
| 게임 화면           | `lib/game_screen.dart`                             |
| 게임 루프           | `lib/game/defense_game.dart`                       |
| 타워/영웅/적 데이터 | `lib/data/game_data_loader.dart`                   |
| JSON 데이터         | `lib/data/json_data_loader.dart`                   |
| enum 정의           | `lib/common/enums.dart`                            |
| 반응형 유틸         | `lib/common/responsive.dart`                       |
| 상성 계산           | `lib/common/constants.dart`                        |
