// 해원의 문 - 스킨 상태 관리
// Riverpod 기반 스킨 보유/장착 상태

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/skin_data.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';

/// 스킨 상태
class SkinState {
  final Set<SkinId> ownedSkins;
  final Map<HeroId, SkinId> equippedSkins;

  const SkinState({
    this.ownedSkins = const {},
    this.equippedSkins = const {},
  });

  SkinState copyWith({
    Set<SkinId>? ownedSkins,
    Map<HeroId, SkinId>? equippedSkins,
  }) {
    return SkinState(
      ownedSkins: ownedSkins ?? this.ownedSkins,
      equippedSkins: equippedSkins ?? this.equippedSkins,
    );
  }
}

/// 스킨 Notifier
class SkinNotifier extends StateNotifier<SkinState> {
  SkinNotifier() : super(SkinState(
    // 기본 스킨은 모두 보유
    ownedSkins: {
      SkinId.kkaebiDefault,
      SkinId.mihoDefault,
      SkinId.gangrimDefault,
      SkinId.suaDefault,
      SkinId.bariDefault,
    },
    // 기본 스킨 장착
    equippedSkins: {
      HeroId.kkaebi: SkinId.kkaebiDefault,
      HeroId.miho: SkinId.mihoDefault,
      HeroId.gangrim: SkinId.gangrimDefault,
      HeroId.sua: SkinId.suaDefault,
      HeroId.bari: SkinId.bariDefault,
    },
  ));

  /// 스킨 구매/획득
  void unlockSkin(SkinId skinId) {
    state = state.copyWith(
      ownedSkins: {...state.ownedSkins, skinId},
    );
    _persist();
  }

  /// 스킨 장착
  void equipSkin(HeroId heroId, SkinId skinId) {
    // 해당 영웅의 스킨인지 확인
    final skin = allSkins[skinId];
    if (skin == null || skin.heroId != heroId) return;
    if (!state.ownedSkins.contains(skinId)) return;

    final newEquipped = Map<HeroId, SkinId>.from(state.equippedSkins);
    newEquipped[heroId] = skinId;
    state = state.copyWith(equippedSkins: newEquipped);
    _persist();
  }

  /// 영웅의 현재 장착 스킨 데이터
  SkinData? getEquippedSkin(HeroId heroId) {
    final skinId = state.equippedSkins[heroId];
    if (skinId == null) return null;
    return allSkins[skinId];
  }

  /// 스킨 보유 여부
  bool ownsSkin(SkinId skinId) => state.ownedSkins.contains(skinId);

  /// 자동 저장
  void _persist() {
    SaveManager.instance.saveSkins(
      ownedSkins: state.ownedSkins,
      equippedSkins: state.equippedSkins,
    );
  }

  /// 세이브 로드
  Future<void> loadFromSave() async {
    final data = await SaveManager.instance.loadSkins();
    if (data == null) return;

    final owned = data['owned'] as Set<SkinId>;
    final equipped = data['equipped'] as Map<HeroId, SkinId>;

    // 기본 스킨은 항상 보유
    final mergedOwned = {
      SkinId.kkaebiDefault,
      SkinId.mihoDefault,
      SkinId.gangrimDefault,
      SkinId.suaDefault,
      SkinId.bariDefault,
      ...owned,
    };

    state = state.copyWith(
      ownedSkins: mergedOwned,
      equippedSkins: equipped,
    );
  }
}

/// 스킨 Provider
final skinProvider = StateNotifierProvider<SkinNotifier, SkinState>(
  (ref) => SkinNotifier(),
);
