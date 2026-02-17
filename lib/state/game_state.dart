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
    );
  }

  /// 한 게이지가 최대인가?
  bool get isWailingMax => wailing >= GameConstants.maxWailing;
}

/// 게임 상태 Notifier
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(const GameState());

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

  /// 한 게이지 증가
  void addWailing(double amount) {
    state = state.copyWith(
      wailing: (state.wailing + amount).clamp(0, GameConstants.maxWailing),
    );
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
}

/// 게임 상태 Provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(),
);
