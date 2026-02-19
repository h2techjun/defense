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

  /// JSON → TowerUpgradeData
  factory TowerUpgradeData.fromJson(Map<String, dynamic> json) {
    return TowerUpgradeData(
      level: json['level'] as int,
      name: json['name'] as String,
      cost: json['cost'] as int,
      damage: (json['damage'] as num).toDouble(),
      range: (json['range'] as num).toDouble(),
      fireRate: (json['fireRate'] as num).toDouble(),
      specialAbility: json['specialAbility'] as String?,
    );
  }

  /// TowerUpgradeData → JSON
  Map<String, dynamic> toJson() => {
    'level': level,
    'name': name,
    'cost': cost,
    'damage': damage,
    'range': range,
    'fireRate': fireRate,
    if (specialAbility != null) 'specialAbility': specialAbility,
  };
}

/// 타워 Tier 4 분기 데이터
class TowerBranchData {
  final TowerBranch branch;
  final String name;
  final String description;
  final int cost;
  final double damage;
  final double range;
  final double fireRate;
  final DamageType? overrideDamageType; // 분기에서 공격 타입 변경 시

  // 분기별 특수 수치
  final double splashRadius;           // 스플래시 반경 (0이면 없음)
  final double dotDamage;              // DoT 초당 데미지 (0이면 없음)
  final double dotDuration;            // DoT 지속시간 (초)
  final double instantKillThreshold;   // 즉사 HP% 임계값 (0이면 없음)
  final double buffMultiplier;         // 버프 배율 (1.0이면 기본)
  final double slowAuraRatio;          // 적 감속 비율 (0이면 없음)
  final bool canDetectStealth;         // 은신 감지 가능
  final bool hasPiercing;              // 관통 (방어 무시)
  final int extraSoldierCount;         // 추가 병사 수 (병영 분기용)
  final double soldierHpMultiplier;    // 병사 HP 배율 (병영 분기용)
  final double purifySpeedMultiplier;  // 정화 속도 배율 (솟대 분기용)
  final bool canReviveTower;           // 타워 부활 가능 (솟대 분기용)
  final double stunDuration;           // 스턴 지속시간 (0이면 없음)
  final double goldBonusRatio;         // 골드 보너스 비율 (도깨비 분기용)
  final String? specialAbility;        // 특수 능력 설명

  const TowerBranchData({
    required this.branch,
    required this.name,
    required this.description,
    required this.cost,
    required this.damage,
    required this.range,
    required this.fireRate,
    this.overrideDamageType,
    this.splashRadius = 0,
    this.dotDamage = 0,
    this.dotDuration = 0,
    this.instantKillThreshold = 0,
    this.buffMultiplier = 1.0,
    this.slowAuraRatio = 0,
    this.canDetectStealth = false,
    this.hasPiercing = false,
    this.extraSoldierCount = 0,
    this.soldierHpMultiplier = 1.0,
    this.purifySpeedMultiplier = 1.0,
    this.canReviveTower = false,
    this.stunDuration = 0,
    this.goldBonusRatio = 0,
    this.specialAbility,
  });

  /// JSON → TowerBranchData
  factory TowerBranchData.fromJson(Map<String, dynamic> json) {
    return TowerBranchData(
      branch: TowerBranch.values.firstWhere((e) => e.name == json['branch']),
      name: json['name'] as String,
      description: json['description'] as String,
      cost: json['cost'] as int,
      damage: (json['damage'] as num).toDouble(),
      range: (json['range'] as num).toDouble(),
      fireRate: (json['fireRate'] as num).toDouble(),
      overrideDamageType: json['overrideDamageType'] != null
          ? DamageType.values.firstWhere((e) => e.name == json['overrideDamageType'])
          : null,
      splashRadius: (json['splashRadius'] as num?)?.toDouble() ?? 0,
      dotDamage: (json['dotDamage'] as num?)?.toDouble() ?? 0,
      dotDuration: (json['dotDuration'] as num?)?.toDouble() ?? 0,
      instantKillThreshold: (json['instantKillThreshold'] as num?)?.toDouble() ?? 0,
      buffMultiplier: (json['buffMultiplier'] as num?)?.toDouble() ?? 1.0,
      slowAuraRatio: (json['slowAuraRatio'] as num?)?.toDouble() ?? 0,
      canDetectStealth: json['canDetectStealth'] as bool? ?? false,
      hasPiercing: json['hasPiercing'] as bool? ?? false,
      extraSoldierCount: json['extraSoldierCount'] as int? ?? 0,
      soldierHpMultiplier: (json['soldierHpMultiplier'] as num?)?.toDouble() ?? 1.0,
      purifySpeedMultiplier: (json['purifySpeedMultiplier'] as num?)?.toDouble() ?? 1.0,
      canReviveTower: json['canReviveTower'] as bool? ?? false,
      stunDuration: (json['stunDuration'] as num?)?.toDouble() ?? 0,
      goldBonusRatio: (json['goldBonusRatio'] as num?)?.toDouble() ?? 0,
      specialAbility: json['specialAbility'] as String?,
    );
  }

  /// TowerBranchData → JSON
  Map<String, dynamic> toJson() => {
    'branch': branch.name,
    'name': name,
    'description': description,
    'cost': cost,
    'damage': damage,
    'range': range,
    'fireRate': fireRate,
    if (overrideDamageType != null) 'overrideDamageType': overrideDamageType!.name,
    if (splashRadius != 0) 'splashRadius': splashRadius,
    if (dotDamage != 0) 'dotDamage': dotDamage,
    if (dotDuration != 0) 'dotDuration': dotDuration,
    if (instantKillThreshold != 0) 'instantKillThreshold': instantKillThreshold,
    if (buffMultiplier != 1.0) 'buffMultiplier': buffMultiplier,
    if (slowAuraRatio != 0) 'slowAuraRatio': slowAuraRatio,
    if (canDetectStealth) 'canDetectStealth': true,
    if (hasPiercing) 'hasPiercing': true,
    if (extraSoldierCount != 0) 'extraSoldierCount': extraSoldierCount,
    if (soldierHpMultiplier != 1.0) 'soldierHpMultiplier': soldierHpMultiplier,
    if (purifySpeedMultiplier != 1.0) 'purifySpeedMultiplier': purifySpeedMultiplier,
    if (canReviveTower) 'canReviveTower': true,
    if (stunDuration != 0) 'stunDuration': stunDuration,
    if (goldBonusRatio != 0) 'goldBonusRatio': goldBonusRatio,
    if (specialAbility != null) 'specialAbility': specialAbility,
  };
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

  /// JSON → TowerData
  factory TowerData.fromJson(Map<String, dynamic> json) {
    return TowerData(
      type: TowerType.values.firstWhere((e) => e.name == json['type']),
      name: json['name'] as String,
      description: json['description'] as String,
      baseCost: json['baseCost'] as int,
      baseDamage: (json['baseDamage'] as num).toDouble(),
      baseRange: (json['baseRange'] as num).toDouble(),
      baseFireRate: (json['baseFireRate'] as num).toDouble(),
      damageType: DamageType.values.firstWhere((e) => e.name == json['damageType']),
      upgrades: (json['upgrades'] as List<dynamic>?)
          ?.map((u) => TowerUpgradeData.fromJson(u as Map<String, dynamic>))
          .toList() ?? [],
      branchA: json['branchA'] != null
          ? TowerBranch.values.firstWhere((e) => e.name == json['branchA'])
          : null,
      branchB: json['branchB'] != null
          ? TowerBranch.values.firstWhere((e) => e.name == json['branchB'])
          : null,
    );
  }

  /// TowerData → JSON
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
    'description': description,
    'baseCost': baseCost,
    'baseDamage': baseDamage,
    'baseRange': baseRange,
    'baseFireRate': baseFireRate,
    'damageType': damageType.name,
    if (upgrades.isNotEmpty) 'upgrades': upgrades.map((u) => u.toJson()).toList(),
    if (branchA != null) 'branchA': branchA!.name,
    if (branchB != null) 'branchB': branchB!.name,
  };
}
