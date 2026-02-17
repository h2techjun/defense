// 해원의 문 - 웨이브 매니저
// 웨이브별 적 스폰 스케줄링, 웨이브 클리어 판정

import 'package:flame/components.dart';

import '../../common/enums.dart';
import '../../data/models/wave_data.dart';
import '../../data/game_data_loader.dart';
import '../../state/game_state.dart';
import '../defense_game.dart';
import '../components/actors/base_enemy.dart';

/// 웨이브 매니저 - 적 스폰 및 웨이브 진행 관리
class WaveManager extends Component with HasGameReference<DefenseGame> {
  final DefenseGame _game;

  List<WaveData> _waves = [];
  int _currentWaveIndex = -1;
  bool _waveActive = false;
  double _waveTimer = 0;
  double _cooldownTimer = 0;
  bool _inCooldown = false;

  // 현재 웨이브 스폰 상태
  List<_SpawnGroupState> _activeGroups = [];
  int _enemiesAlive = 0;

  WaveManager({required DefenseGame game}) : _game = game;

  bool get allWavesComplete =>
      _currentWaveIndex >= _waves.length - 1 && !_waveActive && _enemiesAlive <= 0;

  void loadWaves(List<WaveData> waves) {
    _waves = waves;
    _currentWaveIndex = -1;
    _waveActive = false;
    _enemiesAlive = 0;
  }

  void startNextWave() {
    _currentWaveIndex++;
    if (_currentWaveIndex >= _waves.length) {
      // 모든 웨이브 완료
      if (_enemiesAlive <= 0) {
        _game.victory();
      }
      return;
    }

    final wave = _waves[_currentWaveIndex];
    _waveActive = true;
    _waveTimer = 0;
    _inCooldown = false;

    // 낮/밤 전환
    _game.dayNightSystem.setCycle(wave.dayCycle);
    _game.ref.read(gameStateProvider.notifier).setDayCycle(wave.dayCycle);
    _game.ref.read(gameStateProvider.notifier).nextWave();

    // 스폰 그룹 초기화
    _activeGroups = wave.spawnGroups.map((group) {
      return _SpawnGroupState(
        group: group,
        spawned: 0,
        timer: 0,
        started: false,
      );
    }).toList();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_game.isGameRunning) return;

    // 쿨다운 중 (웨이브 사이 대기)
    if (_inCooldown) {
      _cooldownTimer -= dt;
      if (_cooldownTimer <= 0) {
        _inCooldown = false;
        startNextWave();
      }
      return;
    }

    if (!_waveActive) return;

    _waveTimer += dt;
    bool allGroupsDone = true;

    // 각 스폰 그룹 처리
    for (final gs in _activeGroups) {
      if (gs.spawned >= gs.group.count) continue;

      allGroupsDone = false;

      // 시작 딜레이
      if (!gs.started) {
        if (_waveTimer >= gs.group.startDelay) {
          gs.started = true;
          gs.timer = gs.group.spawnInterval; // 즉시 첫 스폰
        }
        continue;
      }

      gs.timer += dt;
      if (gs.timer >= gs.group.spawnInterval) {
        gs.timer = 0;
        gs.spawned++;
        _spawnEnemy(gs.group.enemyId);
      }
    }

    // 모든 그룹 스폰 완료 + 적 전멸
    if (allGroupsDone) {
      _waveActive = false;

      // 살아있는 적 체크 (다음 프레임에서 확인)
      _checkWaveComplete();
    }
  }

  void _spawnEnemy(EnemyId id) {
    final enemyData = GameDataLoader.enemies[id];
    if (enemyData == null) return;

    final waypoints = _game.gameMap.waypoints;
    if (waypoints.isEmpty) return;

    final enemy = BaseEnemy(
      data: enemyData,
      waypoints: waypoints,
    );

    _enemiesAlive++;
    _game.world.add(enemy);
  }

  void _checkWaveComplete() {
    // 살아있는 적 카운트
    final enemies = _game.world.children.whereType<BaseEnemy>();
    _enemiesAlive = enemies.where((e) => !e.isDead).length;

    if (_enemiesAlive <= 0) {
      if (_currentWaveIndex >= _waves.length - 1) {
        _game.victory();
      } else {
        // 다음 웨이브 쿨다운
        _inCooldown = true;
        _cooldownTimer = 8.0; // 8초 대기
      }
    } else {
      // 계속 체크
      Future.delayed(const Duration(seconds: 1), () {
        if (!_waveActive) _checkWaveComplete();
      });
    }
  }

  /// 외부에서 적 사망 알림
  void onEnemyDied() {
    _enemiesAlive = (_enemiesAlive - 1).clamp(0, 99999);
    if (!_waveActive && _enemiesAlive <= 0) {
      _checkWaveComplete();
    }
  }
}

/// 스폰 그룹 런타임 상태
class _SpawnGroupState {
  final SpawnGroup group;
  int spawned;
  double timer;
  bool started;

  _SpawnGroupState({
    required this.group,
    required this.spawned,
    required this.timer,
    required this.started,
  });
}
