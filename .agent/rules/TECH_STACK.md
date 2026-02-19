# 해원의 문 — 기술 스택

## 프로젝트 개요

| 항목           | 값                             |
| -------------- | ------------------------------ |
| **프로젝트명** | 해원의 문 (Gateway of Regrets) |
| **장르**       | 한국 설화 기반 타워 디펜스 RPG |
| **플랫폼**     | Windows (1차), Mobile (향후)   |
| **언어**       | Dart                           |
| **프레임워크** | Flutter + Flame Engine         |

## 핵심 의존성

| 패키지             | 버전    | 용도                                 |
| ------------------ | ------- | ------------------------------------ |
| `flame`            | ^1.30.1 | 2D 게임 엔진 (ECS, 렌더링, 충돌감지) |
| `flame_riverpod`   | ^5.0.7  | Flame ↔ Flutter 상태 브릿지          |
| `flutter_riverpod` | ^2.6.1  | 반응형 상태관리                      |
| `flame_audio`      | ^2.10.4 | BGM, SFX 재생                        |
| `collection`       | ^1.18.0 | 컬렉션 유틸리티                      |

## 아키텍처

```
┌─────────────────────────────┐
│     Flutter UI Layer        │  main.dart, UI widgets
│  (MaterialApp, Overlays)    │  (HUD, Menus, Dialogs)
├─────────────────────────────┤
│     Riverpod State          │  GameState, UserState
│  (StateNotifierProvider)    │  (불변 상태, copyWith)
├─────────────────────────────┤
│     Flame Game Layer        │  DefenseGame (FlameGame)
│  (ECS Components)           │  Components, Systems, World
├─────────────────────────────┤
│     Data Layer              │  GameDataLoader
│  (Models, Loaders)          │  (하드코딩 → JSON 전환 예정)
└─────────────────────────────┘
```

## 핵심 시스템

| 시스템           | 파일                             | 역할                          |
| ---------------- | -------------------------------- | ----------------------------- |
| WaveManager      | `systems/wave_manager.dart`      | 웨이브별 적 스폰 및 진행 관리 |
| DayNightSystem   | `world/day_night_system.dart`    | 낮/밤 전환, 속성 보너스       |
| ResentmentSystem | `systems/resentment_system.dart` | 한(恨) 게이지, 타워 디버프    |
| GameMap          | `world/game_map.dart`            | 경로, 타워 배치 슬롯 관리     |

## 빌드 & 실행

```bash
# 개발 실행 (Windows)
flutter run -d windows

# 또는 배치 파일
start_game.bat

# 빌드
flutter build windows --release
```
