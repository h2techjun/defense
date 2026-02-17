// 해원의 문 - 영웅 데이터 모델

import '../../common/enums.dart';

/// 영웅 스킬 데이터
class HeroSkillData {
  final String name;
  final String description;
  final double cooldown;
  final double damage;
  final double range;
  final double duration;
  final SkillTargetType targetType;
  final DamageType damageType;

  const HeroSkillData({
    required this.name,
    required this.description,
    required this.cooldown,
    this.damage = 0,
    this.range = 100,
    this.duration = 0,
    this.targetType = SkillTargetType.area,
    this.damageType = DamageType.magical,
  });
}

/// 영웅 진화 단계별 데이터
class HeroEvolutionData {
  final EvolutionTier tier;
  final String visualName;
  final String description;
  final double hpMultiplier;
  final double attackMultiplier;
  final double rangeMultiplier;

  const HeroEvolutionData({
    required this.tier,
    required this.visualName,
    required this.description,
    this.hpMultiplier = 1.0,
    this.attackMultiplier = 1.0,
    this.rangeMultiplier = 1.0,
  });
}

/// 영웅 데이터 (불변)
class HeroData {
  final HeroId id;
  final String name;
  final String title;
  final String backstory;
  final double baseHp;
  final double baseAttack;
  final double baseSpeed;
  final double baseRange;
  final DamageType damageType;
  final HeroSkillData skill;
  final List<HeroEvolutionData> evolutions;
  final Map<String, String> barks; // 상황별 대사

  const HeroData({
    required this.id,
    required this.name,
    required this.title,
    required this.backstory,
    required this.baseHp,
    required this.baseAttack,
    required this.baseSpeed,
    required this.baseRange,
    required this.damageType,
    required this.skill,
    required this.evolutions,
    this.barks = const {},
  });
}
