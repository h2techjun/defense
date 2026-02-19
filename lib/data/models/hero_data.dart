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

  /// JSON → HeroSkillData
  factory HeroSkillData.fromJson(Map<String, dynamic> json) {
    return HeroSkillData(
      name: json['name'] as String,
      description: json['description'] as String,
      cooldown: (json['cooldown'] as num).toDouble(),
      damage: (json['damage'] as num?)?.toDouble() ?? 0,
      range: (json['range'] as num?)?.toDouble() ?? 100,
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
      targetType: SkillTargetType.values.firstWhere(
        (e) => e.name == json['targetType'],
        orElse: () => SkillTargetType.area,
      ),
      damageType: DamageType.values.firstWhere(
        (e) => e.name == json['damageType'],
        orElse: () => DamageType.magical,
      ),
    );
  }

  /// HeroSkillData → JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'cooldown': cooldown,
    if (damage != 0) 'damage': damage,
    'range': range,
    if (duration != 0) 'duration': duration,
    'targetType': targetType.name,
    'damageType': damageType.name,
  };
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

  /// JSON → HeroEvolutionData
  factory HeroEvolutionData.fromJson(Map<String, dynamic> json) {
    return HeroEvolutionData(
      tier: EvolutionTier.values.firstWhere((e) => e.name == json['tier']),
      visualName: json['visualName'] as String,
      description: json['description'] as String,
      hpMultiplier: (json['hpMultiplier'] as num?)?.toDouble() ?? 1.0,
      attackMultiplier: (json['attackMultiplier'] as num?)?.toDouble() ?? 1.0,
      rangeMultiplier: (json['rangeMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// HeroEvolutionData → JSON
  Map<String, dynamic> toJson() => {
    'tier': tier.name,
    'visualName': visualName,
    'description': description,
    if (hpMultiplier != 1.0) 'hpMultiplier': hpMultiplier,
    if (attackMultiplier != 1.0) 'attackMultiplier': attackMultiplier,
    if (rangeMultiplier != 1.0) 'rangeMultiplier': rangeMultiplier,
  };
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

  /// JSON → HeroData
  factory HeroData.fromJson(Map<String, dynamic> json) {
    return HeroData(
      id: HeroId.values.firstWhere((e) => e.name == json['id']),
      name: json['name'] as String,
      title: json['title'] as String,
      backstory: json['backstory'] as String,
      baseHp: (json['baseHp'] as num).toDouble(),
      baseAttack: (json['baseAttack'] as num).toDouble(),
      baseSpeed: (json['baseSpeed'] as num).toDouble(),
      baseRange: (json['baseRange'] as num).toDouble(),
      damageType: DamageType.values.firstWhere((e) => e.name == json['damageType']),
      skill: HeroSkillData.fromJson(json['skill'] as Map<String, dynamic>),
      evolutions: (json['evolutions'] as List<dynamic>)
          .map((e) => HeroEvolutionData.fromJson(e as Map<String, dynamic>))
          .toList(),
      barks: (json['barks'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)) ?? {},
    );
  }

  /// HeroData → JSON
  Map<String, dynamic> toJson() => {
    'id': id.name,
    'name': name,
    'title': title,
    'backstory': backstory,
    'baseHp': baseHp,
    'baseAttack': baseAttack,
    'baseSpeed': baseSpeed,
    'baseRange': baseRange,
    'damageType': damageType.name,
    'skill': skill.toJson(),
    'evolutions': evolutions.map((e) => e.toJson()).toList(),
    if (barks.isNotEmpty) 'barks': barks,
  };
}
