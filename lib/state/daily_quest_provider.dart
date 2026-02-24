// 해원의 문 - 일일 미션 상태 관리
// 미션 진행도 추적, 보상 수령, 연속 출석 관리
// 시즌 패스 XP 핵심 공급원

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/daily_quest_data.dart';
import '../services/save_manager.dart';
import 'season_pass_provider.dart';
import 'user_state.dart';
import 'summon_provider.dart';

/// 일일 미션 상태
class DailyQuestState {
  final String questDate;                    // "2026-02-24" 형식
  final List<DailyQuest> quests;             // 오늘의 미션 4개 (3+보너스1)
  final Map<String, int> progress;           // questId → 현재 진행도
  final Set<String> claimed;                 // 보상 수령한 미션 ID
  final bool allClearClaimed;                // 올클리어 보너스 수령 여부
  final int loginStreak;                     // 연속 출석 일수 (1~7, 7 이후 리셋)
  final String lastLoginDate;               // 마지막 접속일
  final Set<int> streakRewardsClaimed;       // 수령한 출석 보상 일차 (1~7)

  const DailyQuestState({
    this.questDate = '',
    this.quests = const [],
    this.progress = const {},
    this.claimed = const {},
    this.allClearClaimed = false,
    this.loginStreak = 0,
    this.lastLoginDate = '',
    this.streakRewardsClaimed = const {},
  });

  DailyQuestState copyWith({
    String? questDate,
    List<DailyQuest>? quests,
    Map<String, int>? progress,
    Set<String>? claimed,
    bool? allClearClaimed,
    int? loginStreak,
    String? lastLoginDate,
    Set<int>? streakRewardsClaimed,
  }) {
    return DailyQuestState(
      questDate: questDate ?? this.questDate,
      quests: quests ?? this.quests,
      progress: progress ?? this.progress,
      claimed: claimed ?? this.claimed,
      allClearClaimed: allClearClaimed ?? this.allClearClaimed,
      loginStreak: loginStreak ?? this.loginStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      streakRewardsClaimed: streakRewardsClaimed ?? this.streakRewardsClaimed,
    );
  }

  /// 일반 미션 3개 (보너스 제외)
  List<DailyQuest> get mainQuests => quests.length > 3 ? quests.sublist(0, 3) : quests;

  /// 보너스 미션 (4번째)
  DailyQuest? get bonusQuest => quests.length > 3 ? quests[3] : null;

  /// 미션 완료 여부
  bool isCompleted(String questId) {
    final quest = quests.firstWhere((q) => q.id == questId, orElse: () => quests.first);
    return (progress[questId] ?? 0) >= quest.targetValue;
  }

  /// 일반 미션 3개 모두 완료 여부
  bool get isAllMainCompleted {
    for (final q in mainQuests) {
      if (!isCompleted(q.id)) return false;
    }
    return mainQuests.isNotEmpty;
  }

  /// 미수령 보상 존재 여부 (빨간 뱃지용)
  bool get hasUnclaimedRewards {
    for (final q in quests) {
      if (isCompleted(q.id) && !claimed.contains(q.id)) return true;
    }
    if (isAllMainCompleted && !allClearClaimed) return true;
    // 연속 출석 보상 체크
    if (loginStreak > 0 && !streakRewardsClaimed.contains(loginStreak)) return true;
    return false;
  }

  /// 수령 가능한 출석 보상 일차
  int? get claimableStreakDay {
    if (loginStreak > 0 && loginStreak <= 7 && !streakRewardsClaimed.contains(loginStreak)) {
      return loginStreak;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'questDate': questDate,
    'progress': progress,
    'claimed': claimed.toList(),
    'allClearClaimed': allClearClaimed,
    'loginStreak': loginStreak,
    'lastLoginDate': lastLoginDate,
    'streakRewardsClaimed': streakRewardsClaimed.toList(),
  };

  factory DailyQuestState.fromJson(Map<String, dynamic> json) {
    return DailyQuestState(
      questDate: json['questDate'] as String? ?? '',
      progress: (json['progress'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
      claimed: ((json['claimed'] as List?) ?? [])
          .map((e) => e as String).toSet(),
      allClearClaimed: json['allClearClaimed'] as bool? ?? false,
      loginStreak: (json['loginStreak'] as num?)?.toInt() ?? 0,
      lastLoginDate: json['lastLoginDate'] as String? ?? '',
      streakRewardsClaimed: ((json['streakRewardsClaimed'] as List?) ?? [])
          .map((e) => (e as num).toInt()).toSet(),
    );
  }
}

/// 일일 미션 Notifier
class DailyQuestNotifier extends StateNotifier<DailyQuestState> {
  final Ref _ref;
  DailyQuestNotifier(this._ref) : super(const DailyQuestState());

  /// 날짜 문자열 생성
  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 앱 시작 시 호출 — 미션 갱신 + 출석 체크
  void initialize() {
    final today = _today();

    if (state.questDate != today) {
      // 새로운 날 → 미션 갱신
      final newQuests = DailyQuestGenerator.today;
      _checkLoginStreak(today);

      state = state.copyWith(
        questDate: today,
        quests: newQuests,
        progress: {},
        claimed: {},
        allClearClaimed: false,
        lastLoginDate: today,
      );
      _persist();
    }
  }

  /// 연속 출석 체크
  void _checkLoginStreak(String today) {
    if (state.lastLoginDate.isEmpty) {
      // 최초 로그인
      state = state.copyWith(loginStreak: 1, streakRewardsClaimed: {});
      return;
    }

    final lastDate = DateTime.tryParse(state.lastLoginDate);
    if (lastDate == null) {
      state = state.copyWith(loginStreak: 1, streakRewardsClaimed: {});
      return;
    }

    final todayDate = DateTime.parse(today);
    final diff = todayDate.difference(lastDate).inDays;

    if (diff == 1) {
      // 연속 출석!
      int newStreak = state.loginStreak + 1;
      Set<int> newClaimed = Set.from(state.streakRewardsClaimed);
      if (newStreak > 7) {
        // 7일 사이클 완료 → 리셋
        newStreak = 1;
        newClaimed = {};
      }
      state = state.copyWith(loginStreak: newStreak, streakRewardsClaimed: newClaimed);
    } else if (diff > 1) {
      // 출석 끊김 → 1일차부터
      state = state.copyWith(loginStreak: 1, streakRewardsClaimed: {});
    }
    // diff == 0 → 같은 날 (변경 없음)
  }

  /// 미션 진행도 업데이트 (게임 중 자동 호출)
  void updateProgress(QuestType type, int amount) {
    if (state.quests.isEmpty) return;

    final newProgress = Map<String, int>.from(state.progress);
    for (final quest in state.quests) {
      if (quest.type == type) {
        final current = newProgress[quest.id] ?? 0;
        newProgress[quest.id] = current + amount;
      }
    }

    state = state.copyWith(progress: newProgress);
    _persist();
  }

  /// 단일 미션 보상 수령
  bool claimReward(String questId) {
    if (state.claimed.contains(questId)) return false;

    final quest = state.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => state.quests.first,
    );

    if (!state.isCompleted(questId)) return false;

    // 보상 지급
    final userNotifier = _ref.read(userStateProvider.notifier);
    if (quest.rewardGold > 0) userNotifier.addGold(quest.rewardGold);
    if (quest.rewardGems > 0) userNotifier.addGems(quest.rewardGems);

    // 시즌 패스 XP 연동 (핵심!!)
    if (quest.rewardPassXp > 0) {
      _ref.read(seasonPassProvider.notifier).addXp(quest.rewardPassXp);
    }

    state = state.copyWith(claimed: {...state.claimed, questId});
    _persist();
    return true;
  }

  /// 올클리어 보너스 수령
  bool claimAllClearBonus() {
    if (!state.isAllMainCompleted || state.allClearClaimed) return false;

    final userNotifier = _ref.read(userStateProvider.notifier);
    userNotifier.addGems(allClearBonusGems);
    userNotifier.addGold(allClearBonusGold);
    _ref.read(seasonPassProvider.notifier).addXp(allClearBonusPassXp);

    state = state.copyWith(allClearClaimed: true);
    _persist();
    return true;
  }

  /// 연속 출석 보상 수령
  bool claimStreakReward(int day) {
    if (day != state.loginStreak) return false;
    if (state.streakRewardsClaimed.contains(day)) return false;
    if (day < 1 || day > loginStreakRewards.length) return false;

    final reward = loginStreakRewards[day - 1];
    final userNotifier = _ref.read(userStateProvider.notifier);

    if (reward.gold > 0) userNotifier.addGold(reward.gold);
    if (reward.gems > 0) userNotifier.addGems(reward.gems);
    if (reward.summonTickets > 0) {
      _ref.read(summonProvider.notifier).addTickets('hero', reward.summonTickets);
    }

    state = state.copyWith(
      streakRewardsClaimed: {...state.streakRewardsClaimed, day},
    );
    _persist();
    return true;
  }

  void _persist() {
    SaveManager.instance.saveDailyQuest(state.toJson());
  }

  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadDailyQuest();
    if (data != null) {
      final saved = DailyQuestState.fromJson(data);
      // 미션은 날짜 시드로 재생성
      final today = _today();
      if (saved.questDate == today) {
        state = saved.copyWith(quests: DailyQuestGenerator.today);
      } else {
        // 날짜 변경 → 새 미션 생성
        state = saved;
        initialize();
      }
    } else {
      initialize();
    }
  }
}

/// Provider
final dailyQuestProvider =
    StateNotifierProvider<DailyQuestNotifier, DailyQuestState>(
  (ref) => DailyQuestNotifier(ref),
);
