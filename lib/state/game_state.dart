// 해원의 문 - 게임 상태 (Riverpod)
// 게임 플레이 중 실시간으로 변하는 상태를 관리합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enums.dart';
import '../common/constants.dart';

/// 게임 인게임 상태
class GameState {
  final int sinmyeong; // 자원 (마나/골드)
  final double wailing; // 한 게이지 (0~100)
  final int gatewayHp; // 해원문 HP
  final int maxGatewayHp;
  final int currentWave;
  final int totalWaves;
  final DayCycle dayCycle;
  final GamePhase phase;
  final int score;
  final int enemiesKilled;
  final double gameSpeed;
  final int starRating; // 0~3
  final double elapsedSeconds; // 이번 턴 경과 시간 (초)
  // 보스 상태
  final String? bossName;
  final double bossHp;
  final double bossMaxHp;
  // 다음 웨이브 미리보기
  final List<String> nextWaveEnemyIds;
  final bool nextWaveIsBoss;

  const GameState({
    this.sinmyeong = 200,
    this.wailing = 0,
    this.gatewayHp = 20,
    this.maxGatewayHp = 20,
    this.currentWave = 0,
    this.totalWaves = 10,
    this.dayCycle = DayCycle.day,
    this.phase = GamePhase.mainMenu,
    this.score = 0,
    this.enemiesKilled = 0,
    this.gameSpeed = 1.0,
    this.starRating = 0,
    this.elapsedSeconds = 0,
    this.bossName,
    this.bossHp = 0,
    this.bossMaxHp = 0,
    this.nextWaveEnemyIds = const [],
    this.nextWaveIsBoss = false,
  });

  GameState copyWith({
    int? sinmyeong,
    double? wailing,
    int? gatewayHp,
    int? maxGatewayHp,
    int? currentWave,
    int? totalWaves,
    DayCycle? dayCycle,
    GamePhase? phase,
    int? score,
    int? enemiesKilled,
    double? gameSpeed,
    int? starRating,
    double? elapsedSeconds,
    String? bossName,
    double? bossHp,
    double? bossMaxHp,
    List<String>? nextWaveEnemyIds,
    bool? nextWaveIsBoss,
  }) {
    return GameState(
      sinmyeong: sinmyeong ?? this.sinmyeong,
      wailing: wailing ?? this.wailing,
      gatewayHp: gatewayHp ?? this.gatewayHp,
      maxGatewayHp: maxGatewayHp ?? this.maxGatewayHp,
      currentWave: currentWave ?? this.currentWave,
      totalWaves: totalWaves ?? this.totalWaves,
      dayCycle: dayCycle ?? this.dayCycle,
      phase: phase ?? this.phase,
      score: score ?? this.score,
      enemiesKilled: enemiesKilled ?? this.enemiesKilled,
      gameSpeed: gameSpeed ?? this.gameSpeed,
      starRating: starRating ?? this.starRating,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      bossName: bossName ?? this.bossName,
      bossHp: bossHp ?? this.bossHp,
      bossMaxHp: bossMaxHp ?? this.bossMaxHp,
      nextWaveEnemyIds: nextWaveEnemyIds ?? this.nextWaveEnemyIds,
      nextWaveIsBoss: nextWaveIsBoss ?? this.nextWaveIsBoss,
    );
  }

  /// 한 게이지가 최대인가?
  bool get isWailingMax => wailing >= GameConstants.maxWailing;
}

/// 게임 상태 Notifier
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(const GameState());

  /// 솟대 한 억제 배율 (0~1, 0=억제 없음)
  double _sotdaeWailingReduction = 0;

  /// 게임 초기화
  void initLevel({
    required int startingSinmyeong,
    required int gatewayHp,
    required int totalWaves,
  }) {
    state = GameState(
      sinmyeong: startingSinmyeong,
      gatewayHp: gatewayHp,
      maxGatewayHp: gatewayHp,
      totalWaves: totalWaves,
      phase: GamePhase.playing,
    );
  }

  /// 신명(자원) 변경
  void addSinmyeong(int amount) {
    state = state.copyWith(sinmyeong: (state.sinmyeong + amount).clamp(0, 99999));
  }

  /// 신명 소비 (타워 건설 등)
  bool spendSinmyeong(int amount) {
    if (state.sinmyeong < amount) return false;
    state = state.copyWith(sinmyeong: state.sinmyeong - amount);
    return true;
  }

  /// 한 게이지 증가 (솟대 억제 적용)
  void addWailing(double amount) {
    // 양수(증가)일 때만 솟대 억제 적용
    double adjusted = amount;
    if (amount > 0 && _sotdaeWailingReduction > 0) {
      adjusted = amount * (1.0 - _sotdaeWailingReduction);
    }
    state = state.copyWith(
      wailing: (state.wailing + adjusted).clamp(0, GameConstants.maxWailing),
    );
  }

  /// 솟대 한 억제 배율 설정
  void setSotdaeWailingReduction(double ratio) {
    _sotdaeWailingReduction = ratio.clamp(0, 1.0);
  }

  /// 한 게이지 자연 감소
  void decayWailing(double dt) {
    if (state.wailing > 0) {
      state = state.copyWith(
        wailing: (state.wailing - GameConstants.wailingDecayPerSecond * dt).clamp(0, GameConstants.maxWailing),
      );
    }
  }

  /// 게이트웨이 피격
  void damageGateway(int amount) {
    final newHp = (state.gatewayHp - amount).clamp(0, state.maxGatewayHp);
    state = state.copyWith(gatewayHp: newHp);
    if (newHp <= 0) {
      state = state.copyWith(phase: GamePhase.defeat);
    }
  }

  /// 낮/밤 전환
  void setDayCycle(DayCycle cycle) {
    state = state.copyWith(dayCycle: cycle);
  }

  /// 웨이브 진행
  void nextWave() {
    state = state.copyWith(currentWave: state.currentWave + 1);
  }

  /// 다음 웨이브 미리보기 설정
  void setNextWavePreview(List<String> enemyIds, bool isBoss) {
    state = state.copyWith(
      nextWaveEnemyIds: enemyIds,
      nextWaveIsBoss: isBoss,
    );
  }

  /// 적 처치 카운트
  void addKill() {
    state = state.copyWith(
      enemiesKilled: state.enemiesKilled + 1,
      score: state.score + 10,
    );
  }

  /// 승리
  void victory() {
    state = state.copyWith(phase: GamePhase.victory);
  }

  /// 게임 페이즈 변경
  void setPhase(GamePhase phase) {
    state = state.copyWith(phase: phase);
  }

  /// 게임 배속 변경
  void setGameSpeed(double speed) {
    state = state.copyWith(gameSpeed: speed);
  }

  /// 게임 경과 시간 업데이트
  void updateElapsedTime(double dt) {
    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + dt);
  }

  /// 보스 등장
  void setBoss(String name, double hp) {
    state = state.copyWith(bossName: name, bossHp: hp, bossMaxHp: hp);
  }

  /// 보스 HP 업데이트
  void updateBossHp(double hp) {
    state = state.copyWith(bossHp: hp.clamp(0, state.bossMaxHp));
  }

  /// 보스 처치/사라짐
  void clearBoss() {
    state = GameState(
      sinmyeong: state.sinmyeong,
      wailing: state.wailing,
      gatewayHp: state.gatewayHp,
      maxGatewayHp: state.maxGatewayHp,
      currentWave: state.currentWave,
      totalWaves: state.totalWaves,
      dayCycle: state.dayCycle,
      phase: state.phase,
      score: state.score,
      enemiesKilled: state.enemiesKilled,
      gameSpeed: state.gameSpeed,
      starRating: state.starRating,
      elapsedSeconds: state.elapsedSeconds,
      // bossName: null (기본값)
    );
  }

  /// 별 평가 계산 (승리 시 호출)
  void calculateStarRating() {
    if (state.maxGatewayHp <= 0) return;
    final hpRatio = state.gatewayHp / state.maxGatewayHp;
    int stars;
    if (hpRatio >= 0.9) {
      stars = 3; // HP 90%+ → ⭐⭐⭐
    } else if (hpRatio >= 0.5) {
      stars = 2; // HP 50%+ → ⭐⭐
    } else {
      stars = 1; // 그 외 → ⭐
    }
    state = state.copyWith(starRating: stars);
  }

  /// ── 배치 상태 업데이트 (단 1회의 state 갱신) ──
  /// 게임 루프에서 매 프레임 호출 — 여러 변경을 하나의 copyWith로 통합
  void batchUpdate({
    int addSinmyeongAmount = 0,
    int addKillCount = 0,
    double addWailingAmount = 0,
    double decayWailingAmount = 0,
    int damageGatewayAmount = 0,
    double? sotdaeWailingReduction,
    DayCycle? dayCycle,
  }) {
    // 솟대 억제 배율 업데이트 (state를 거치지 않으므로 먼저 처리)
    if (sotdaeWailingReduction != null) {
      _sotdaeWailingReduction = sotdaeWailingReduction.clamp(0, 1.0);
    }

    // 한 게이지 증가 계산 (솟대 억제 적용)
    double adjustedWailing = addWailingAmount;
    if (addWailingAmount > 0 && _sotdaeWailingReduction > 0) {
      adjustedWailing = addWailingAmount * (1.0 - _sotdaeWailingReduction);
    }

    // 새 상태 계산 — 단 1회의 copyWith
    final int newSinmyeong = (state.sinmyeong + addSinmyeongAmount).clamp(0, 99999);
    final newKills = state.enemiesKilled + addKillCount;
    final newScore = state.score + (addKillCount * 10);
    final double newWailing = (state.wailing + adjustedWailing - 
        (decayWailingAmount > 0 ? GameConstants.wailingDecayPerSecond * decayWailingAmount : 0))
        .clamp(0.0, GameConstants.maxWailing.toDouble());
    final int newGatewayHp = (state.gatewayHp - damageGatewayAmount).clamp(0, state.maxGatewayHp);

    state = state.copyWith(
      sinmyeong: newSinmyeong,
      enemiesKilled: newKills,
      score: newScore,
      wailing: newWailing,
      gatewayHp: newGatewayHp,
      dayCycle: dayCycle ?? state.dayCycle,
      phase: newGatewayHp <= 0 ? GamePhase.defeat : state.phase,
    );
  }
}

/// 게임 상태 Provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(),
);
