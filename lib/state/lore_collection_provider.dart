// 해원의 문 - 설화도감 상태 관리
// 3단계 해금 + 킬 카운트 추적 + 수집률 보상

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/lore_collection_data.dart';
import '../services/save_manager.dart';
import 'user_state.dart';

/// 설화도감 상태
class LoreCollectionState {
  /// 엔트리별 킬 카운트
  final Map<String, int> killCounts;

  /// 보석 보상을 수령한 단계 (entryId → Set<LoreUnlockTier>)
  final Map<String, Set<LoreUnlockTier>> claimedTiers;

  /// 수령한 마일스톤 (percentage → claimed)
  final Set<double> claimedMilestones;

  const LoreCollectionState({
    this.killCounts = const {},
    this.claimedTiers = const {},
    this.claimedMilestones = const {},
  });

  LoreCollectionState copyWith({
    Map<String, int>? killCounts,
    Map<String, Set<LoreUnlockTier>>? claimedTiers,
    Set<double>? claimedMilestones,
  }) {
    return LoreCollectionState(
      killCounts: killCounts ?? this.killCounts,
      claimedTiers: claimedTiers ?? this.claimedTiers,
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
    );
  }

  /// 특정 엔트리의 킬 카운트
  int getKills(String entryId) => killCounts[entryId] ?? 0;

  /// 특정 엔트리의 해금 단계
  LoreUnlockTier getTier(LoreEntry entry) {
    return entry.getTier(getKills(entry.id));
  }

  /// 전체 수집률 (encountered 이상 / 전체)
  double get collectionRate {
    if (allLoreEntries.isEmpty) return 0;
    int discovered = 0;
    for (final entry in allLoreEntries) {
      if (getTier(entry) != LoreUnlockTier.locked) {
        discovered++;
      }
    }
    return discovered / allLoreEntries.length;
  }

  /// 카테고리별 수집률
  double categoryRate(LoreCategory category) {
    final entries = allLoreEntries.where((e) => e.category == category);
    if (entries.isEmpty) return 0;
    int discovered = 0;
    for (final entry in entries) {
      if (getTier(entry) != LoreUnlockTier.locked) discovered++;
    }
    return discovered / entries.length;
  }

  /// 미수령 보석 보상 존재 여부
  bool get hasUnclaimedRewards {
    for (final entry in allLoreEntries) {
      final tier = getTier(entry);
      if (tier == LoreUnlockTier.locked) continue;
      final claimed = claimedTiers[entry.id] ?? {};
      // 현재 해금된 모든 단계의 보상을 수령했는지
      for (final t in LoreUnlockTier.values) {
        if (t == LoreUnlockTier.locked) continue;
        if (t.index <= tier.index && !claimed.contains(t)) return true;
      }
    }
    // 마일스톤 체크
    for (final ms in collectionMilestones) {
      if (collectionRate >= ms.percentage && !claimedMilestones.contains(ms.percentage)) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'killCounts': killCounts,
    'claimedTiers': claimedTiers.map(
      (k, v) => MapEntry(k, v.map((t) => t.name).toList()),
    ),
    'claimedMilestones': claimedMilestones.toList(),
  };

  factory LoreCollectionState.fromJson(Map<String, dynamic> json) {
    return LoreCollectionState(
      killCounts: (json['killCounts'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
      claimedTiers: (json['claimedTiers'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(
            k,
            ((v as List?) ?? [])
                .map((t) => LoreUnlockTier.values.firstWhere(
                  (e) => e.name == t,
                  orElse: () => LoreUnlockTier.locked,
                ))
                .toSet(),
          )) ?? {},
      claimedMilestones: ((json['claimedMilestones'] as List?) ?? [])
          .map((e) => (e as num).toDouble()).toSet(),
    );
  }
}

/// 설화도감 Notifier
class LoreCollectionNotifier extends StateNotifier<LoreCollectionState> {
  final Ref _ref;
  LoreCollectionNotifier(this._ref) : super(const LoreCollectionState());

  /// 적 처치 기록 (전투 중 자동 호출)
  void recordKill(String enemyId) {
    final newCounts = Map<String, int>.from(state.killCounts);
    newCounts[enemyId] = (newCounts[enemyId] ?? 0) + 1;
    state = state.copyWith(killCounts: newCounts);
    _persist();
  }

  /// 적 아닌 항목 (영웅/세계관)은 수동 해금이나 자동 조우
  void recordEncounter(String entryId) {
    final current = state.killCounts[entryId] ?? 0;
    if (current == 0) {
      final newCounts = Map<String, int>.from(state.killCounts);
      newCounts[entryId] = 1;
      state = state.copyWith(killCounts: newCounts);
      _persist();
    }
  }

  /// 영웅 사용 카운트 증가
  void recordHeroUse(String heroLoreId) {
    final newCounts = Map<String, int>.from(state.killCounts);
    newCounts[heroLoreId] = (newCounts[heroLoreId] ?? 0) + 1;
    state = state.copyWith(killCounts: newCounts);
    _persist();
  }

  /// 단계 보상 수령
  bool claimTierReward(String entryId, LoreUnlockTier tier) {
    final entry = allLoreEntries.firstWhere(
      (e) => e.id == entryId,
      orElse: () => allLoreEntries.first,
    );

    // 해금 조건 확인
    final currentTier = state.getTier(entry);
    if (tier.index > currentTier.index) return false;

    // 이미 수령 확인
    final claimed = state.claimedTiers[entryId] ?? {};
    if (claimed.contains(tier)) return false;

    // 보석 지급
    final gems = entry.gemsForTier(tier);
    if (gems > 0) {
      _ref.read(userStateProvider.notifier).addGems(gems);
    }

    // 수령 기록
    final newClaimedTiers = Map<String, Set<LoreUnlockTier>>.from(
      state.claimedTiers.map((k, v) => MapEntry(k, Set.from(v))),
    );
    newClaimedTiers[entryId] = {...claimed, tier};

    state = state.copyWith(claimedTiers: newClaimedTiers);
    _persist();
    return true;
  }

  /// 마일스톤 보상 수령
  bool claimMilestone(double percentage) {
    if (state.collectionRate < percentage) return false;
    if (state.claimedMilestones.contains(percentage)) return false;

    final milestone = collectionMilestones.firstWhere(
      (m) => m.percentage == percentage,
    );

    final userNotifier = _ref.read(userStateProvider.notifier);
    userNotifier.addGems(milestone.rewardGems);
    userNotifier.addGold(milestone.rewardGold);

    state = state.copyWith(
      claimedMilestones: {...state.claimedMilestones, percentage},
    );
    _persist();
    return true;
  }

  void _persist() {
    SaveManager.instance.saveLoreCollection(state.toJson());
  }

  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadLoreCollection();
    if (data != null) {
      state = LoreCollectionState.fromJson(data);
    }
  }
}

/// Provider
final loreCollectionProvider =
    StateNotifierProvider<LoreCollectionNotifier, LoreCollectionState>(
  (ref) => LoreCollectionNotifier(ref),
);
