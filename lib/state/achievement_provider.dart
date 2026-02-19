// 해원의 문 - 업적 + 랭킹 상태 관리
// Riverpod StateNotifier 기반

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/achievement_data.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';

// ═══════════════════════════════════════════
// 업적 상태
// ═══════════════════════════════════════════

class AchievementState {
  final Map<String, int> progress;    // 업적ID → 현재 진행도
  final Set<String> completed;        // 완료된 업적 ID
  final Set<String> claimed;          // 보상 수령된 업적 ID

  const AchievementState({
    this.progress = const {},
    this.completed = const {},
    this.claimed = const {},
  });

  AchievementState copyWith({
    Map<String, int>? progress,
    Set<String>? completed,
    Set<String>? claimed,
  }) => AchievementState(
    progress: progress ?? this.progress,
    completed: completed ?? this.completed,
    claimed: claimed ?? this.claimed,
  );

  /// 완료 비율
  double get completionRate {
    if (allAchievements.isEmpty) return 0;
    return completed.length / allAchievements.length;
  }

  /// 미수령 보상 수
  int get unclaimedCount => completed.length - claimed.length;

  Map<String, dynamic> toJson() => {
    'progress': progress,
    'completed': completed.toList(),
    'claimed': claimed.toList(),
  };

  factory AchievementState.fromJson(Map<String, dynamic> json) {
    return AchievementState(
      progress: ((json['progress'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      completed: ((json['completed'] as List?) ?? [])
          .map((e) => e as String)
          .toSet(),
      claimed: ((json['claimed'] as List?) ?? [])
          .map((e) => e as String)
          .toSet(),
    );
  }
}

// ═══════════════════════════════════════════
// 랭킹 상태 (로컬)
// ═══════════════════════════════════════════

class RankingState {
  final List<RankingEntry> towerRankings;     // 무한의 탑 기록
  final List<RankingEntry> dailyRankings;     // 일일 도전 기록
  final int personalBestTower;                // 개인 최고 (탑)
  final int personalBestDaily;                // 개인 최고 (일일)

  const RankingState({
    this.towerRankings = const [],
    this.dailyRankings = const [],
    this.personalBestTower = 0,
    this.personalBestDaily = 0,
  });

  RankingState copyWith({
    List<RankingEntry>? towerRankings,
    List<RankingEntry>? dailyRankings,
    int? personalBestTower,
    int? personalBestDaily,
  }) => RankingState(
    towerRankings: towerRankings ?? this.towerRankings,
    dailyRankings: dailyRankings ?? this.dailyRankings,
    personalBestTower: personalBestTower ?? this.personalBestTower,
    personalBestDaily: personalBestDaily ?? this.personalBestDaily,
  );

  Map<String, dynamic> toJson() => {
    'towerRankings': towerRankings.map((e) => e.toJson()).toList(),
    'dailyRankings': dailyRankings.map((e) => e.toJson()).toList(),
    'personalBestTower': personalBestTower,
    'personalBestDaily': personalBestDaily,
  };

  factory RankingState.fromJson(Map<String, dynamic> json) {
    return RankingState(
      towerRankings: ((json['towerRankings'] as List?) ?? [])
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyRankings: ((json['dailyRankings'] as List?) ?? [])
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      personalBestTower: (json['personalBestTower'] as num?)?.toInt() ?? 0,
      personalBestDaily: (json['personalBestDaily'] as num?)?.toInt() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════
// 업적 Notifier
// ═══════════════════════════════════════════

class AchievementNotifier extends StateNotifier<AchievementState> {
  AchievementNotifier() : super(const AchievementState());

  /// 업적 진행도 증가
  void incrementProgress(String achievementId, {int amount = 1}) {
    final current = state.progress[achievementId] ?? 0;
    final newValue = current + amount;
    final newProgress = Map<String, int>.from(state.progress);
    newProgress[achievementId] = newValue;

    // 달성 여부 확인
    final newCompleted = Set<String>.from(state.completed);
    try {
      final achievement = allAchievements.firstWhere((a) => a.id == achievementId);
      if (newValue >= achievement.targetValue) {
        newCompleted.add(achievementId);
      }
    } catch (_) {
      // 알 수 없는 업적 ID는 무시
    }

    state = state.copyWith(progress: newProgress, completed: newCompleted);
    _persist();
  }

  /// 업적 진행도 직접 설정 (최고 기록형 업적 — 예: 무한의 탑 최고층)
  void setProgress(String achievementId, int value) {
    final current = state.progress[achievementId] ?? 0;
    if (value <= current) return; // 기존 기록보다 낮으면 무시

    final newProgress = Map<String, int>.from(state.progress);
    newProgress[achievementId] = value;

    final newCompleted = Set<String>.from(state.completed);
    try {
      final achievement = allAchievements.firstWhere((a) => a.id == achievementId);
      if (value >= achievement.targetValue) {
        newCompleted.add(achievementId);
      }
    } catch (_) {}

    state = state.copyWith(progress: newProgress, completed: newCompleted);
    _persist();
  }

  /// 보상 수령
  bool claimReward(String achievementId) {
    if (!state.completed.contains(achievementId)) return false;
    if (state.claimed.contains(achievementId)) return false;

    state = state.copyWith(
      claimed: {...state.claimed, achievementId},
    );
    _persist();
    return true;
  }

  /// 특정 업적 진행도 조회
  int getProgress(String achievementId) {
    return state.progress[achievementId] ?? 0;
  }

  void _persist() async {
    await SaveManager.instance.saveAchievements(state.toJson());
  }

  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadAchievements();
    if (data != null) {
      state = AchievementState.fromJson(data);
    }
  }
}

// ═══════════════════════════════════════════
// 랭킹 Notifier
// ═══════════════════════════════════════════

class RankingNotifier extends StateNotifier<RankingState> {
  RankingNotifier() : super(const RankingState());

  /// 무한의 탑 기록 추가
  void addTowerRecord(int floor, HeroId? heroId) {
    final entry = RankingEntry(
      playerName: '나',
      score: floor,
      achievedAt: DateTime.now(),
      usedHero: heroId,
    );

    final rankings = [...state.towerRankings, entry]
      ..sort((a, b) => b.score.compareTo(a.score));

    // 상위 10개만 유지
    final top10 = rankings.take(10).toList();
    final best = floor > state.personalBestTower ? floor : state.personalBestTower;

    state = state.copyWith(towerRankings: top10, personalBestTower: best);
    _persist();
  }

  /// 일일 도전 기록 추가
  void addDailyRecord(int waves, HeroId? heroId) {
    final entry = RankingEntry(
      playerName: '나',
      score: waves,
      achievedAt: DateTime.now(),
      usedHero: heroId,
    );

    final rankings = [...state.dailyRankings, entry]
      ..sort((a, b) => b.score.compareTo(a.score));

    final top10 = rankings.take(10).toList();
    final best = waves > state.personalBestDaily ? waves : state.personalBestDaily;

    state = state.copyWith(dailyRankings: top10, personalBestDaily: best);
    _persist();
  }

  void _persist() async {
    await SaveManager.instance.saveRankings(state.toJson());
  }

  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadRankings();
    if (data != null) {
      state = RankingState.fromJson(data);
    }
  }
}

// ═══════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>(
  (ref) => AchievementNotifier(),
);

final rankingProvider =
    StateNotifierProvider<RankingNotifier, RankingState>(
  (ref) => RankingNotifier(),
);
