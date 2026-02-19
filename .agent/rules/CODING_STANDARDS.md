# 해원의 문 — Dart/Flame 코딩 표준

> 이 문서는 해원의 문 프로젝트의 코딩 규칙을 정의합니다.

---

## 1. 기술 스택

| 기술           | 버전    | 용도                    |
| -------------- | ------- | ----------------------- |
| Flutter        | 3.x     | 프레임워크              |
| Dart           | ^3.6.0  | 언어                    |
| Flame          | ^1.30.1 | 게임 엔진               |
| Riverpod       | ^2.6.1  | 상태 관리               |
| Flame Riverpod | ^5.0.7  | Flame ↔ Riverpod 브릿지 |
| Flame Audio    | ^2.10.4 | 사운드                  |

---

## 2. 디렉토리 구조

```
lib/
├── common/          # 상수, 열거형 (게임 전역)
├── data/
│   ├── models/      # 데이터 모델 (EnemyData, TowerData 등)
│   └── game_data_loader.dart  # 게임 데이터 레지스트리
├── game/
│   ├── components/
│   │   ├── actors/  # 적(Enemy), 영웅(Hero)
│   │   ├── towers/  # 타워, 투사체
│   │   └── items/   # 원혼(Spirit) 등 아이템
│   ├── systems/     # 웨이브매니저, 원한시스템
│   └── world/       # 맵, 낮밤 시스템
├── state/           # Riverpod 상태 (GameState, UserState)
├── ui/
│   ├── dialogs/     # 게임 결과 다이얼로그
│   ├── hud/         # 인게임 HUD, 타워 선택
│   └── menus/       # 메인 메뉴
└── main.dart        # 앱 진입점
```

---

## 3. 명명 규칙

```dart
// 파일명: snake_case
base_enemy.dart
game_data_loader.dart

// 클래스: PascalCase
class BaseTower extends PositionComponent {}
class WaveManager extends Component {}

// 변수/함수: camelCase
double _fireTimer = 0;
void startNextWave() {}

// 상수: lowerCamelCase (Dart 표준)
static const double tileSize = 64.0;

// private: _ 접두사
double _hp = 0;
void _die() {}

// enum: PascalCase (값은 camelCase)
enum TowerType { archer, barracks, shaman }
```

---

## 4. Flame 컴포넌트 규칙

### 4.1. 컴포넌트 라이프사이클

```dart
class MyComponent extends PositionComponent with HasGameReference<DefenseGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 초기화 로직
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 매 프레임 로직
  }
}
```

### 4.2. 금지 패턴

```dart
// ❌ Future.delayed 사용 금지 (Flame 생명주기 외부)
Future.delayed(Duration(seconds: 1), () => doSomething());

// ✅ Flame의 TimerComponent 사용
add(TimerComponent(
  period: 1.0,
  removeOnFinish: true,
  onTick: () => doSomething(),
));
```

### 4.3. 컴포넌트 추가 시 중복 방지

```dart
// ❌ 위험: 같은 컴포넌트를 두 번 추가
world.add(waveManager);
world.add(waveManager); // 버그!

// ✅ 안전
world.add(waveManager);
```

---

## 5. Riverpod 규칙

```dart
// ✅ StateNotifier + StateNotifierProvider 사용
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(const GameState());
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(),
);

// ✅ Flame 내에서 Riverpod 접근
game.ref.read(gameStateProvider.notifier).addSinmyeong(amount);

// ❌ 금지: any 타입 사용
dynamic value = ref.read(someProvider); // 절대 금지
```

---

## 6. 상수 관리

모든 게임 밸런스 수치는 `GameConstants`에서 중앙 관리합니다.

```dart
// ✅ 올바른 사용
_cooldownTimer = GameConstants.waveCooldown;

// ❌ 매직넘버 금지
_cooldownTimer = 8.0; // 왜 8인가?
```

---

## 7. 디버그 로깅

```dart
// ❌ 금지
print('DEBUG: something happened');

// ✅ 권장 (릴리즈 빌드에서 자동 제거)
assert(() {
  debugPrint('something happened');
  return true;
}());

// ✅ 또는 kDebugMode 가드
import 'package:flutter/foundation.dart';
if (kDebugMode) {
  debugPrint('something happened');
}
```

---

## 8. 주석 표준

```dart
/// 클래스/함수에는 문서 주석 (///)
/// 한국어로 작성

// 인라인 주석은 한 줄 주석 (//)
// 한국어로 작성

// TODO: 미완성 기능 표시
// FIXME: 알려진 버그 표시
// HACK: 임시 해결책 표시
```

---

## 9. Git 커밋 메시지

```
[타입] 제목 (한국어)

fix: 중복 waveManager 추가 제거
feat: 영웅 선택 화면 구현
refactor: debug print 제거
docs: README 업데이트
style: 코드 포맷팅
```
