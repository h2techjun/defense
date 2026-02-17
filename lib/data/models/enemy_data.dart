// 해원의 문 - 적 데이터 모델

import '../../common/enums.dart';

/// 적 특수 능력
class EnemyAbility {
  final String name;
  final String description;
  final double value; // 능력의 수치 (확률, 데미지 등)
  final double duration;

  const EnemyAbility({
    required this.name,
    required this.description,
    this.value = 0,
    this.duration = 0,
  });
}

/// 적 데이터 (불변)
class EnemyData {
  final EnemyId id;
  final String name;
  final String description;
  final Chapter chapter;
  final double hp;
  final double speed;
  final double attack;
  final ArmorType armorType;
  final int sinmyeongReward; // 처치 시 신명 보상
  final double evasion; // 기본 회피율 (0~1)
  final bool isFlying; // 비행 유닛 여부
  final bool isBoss; // 보스 여부
  final List<EnemyAbility> abilities;

  /// 사망 시 스폰되는 적 ID (2페이즈)
  final EnemyId? deathSpawnId;
  final int deathSpawnCount;

  const EnemyData({
    required this.id,
    required this.name,
    required this.description,
    required this.chapter,
    required this.hp,
    required this.speed,
    this.attack = 0,
    required this.armorType,
    required this.sinmyeongReward,
    this.evasion = 0,
    this.isFlying = false,
    this.isBoss = false,
    this.abilities = const [],
    this.deathSpawnId,
    this.deathSpawnCount = 0,
  });
}
