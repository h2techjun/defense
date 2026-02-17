// 해원의 문 - 메인 게임 루프 (DefenseGame)

import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
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

/// 메인 게임 클래스
class DefenseGame extends FlameGame
    with HasCollisionDetection, TapCallbacks, RiverpodGameMixin {
  late WaveManager waveManager;
  late DayNightSystem dayNightSystem;
  late ResentmentSystem resentmentSystem;
  late GameMap gameMap;

  LevelData? currentLevel;
  bool isGameRunning = false;

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

    // 맵 초기화
    gameMap = GameMap();
    world.add(gameMap);

    // 시스템 초기화
    dayNightSystem = DayNightSystem();
    resentmentSystem = ResentmentSystem();
    waveManager = WaveManager(game: this);

    world.add(dayNightSystem);
    world.add(resentmentSystem);
    world.add(waveManager);
  }

  /// 레벨 시작
  void startLevel(LevelData level) {
    currentLevel = level;
    isGameRunning = true;

    // Riverpod 상태 초기화
    ref.read(gameStateProvider.notifier).initLevel(
      startingSinmyeong: level.startingSinmyeong,
      gatewayHp: level.gatewayHp,
      totalWaves: level.waves.length,
    );

    // 맵에 경로 설정
    gameMap.setPath(level.path);

    // 웨이브 데이터 설정
    waveManager.loadWaves(level.waves);

    // 첫 웨이브 시작
    waveManager.startNextWave();
  }

  /// 타워 배치
  void placeTower(TowerType type, Vector2 position) {
    final towerData = GameDataLoader.towers[type];
    if (towerData == null) return;

    final stateNotifier = ref.read(gameStateProvider.notifier);
    if (!stateNotifier.spendSinmyeong(towerData.baseCost)) return;

    // 타워 컴포넌트 생성은 towers/base_tower.dart에서 처리
  }

  /// 적이 게이트웨이에 도달했을 때
  void onEnemyReachedGateway(int damage) {
    ref.read(gameStateProvider.notifier).damageGateway(damage);

    final state = ref.read(gameStateProvider);
    if (state.gatewayHp <= 0) {
      gameOver();
    }
  }

  /// 적 처치 시
  void onEnemyKilled(int sinmyeongReward) {
    final notifier = ref.read(gameStateProvider.notifier);
    notifier.addSinmyeong(sinmyeongReward);
    notifier.addKill();
    notifier.addWailing(GameConstants.wailingPerEnemy);
  }

  /// 원혼 수집 시
  void onSpiritCollected() {
    ref.read(gameStateProvider.notifier).addSinmyeong(
      GameConstants.spiritSinmyeongReward,
    );
  }

  /// 게임 오버
  void gameOver() {
    isGameRunning = false;
    ref.read(gameStateProvider.notifier).setPhase(GamePhase.defeat);
    overlays.add('GameOverOverlay');
  }

  /// 승리
  void victory() {
    isGameRunning = false;
    ref.read(gameStateProvider.notifier).victory();
    overlays.add('VictoryOverlay');
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isGameRunning) return;

    // 한 게이지 자연 감소
    ref.read(gameStateProvider.notifier).decayWailing(dt);
  }
}
