// 해원의 문 - 소환권 시스템 (Riverpod)
// 영웅 소환, 타워 강화권 등 소환 아이템 관리

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/save_manager.dart';

class SummonState {
  final int heroSummonTickets;
  final int towerUpgradeTickets;

  const SummonState({
    this.heroSummonTickets = 0,
    this.towerUpgradeTickets = 0,
  });

  SummonState copyWith({
    int? heroSummonTickets,
    int? towerUpgradeTickets,
  }) {
    return SummonState(
      heroSummonTickets: heroSummonTickets ?? this.heroSummonTickets,
      towerUpgradeTickets: towerUpgradeTickets ?? this.towerUpgradeTickets,
    );
  }

  Map<String, dynamic> toJson() => {
    'heroSummonTickets': heroSummonTickets,
    'towerUpgradeTickets': towerUpgradeTickets,
  };

  factory SummonState.fromJson(Map<String, dynamic> json) {
    return SummonState(
      heroSummonTickets: (json['heroSummonTickets'] as num?)?.toInt() ?? 0,
      towerUpgradeTickets: (json['towerUpgradeTickets'] as num?)?.toInt() ?? 0,
    );
  }
}

class SummonNotifier extends StateNotifier<SummonState> {
  SummonNotifier() : super(const SummonState());

  /// 데이터 로드
  Future<void> load() async {
    final data = await SaveManager.instance.loadCustomData('summon_state');
    if (data != null) {
      state = SummonState.fromJson(data);
    }
  }

  /// 자동 저장
  Future<void> _save() async {
    await SaveManager.instance.saveCustomData('summon_state', state.toJson());
  }

  /// 소환권 추가
  void addTickets(String type, int amount) {
    if (type == 'hero' || type == 'summonTicket') {
      state = state.copyWith(heroSummonTickets: state.heroSummonTickets + amount);
    } else if (type == 'towerUpgrade') {
      state = state.copyWith(towerUpgradeTickets: state.towerUpgradeTickets + amount);
    }
    _save();
  }

  /// 소환권 사용
  bool useTicket(String type, int amount) {
    if (type == 'hero') {
      if (state.heroSummonTickets < amount) return false;
      state = state.copyWith(heroSummonTickets: state.heroSummonTickets - amount);
    } else if (type == 'towerUpgrade') {
      if (state.towerUpgradeTickets < amount) return false;
      state = state.copyWith(towerUpgradeTickets: state.towerUpgradeTickets - amount);
    } else {
      return false;
    }
    _save();
    return true;
  }
}

final summonProvider = StateNotifierProvider<SummonNotifier, SummonState>((ref) {
  return SummonNotifier();
});
