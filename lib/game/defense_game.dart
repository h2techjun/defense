// 해원의 문 - 메인 게임 루프 (DefenseGame)


import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame_riverpod/flame_riverpod.dart';

import '../common/enums.dart';
import '../common/constants.dart';
import '../data/game_data_loader.dart';
import '../data/models/wave_data.dart';
import '../state/game_state.dart';
import '../state/tower_loadout_provider.dart';
import 'systems/wave_manager.dart';
import 'systems/grid_system.dart';
import 'systems/resentment_system.dart';
import 'world/day_night_system.dart';
import 'world/game_map.dart';
import 'components/towers/base_tower.dart';
import 'components/actors/base_enemy.dart';
import 'components/actors/base_hero.dart';
import 'components/objects/map_object_component.dart';
import '../state/hero_party_provider.dart';
import '../audio/sound_manager.dart';
import '../services/save_manager.dart';
import '../state/relic_provider.dart';
import '../data/models/relic_data.dart';
import '../services/game_event_bridge.dart';
import '../state/endless_tower_provider.dart';
import 'mixins/game_bark_mixin.dart';
import 'mixins/game_camera_effects_mixin.dart';

/// 메인 게임 클래스
class DefenseGame extends FlameGame
    with HasCollisionDetection, TapCallbacks, RiverpodGameMixin,
         GameBarkMixin, GameCameraEffectsMixin {
  // 선언 시점에 초기화 (late 제거 — UI에서 gameplay 전환 시 안전하게 접근)
  WaveManager? _waveManager;
  WaveManager get waveManager => _waveManager ??= WaveManager(game: this);
  DayNightSystem dayNightSystem = DayNightSystem();
  ResentmentSystem resentmentSystem = ResentmentSystem();
  GameMap gameMap = GameMap();
  GridSystem gridSystem = GridSystem(cellSize: 80.0);

  LevelData? currentLevel;
  GameMode _currentGameMode = GameMode.campaign;
  GameMode get currentGameMode => _currentGameMode;
  bool isGameRunning = false;
  double _wailingDecayAccum = 0;
  double _enemyCacheAccum = 0;
  bool isPaused = false;
  double _gameSpeed = 1.0;
  double _debugLogAccum = 0; // 디버그 로깅 누적기
  double _elapsedAccum = 0; // 경과 시간 누적기 (1초 주기)
  double _achieveFlushAccum = 0; // 업적 배치 플러시 누적기 (3초 주기)
  // ── 이벤트 브릿지 캐시 (매번 ref.read 호출 방지) ──
  GameEventBridge? _eventBridgeCache;
  GameEventBridge get _eventBridge {
    final cached = _eventBridgeCache;
    if (cached != null) return cached;
    final bridge = ref.read(gameEventBridgeProvider);
    _eventBridgeCache = bridge;
    return bridge;
  }

  // ── 배치 상태 업데이트 큐 (addPostFrameCallback 과부하 방지) ──
  // 모든 Riverpod 상태 변경은 이 큐를 통해 일괄 처리됨
  int _pendingSinmyeong = 0;
  int _pendingKills = 0;
  double _pendingWailing = 0;
  int _pendingGatewayDmg = 0;
  double _pendingSotdaeReduction = 0;
  double _pendingWailingDecay = 0;
  bool _pendingStateFlush = false;

  /// 외부 컴포넌트에서 한 게이지 증가를 배치 큐에 추가
  void addPendingWailing(double amount) {
    _pendingWailing += amount;
    _pendingStateFlush = true;
  }

  /// 외부 컴포넌트에서 신명 보상을 배치 큐에 추가
  void onBonusSinmyeong(int amount) {
    _pendingSinmyeong += amount;
    _pendingStateFlush = true;
  }

  /// 솟대 한 억제 효과를 배치 큐에 설정
  void setSotdaeReduction(double amount) {
    _pendingSotdaeReduction = amount;
    _pendingStateFlush = true;
  }

  /// 외부 컴포넌트에서 flush 예약
  void markStateFlush() {
    _pendingStateFlush = true;
  }

  /// ── 적 캐시 (매 프레임 1회만 갱신) ──
  /// 모든 컴포넌트가 이 캐시를 사용해야 함
  List<BaseEnemy> cachedEnemies = const [];
  /// 살아있는 적만 필터링된 캐시
  List<BaseEnemy> cachedAliveEnemies = const [];
  /// 타워 캐시 (whereType<BaseTower> 매 프레임 순회 방지)
  List<BaseTower> cachedTowers = const [];

  // 유물 신명 보너스 캐시 (0.2초 주기 갱신 — 매 kill마다 계산 방지)
  double _cachedRelicSinmyeongBonus = 0;

  /// ── 활성 영웅 리스트 ──
  List<BaseHero> activeHeroes = [];

  /// ── 맵 오브젝트 시스템 ──
  List<MapObjectComponent> activeMapObjects = [];
  final Map<String, bool> _mapObjectFlags = {};

  // Bark 시스템은 GameBarkMixin에서 관리
  // Camera 이펙트는 GameCameraEffectsMixin에서 관리

  /// 현재 게임 속도 (1.0 / 2.0 / 3.0)
  double get gameSpeed => _gameSpeed;

  /// 현재 선택된 타워 타입 (UI에서 설정)
  TowerType? selectedTowerType;

  /// 타워 클릭 콜백 (UI에서 다이얼로그 표시용)
  void Function(BaseTower tower)? onTowerTappedCallback;

  /// 타워 설치 완료 콜백 (UI에서 선택 해제용)
  VoidCallback? onTowerPlacedCallback;

  /// 호버 콜백 (UI에서 툴팁 표시용)
  void Function(Map<String, dynamic> info)? onComponentHover;
  VoidCallback? onComponentHoverExit;

  /// 일시정지 토글
  void togglePause() {
    isPaused = !isPaused;
    paused = isPaused;
  }

  /// 배속 토글 (1× ↔ 2×) — 3배속 제거 (시스템 부하 방지)
  void cycleGameSpeed() {
    _gameSpeed = _gameSpeed >= 2.0 ? 1.0 : 2.0;
  }

  /// 배속 직접 설정
  void setGameSpeed(double speed) {
    _gameSpeed = speed.clamp(1.0, 2.0);
  }

  /// 현재 범위 강조 중인 타워
  BaseTower? _highlightedTower;

  /// 타워 클릭 시 호출 (BaseTower에서)
  void onTowerTapped(BaseTower tower) {
    // 이전 타워 범위 해제
    if (_highlightedTower != null && _highlightedTower != tower) {
      _highlightedTower!.hideRange();
    }
    _highlightedTower = tower;
    onTowerTappedCallback?.call(tower);
  }

  /// 타워 선택 해제 (빈 곳 클릭 등)
  void clearTowerHighlight() {
    _highlightedTower?.hideRange();
    _highlightedTower = null;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // 높이는 696으로 고정하되, 너비는 모바일 비율에 따라 무한 확장
    final targetH = GameConstants.gameHeight + 120;
    camera.viewfinder.zoom = size.y / targetH;
    camera.viewfinder.position = Vector2(
      (size.x / camera.viewfinder.zoom) / 2,
      targetH / 2 + 40,
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF1a0f29); // 어두운 보라색 배경

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 카메라 설정: 높이를 고정(696)하고, 너비는 화면 비율에 맞춰 동적으로 확장(onGameResize에서 처리)

    // 맵 & 시스템을 월드에 추가 (이미 선언 시점에 생성됨)
    world.add(gameMap);
    world.add(dayNightSystem);
    world.add(resentmentSystem);
    _waveManager ??= WaveManager(game: this);
    world.add(waveManager);

    if (kDebugMode) debugPrint('DefenseGame.onLoad complete');

    // onLoad 완료 전에 startLevel이 호출되었다면 지금 실행
    if (_pendingLevel != null) {
      final level = _pendingLevel!;
      _pendingLevel = null;
      if (kDebugMode) debugPrint('Processing pending level: ${level.name}');
      startLevel(level);
    }
  }

  LevelData? _pendingLevel;

  /// 레벨 시작
  void startLevel(LevelData level, {GameMode mode = GameMode.campaign}) {
    if (!isLoaded) {
      if (kDebugMode) debugPrint('Game not loaded yet, storing pending level: ${level.name}');
      _pendingLevel = level;
      return;
    }
    if (kDebugMode) debugPrint('startLevel: ${level.name} (mode: $mode) — path: ${level.path.length} points');
    currentLevel = level;
    _currentGameMode = mode;
    isGameRunning = true;

    // Riverpod 상태 초기화 — 직접 호출 (addPostFrameCallback 제거)
    ref.read(gameStateProvider.notifier).initLevel(
      startingSinmyeong: level.startingSinmyeong,
      gatewayHp: level.gatewayHp,
      totalWaves: level.waves.length,
    );

    // 맵에 경로 설정
    gameMap.setPath(level.path);

    // 웨이브 데이터 설정
    waveManager.loadWaves(level.waves);

    // 영웅 스폰 (저장된 레벨 로드 포함)
    _spawnHeroes();

    // BGM 시작 (낮 전투)
    SoundManager.instance.playBgm(BgmType.dayBgm);

    // 맵 오브젝트 스폰
    _spawnMapObjects();

    // 첫 웨이브 시작
    SoundManager.instance.playSfx(SfxType.waveStart);
    waveManager.startNextWave();
  }

  /// 영웅을 전투에 배치
  Future<void> _spawnHeroes() async {
    // 기존 영웅 제거
    for (final hero in activeHeroes) {
      hero.removeFromParent();
    }
    activeHeroes.clear();

    // Riverpod에서 파티 읽기
    final partyState = ref.read(heroPartyProvider);
    if (partyState.party.isEmpty) return;

    // 경로의 첫 번째 웨이포인트 (게이트웨이 근처) 에서 배치
    final pathPoints = gameMap.waypoints;
    if (pathPoints.isEmpty) return;

    // 게이트웨이(경로 마지막) 앞에 영웅 배치
    final gatewayPos = pathPoints.last;
    final heroPositions = [
      Vector2(gatewayPos.x - 60, gatewayPos.y - 30), // 좌상
      Vector2(gatewayPos.x - 60, gatewayPos.y + 30), // 좌하
      Vector2(gatewayPos.x - 100, gatewayPos.y),      // 좌측 중앙
    ];

    // 저장된 영웅 레벨 로드
    final savedLevels = await SaveManager.instance.loadHeroLevels();

    for (int i = 0; i < partyState.party.length; i++) {
      final slot = partyState.party[i];
      final heroData = GameDataLoader.getHeroes()[slot.heroId];
      if (heroData == null) continue;

      final pos = i < heroPositions.length
          ? heroPositions[i]
          : Vector2(gatewayPos.x - 60 - (i * 40), gatewayPos.y);

      // 저장된 레벨 적용 (없으면 기본 1)
      final saved = savedLevels[slot.heroId.name];
      final heroLevel = saved?['level'] ?? 1;
      final heroXp = saved?['xp'] ?? 0;

      final hero = BaseHero(
        data: heroData,
        position: pos,
        level: heroLevel,
      );
      // 저장된 경험치 복원
      hero.restoreXp(heroXp);

      world.add(hero);
      activeHeroes.add(hero);
    }
  }

  /// 특정 인덱스의 영웅 스킬 발동 (HeroSkillPanel에서 호출)
  void useHeroSkill(int index) {
    if (index < 0 || index >= activeHeroes.length) return;
    activeHeroes[index].useSkill();
    SoundManager.instance.playSfx(SfxType.heroSkill);

    // 스킬 사용 업적 (배치 처리 — 캐시된 브릿지 사용)
    _eventBridge.onSkillUsed();
  }

  // ── 맵 오브젝트 관련 메서드 ──

  /// 맵 오브젝트 스폰 (레벨 데이터 기반)
  void _spawnMapObjects() {
    // 기존 오브젝트 제거
    for (final obj in activeMapObjects) {
      obj.removeFromParent();
    }
    activeMapObjects.clear();
    _mapObjectFlags.clear();

    final level = currentLevel;
    if (level == null || level.mapObjects.isEmpty) return;

    final tileSize = 40.0;
    for (final objData in level.mapObjects) {
      final worldPos = Vector2(
        objData.gridX * tileSize + tileSize / 2,
        objData.gridY * tileSize + tileSize / 2,
      );
      final component = MapObjectComponent(
        data: objData,
        position: worldPos,
      );
      world.add(component);
      activeMapObjects.add(component);
    }

    if (kDebugMode) debugPrint('🏔️ 맵 오브젝트 ${level.mapObjects.length}개 스폰');
  }

  /// 맵 오브젝트 플래그 설정 (우물 정화, 횡불 점화 등)
  void setMapObjectFlag(String key, bool value) {
    _mapObjectFlags[key] = value;
  }

  /// 맵 오브젝트 플래그 조회
  bool getMapObjectFlag(String key) {
    return _mapObjectFlags[key] ?? false;
  }

  /// 주야 전환 강제 (당산나무 효과)
  void forceDayCycle(DayCycle cycle) {
    dayNightSystem.forceCycle(cycle);
  }

  /// 활성 맵 오브젝트 중 특정 타입 조회
  List<MapObjectComponent> getActiveMapObjectsOfType(MapObjectType type) {
    return activeMapObjects
        .where((obj) => obj.data.type == type && obj.state == MapObjectState.active)
        .toList();
  }

  /// 화면 탭 → 선택된 타워 배치
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (!isGameRunning) return;
    if (selectedTowerType == null) return;

    // 화면 좌표(캔버스 기준) -> 월드 좌표 변환 (Viewport letterbox 고려)
    final worldPos = camera.globalToLocal(event.canvasPosition);

    // 가장 가까운 빈 배치 지점 찾기
    final slotIndex = gameMap.findNearestEmptySlot(worldPos);
    if (kDebugMode) debugPrint('Tap worldPos=$worldPos, slotIndex=$slotIndex, slots=${gameMap.towerSlots.length}');

    if (slotIndex != null) {
      _placeTowerAtSlot(slotIndex);
    }
  }

  /// 드래그 앤 드롭으로 타워 배치 처리 (위젯 로컬 좌표 기반)
  void handleDragDrop(Offset localPosition, TowerType towerType, Size? widgetSize) {
    if (!isGameRunning) return;

    if (kDebugMode) debugPrint('DragDrop local=$localPosition widget=$widgetSize type=$towerType');

    // 드롭된 타워 타입 설정
    selectedTowerType = towerType;

    // 상단 UI(game_screen)에서 이미 스케일이 반영된 정확한 커서 중심을 넘겨줍니다.

    // Flame 1.x CameraComponent의 좌표 변환 기능 사용 (GameWidget 내 로컬좌표 -> 월드좌표)
    // game_screen.dart에서 전달한 localPosition은 이미 GameWidget(Viewport) 기준 로컬 좌표입니다.
    // 여기서 viewfinder.transform.globalToLocal 대신 camera.globalToLocal을 사용해야 레터박스와 스케일링이 정확히 반영 계산됩니다.
    final worldPos = camera.globalToLocal(
      Vector2(localPosition.dx, localPosition.dy)
    );
    
    debugPrint('[DRAG DEBUG] FLAME worldPos => $worldPos');

    // 가장 가까운 빈 배치 지점 찾기
    final slotIndex = gameMap.findNearestEmptySlot(worldPos);
    
    debugPrint('[DRAG DEBUG] findNearestEmptySlot => $slotIndex');

    if (slotIndex != null) {
      _placeTowerAtSlot(slotIndex);
      selectedTowerType = null;
    } else {
      if (kDebugMode) debugPrint('No valid slot found near $worldPos');
    }
  }

  /// 특정 슬롯에 타워 배치 (내부 로직 분리)
  /// 이 스테이지에서 배치된 타워 종류 추적 (XP 부여용)
  final Set<TowerType> _placedTowerTypes = {};

  void _placeTowerAtSlot(int slotIndex) {
    if (selectedTowerType == null) return;

    final towerData = GameDataLoader.getTowers()[selectedTowerType!];
    if (towerData == null) return;

    // 자원 소비
    final stateNotifier = ref.read(gameStateProvider.notifier);
    if (!stateNotifier.spendSinmyeong(towerData.baseCost)) return;

    // 슬롯 점유
    gameMap.occupySlot(slotIndex);

    // 외부 레벨 가져오기
    final loadoutState = ref.read(towerLoadoutProvider);
    final extLevel = loadoutState.getTowerLevel(selectedTowerType!);

    // 타워 생성 및 추가 (외부 레벨 반영)
    final tower = BaseTower(
      data: towerData,
      position: gameMap.towerSlots[slotIndex].clone(),
      externalLevel: extLevel,
    );
    world.add(tower);

    // 배치된 타워 종류 기록
    _placedTowerTypes.add(selectedTowerType!);

    // 타워 건설 업적 (배치 처리 — 캐시된 브릿지 사용)
    _eventBridge.onTowerBuilt();

    // 설치 SFX
    SoundManager.instance.playSfx(SfxType.uiPlace);

    // 설치 후 선택 해제
    selectedTowerType = null;
    onTowerPlacedCallback?.call();
  }

  /// 적이 게이트웨이에 도달했을 때
  void onEnemyReachedGateway(int damage) {
    SoundManager.instance.playSfx(SfxType.gatewayHit);
    shakeScreen(damage > 1 ? 6.0 : 3.0);
    _pendingGatewayDmg += damage;
    _pendingStateFlush = true;
  }

  // shakeScreen, triggerRedFlash, redFlashTimer → GameCameraEffectsMixin

  /// 적 처치 시
  void onEnemyKilled(int sinmyeongReward, {bool isBoss = false, EnemyId? enemyId}) {
    SoundManager.instance.playSfx(SfxType.enemyDeath);

    // 웨이브 진행 보너스: 후반 웨이브에서 추가 보상
    final waveIndex = waveManager.currentWaveIndex;
    final totalWaves = waveManager.totalWaveCount;
    final waveBonus = totalWaves > 0
        ? 1.0 + (waveIndex / totalWaves) * 0.5
        : 1.0;

    // 엽전검 유물: 신명 +30% 보너스 (캐시된 값 사용 — 0.2초 주기 갱신)
    final relicSinmyeongBonus = _cachedRelicSinmyeongBonus;

    _pendingSinmyeong += (sinmyeongReward * waveBonus * (1 + relicSinmyeongBonus)).round();
    _pendingKills++;
    _pendingWailing += GameConstants.wailingPerEnemy;
    _pendingStateFlush = true;

    // 업적 이벤트 (배치 처리 — 캐시된 브릿지 사용)
    _eventBridge.onEnemyKilled(isBoss: isBoss, enemyId: enemyId);

    // 영웅 경험치 분배 (보스: 5XP, 일반: 1XP — 50스테이지 기준 보수적)
    final xpAmount = isBoss ? 5 : 1;
    for (final hero in activeHeroes) {
      if (!hero.isDead) {
        hero.gainXp(xpAmount);
      }
    }

    // 보스 처치 대사
    if (isBoss) {
      onBossKilled();
    }
  }


  /// 원혼 수집 시
  void onSpiritCollected() {
    _pendingSinmyeong += GameConstants.spiritSinmyeongReward;
    _pendingStateFlush = true;
  }

  /// 게임 오버
  void gameOver() {
    isGameRunning = false;
    SoundManager.instance.stopBgm();
    SoundManager.instance.playSfx(SfxType.defeat);
    ref.read(gameStateProvider.notifier).setPhase(GamePhase.defeat);
    overlays.add('GameOverOverlay');

    // 패배해도 킬 카운트 등 배치 이벤트 flush
    _eventBridge.flushBatch();

    // 패배해도 영웅 레벨 저장
    _saveHeroLevels();
  }

  /// 승리
  void victory() {
    isGameRunning = false;
    SoundManager.instance.stopBgm();
    SoundManager.instance.playSfx(SfxType.victory);
    ref.read(gameStateProvider.notifier).calculateStarRating();
    ref.read(gameStateProvider.notifier).victory();
    overlays.add('VictoryOverlay');

    // 스테이지 클리어 보너스 XP (50스테이지 기준 완만 곡선)
    final chapterIdx = currentLevel?.chapter.index ?? 0;
    final stageNum = currentLevel?.levelNumber ?? 1;
    final bonusXp = (chapterIdx * 3 + stageNum * 2 + 5).clamp(7, 45);
    for (final hero in activeHeroes) {
      hero.gainXp(bonusXp);
    }

    // 타워 XP 부여 (스테이지에서 배치한 타워에만)
    if (_placedTowerTypes.isNotEmpty) {
      final towerXp = (chapterIdx * 3 + stageNum * 2 + 8).clamp(10, 50);
      ref.read(towerLoadoutProvider.notifier)
          .gainTowerXp(_placedTowerTypes, towerXp);
    }

    // 게임 모드별 이벤트 브릿지 호출
    final gameState = ref.read(gameStateProvider);

    switch (_currentGameMode) {
      case GameMode.campaign:
        // 시즌패스 XP + 스토리/피해0 업적
        _eventBridge.onStageClear(
          chapter: chapterIdx,
          stageNum: stageNum,
          gatewayHp: gameState.gatewayHp,
          maxGatewayHp: gameState.maxGatewayHp,
        );
        break;

      case GameMode.endlessTower:
        // 무한의 탑 — 층 클리어 기록
        final floor = ref.read(endlessTowerProvider).currentFloor;
        final heroId = activeHeroes.isNotEmpty ? activeHeroes.first.data.id : null;
        _eventBridge.onEndlessTowerFloorClear(floor, heroId: heroId);
        // 탑 진행 상태 업데이트 (층별 보너스 젬)
        final gemsEarned = floor * 5 + 10; // 층 기반 보너스
        ref.read(endlessTowerProvider.notifier).clearFloor(floor, gemsEarned);
        break;

      case GameMode.dailyChallenge:
        // 일일 도전 — 생존 웨이브 기록
        final wavesSurvived = gameState.currentWave;
        final heroId = activeHeroes.isNotEmpty ? activeHeroes.first.data.id : null;
        _eventBridge.onDailyChallengeComplete(wavesSurvived, heroId: heroId);
        // 도전 완료 처리
        ref.read(dailyChallengeProvider.notifier).completeChallenge(wavesSurvived);
        break;
    }

    // 영웅 레벨 업적 (최고 레벨 기준)
    for (final hero in activeHeroes) {
      _eventBridge.onHeroLevelUp(
        hero.level,
        activeHeroes.length,
      );
    }

    // ── 영웅 사용 → 도감 카운트 증가 ──
    _eventBridge.onHeroUsed(
      activeHeroes.map((h) => h.data.id).toList(),
    );

    // 영웅 레벨 영구 저장
    _saveHeroLevels();
  }

  /// 영웅 레벨 저장 (승리/패배 모두)
  void _saveHeroLevels() {
    for (final hero in activeHeroes) {
      SaveManager.instance.saveHeroLevel(hero.data.id, hero.level, hero.xp);
    }
  }

  // ── 프리즈 진단용 ──
  int _updateFrameCount = 0;
  int _renderFrameCount = 0;
  double _freezeCheckAccum = 0;

  @override
  void render(Canvas canvas) {
    _renderFrameCount++;
    try {
      super.render(canvas);
      // ── 밤 오버레이 + 빨간 플래시 ── (GameCameraEffectsMixin)
      renderNightOverlay(canvas);
      renderRedFlash(canvas);
    } catch (e, st) {
      debugPrint('🚨 [RENDER-ERROR] $e');
      debugPrint('$st');
    }
  }

  // Night overlay rendering → GameCameraEffectsMixin.renderNightOverlay()

  @override
  void update(double dt) {
    _updateFrameCount++;

    // 프리즈 감지: update vs render 카운트 비교 (5초 주기)
    _freezeCheckAccum += dt;
    if (_freezeCheckAccum >= 5.0) {
      debugPrint('🔍 [FREEZE-CHECK] updates=$_updateFrameCount renders=$_renderFrameCount '
        'ratio=${_renderFrameCount > 0 ? (_updateFrameCount / _renderFrameCount).toStringAsFixed(1) : "NaN"} '
        'children=${world.children.length}');
      _freezeCheckAccum = 0;
      _updateFrameCount = 0;
      _renderFrameCount = 0;
    }

    // 배속 적용
    final scaledDt = dt * _gameSpeed;
    try {
      super.update(scaledDt);
    } catch (e, st) {
      debugPrint('🚨 [UPDATE-ERROR] $e');
      debugPrint('$st');
    }

    // ── 공간 분할(Grid) 업데이트 ──
    // cachedAliveEnemies 리스트 자체는 0.2초 갱신이지만, 객체 내부 position은 최신 프레임입니다.
    gridSystem.updateGrid(cachedAliveEnemies);

    // 대기 중인 레벨 처리 (onLoad 후 첫 프레임에서 실행)
    if (_pendingLevel != null && isLoaded) {
      final level = _pendingLevel!;
      _pendingLevel = null;
      if (kDebugMode) debugPrint('Processing pending level in update: ${level.name}');
      startLevel(level);
    }

    if (!isGameRunning) return;

    // ── 디버그 로깅 (3초 주기) — 프리즈 진단용 ──
    _debugLogAccum += dt;
    if (_debugLogAccum >= 3.0) {
      _debugLogAccum = 0;
      final totalChildren = world.children.length;
      final aliveCount = cachedAliveEnemies.length;
      final towerCount = cachedTowers.length;
      final wm = _waveManager;
      final pendingOps = 'sinm=$_pendingSinmyeong kills=$_pendingKills '
        'wail=${_pendingWailing.toStringAsFixed(1)} gwDmg=$_pendingGatewayDmg '
        'flush=$_pendingStateFlush';
      debugPrint('[GAME] dt=${dt.toStringAsFixed(4)} speed=$_gameSpeed '
        'children=$totalChildren alive=$aliveCount towers=$towerCount '
        'wave=${wm?.currentWaveIndex ?? -1} paused=$isPaused '
        'pending=[$pendingOps]');
      
      // ── 적 위치/상태 덤프 (최대 3마리) ──
      final enemies = cachedAliveEnemies.take(3);
      for (final e in enemies) {
        debugPrint('  [ALIVE-ENEMY] ${e.data.id.name} '
          'pos=(${e.position.x.toInt()},${e.position.y.toInt()}) '
          'state=${e.debugState} speed=${e.debugSpeed.toStringAsFixed(1)} '
          'blocked=${e.debugBlockedBy != null} '
          'wpIdx=${e.debugWaypointIndex} '
          'stun=${e.debugStunTimer.toStringAsFixed(1)} '
          'berserk=${e.debugIsBerserk}');
      }
    }

    // ── 적 캐시 갱신 (0.2초 주기 — 매 프레임 순회 방지) ──
    _enemyCacheAccum += scaledDt;
    if (_enemyCacheAccum >= 0.2) {
      _enemyCacheAccum = 0;
      cachedEnemies = world.children.whereType<BaseEnemy>().toList();
      cachedAliveEnemies = cachedEnemies.where((e) => !e.isDead && e.isMounted).toList();
      cachedTowers = world.children.whereType<BaseTower>().toList();

      // 유물 신명 보너스 캐시 갱신 (ref.read 호출 최소화)
      double relicBonus = 0;
      for (final hero in activeHeroes) {
        if (!hero.isDead) {
          final bonus = ref.read(relicProvider.notifier)
              .getEffectBonus(hero.data.id, RelicEffectType.sinmyeongBonus);
          if (bonus > relicBonus) relicBonus = bonus;
        }
      }
      _cachedRelicSinmyeongBonus = relicBonus;
    }

    // ── 한 감소 누적 (0.5초 주기) ──
    _wailingDecayAccum += scaledDt;
    if (_wailingDecayAccum >= 0.5) {
      _pendingWailingDecay += _wailingDecayAccum;
      _wailingDecayAccum = 0;
      _pendingStateFlush = true;
    }

    // ── 게임 경과 시간 업데이트 (1초 주기) ──
    _elapsedAccum += scaledDt;
    if (_elapsedAccum >= 1.0) {
      ref.read(gameStateProvider.notifier).updateElapsedTime(_elapsedAccum);
      _elapsedAccum = 0;
    }

    // ── 업적 배치 플러시 (3초 주기 — 성능 보호) ──
    _achieveFlushAccum += scaledDt;
    if (_achieveFlushAccum >= 3.0) {
      _achieveFlushAccum = 0;
      try {
        _eventBridge.flushBatch();
      } catch (e) {
        debugPrint('[ACHIEVE-FLUSH-ERROR] $e');
      }
    }

    // ── 배치 상태 업데이트: 모든 이벤트를 모아 단 1회 state 갱신 ──
    // Riverpod 위젯 rebuild를 최소화 (프레임당 최대 1회)
    if (_pendingStateFlush) {
      _pendingStateFlush = false;

      final sinm = _pendingSinmyeong;
      final kills = _pendingKills;
      final wail = _pendingWailing;
      final decay = _pendingWailingDecay;
      final gwDmg = _pendingGatewayDmg;
      final sotdae = _pendingSotdaeReduction;
      _pendingSinmyeong = 0;
      _pendingKills = 0;
      _pendingWailing = 0;
      _pendingWailingDecay = 0;
      _pendingGatewayDmg = 0;
      _pendingSotdaeReduction = 0;

      try {
        ref.read(gameStateProvider.notifier).batchUpdate(
          addSinmyeongAmount: sinm,
          addKillCount: kills,
          addWailingAmount: wail,
          decayWailingAmount: decay,
          damageGatewayAmount: gwDmg,
          sotdaeWailingReduction: sotdae > 0 ? sotdae : null,
        );

        // 게이트웨이 파괴 체크
        if (gwDmg > 0) {
          final state = ref.read(gameStateProvider);
          if (state.gatewayHp <= 0) gameOver();
        }
      } catch (e, st) {
        debugPrint('🚨 [BATCH-UPDATE-ERROR] $e');
        debugPrint('$st');
      }
    }

    // ── 카메라 이펙트 (GameCameraEffectsMixin) ──
    updateScreenShake(dt);
    updateRedFlash(dt);

    // ── 대사 시스템 (GameBarkMixin) ──
    updateBarkCooldown(dt);
    final transitioned = checkDayCycleTransition();
    if (transitioned == DayCycle.night) {
      SoundManager.instance.playBgm(BgmType.nightBgm);
    } else if (transitioned == DayCycle.day) {
      SoundManager.instance.playBgm(BgmType.dayBgm);
    }

    // ── 아군 위기 대사 ──
    final state = ref.read(gameStateProvider);
    checkAllyDangerBark(state.gatewayHp, state.maxGatewayHp);
  }

  // Bark 시스템 → GameBarkMixin (game_bark_mixin.dart)
  // Camera 이펙트 → GameCameraEffectsMixin (game_camera_effects_mixin.dart)
}
