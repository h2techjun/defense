// 해원의 문 — 유물 상태 관리 Provider
// 보유 유물 + 영웅별 장착 상태

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/relic_data.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';

/// 유물 시스템 상태
class RelicState {
  /// 잠금 해제된 유물 목록
  final Set<RelicId> unlockedRelics;

  /// 영웅별 장착된 유물 (최대 1개)
  final Map<HeroId, RelicId?> equippedRelics;

  const RelicState({
    this.unlockedRelics = const {},
    this.equippedRelics = const {},
  });

  RelicState copyWith({
    Set<RelicId>? unlockedRelics,
    Map<HeroId, RelicId?>? equippedRelics,
  }) {
    return RelicState(
      unlockedRelics: unlockedRelics ?? this.unlockedRelics,
      equippedRelics: equippedRelics ?? this.equippedRelics,
    );
  }
}

/// 유물 StateNotifier
class RelicNotifier extends StateNotifier<RelicState> {
  RelicNotifier() : super(const RelicState());

  /// 유물 잠금 해제
  void unlockRelic(RelicId relicId) {
    if (state.unlockedRelics.contains(relicId)) return;
    state = state.copyWith(
      unlockedRelics: {...state.unlockedRelics, relicId},
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

  /// 특정 효과 유형의 보너스 합산 (파티 전체)
  double getEffectBonus(HeroId heroId, RelicEffectType effectType) {
    final relic = getEquippedRelicData(heroId);
    if (relic == null || relic.effectType != effectType) return 0;
    return relic.effectValue;
  }

  /// 세이브 데이터 자동 저장
  void _persist() {
    SaveManager.instance.saveRelics(
      unlockedRelics: state.unlockedRelics,
      equippedRelics: state.equippedRelics,
    );
  }

  /// 세이브에서 유물 상태 복원
  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadRelics();
    if (data == null) return;

    final unlocked = data['unlocked'] as Set<RelicId>;
    final equipped = data['equipped'] as Map<HeroId, RelicId?>;

    state = state.copyWith(
      unlockedRelics: unlocked,
      equippedRelics: equipped,
    );
  }
}

/// 유물 Provider
final relicProvider = StateNotifierProvider<RelicNotifier, RelicState>((ref) {
  return RelicNotifier();
});
