// 해원의 문 - 메인 게임 루프 (DefenseGame)

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame_riverpod/flame_riverpod.dart';

import '../common/enums.dart';
import '../common/constants.dart';
import '../data/game_data_loader.dart';
import '../data/models/wave_data.dart';
import '../state/game_state.dart';
import 'systems/wave_manager.dart';
import 'systems/resentment_system.dart';
import 'world/day_night_system.dart';
import 'world/game_map.dart';
import 'components/towers/base_tower.dart';
import 'components/actors/base_enemy.dart';
import 'components/actors/base_hero.dart';
import '../data/game_data_loader.dart';
import '../state/hero_party_provider.dart';
import '../audio/sound_manager.dart';

/// 메인 게임 클래스
class DefenseGame extends FlameGame
    with HasCollisionDetection, TapCallbacks, RiverpodGameMixin {
  // 선언 시점에 초기화 (late 제거 — UI에서 gameplay 전환 시 안전하게 접근)
  WaveManager? _waveManager;
  WaveManager get waveManager => _waveManager ??= WaveManager(game: this);
  DayNightSystem dayNightSystem = DayNightSystem();
  ResentmentSystem resentmentSystem = ResentmentSystem();
  GameMap gameMap = GameMap();

  LevelData? currentLevel;
  bool isGameRunning = false;
  double _wailingDecayAccum = 0;
  double _enemyCacheAccum = 0;
  bool isPaused = false;
  double _gameSpeed = 1.0;

  /// ── 적 캐시 (매 프레임 1회만 갱신) ──
  /// 모든 컴포넌트가 이 캐시를 사용해야 함
  List<BaseEnemy> cachedEnemies = const [];
  /// 살아있는 적만 필터링된 캐시
  List<BaseEnemy> cachedAliveEnemies = const [];

  /// ── 활성 영웅 리스트 ──
  List<BaseHero> activeHeroes = [];

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

  /// 배속 순환 (1× → 2× → 3× → 1×)
  void cycleGameSpeed() {
    if (_gameSpeed >= 3.0) {
      _gameSpeed = 1.0;
    } else {
      _gameSpeed += 1.0;
    }
  }

  /// 배속 직접 설정
  void setGameSpeed(double speed) {
    _gameSpeed = speed.clamp(1.0, 3.0);
  }

  /// 타워 클릭 시 호출 (BaseTower에서)
  void onTowerTapped(BaseTower tower) {
    onTowerTappedCallback?.call(tower);
  }

  @override
  Color backgroundColor() => const Color(0xFF1a0f29); // 어두운 보라색 배경

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 카메라 설정
    camera.viewfinder.visibleGameSize = Vector2(
      GameConstants.gameWidth,
      GameConstants.gameHeight,
    );
    camera.viewfinder.position = Vector2(
      GameConstants.gameWidth / 2,
      GameConstants.gameHeight / 2,
    );

    // 맵 & 시스템을 월드에 추가 (이미 선언 시점에 생성됨)
    world.add(gameMap);
    world.add(dayNightSystem);
    world.add(resentmentSystem);
    _waveManager ??= WaveManager(game: this);
    world.add(waveManager);

    if (kDebugMode) debugPrint('DefenseGame.onLoad complete');

    // 사운드 초기화
    SoundManager.instance.init();

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
  void startLevel(LevelData level) {
    if (!isLoaded) {
      if (kDebugMode) debugPrint('Game not loaded yet, storing pending level: ${level.name}');
      _pendingLevel = level;
      return;
    }
    if (kDebugMode) debugPrint('startLevel: ${level.name} — path: ${level.path.length} points');
    currentLevel = level;
    isGameRunning = true;

    // Riverpod 상태 초기화 (빌드 페이즈 외부에서 실행)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).initLevel(
        startingSinmyeong: level.startingSinmyeong,
        gatewayHp: level.gatewayHp,
        totalWaves: level.waves.length,
      );
    });

    // 맵에 경로 설정
    gameMap.setPath(level.path);

    // 웨이브 데이터 설정
    waveManager.loadWaves(level.waves);

    // 영웅 스폰
    _spawnHeroes();

    // BGM 시작 (낮 전투)
    SoundManager.instance.playBgm(BgmType.dayBgm);

    // 첫 웨이브 시작
    SoundManager.instance.playSfx(SfxType.waveStart);
    waveManager.startNextWave();
  }

  /// 영웅을 전투에 배치
  void _spawnHeroes() {
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

    for (int i = 0; i < partyState.party.length; i++) {
      final slot = partyState.party[i];
      final heroData = GameDataLoader.heroes[slot.heroId];
      if (heroData == null) continue;

      final pos = i < heroPositions.length
          ? heroPositions[i]
          : Vector2(gatewayPos.x - 60 - (i * 40), gatewayPos.y);

      final hero = BaseHero(
        data: heroData,
        position: pos,
        level: slot.level,
      );

      world.add(hero);
      activeHeroes.add(hero);
    }
  }

  /// 특정 인덱스의 영웅 스킬 발동 (HeroSkillPanel에서 호출)
  void useHeroSkill(int index) {
    if (index < 0 || index >= activeHeroes.length) return;
    activeHeroes[index].useSkill();
    SoundManager.instance.playSfx(SfxType.heroSkill);
  }

  /// 화면 탭 → 선택된 타워 배치
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (!isGameRunning) return;
    if (selectedTowerType == null) return;

    // 화면 좌표 → 월드 좌표 변환
    final worldPos = camera.viewfinder.transform.globalToLocal(
      event.devicePosition,
    );

    // 가장 가까운 빈 배치 지점 찾기
    final slotIndex = gameMap.findNearestEmptySlot(worldPos);
    if (kDebugMode) debugPrint('Tap worldPos=$worldPos, slotIndex=$slotIndex, slots=${gameMap.towerSlots.length}');

    if (slotIndex != null) {
      _placeTowerAtSlot(slotIndex);
    }
  }

  /// 드래그 앤 드롭으로 타워 배치 처리
  void handleDragDrop(Offset globalPosition, TowerType towerType) {
    if (!isGameRunning) return;

    if (kDebugMode) debugPrint('DragDrop at $globalPosition with $towerType');
    
    // 마우스 포인터 위치 보정 (아이콘 중앙이 놓는 지점이 되도록)
    // TowerSelectPanel에서 Offset(-32, -32)를 줬으므로, 받은 좌표는 TopLeft임.
    // 다시 +32를 해줘야 실제 마우스 좌표가 됨.
    final correctedPosition = globalPosition + const Offset(32, 32);



    // 드롭된 타워 타입 설정
    selectedTowerType = towerType;

    // 화면 좌표(Global) -> 월드 좌표 변환
    final worldPos = camera.viewfinder.transform.globalToLocal(
      Vector2(correctedPosition.dx, correctedPosition.dy)
    );
    


    // 가장 가까운 빈 배치 지점 찾기
    final slotIndex = gameMap.findNearestEmptySlot(worldPos);
    
    if (slotIndex != null) {
      _placeTowerAtSlot(slotIndex);
      // 배치 후 선택 해제 (원치 않으면 주석 처리)
      selectedTowerType = null;
    } else {
      if (kDebugMode) debugPrint('No valid slot found near $worldPos');
    }
  }

  /// 특정 슬롯에 타워 배치 (내부 로직 분리)
  void _placeTowerAtSlot(int slotIndex) {
    if (selectedTowerType == null) return;

    final towerData = GameDataLoader.towers[selectedTowerType!];
    if (towerData == null) return;

    // 자원 소비
    final stateNotifier = ref.read(gameStateProvider.notifier);
    if (!stateNotifier.spendSinmyeong(towerData.baseCost)) return;

    // 슬롯 점유
    gameMap.occupySlot(slotIndex);

    // 타워 생성 및 추가
    final tower = BaseTower(
      data: towerData,
      position: gameMap.towerSlots[slotIndex].clone(),
    );
    world.add(tower);

    // 설치 SFX
    SoundManager.instance.playSfx(SfxType.uiPlace);

    // 설치 후 선택 해제
    selectedTowerType = null;
    onTowerPlacedCallback?.call();
  }

  /// 적이 게이트웨이에 도달했을 때
  void onEnemyReachedGateway(int damage) {
    SoundManager.instance.playSfx(SfxType.gatewayHit);

    // 화면 흔들림 효과
    _shakeScreen(damage > 1 ? 6.0 : 3.0);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).damageGateway(damage);
      final state = ref.read(gameStateProvider);
      if (state.gatewayHp <= 0) {
        gameOver();
      }
    });
  }

  /// 화면 흔들림 (Screen Shake)
  double _shakeTimer = 0;
  double _shakeIntensity = 0;

  void _shakeScreen(double intensity) {
    _shakeIntensity = intensity;
    _shakeTimer = 0.3; // 0.3초간 흔들림
  }

  /// 적 처치 시
  void onEnemyKilled(int sinmyeongReward) {
    SoundManager.instance.playSfx(SfxType.enemyDeath);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(gameStateProvider.notifier);
      notifier.addSinmyeong(sinmyeongReward);
      notifier.addKill();
      notifier.addWailing(GameConstants.wailingPerEnemy);
    });
  }

  /// 원혼 수집 시
  void onSpiritCollected() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).addSinmyeong(
        GameConstants.spiritSinmyeongReward,
      );
    });
  }

  /// 게임 오버
  void gameOver() {
    isGameRunning = false;
    SoundManager.instance.stopBgm();
    SoundManager.instance.playSfx(SfxType.defeat);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).setPhase(GamePhase.defeat);
    });
    overlays.add('GameOverOverlay');
  }

  /// 승리
  void victory() {
    isGameRunning = false;
    SoundManager.instance.stopBgm();
    SoundManager.instance.playSfx(SfxType.victory);
    // 별점을 즉시 계산 (오버레이 렌더링 전에 확정)
    ref.read(gameStateProvider.notifier).calculateStarRating();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).victory();
    });
    overlays.add('VictoryOverlay');
  }

  @override
  void update(double dt) {
    // 배속 적용
    final scaledDt = dt * _gameSpeed;
    super.update(scaledDt);

    // 대기 중인 레벨 처리 (onLoad 후 첫 프레임에서 실행)
    if (_pendingLevel != null && isLoaded) {
      final level = _pendingLevel!;
      _pendingLevel = null;
      if (kDebugMode) debugPrint('Processing pending level in update: ${level.name}');
      startLevel(level);
    }

    if (!isGameRunning) return;

    // ── 적 캐시 갱신 (0.2초 주기 — 매 프레임 순회 방지) ──
    _enemyCacheAccum += scaledDt;
    if (_enemyCacheAccum >= 0.2) {
      _enemyCacheAccum = 0;
      cachedEnemies = world.children.whereType<BaseEnemy>().toList();
      cachedAliveEnemies = cachedEnemies.where((e) => !e.isDead && e.isMounted).toList();
    }

    // 한 게이지 자연 감소 (0.5초 주기 — 매 프레임 callback 방지)
    _wailingDecayAccum += scaledDt;
    if (_wailingDecayAccum >= 0.5) {
      final decayAmount = _wailingDecayAccum;
      _wailingDecayAccum = 0;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ref.read(gameStateProvider.notifier).decayWailing(decayAmount);
      });
    }

    // ── 화면 흔들림 (Screen Shake) ──
    if (_shakeTimer > 0) {
      _shakeTimer -= dt; // 실제 dt 사용 (배속 무관)
      final rng = math.Random();
      final offsetX = (rng.nextDouble() - 0.5) * 2 * _shakeIntensity;
      final offsetY = (rng.nextDouble() - 0.5) * 2 * _shakeIntensity;
      camera.viewfinder.position = Vector2(
        GameConstants.gameWidth / 2 + offsetX,
        GameConstants.gameHeight / 2 + offsetY,
      );
    } else if (_shakeIntensity > 0) {
      // 흔들림 종료 → 카메라 복귀
      _shakeIntensity = 0;
      camera.viewfinder.position = Vector2(
        GameConstants.gameWidth / 2,
        GameConstants.gameHeight / 2,
      );
    }
  }
}
