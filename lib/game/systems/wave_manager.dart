// 해원의 문 - 웨이브 매니저
// 웨이브별 적 스폰 스케줄링, 웨이브 클리어 판정

import 'package:flame/components.dart';
import 'package:flutter/scheduler.dart';

import '../../common/constants.dart';
import '../../common/enums.dart';
import '../../data/models/wave_data.dart';
import '../../data/game_data_loader.dart';
import '../../state/game_state.dart';
import '../../state/tower_loadout_provider.dart';
import '../../state/hero_party_provider.dart';
import '../defense_game.dart';
import '../components/actors/base_enemy.dart';
import '../../audio/sound_manager.dart';

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
  double _checkTimer = 0;
  bool _pendingCheck = false;
  bool _firstWaveStarted = false;

  WaveManager({required DefenseGame game}) : _game = game;

  bool get allWavesComplete =>
      _currentWaveIndex >= _waves.length - 1 && !_waveActive && _enemiesAlive <= 0;

  /// 외부 접근용 getter
  bool get isInCooldown => _inCooldown;
  double get cooldownRemaining => _cooldownTimer;
  bool get isWaveActive => _waveActive;
  int get currentWaveIndex => _currentWaveIndex;
  int get totalWaveCount => _waves.length;

  /// 현재 웨이브 내러티브 (있을 때만)
  String? get currentNarrative {
    if (_currentWaveIndex < 0 || _currentWaveIndex >= _waves.length) return null;
    return _waves[_currentWaveIndex].narrative;
  }

  /// 다음 웨이브 미리보기 데이터 (HUD 표시용)
  WaveData? get nextWaveData {
    final nextIdx = _currentWaveIndex + 1;
    if (nextIdx < 0 || nextIdx >= _waves.length) return null;
    return _waves[nextIdx];
  }

  /// 현재 웨이브 데이터
  WaveData? get currentWaveData {
    if (_currentWaveIndex < 0 || _currentWaveIndex >= _waves.length) return null;
    return _waves[_currentWaveIndex];
  }

  void loadWaves(List<WaveData> waves) {
    _waves = waves;
    _currentWaveIndex = -1;
    _waveActive = false;
    _enemiesAlive = 0;
  }

  /// 첫 웨이브 전 준비 시간 (5초)
  static const double firstWavePrepTime = 7.0;

  void startNextWave() {
    _currentWaveIndex++;
    print('[WAVE] startNextWave: waveIndex=$_currentWaveIndex / total=${_waves.length}, alive=$_enemiesAlive');
    if (_currentWaveIndex >= _waves.length) {
      // 모든 웨이브 완료
      print('[WAVE] All waves done! alive=$_enemiesAlive');
      if (_enemiesAlive <= 0) {
        _game.victory();
      }
      return;
    }

    // 첫 웨이브는 준비 시간 부여 (5초 동안 타워 배치 가능)
    if (_currentWaveIndex == 0 && !_firstWaveStarted) {
      _firstWaveStarted = true;
      _inCooldown = true;
      _cooldownTimer = firstWavePrepTime;

      // UI에 웨이브 정보 미리 표시 — 직접 호출
      _game.ref.read(gameStateProvider.notifier).nextWave();
      // 첫 웨이브 미리보기 전달
      _updateNextWavePreview(0);
      _currentWaveIndex = -1; // 다시 startNextWave에서 0번으로 시작
      return;
    }

    final wave = _waves[_currentWaveIndex];
    _waveActive = true;
    _waveTimer = 0;
    _inCooldown = false;

    // 낮/밤 전환 — 직접 호출 (addPostFrameCallback 제거)
    _game.dayNightSystem.setCycle(wave.dayCycle);
    _game.ref.read(gameStateProvider.notifier).setDayCycle(wave.dayCycle);
    if (_currentWaveIndex > 0) {
      _game.ref.read(gameStateProvider.notifier).nextWave();
    }

    // 첫 웨이브 시 전투 시작 대사
    if (_currentWaveIndex == 0) {
      _game.onBattleStart();
    }

    // 스폰 그룹 초기화
    _activeGroups = wave.spawnGroups.map((group) {
      return _SpawnGroupState(
        group: group,
        spawned: 0,
        timer: 0,
        started: false,
      );
    }).toList();

    // 다음 웨이브 미리보기 전달
    _updateNextWavePreview(_currentWaveIndex + 1);
  }

  /// 다음 웨이브 미리보기 정보를 GameState에 전달
  void _updateNextWavePreview(int nextIdx) {
    if (nextIdx >= 0 && nextIdx < _waves.length) {
      final next = _waves[nextIdx];
      // 적 ID + 수량 문자열 리스트 생성 (예: "도깨비 x5")
      final enemyIds = next.spawnGroups.map((g) {
        return '${g.enemyId.name}:${g.count}';
      }).toList();
      // 보스 여부 — enemyId에 'boss' 포함 시
      final isBoss = next.spawnGroups.any(
        (g) => g.enemyId.name.toLowerCase().contains('boss'),
      );
      _game.ref.read(gameStateProvider.notifier)
          .setNextWavePreview(enemyIds, isBoss);
    } else {
      // 마지막 웨이브 — 미리보기 초기화
      _game.ref.read(gameStateProvider.notifier)
          .setNextWavePreview([], false);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_game.isGameRunning) return;

    try {
      _doUpdate(dt);
    } catch (e, st) {
      print('[WAVE] ERROR in update: $e');
      print('[WAVE] StackTrace: $st');
      // 에러 발생해도 게임 루프는 계속 동작
    }
  }

  void _doUpdate(double dt) {
    // 웨이브 완료 후 적 전멸 체크 (1초 주기)
    if (_pendingCheck) {
      _checkTimer += dt;
      if (_checkTimer >= 1.0) {
        _checkTimer = 0;
        _checkWaveComplete();
      }
    }

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
        print('[WAVE] Spawned ${gs.group.enemyId}, group ${gs.spawned}/${gs.group.count}');
      }
    }

    // 모든 그룹 스폰 완료 + 적 전멸
    if (allGroupsDone) {
      _waveActive = false;
      print('[WAVE] All groups spawned for wave $_currentWaveIndex, checking complete...');
      // 살아있는 적 체크 (다음 프레임에서 확인)
      _checkWaveComplete();
    }
  }

  void _spawnEnemy(EnemyId id) {
    final enemyData = GameDataLoader.getEnemies()[id];
    if (enemyData == null) return;

    final waypoints = _game.gameMap.waypoints;
    if (waypoints.isEmpty) return;

    // 유저 레벨 기반 적 스케일링 (에피소드 진행에 따른 난이도 조절)
    final userScaling = _calculateUserScaling();

    final enemy = BaseEnemy(
      data: enemyData,
      waypoints: waypoints,
      hpMultiplier: userScaling * 1.3,  // 기본 30% HP 상향
      speedMultiplier: 1.1,             // 기본 10% 속도 상향
    );

    _enemiesAlive++;
    _game.world.add(enemy);

    // 보스 등장 연출 — 이름에 'boss' 포함 시
    if (id.name.toLowerCase().contains('boss')) {
      _game.onBossAppear();
      _game.shakeScreen(6.0, duration: 0.8);
      _game.triggerRedFlash(duration: 0.3);
      SoundManager.instance.playSfx(SfxType.enemyBoss);
      SoundManager.instance.playBgm(BgmType.boss);
    }
  }

  /// 유저 영웅/타워 레벨에 기반한 적 HP 스케일링 배율
  /// 영웅 Lv1 + 타워 Lv1 = 1.0x (변화 없음)
  /// 영웅 Lv50 + 타워 Lv10 = 약 1.25x (25% 증가)
  double _calculateUserScaling() {
    // 타워 외부 레벨 평균 (1~10)
    final loadoutState = _game.ref.read(towerLoadoutProvider);
    double avgTowerLevel = 1.0;
    if (loadoutState.loadout.isNotEmpty) {
      double sum = 0;
      for (final t in loadoutState.loadout) {
        sum += loadoutState.getTowerLevel(t);
      }
      avgTowerLevel = sum / loadoutState.loadout.length;
    }

    // 영웅 레벨 평균 (1~50)
    final heroState = _game.ref.read(heroPartyProvider);
    double avgHeroLevel = 1.0;
    if (heroState.party.isNotEmpty) {
      double sum = 0;
      for (final h in heroState.party) {
        sum += h.level;
      }
      avgHeroLevel = sum / heroState.party.length;
    }

    // 보수적 스케일링: 타워 Lv 기여 +1.5%/lv, 영웅 Lv 기여 +0.3%/lv
    final towerScaling = 1.0 + (avgTowerLevel - 1) * 0.015;
    final heroScaling = 1.0 + (avgHeroLevel - 1) * 0.003;

    return towerScaling * heroScaling;
  }

  void _checkWaveComplete() {
    // 살아있는 적 카운트 (캐시 활용)
    _enemiesAlive = _game.cachedAliveEnemies.length;
    print('[WAVE] checkComplete: wave=$_currentWaveIndex, alive=$_enemiesAlive, pending=$_pendingCheck');

    if (_enemiesAlive <= 0) {
      _pendingCheck = false;
      if (_currentWaveIndex >= _waves.length - 1) {
        print('[WAVE] VICTORY!');
        _game.victory();
      } else {
        // 다음 웨이브 쿨다운
        _inCooldown = true;
        _cooldownTimer = GameConstants.waveCooldown;
        print('[WAVE] Cooldown ${GameConstants.waveCooldown}s -> next wave ${_currentWaveIndex + 1}');
      }
    } else {
      // update()에서 1초 주기로 재체크
      _pendingCheck = true;
      _checkTimer = 0;
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
