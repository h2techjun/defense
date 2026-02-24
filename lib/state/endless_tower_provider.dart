// 해원의 문 - 무한의 탑 + 일일 도전 상태 관리
// Riverpod 기반 진행 상황, 보상, 세이브 연동
// 열쇠 시스템 + 보석 부활 + 최초 클리어 보너스

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/endless_tower_data.dart';
import '../data/models/daily_challenge_data.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';
import 'user_state.dart';

/// 무한의 탑 상태
class EndlessTowerState {
  final int highestFloor;        // 역대 최고 도달 층
  final int currentFloor;        // 현재 진행 중인 층 (0 = 미시작)
  final int totalGemsEarned;     // 누적 보석 획득
  final int totalFloorsCleared;  // 누적 클리어 층 수
  final List<RestRewardType> activeBuffs; // 현재 활성 버프 (휴식 보상)
  final int buffRemainingFloors; // 버프 남은 층 수
  final int dailyKeys;           // 남은 일일 열쇠 (하루 3개)
  final String lastKeyResetDate; // 열쇠 리셋 날짜
  final Set<int> firstClearFloors; // 최초 클리어 보석 받은 층 (10, 20, 30...)

  /// 열쇠 시스템 상수
  static const int maxDailyKeys = 3;
  static const int gemCostPerKey = 5;
  static const int reviveCostGems = 10;
  static const int firstClearGemsPerMilestone = 15;

  const EndlessTowerState({
    this.highestFloor = 0,
    this.currentFloor = 0,
    this.totalGemsEarned = 0,
    this.totalFloorsCleared = 0,
    this.activeBuffs = const [],
    this.buffRemainingFloors = 0,
    this.dailyKeys = 3,
    this.lastKeyResetDate = '',
    this.firstClearFloors = const {},
  });

  EndlessTowerState copyWith({
    int? highestFloor,
    int? currentFloor,
    int? totalGemsEarned,
    int? totalFloorsCleared,
    List<RestRewardType>? activeBuffs,
    int? buffRemainingFloors,
    int? dailyKeys,
    String? lastKeyResetDate,
    Set<int>? firstClearFloors,
  }) {
    return EndlessTowerState(
      highestFloor: highestFloor ?? this.highestFloor,
      currentFloor: currentFloor ?? this.currentFloor,
      totalGemsEarned: totalGemsEarned ?? this.totalGemsEarned,
      totalFloorsCleared: totalFloorsCleared ?? this.totalFloorsCleared,
      activeBuffs: activeBuffs ?? this.activeBuffs,
      buffRemainingFloors: buffRemainingFloors ?? this.buffRemainingFloors,
      dailyKeys: dailyKeys ?? this.dailyKeys,
      lastKeyResetDate: lastKeyResetDate ?? this.lastKeyResetDate,
      firstClearFloors: firstClearFloors ?? this.firstClearFloors,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
    'highestFloor': highestFloor,
    'currentFloor': currentFloor,
    'totalGemsEarned': totalGemsEarned,
    'totalFloorsCleared': totalFloorsCleared,
    'activeBuffs': activeBuffs.map((b) => b.name).toList(),
    'buffRemainingFloors': buffRemainingFloors,
    'dailyKeys': dailyKeys,
    'lastKeyResetDate': lastKeyResetDate,
    'firstClearFloors': firstClearFloors.toList(),
  };

  /// JSON 역직렬화
  factory EndlessTowerState.fromJson(Map<String, dynamic> json) {
    return EndlessTowerState(
      highestFloor: json['highestFloor'] as int? ?? 0,
      currentFloor: json['currentFloor'] as int? ?? 0,
      totalGemsEarned: json['totalGemsEarned'] as int? ?? 0,
      totalFloorsCleared: json['totalFloorsCleared'] as int? ?? 0,
      activeBuffs: (json['activeBuffs'] as List<dynamic>?)
          ?.map((b) => RestRewardType.values.firstWhere(
                (e) => e.name == b,
                orElse: () => RestRewardType.gemBonus,
              ))
          .toList() ?? [],
      buffRemainingFloors: json['buffRemainingFloors'] as int? ?? 0,
      dailyKeys: json['dailyKeys'] as int? ?? 3,
      lastKeyResetDate: json['lastKeyResetDate'] as String? ?? '',
      firstClearFloors: ((json['firstClearFloors'] as List?) ?? [])
          .map((e) => (e as num).toInt()).toSet(),
    );
  }
}

/// 일일 도전 상태
class DailyChallengeState {
  final String? lastCompletedDate; // "2026-02-19" 형식
  final int bestWavesSurvived;     // 역대 최고 생존 웨이브
  final int totalChallengesCompleted;
  final int streak;                // 연속 도전 일수

  const DailyChallengeState({
    this.lastCompletedDate,
    this.bestWavesSurvived = 0,
    this.totalChallengesCompleted = 0,
    this.streak = 0,
  });

  DailyChallengeState copyWith({
    String? lastCompletedDate,
    int? bestWavesSurvived,
    int? totalChallengesCompleted,
    int? streak,
  }) {
    return DailyChallengeState(
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      bestWavesSurvived: bestWavesSurvived ?? this.bestWavesSurvived,
      totalChallengesCompleted: totalChallengesCompleted ?? this.totalChallengesCompleted,
      streak: streak ?? this.streak,
    );
  }

  /// 오늘 이미 완료했는지
  bool get isCompletedToday {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return lastCompletedDate == today;
  }

  Map<String, dynamic> toJson() => {
    'lastCompletedDate': lastCompletedDate,
    'bestWavesSurvived': bestWavesSurvived,
    'totalChallengesCompleted': totalChallengesCompleted,
    'streak': streak,
  };

  factory DailyChallengeState.fromJson(Map<String, dynamic> json) {
    return DailyChallengeState(
      lastCompletedDate: json['lastCompletedDate'] as String?,
      bestWavesSurvived: json['bestWavesSurvived'] as int? ?? 0,
      totalChallengesCompleted: json['totalChallengesCompleted'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
    );
  }
}

/// 무한의 탑 Notifier
class EndlessTowerNotifier extends StateNotifier<EndlessTowerState> {
  final Ref _ref;
  EndlessTowerNotifier(this._ref) : super(const EndlessTowerState());

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 열쇠 리셋 체크 (하루 3개)
  void checkKeyReset() {
    final today = _today();
    if (state.lastKeyResetDate != today) {
      state = state.copyWith(
        dailyKeys: EndlessTowerState.maxDailyKeys,
        lastKeyResetDate: today,
      );
      _persist();
    }
  }

  /// 열쇠 소모하여 도전 시작
  bool useKey() {
    checkKeyReset();
    if (state.dailyKeys <= 0) return false;
    state = state.copyWith(dailyKeys: state.dailyKeys - 1);
    _persist();
    return true;
  }

  /// 보석으로 열쇠 구매 [💰 Monetize]
  bool buyKey() {
    final user = _ref.read(userStateProvider);
    if (user.gems < EndlessTowerState.gemCostPerKey) return false;
    _ref.read(userStateProvider.notifier).addGems(-EndlessTowerState.gemCostPerKey);
    state = state.copyWith(dailyKeys: state.dailyKeys + 1);
    _persist();
    return true;
  }

  /// 새로운 도전 시작 (열쇠 소모)
  bool startRun() {
    if (!useKey()) return false;
    state = state.copyWith(
      currentFloor: 1,
      activeBuffs: [],
      buffRemainingFloors: 0,
    );
    _persist();
    return true;
  }

  /// 층 클리어
  void clearFloor(int floor, int gemsEarned) {
    final newHighest = floor > state.highestFloor ? floor : state.highestFloor;
    final newBuffFloors = state.buffRemainingFloors > 0
        ? state.buffRemainingFloors - 1
        : 0;

    // 최초 클리어 보너스 체크 (10층 단위)
    int bonusGems = 0;
    Set<int>? newFirstClears;
    if (floor % 10 == 0 && !state.firstClearFloors.contains(floor)) {
      bonusGems = EndlessTowerState.firstClearGemsPerMilestone;
      newFirstClears = {...state.firstClearFloors, floor};
      _ref.read(userStateProvider.notifier).addGems(bonusGems);
    }

    state = state.copyWith(
      currentFloor: floor + 1,
      highestFloor: newHighest,
      totalGemsEarned: state.totalGemsEarned + gemsEarned + bonusGems,
      totalFloorsCleared: state.totalFloorsCleared + 1,
      buffRemainingFloors: newBuffFloors,
      activeBuffs: newBuffFloors <= 0 ? [] : null,
      firstClearFloors: newFirstClears,
    );
    _persist();
  }

  /// 휴식 보상 선택
  void selectRestReward(RestRewardType reward) {
    if (reward == RestRewardType.towerDiscount ||
        reward == RestRewardType.heroBoost) {
      state = state.copyWith(
        activeBuffs: [...state.activeBuffs, reward],
        buffRemainingFloors: 3,
      );
    }
    // 다음 층으로 진행
    state = state.copyWith(currentFloor: state.currentFloor + 1);
    _persist();
  }

  /// 보석으로 부활 (패배 시 이어하기) [💰 Monetize]
  bool reviveWithGems() {
    if (state.currentFloor <= 0) return false;
    final user = _ref.read(userStateProvider);
    if (user.gems < EndlessTowerState.reviveCostGems) return false;
    _ref.read(userStateProvider.notifier).addGems(-EndlessTowerState.reviveCostGems);
    // 현재 층에서 다시 시작 (진행 유지)
    return true;
  }

  /// 패배 시 (진행 초기화, 기록 유지)
  void onDefeat() {
    state = state.copyWith(
      currentFloor: 0,
      activeBuffs: [],
      buffRemainingFloors: 0,
    );
    _persist();
  }

  /// 세이브
  void _persist() {
    SaveManager.instance.saveEndlessTower(state.toJson());
  }

  /// 로드
  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadEndlessTower();
    if (data != null) {
      state = EndlessTowerState.fromJson(data);
      checkKeyReset();
    }
  }
}

/// 일일 도전 Notifier
class DailyChallengeNotifier extends StateNotifier<DailyChallengeState> {
  DailyChallengeNotifier() : super(const DailyChallengeState());

  /// 도전 완료
  void completeChallenge(int wavesSurvived) {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 연속 도전 계산
    int newStreak = state.streak;
    if (state.lastCompletedDate != null) {
      final lastDate = DateTime.tryParse(state.lastCompletedDate!);
      if (lastDate != null) {
        final diff = now.difference(lastDate).inDays;
        if (diff == 1) {
          newStreak = state.streak + 1;
        } else if (diff > 1) {
          newStreak = 1;
        }
      }
    } else {
      newStreak = 1;
    }

    state = state.copyWith(
      lastCompletedDate: today,
      bestWavesSurvived: wavesSurvived > state.bestWavesSurvived
          ? wavesSurvived
          : null,
      totalChallengesCompleted: state.totalChallengesCompleted + 1,
      streak: newStreak,
    );
    _persist();
  }

  void _persist() {
    SaveManager.instance.saveDailyChallenge(state.toJson());
  }

  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadDailyChallenge();
    if (data != null) {
      state = DailyChallengeState.fromJson(data);
    }
  }
}

/// Providers
final endlessTowerProvider =
    StateNotifierProvider<EndlessTowerNotifier, EndlessTowerState>(
  (ref) => EndlessTowerNotifier(ref),
);

final dailyChallengeProvider =
    StateNotifierProvider<DailyChallengeNotifier, DailyChallengeState>(
  (ref) => DailyChallengeNotifier(),
);
