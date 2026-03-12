// 해원의 문 - 업적 + 랭킹 상태 관리
// Riverpod StateNotifier 기반

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/achievement_data.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';
import 'user_state.dart';
import 'season_pass_provider.dart';

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
  final String seasonMonth;                   // 시즌 월 ("2026-03") → 매월 리셋
  final int seasonBestTower;                  // 이번 시즌 탑 최고
  final int seasonBestDaily;                  // 이번 시즌 도전 최고
  final Map<int, int> floorMilestones;        // 층별 최고 기록 {10: 3시간, 20: 5시간, ...}

  const RankingState({
    this.towerRankings = const [],
    this.dailyRankings = const [],
    this.personalBestTower = 0,
    this.personalBestDaily = 0,
    this.seasonMonth = '',
    this.seasonBestTower = 0,
    this.seasonBestDaily = 0,
    this.floorMilestones = const {},
  });

  RankingState copyWith({
    List<RankingEntry>? towerRankings,
    List<RankingEntry>? dailyRankings,
    int? personalBestTower,
    int? personalBestDaily,
    String? seasonMonth,
    int? seasonBestTower,
    int? seasonBestDaily,
    Map<int, int>? floorMilestones,
  }) => RankingState(
    towerRankings: towerRankings ?? this.towerRankings,
    dailyRankings: dailyRankings ?? this.dailyRankings,
    personalBestTower: personalBestTower ?? this.personalBestTower,
    personalBestDaily: personalBestDaily ?? this.personalBestDaily,
    seasonMonth: seasonMonth ?? this.seasonMonth,
    seasonBestTower: seasonBestTower ?? this.seasonBestTower,
    seasonBestDaily: seasonBestDaily ?? this.seasonBestDaily,
    floorMilestones: floorMilestones ?? this.floorMilestones,
  );

  Map<String, dynamic> toJson() => {
    'towerRankings': towerRankings.map((e) => e.toJson()).toList(),
    'dailyRankings': dailyRankings.map((e) => e.toJson()).toList(),
    'personalBestTower': personalBestTower,
    'personalBestDaily': personalBestDaily,
    'seasonMonth': seasonMonth,
    'seasonBestTower': seasonBestTower,
    'seasonBestDaily': seasonBestDaily,
    'floorMilestones': floorMilestones.map((k, v) => MapEntry(k.toString(), v)),
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
      seasonMonth: json['seasonMonth'] as String? ?? '',
      seasonBestTower: (json['seasonBestTower'] as num?)?.toInt() ?? 0,
      seasonBestDaily: (json['seasonBestDaily'] as num?)?.toInt() ?? 0,
      floorMilestones: ((json['floorMilestones'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(int.parse(k), (v as num).toInt())),
    );
  }
}

// ═══════════════════════════════════════════
// 업적 Notifier
// ═══════════════════════════════════════════

class AchievementNotifier extends StateNotifier<AchievementState> {
  final Ref _ref;
  AchievementNotifier(this._ref) : super(const AchievementState());

  /// 업적 진행도 증가
  void incrementProgress(String achievementId, {int amount = 1}) {
    final current = state.progress[achievementId] ?? 0;
    final newValue = current + amount;
    final newProgress = Map<String, int>.from(state.progress);
    newProgress[achievementId] = newValue;

    // 달성 여부 확인
    final newCompleted = Set<String>.from(state.completed);
    bool justAchieved = false;
    try {
      final achievement = allAchievements.firstWhere((a) => a.id == achievementId);
      if (newValue >= achievement.targetValue && !state.completed.contains(achievementId)) {
        newCompleted.add(achievementId);
        justAchieved = true;
      }
    } catch (_) {
      // 알 수 없는 업적 ID는 무시
    }

    state = state.copyWith(progress: newProgress, completed: newCompleted);
    _persist();

    // 업적 달성 알림
    if (justAchieved) {
      _ref.read(lastAchievedIdProvider.notifier).state = achievementId;
      debugPrint('[🏆 ACHIEVEMENT] 업적 달성: $achievementId');
    }
  }

  /// 여러 업적을 한 번에 증가 (Map 복사 1회, persist 1회 — 성능 최적화)
  void batchIncrementProgress(Map<String, int> updates) {
    if (updates.isEmpty) return;

    final newProgress = Map<String, int>.from(state.progress);
    final newCompleted = Set<String>.from(state.completed);

    for (final entry in updates.entries) {
      final current = newProgress[entry.key] ?? 0;
      final newValue = current + entry.value;
      newProgress[entry.key] = newValue;

      try {
        final achievement = allAchievements.firstWhere((a) => a.id == entry.key);
        if (newValue >= achievement.targetValue) {
          newCompleted.add(entry.key);
        }
      } catch (_) {}
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

    // ── 실제 보석 보상 지급 ──
    try {
      final achievement = allAchievements.firstWhere((a) => a.id == achievementId);
      if (achievement.rewardGems > 0) {
        _ref.read(userStateProvider.notifier).addGems(achievement.rewardGems);
      }
      if (achievement.rewardPassXp > 0) {
        _ref.read(seasonPassProvider.notifier).addXp(achievement.rewardPassXp);
      }
    } catch (_) {}

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

    // 시즌 기록 업데이트
    _checkSeasonReset();
    final seasonBest = floor > state.seasonBestTower ? floor : state.seasonBestTower;
    state = state.copyWith(seasonBestTower: seasonBest);

    // 층별 마일스톤 기록 (10, 20, 30층 도달 시)
    final milestones = Map<int, int>.from(state.floorMilestones);
    for (final milestone in [10, 20, 30, 50, 100]) {
      if (floor >= milestone && !milestones.containsKey(milestone)) {
        milestones[milestone] = DateTime.now().millisecondsSinceEpoch;
      }
    }
    state = state.copyWith(floorMilestones: milestones);

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

    // 시즌 기록 업데이트
    _checkSeasonReset();
    final seasonBest = waves > state.seasonBestDaily ? waves : state.seasonBestDaily;
    state = state.copyWith(seasonBestDaily: seasonBest);

    _persist();
  }

  /// 시즌 리셋 체크 (매월 1일 자동 리셋)
  void _checkSeasonReset() {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (state.seasonMonth != currentMonth) {
      state = state.copyWith(
        seasonMonth: currentMonth,
        seasonBestTower: 0,
        seasonBestDaily: 0,
      );
    }
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
  (ref) => AchievementNotifier(ref),
);

final rankingProvider =
    StateNotifierProvider<RankingNotifier, RankingState>(
  (ref) => RankingNotifier(),
);

/// 최근 달성된 업적 ID (업적 팝업 트리거용)
final lastAchievedIdProvider = StateProvider<String?>((ref) => null);
