# 해원의 문 — 기술 스택

> **TECH_STACK Override**: 글로벌 자비스 v4.0 기반, Flutter/Flame 게임 프로젝트 특화

## 프로젝트 개요

| 항목           | 값                             |
| -------------- | ------------------------------ |
| **프로젝트명** | 해원의 문 (Gateway of Regrets) |
| **장르**       | 한국 설화 기반 타워 디펜스 RPG |
| **플랫폼**     | Windows (1차), Mobile (향후)   |
| **언어**       | Dart 3.x (null safety)         |
| **프레임워크** | Flutter + Flame Engine         |

---

## 핵심 의존성

| 패키지             | 버전    | 용도                                 |
| ------------------ | ------- | ------------------------------------ |
| `flame`            | ^1.30.1 | 2D 게임 엔진 (ECS, 렌더링, 충돌감지) |
| `flame_riverpod`   | ^5.0.7  | Flame ↔ Flutter 상태 브릿지          |
| `flutter_riverpod` | ^2.6.1  | 반응형 상태관리                      |
| `flame_audio`      | ^2.10.4 | BGM, SFX 재생                        |
| `collection`       | ^1.18.0 | 컬렉션 유틸리티                      |

---

## 🏗️ 아키텍처

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

---

## 📊 핵심 시스템

| 시스템           | 파일                             | 역할                          |
| ---------------- | -------------------------------- | ----------------------------- |
| WaveManager      | `systems/wave_manager.dart`      | 웨이브별 적 스폰 및 진행 관리 |
| DayNightSystem   | `world/day_night_system.dart`    | 낮/밤 전환, 속성 보너스       |
| ResentmentSystem | `systems/resentment_system.dart` | 한(恨) 게이지, 타워 디버프    |
| ProjectileSystem | `systems/projectile_system.dart` | 투사체 관리, 충돌 검사        |
| GameMap          | `world/game_map.dart`            | 경로, 타워 배치 슬롯 관리     |

---

## ✅ 승인된 기술 (이 프로젝트에서 사용 가능)

| 기술 | 용도 |
|------|------|
| Flutter | UI 프레임워크 |
| Flame | 2D 게임 엔진 |
| Riverpod | 상태 관리 |
| flame_audio | 사운드 |
| SharedPreferences | 로컬 저장 |
| Google Mobile Ads | 보상형 광고 |
| Firebase (향후) | 인증, 분석 |

## ❌ 금지된 기술 (이 프로젝트에서 사용 불가)

| 기술 | 사유 |
|------|------|
| Provider | Riverpod으로 통일 |
| GetX | 아키텍처 위반, 암시적 의존성 |
| Flutter Bloc | Riverpod으로 통일 |
| setState (직접) | Riverpod 기반 상태 관리 |
| Future.delayed | Flame TimerComponent 사용 (AP-017) |
| dynamic (남용) | 명시적 타입 필수 (DOCTRINE Rule 7) |

---

## 🎨 상태 관리 규칙

```dart
// ✅ 이 프로젝트의 상태 관리 표준

// 1. 불변 상태 + copyWith
@immutable
class GameState {
  final int wave;
  GameState copyWith({int? wave}) => GameState(wave: wave ?? this.wave);
}

// 2. StateNotifier + Riverpod
class GameStateNotifier extends StateNotifier<GameState> { ... }

// 3. Flame → Riverpod 브릿지
class TowerComponent extends PositionComponent
    with HasGameReference<DefenseGame>, RiverpodComponentMixin { ... }
```

---

## 🏃 빌드 & 실행

```bash
# 개발 실행 (Windows)
flutter run -d windows

# 또는 배치 파일
start_game.bat

# 릴리즈 빌드
flutter build windows --release

# 분석 & 린트
flutter analyze
dart fix --apply
```
