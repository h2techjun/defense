# Gateway of Regrets — 프로젝트 진행 상황

> 마지막 업데이트: 2026-02-20 09:40 KST

---

## ✅ 완료된 작업

### 1. 게임 이벤트 → Provider 브릿지 시스템

- `GameEventBridge` (`lib/services/game_event_bridge.dart`) 구현
  - 적 처치 (배치 처리) → 업적 연동
  - 보스 처치 → 업적 연동
  - 스킬 사용 (배치 처리) → 업적 연동
  - 타워 건설 (배치 처리) → 업적 연동
  - 스테이지 클리어 → 시즌패스 XP + 업적
  - 무한의 탑 클리어 → 업적 + 랭킹
  - 일일 도전 완료 → 업적 + 랭킹
  - 영웅 레벨업 → 업적
  - 스킨 획득 → 업적
  - 유물 획득 → 업적
  - 결제 완료 → VIP

### 2. 성능 최적화 (4가지)

| #   | 파일                        | 내용                                | 효과                |
| --- | --------------------------- | ----------------------------------- | ------------------- |
| 1   | `achievement_provider.dart` | `batchIncrementProgress()` 추가     | 6× persist → 1×     |
| 2   | `defense_game.dart`         | `_eventBridge` lazy cache getter    | ref.read 1회만      |
| 3   | `defense_game.dart`         | 업적 flush를 3초 독립 타이머로 분리 | 빈도 6배 감소       |
| 4   | `defense_game.dart`         | 유물 보너스 0.2초 캐시              | 매 킬마다 루프 제거 |

### 3. 게임 모드별 이벤트 분기

- `defense_game.dart` — `GameMode` 추적 필드 추가
- `startLevel(level, {mode})` — 캠페인/무한탑/일일도전 모드 전달
- `victory()` — 모드별 이벤트 브릿지 분기 (`switch`)
  - `campaign` → `onStageClear()`
  - `endlessTower` → `onEndlessTowerFloorClear()` + `clearFloor()`
  - `dailyChallenge` → `onDailyChallengeComplete()` + `completeChallenge()`
- `gameOver()` — 패배 시에도 `flushBatch()` 호출
- `main.dart` — `_startLevel(level, mode:)` 전달 체인 완성

### 4. UI 수정

- 스테이지 선택 카드 텍스트 overflow 해결 (`stage_select_screen.dart`)
- CanvasKit 웹 렌더러 강제 설정 (`web/index.html`)
- 가로모드 설정 확인 (이미 적용됨)

---

## 🔧 남은 작업 (TODO)

### 우선순위 높음 (핵심 기능)

- [ ] **`onRelicUnlocked()` 호출부 연결** — 유물 해금 시 브릿지 호출 필요
  - `RelicNotifier.unlockRelic()`는 `Ref` 없음 → UI 호출부에서 브릿지 호출 추가
  - 또는 `RelicNotifier`를 `Ref`를 받도록 리팩토링
- [ ] **`onPurchaseComplete()` 호출부 연결** — 결제 완료 시 VIP 연동
  - 결제 시스템 (Paddle 연동 후) UI에서 브릿지 호출 추가
- [ ] **`onSkinUnlocked()` 호출부 연결** — 스킨 구매/획득 시
  - 스킨 샵(`skin_shop_screen.dart`)에서 구매 완료 후 호출

### 우선순위 중간 (완성도)

- [ ] **`onHeroLevelUp()` 실시간 호출** — 현재 `victory()` 시점에만 호출됨
  - 전투 중 레벨업 시 실시간으로도 호출해야 업적이 즉시 반영
- [ ] **무한탑/일일도전 패배 시 `onDefeat()` 호출** — `gameOver()`에서 모드별 분기
  - 현재 `gameOver()`는 모드 무관하게 동일 처리
- [ ] **랭킹 시스템 백엔드 연동** — `rankingProvider.notifier` 메서드들이 로컬 저장만
- [ ] **시즌패스 보상 수령 UI** 완성

### 우선순위 낮음 (개선)

- [ ] **`_eventBridgeCache` 초기화 타이밍** — 게임 재시작 시 캐시 무효화
- [ ] **웹 빌드 테스트** — CanvasKit 강제 후 실제 동작 확인
- [ ] **이미지 사전 로드** — 웹에서 스프라이트 로드 타이밍 이슈 방지

---

## 📁 주요 수정 파일 목록

| 파일                                    | 변경 내용                                       |
| --------------------------------------- | ----------------------------------------------- |
| `lib/services/game_event_bridge.dart`   | 이벤트 브릿지 전체 구현                         |
| `lib/state/achievement_provider.dart`   | `batchIncrementProgress()` 추가                 |
| `lib/game/defense_game.dart`            | GameMode 추적, victory() 분기, 캐시, 3초 타이머 |
| `lib/main.dart`                         | `_startLevel(level, mode:)` 전달                |
| `lib/ui/menus/stage_select_screen.dart` | 카드 overflow 수정                              |
| `web/index.html`                        | CanvasKit 렌더러 강제                           |

---

## 🔑 아키텍처 메모

### 이벤트 흐름

```
게임 내 이벤트 → DefenseGame 메서드 → GameEventBridge → Provider(업적/시즌패스/VIP/랭킹)
```

### GameMode 전달 체인

```
EndlessTowerScreen.onStartLevel(level, GameMode.endlessTower)
  → main.dart _startLevel(level, mode: mode)
    → DefenseGame.startLevel(level, mode: mode)
      → _currentGameMode = mode
        → victory() switch(_currentGameMode)
```

### 배치 처리 흐름

```
onEnemyKilled() → _batchKills++
  → flushBatch() (3초 주기) → batchIncrementProgress(map)
    → state.copyWith 1회 + persist 1회
```
