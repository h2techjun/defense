// 해원의 문 - 시즌 패스 + VIP 상태 관리
// Riverpod StateNotifier 기반

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/season_pass_data.dart';
import '../services/save_manager.dart';

// ═══════════════════════════════════════════
// 시즌 패스 상태
// ═══════════════════════════════════════════

class SeasonPassState {
  final int currentLevel;        // 현재 레벨 (1~50)
  final int currentXp;           // 현재 레벨 내 XP
  final bool isPremiumPass;      // 프리미엄 패스 구매 여부
  final Set<int> claimedFree;    // 수령한 무료 보상 레벨
  final Set<int> claimedPremium; // 수령한 프리미엄 보상 레벨
  final int seasonNumber;        // 현재 시즌

  const SeasonPassState({
    this.currentLevel = 1,
    this.currentXp = 0,
    this.isPremiumPass = false,
    this.claimedFree = const {},
    this.claimedPremium = const {},
    this.seasonNumber = 1,
  });

  SeasonPassState copyWith({
    int? currentLevel,
    int? currentXp,
    bool? isPremiumPass,
    Set<int>? claimedFree,
    Set<int>? claimedPremium,
    int? seasonNumber,
  }) {
    return SeasonPassState(
      currentLevel: currentLevel ?? this.currentLevel,
      currentXp: currentXp ?? this.currentXp,
      isPremiumPass: isPremiumPass ?? this.isPremiumPass,
      claimedFree: claimedFree ?? this.claimedFree,
      claimedPremium: claimedPremium ?? this.claimedPremium,
      seasonNumber: seasonNumber ?? this.seasonNumber,
    );
  }

  /// 전체 누적 XP
  int get totalXp {
    int total = 0;
    for (int i = 1; i < currentLevel; i++) {
      total += season1.xpForLevel(i);
    }
    return total + currentXp;
  }

  /// 현재 레벨에서 필요한 총 XP
  int get currentLevelXpRequired => season1.xpForLevel(currentLevel);

  /// 다음 레벨까지 필요한 XP
  int get xpToNextLevel => currentLevelXpRequired - currentXp;

  /// 레벨 진행률 (0.0 ~ 1.0)
  double get levelProgress => currentXp / currentLevelXpRequired;

  /// 최대 레벨 도달 여부
  bool get isMaxLevel => currentLevel >= season1.maxLevel;

  Map<String, dynamic> toJson() => {
    'currentLevel': currentLevel,
    'currentXp': currentXp,
    'isPremiumPass': isPremiumPass,
    'claimedFree': claimedFree.toList(),
    'claimedPremium': claimedPremium.toList(),
    'seasonNumber': seasonNumber,
  };

  factory SeasonPassState.fromJson(Map<String, dynamic> json) {
    return SeasonPassState(
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
      currentXp: (json['currentXp'] as num?)?.toInt() ?? 0,
      isPremiumPass: json['isPremiumPass'] as bool? ?? false,
      claimedFree: ((json['claimedFree'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toSet(),
      claimedPremium: ((json['claimedPremium'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toSet(),
      seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 1,
    );
  }
}

// ═══════════════════════════════════════════
// VIP 상태
// ═══════════════════════════════════════════

class VipState {
  final int totalSpendKRW;       // 누적 결제액
  final String lastDailyReward;  // 마지막 일일 보상 수령 날짜 (yyyy-MM-dd)

  const VipState({
    this.totalSpendKRW = 0,
    this.lastDailyReward = '',
  });

  VipTier get tier => VipTierExt.fromTotalSpend(totalSpendKRW);

  VipState copyWith({
    int? totalSpendKRW,
    String? lastDailyReward,
  }) => VipState(
    totalSpendKRW: totalSpendKRW ?? this.totalSpendKRW,
    lastDailyReward: lastDailyReward ?? this.lastDailyReward,
  );

  Map<String, dynamic> toJson() => {
    'totalSpendKRW': totalSpendKRW,
    'lastDailyReward': lastDailyReward,
  };

  factory VipState.fromJson(Map<String, dynamic> json) => VipState(
    totalSpendKRW: (json['totalSpendKRW'] as num?)?.toInt() ?? 0,
    lastDailyReward: json['lastDailyReward'] as String? ?? '',
  );
}

// ═══════════════════════════════════════════
// 시즌 패스 Notifier
// ═══════════════════════════════════════════

class SeasonPassNotifier extends StateNotifier<SeasonPassState> {
  SeasonPassNotifier() : super(const SeasonPassState());

  /// XP 획득 (스테이지 클리어, 업적 달성 등)
  void addXp(int amount) {
    if (state.isMaxLevel) return;

    int newXp = state.currentXp + amount;
    int newLevel = state.currentLevel;

    // 레벨업 체크 (연속 레벨업 가능, 동적 XP 사용)
    while (newXp >= season1.xpForLevel(newLevel) && newLevel < season1.maxLevel) {
      newXp -= season1.xpForLevel(newLevel);
      newLevel++;
    }

    // 최대 레벨이면 XP 캡
    if (newLevel >= season1.maxLevel) {
      newLevel = season1.maxLevel;
      newXp = 0;
    }

    state = state.copyWith(currentLevel: newLevel, currentXp: newXp);
    _persist();
  }

  /// 프리미엄 패스 구매
  void purchasePremium() {
    state = state.copyWith(isPremiumPass: true);
    _persist();
  }

  /// 보상 수령
  bool claimReward(int level, bool isPremium) {
    if (level > state.currentLevel) return false;

    if (isPremium) {
      if (!state.isPremiumPass) return false;
      if (state.claimedPremium.contains(level)) return false;
      state = state.copyWith(
        claimedPremium: {...state.claimedPremium, level},
      );
    } else {
      if (state.claimedFree.contains(level)) return false;
      state = state.copyWith(
        claimedFree: {...state.claimedFree, level},
      );
    }

    _persist();
    return true;
  }

  /// 보상 수령 가능 여부
  bool canClaim(int level, bool isPremium) {
    if (level > state.currentLevel) return false;
    if (isPremium) {
      return state.isPremiumPass && !state.claimedPremium.contains(level);
    }
    return !state.claimedFree.contains(level);
  }

  void _persist() async {
    await SaveManager.instance.saveSeasonPass(state.toJson());
  }

  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadSeasonPass();
    if (data != null) {
      state = SeasonPassState.fromJson(data);
    }
  }
}

// ═══════════════════════════════════════════
// VIP Notifier
// ═══════════════════════════════════════════

class VipNotifier extends StateNotifier<VipState> {
  VipNotifier() : super(const VipState());

  /// 결제 기록 추가
  void addPurchase(int amountKRW) {
    state = state.copyWith(
      totalSpendKRW: state.totalSpendKRW + amountKRW,
    );
    _persist();
  }

  /// 일일 보석 보상 수령
  int claimDailyBonus() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (state.lastDailyReward == today) return 0;

    final bonus = state.tier.dailyGemBonus;
    if (bonus <= 0) return 0;

    state = state.copyWith(lastDailyReward: today);
    _persist();
    return bonus;
  }

  /// 일일 보상 수령 가능 여부
  bool get canClaimDaily {
    if (state.tier == VipTier.none) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return state.lastDailyReward != today;
  }

  void _persist() async {
    await SaveManager.instance.saveVip(state.toJson());
  }

  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadVip();
    if (data != null) {
      state = VipState.fromJson(data);
    }
  }
}

// ═══════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════

final seasonPassProvider =
    StateNotifierProvider<SeasonPassNotifier, SeasonPassState>(
  (ref) => SeasonPassNotifier(),
);

final vipProvider =
    StateNotifierProvider<VipNotifier, VipState>(
  (ref) => VipNotifier(),
);
