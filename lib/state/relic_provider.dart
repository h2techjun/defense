// 해원의 문 — 유물 상태 관리 Provider
// 보유 유물 + 영웅별 장착 상태 + 강화 시스템

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/relic_data.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';
import 'user_state.dart';

/// 유물 강화 결과
enum UpgradeResult {
  success,    // 강화 성공!
  failed,     // 강화 실패 (레벨 유지)
  maxLevel,   // 이미 최대 레벨
  notEnoughGold, // 골드 부족
  notUnlocked,   // 유물 미해금
}

/// 유물 시스템 상태
class RelicState {
  /// 잠금 해제된 유물 목록
  final Set<RelicId> unlockedRelics;

  /// 영웅별 장착된 유물 (최대 1개)
  final Map<HeroId, RelicId?> equippedRelics;

  /// 유물별 강화 레벨 (1~5, 해금 시 Lv1)
  final Map<RelicId, int> relicLevels;

  const RelicState({
    this.unlockedRelics = const {},
    this.equippedRelics = const {},
    this.relicLevels = const {},
  });

  RelicState copyWith({
    Set<RelicId>? unlockedRelics,
    Map<HeroId, RelicId?>? equippedRelics,
    Map<RelicId, int>? relicLevels,
  }) {
    return RelicState(
      unlockedRelics: unlockedRelics ?? this.unlockedRelics,
      equippedRelics: equippedRelics ?? this.equippedRelics,
      relicLevels: relicLevels ?? this.relicLevels,
    );
  }

  /// 특정 유물의 현재 레벨
  int getLevel(RelicId id) => relicLevels[id] ?? 1;
}

/// 유물 StateNotifier
class RelicNotifier extends StateNotifier<RelicState> {
  final Ref _ref;
  final Random _rng = Random();

  RelicNotifier(this._ref) : super(const RelicState());

  /// 유물 잠금 해제 (Lv1로 시작)
  void unlockRelic(RelicId relicId) {
    if (state.unlockedRelics.contains(relicId)) return;
    state = state.copyWith(
      unlockedRelics: {...state.unlockedRelics, relicId},
      relicLevels: {...state.relicLevels, relicId: 1},
    );
    _persist();
  }

  /// 영웅에 유물 장착
  void equipRelic(HeroId heroId, RelicId relicId) {
    if (!state.unlockedRelics.contains(relicId)) return;

    // 다른 영웅이 이미 장착 중이면 해제
    final newEquipped = Map<HeroId, RelicId?>.from(state.equippedRelics);
    newEquipped.forEach((key, value) {
      if (value == relicId) newEquipped[key] = null;
    });
    newEquipped[heroId] = relicId;

    state = state.copyWith(equippedRelics: newEquipped);
    _persist();
  }

  /// 영웅의 유물 해제
  void unequipRelic(HeroId heroId) {
    final newEquipped = Map<HeroId, RelicId?>.from(state.equippedRelics);
    newEquipped[heroId] = null;
    state = state.copyWith(equippedRelics: newEquipped);
    _persist();
  }

  /// 특정 영웅의 장착 유물 데이터 반환
  RelicData? getEquippedRelicData(HeroId heroId) {
    final relicId = state.equippedRelics[heroId];
    if (relicId == null) return null;
    return allRelics[relicId];
  }

  /// 특정 효과 유형의 보너스 합산 (강화 레벨 반영!)
  double getEffectBonus(HeroId heroId, RelicEffectType effectType) {
    final relicId = state.equippedRelics[heroId];
    if (relicId == null) return 0;
    final relic = allRelics[relicId];
    if (relic == null || relic.effectType != effectType) return 0;
    final level = state.getLevel(relicId);
    return relic.effectAtLevel(level);
  }

  /// 유물 강화 시도 — 골드 소비 + 확률 판정
  UpgradeResult upgradeRelic(RelicId relicId) {
    // 1. 해금 확인
    if (!state.unlockedRelics.contains(relicId)) {
      return UpgradeResult.notUnlocked;
    }

    // 2. 최대 레벨 확인
    final currentLevel = state.getLevel(relicId);
    if (currentLevel >= relicMaxLevel) {
      return UpgradeResult.maxLevel;
    }

    // 3. 강화 비용 확인
    final relic = allRelics[relicId]!;
    final cost = relic.upgradeCost(currentLevel);
    if (cost <= 0) return UpgradeResult.maxLevel;

    // 4. 골드 부족 확인
    final userNotifier = _ref.read(userStateProvider.notifier);
    if (!userNotifier.spendGold(cost)) {
      return UpgradeResult.notEnoughGold;
    }

    // 5. 성공률 판정
    final successRate = relic.upgradeSuccessRate(currentLevel);
    final roll = _rng.nextInt(100); // 0~99

    if (roll < successRate) {
      // ✅ 강화 성공!
      state = state.copyWith(
        relicLevels: {...state.relicLevels, relicId: currentLevel + 1},
      );
      _persist();

      if (kDebugMode) {
        debugPrint('🏺 유물 강화 성공: ${relic.nameKo} Lv$currentLevel → Lv${currentLevel + 1} (비용: ${cost}골)');
      }
      return UpgradeResult.success;
    } else {
      // ❌ 강화 실패 (골드는 소비됨, 레벨 유지)
      _persist();

      if (kDebugMode) {
        debugPrint('💔 유물 강화 실패: ${relic.nameKo} Lv$currentLevel (확률: $successRate%, 비용: ${cost}골 소비)');
      }
      return UpgradeResult.failed;
    }
  }

  /// 세이브 데이터 자동 저장
  void _persist() {
    SaveManager.instance.saveRelics(
      unlockedRelics: state.unlockedRelics,
      equippedRelics: state.equippedRelics,
      relicLevels: state.relicLevels,
    );
  }

  /// 세이브에서 유물 상태 복원
  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadRelics();
    if (data == null) return;

    final unlocked = data['unlocked'] as Set<RelicId>;
    final equipped = data['equipped'] as Map<HeroId, RelicId?>;
    final levels = data['levels'] as Map<RelicId, int>? ?? {};

    state = state.copyWith(
      unlockedRelics: unlocked,
      equippedRelics: equipped,
      relicLevels: levels,
    );
  }
}

/// 유물 Provider
final relicProvider = StateNotifierProvider<RelicNotifier, RelicState>((ref) {
  return RelicNotifier(ref);
});
