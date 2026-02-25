// 해원의 문 - 시즌 패스 + VIP 상태 관리
// Riverpod StateNotifier 기반

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enums.dart';
import '../data/models/season_pass_data.dart';
import '../data/models/skin_data.dart';
import '../data/models/relic_data.dart';
import '../services/save_manager.dart';
import 'user_state.dart';
import 'summon_provider.dart';
import 'skin_provider.dart';
import 'relic_provider.dart';
import 'hero_party_provider.dart';

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
  final bool hasMonthlySubscription;
  final String subscriptionEndDate; // yyyy-MM-dd

  const VipState({
    this.totalSpendKRW = 0,
    this.lastDailyReward = '',
    this.hasMonthlySubscription = false,
    this.subscriptionEndDate = '',
  });

  VipTier get tier => VipTierExt.fromTotalSpend(totalSpendKRW);

  VipState copyWith({
    int? totalSpendKRW,
    String? lastDailyReward,
    bool? hasMonthlySubscription,
    String? subscriptionEndDate,
  }) => VipState(
    totalSpendKRW: totalSpendKRW ?? this.totalSpendKRW,
    lastDailyReward: lastDailyReward ?? this.lastDailyReward,
    hasMonthlySubscription: hasMonthlySubscription ?? this.hasMonthlySubscription,
    subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
  );

  Map<String, dynamic> toJson() => {
    'totalSpendKRW': totalSpendKRW,
    'lastDailyReward': lastDailyReward,
    'hasMonthlySubscription': hasMonthlySubscription,
    'subscriptionEndDate': subscriptionEndDate,
  };

  factory VipState.fromJson(Map<String, dynamic> json) => VipState(
    totalSpendKRW: (json['totalSpendKRW'] as num?)?.toInt() ?? 0,
    lastDailyReward: json['lastDailyReward'] as String? ?? '',
    hasMonthlySubscription: json['hasMonthlySubscription'] as bool? ?? false,
    subscriptionEndDate: json['subscriptionEndDate'] as String? ?? '',
  );
}

// ═══════════════════════════════════════════
// 시즌 패스 Notifier
// ═══════════════════════════════════════════

class SeasonPassNotifier extends StateNotifier<SeasonPassState> {
  final Ref _ref;
  SeasonPassNotifier(this._ref) : super(const SeasonPassState());

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
    
    // ── 실제 보상 지급 ──
    final seasonRewards = season1.rewards;
    final reward = seasonRewards.firstWhere(
      (r) => r.level == level && r.isPremium == isPremium,
      orElse: () => const PassReward(level: 0, type: PassRewardType.gold, name: '', emoji: ''),
    );

    if (reward.level != 0) {
      _grantReward(reward);
    }

    return true;
  }

  void _grantReward(PassReward reward) {
    final userNotifier = _ref.read(userStateProvider.notifier);
    
    switch (reward.type) {
      case PassRewardType.gems:
        userNotifier.addGems(reward.amount);
        break;
      case PassRewardType.gold:
        userNotifier.addGold(reward.amount);
        break;
      case PassRewardType.heroXp:
        // 현재 선택된 영웅 혹은 모든 보유 영웅 경험치 부여
        final party = _ref.read(heroPartyProvider).party;
        if (party.isNotEmpty) {
          final heroId = party.first.heroId;
          _ref.read(userStateProvider.notifier).levelUpHero(heroId);
          _ref.read(heroPartyProvider.notifier).levelUpHero(heroId);
        }
        break;
      case PassRewardType.skin:
        if (reward.unlockId != null) {
          try {
            final skinId = SkinId.values.firstWhere((s) => s.name == reward.unlockId);
            _ref.read(skinProvider.notifier).unlockSkin(skinId);
          } catch (_) {
            print('[SeasonPass] Unknown SkinId: ${reward.unlockId}');
          }
        }
        break;
      case PassRewardType.relic:
        if (reward.unlockId != null) {
          try {
            final relicId = RelicId.values.firstWhere((r) => r.name == reward.unlockId);
            _ref.read(relicProvider.notifier).unlockRelic(relicId);
          } catch (_) {
            print('[SeasonPass] Unknown RelicId: ${reward.unlockId}');
          }
        }
        break;
      case PassRewardType.summonTicket:
        _ref.read(summonProvider.notifier).addTickets('summonTicket', reward.amount);
        print('[SeasonPass] 소환권 보상 획득: ${reward.amount}');
        break;
      default:
        print('[SeasonPass] 기타 보상 획득: ${reward.name}');
        break;
    }
  }

  /// 보상 수령 가능 여부
  bool canClaim(int level, bool isPremium) {
    if (level > state.currentLevel) return false;
    if (isPremium) {
      return state.isPremiumPass && !state.claimedPremium.contains(level);
    }
    return !state.claimedFree.contains(level);
  }

  /// 보석으로 레벨 구매 [💰 Monetize]
  /// 30 보석 = 1 레벨 (시즌 종료 직전 급하게 올리고 싶은 유저 타겟)
  static const int gemsPerLevel = 30;

  bool purchaseLevels(int count) {
    if (count <= 0) return false;
    final totalCost = gemsPerLevel * count;
    final userState = _ref.read(userStateProvider);
    if (userState.gems < totalCost) return false;

    // 보석 차감
    _ref.read(userStateProvider.notifier).addGems(-totalCost);

    // 레벨 올리기
    int newLevel = state.currentLevel;
    for (int i = 0; i < count; i++) {
      if (newLevel < 50) newLevel++;
    }

    state = state.copyWith(currentLevel: newLevel, currentXp: 0);
    _persist();
    return true;
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
  final Ref _ref;
  VipNotifier(this._ref) : super(const VipState());

  /// 결제 기록 추가
  void addPurchase(int amountKRW) {
    state = state.copyWith(
      totalSpendKRW: state.totalSpendKRW + amountKRW,
    );
    _persist();
  }

  /// 월정액 구매 [💰 Monetize]
  void purchaseMonthlySubscription() {
    final today = DateTime.now();
    final end = today.add(const Duration(days: 30));
    final endStr = end.toIso8601String().substring(0, 10);
    
    // 월정액 가격 임의 합산 (9,900원)
    state = state.copyWith(
      hasMonthlySubscription: true,
      subscriptionEndDate: endStr,
      totalSpendKRW: state.totalSpendKRW + 9900,
    );
    _persist();
  }

  /// 일일 보석 보상 수령 (VIP + 월정액)
  int claimDailyBonus() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (state.lastDailyReward == todayStr) return 0;

    int totalBonus = 0;
    
    // VIP 티어 기본 보너스
    totalBonus += state.tier.dailyGemBonus;

    // 월정액 구독자 추가 보상
    if (state.hasMonthlySubscription && state.subscriptionEndDate.compareTo(todayStr) >= 0) {
      totalBonus += 50; // 월정액 유저는 매일 50개 추가 보석
    }

    if (totalBonus <= 0) return 0;

    state = state.copyWith(lastDailyReward: todayStr);
    _persist();

    // 실제 보석 지급
    _ref.read(userStateProvider.notifier).addGems(totalBonus);
    
    return totalBonus;
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
  (ref) => SeasonPassNotifier(ref),
);

final vipProvider =
    StateNotifierProvider<VipNotifier, VipState>(
  (ref) => VipNotifier(ref),
);
