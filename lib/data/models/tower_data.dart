// 해원의 문 - 타워 데이터 모델

import '../../common/enums.dart';

/// 타워 업그레이드 데이터
class TowerUpgradeData {
  final int level;
  final String name;
  final int cost;
  final double damage;
  final double range;
  final double fireRate; // 초당 발사 횟수
  final String? specialAbility;

  const TowerUpgradeData({
    required this.level,
    required this.name,
    required this.cost,
    required this.damage,
    required this.range,
    required this.fireRate,
    this.specialAbility,
  });
}

/// 타워 데이터 (불변)
class TowerData {
  final TowerType type;
  final String name;
  final String description;
  final int baseCost;
  final double baseDamage;
  final double baseRange;
  final double baseFireRate;
  final DamageType damageType;
  final List<TowerUpgradeData> upgrades;

  /// Tier 4 분기점 (두 가지 선택)
  final TowerBranch? branchA;
  final TowerBranch? branchB;

  const TowerData({
    required this.type,
    required this.name,
    required this.description,
    required this.baseCost,
    required this.baseDamage,
    required this.baseRange,
    required this.baseFireRate,
    required this.damageType,
    this.upgrades = const [],
    this.branchA,
    this.branchB,
  });
}
