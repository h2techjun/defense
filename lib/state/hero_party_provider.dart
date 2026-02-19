// 해원의 문 - 영웅 파티 상태 관리
// 전투에 투입할 영웅 파티 (최대 3명) 선택 + 레벨 관리

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';

/// 전투 파티 슬롯 (영웅 ID + 레벨)
class HeroPartySlot {
  final HeroId heroId;
  final int level;

  const HeroPartySlot({required this.heroId, this.level = 1});

  HeroPartySlot copyWith({HeroId? heroId, int? level}) {
    return HeroPartySlot(
      heroId: heroId ?? this.heroId,
      level: level ?? this.level,
    );
  }
}

/// 영웅 파티 상태
class HeroPartyState {
  final List<HeroPartySlot> party; // 최대 1명
  static const int maxPartySize = 1;

  const HeroPartyState({this.party = const []});

  HeroPartyState copyWith({List<HeroPartySlot>? party}) {
    return HeroPartyState(party: party ?? this.party);
  }

  /// 파티에 특정 영웅이 있는지
  bool containsHero(HeroId id) =>
      party.any((slot) => slot.heroId == id);

  /// 파티가 가득 찼는지
  bool get isFull => party.length >= maxPartySize;
}

/// 영웅 파티 Notifier
class HeroPartyNotifier extends StateNotifier<HeroPartyState> {
  HeroPartyNotifier() : super(const HeroPartyState(
    // 기본 파티: 깨비 1명
    party: [
      HeroPartySlot(heroId: HeroId.kkaebi, level: 1),
    ],
  )) {
    // 앱 시작 시 저장된 영웅 로드
    _loadSavedHero();
  }

  /// 저장된 영웅 선택 로드 (레벨 포함)
  Future<void> _loadSavedHero() async {
    final savedHero = await SaveManager.instance.loadSelectedHero();
    if (savedHero != null) {
      // 저장된 레벨 로드
      final savedLevel = await SaveManager.instance.loadHeroLevel(savedHero);
      final heroLevel = savedLevel['level'] ?? 1;
      state = state.copyWith(
        party: [HeroPartySlot(heroId: savedHero, level: heroLevel)],
      );
    }
  }

  /// 파티에 영웅 추가 (1명 제한 — 교체 방식)
  void addHero(HeroId id, {int level = 1}) {
    if (state.containsHero(id)) return;
    // 1명 제한: 기존 영웅을 교체
    state = state.copyWith(
      party: [HeroPartySlot(heroId: id, level: level)],
    );
    // 선택 저장
    SaveManager.instance.saveSelectedHero(id);
  }

  /// 파티에서 영웅 제거
  void removeHero(HeroId id) {
    state = state.copyWith(
      party: state.party.where((s) => s.heroId != id).toList(),
    );
  }

  /// 파티 슬롯 교체
  void replaceHero(int index, HeroId newId, {int level = 1}) {
    if (index < 0 || index >= state.party.length) return;
    if (state.containsHero(newId)) return;
    final updated = List<HeroPartySlot>.from(state.party);
    updated[index] = HeroPartySlot(heroId: newId, level: level);
    state = state.copyWith(party: updated);
    // 선택 저장
    SaveManager.instance.saveSelectedHero(newId);
  }

  /// 영웅 레벨 업
  void levelUpHero(HeroId id) {
    final updated = state.party.map((slot) {
      if (slot.heroId == id) {
        return slot.copyWith(level: slot.level + 1);
      }
      return slot;
    }).toList();
    state = state.copyWith(party: updated);
  }

  /// 전체 파티 교체
  void setParty(List<HeroPartySlot> newParty) {
    state = state.copyWith(party: newParty.take(HeroPartyState.maxPartySize).toList());
    // 선택 저장
    if (newParty.isNotEmpty) {
      SaveManager.instance.saveSelectedHero(newParty.first.heroId);
    }
  }
}

/// 영웅 파티 Provider
final heroPartyProvider = StateNotifierProvider<HeroPartyNotifier, HeroPartyState>(
  (ref) => HeroPartyNotifier(),
);
