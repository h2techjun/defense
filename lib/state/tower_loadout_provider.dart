// 해원의 문 - 타워 출전 & 외부 레벨 관리
// 출전 타워 선택 + 스테이지 참여 기반 XP/레벨 시스템

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';

/// 타워 외부 레벨 데이터
class TowerLevelData {
  final int level;
  final int xp;

  const TowerLevelData({this.level = 1, this.xp = 0});

  TowerLevelData copyWith({int? level, int? xp}) =>
      TowerLevelData(level: level ?? this.level, xp: xp ?? this.xp);
}

/// 타워 출전 + 레벨 상태
class TowerLoadoutState {
  /// 출전 타워 (최대 5칸)
  final List<TowerType> loadout;

  /// 타워별 외부 레벨/XP
  final Map<TowerType, TowerLevelData> towerLevels;

  const TowerLoadoutState({
    this.loadout = const [],
    this.towerLevels = const {},
  });

  TowerLoadoutState copyWith({
    List<TowerType>? loadout,
    Map<TowerType, TowerLevelData>? towerLevels,
  }) =>
      TowerLoadoutState(
        loadout: loadout ?? this.loadout,
        towerLevels: towerLevels ?? this.towerLevels,
      );

  /// 특정 타워의 외부 레벨
  int getTowerLevel(TowerType type) =>
      towerLevels[type]?.level ?? 1;

  /// 특정 타워의 현재 XP
  int getTowerXp(TowerType type) =>
      towerLevels[type]?.xp ?? 0;
}

/// 타워 출전 & 레벨 관리 노티파이어
class TowerLoadoutNotifier extends StateNotifier<TowerLoadoutState> {
  /// 최대 출전 슬롯
  static const int maxLoadoutSlots = 5;

  /// 외부 레벨 최대치 (시즌 1 기준, 추후 재조정)
  static const int maxExternalLevel = 10;

  /// 레벨별 필요 XP 공식: 15 * level^2.0 (50스테이지 기준 완만 곡선)
  static int xpForLevel(int level) =>
      (15 * math.pow(level, 2.0)).floor();

  TowerLoadoutNotifier() : super(const TowerLoadoutState()) {
    _loadSaved();
  }

  /// 저장된 데이터 로드
  Future<void> _loadSaved() async {
    final loadout = await SaveManager.instance.loadTowerLoadout();
    final levels = await SaveManager.instance.loadTowerLevels();

    // 기본 출전: 모든 기본 타워
    final defaultLoadout = [
      TowerType.archer,
      TowerType.barracks,
      TowerType.shaman,
      TowerType.artillery,
      TowerType.sotdae,
    ];

    final towerLevels = <TowerType, TowerLevelData>{};
    for (final entry in levels.entries) {
      try {
        final type = TowerType.values.firstWhere((t) => t.name == entry.key);
        towerLevels[type] = TowerLevelData(
          level: entry.value['level'] ?? 1,
          xp: entry.value['xp'] ?? 0,
        );
      } catch (_) {
        // 알 수 없는 타워 타입 무시
      }
    }

    state = state.copyWith(
      loadout: loadout.isNotEmpty ? loadout : defaultLoadout,
      towerLevels: towerLevels,
    );
  }

  /// 출전 슬롯에 타워 배치
  void setLoadoutSlot(int slot, TowerType type) {
    if (slot < 0 || slot >= maxLoadoutSlots) return;
    final newLoadout = List<TowerType>.from(state.loadout);

    // 이미 같은 타워가 있으면 기존 위치에서 제거
    newLoadout.remove(type);

    // 슬롯 범위 조정
    while (newLoadout.length <= slot) {
      newLoadout.add(TowerType.values.first); // 임시
    }
    newLoadout[slot] = type;

    state = state.copyWith(loadout: newLoadout);
    _saveLoadout();
  }

  /// 드래그&드롭으로 특정 슬롯에 타워 삽입
  /// - 이미 편성된 타워: 기존 위치에서 제거 후 지정 슬롯에 삽입
  /// - 미편성 타워 + 빈 자리: 지정 슬롯에 삽입
  /// - 미편성 타워 + 가득 참: 지정 슬롯의 기존 타워를 교체
  void insertAtSlot(int slot, TowerType type) {
    if (slot < 0 || slot >= maxLoadoutSlots) return;
    final newLoadout = List<TowerType>.from(state.loadout);

    final existingIndex = newLoadout.indexOf(type);
    if (existingIndex >= 0) {
      // 이미 편성된 타워 → 위치 이동
      newLoadout.removeAt(existingIndex);
      final insertIdx = slot.clamp(0, newLoadout.length);
      newLoadout.insert(insertIdx, type);
    } else if (newLoadout.length < maxLoadoutSlots) {
      // 빈 자리 있음 → 삽입
      final insertIdx = slot.clamp(0, newLoadout.length);
      newLoadout.insert(insertIdx, type);
    } else {
      // 가득 참 → 해당 슬롯의 타워를 교체
      if (slot < newLoadout.length) {
        newLoadout[slot] = type;
      }
    }

    state = state.copyWith(loadout: newLoadout);
    _saveLoadout();
  }

  /// 출전 슬롯에서 타워 제거
  void removeFromLoadout(TowerType type) {
    final newLoadout = List<TowerType>.from(state.loadout);
    newLoadout.remove(type);
    state = state.copyWith(loadout: newLoadout);
    _saveLoadout();
  }

  /// 출전 목록에 타워 추가
  void addToLoadout(TowerType type) {
    if (state.loadout.contains(type)) return;
    if (state.loadout.length >= maxLoadoutSlots) return;
    final newLoadout = List<TowerType>.from(state.loadout)..add(type);
    state = state.copyWith(loadout: newLoadout);
    _saveLoadout();
  }

  /// 스테이지 완료 시 참여 타워에 XP 부여
  void gainTowerXp(Set<TowerType> participatedTowers, int baseXp) {
    final newLevels = Map<TowerType, TowerLevelData>.from(state.towerLevels);

    for (final type in participatedTowers) {
      final current = newLevels[type] ?? const TowerLevelData();
      if (current.level >= maxExternalLevel) continue;

      int newXp = current.xp + baseXp;
      int newLevel = current.level;

      // XP가 레벨업 기준을 넘으면 레벨업
      while (newLevel < maxExternalLevel && newXp >= xpForLevel(newLevel)) {
        newXp -= xpForLevel(newLevel);
        newLevel++;
      }

      // 최대 레벨 도달 시 XP 초기화
      if (newLevel >= maxExternalLevel) {
        newLevel = maxExternalLevel;
        newXp = 0;
      }

      newLevels[type] = TowerLevelData(level: newLevel, xp: newXp);
    }

    state = state.copyWith(towerLevels: newLevels);
    _saveLevels();
  }

  /// 외부 레벨에 따른 데미지 배율 (레벨당 +3%, 보수적)
  static double damageMultiplier(int externalLevel) =>
      1.0 + (externalLevel - 1) * 0.03;

  /// 외부 레벨에 따른 사거리 배율 (레벨당 +1.5%)
  static double rangeMultiplier(int externalLevel) =>
      1.0 + (externalLevel - 1) * 0.015;

  /// 외부 레벨에 따른 공속 배율 (레벨당 +2%, 발사간격 감소)
  static double fireRateMultiplier(int externalLevel) =>
      1.0 + (externalLevel - 1) * 0.02;

  /// 저장
  Future<void> _saveLoadout() async {
    await SaveManager.instance.saveTowerLoadout(
      state.loadout.map((t) => t.name).toList(),
    );
  }

  Future<void> _saveLevels() async {
    final data = <String, Map<String, int>>{};
    for (final entry in state.towerLevels.entries) {
      data[entry.key.name] = {
        'level': entry.value.level,
        'xp': entry.value.xp,
      };
    }
    await SaveManager.instance.saveTowerLevels(data);
  }
}

/// Riverpod Provider
final towerLoadoutProvider =
    StateNotifierProvider<TowerLoadoutNotifier, TowerLoadoutState>(
  (ref) => TowerLoadoutNotifier(),
);
