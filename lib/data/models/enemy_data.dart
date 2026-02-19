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

  /// JSON → EnemyAbility
  factory EnemyAbility.fromJson(Map<String, dynamic> json) {
    return EnemyAbility(
      name: json['name'] as String,
      description: json['description'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
    );
  }

  /// EnemyAbility → JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    if (value != 0) 'value': value,
    if (duration != 0) 'duration': duration,
  };
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
  final bool isStealth; // 은신 (영웅만 감지 가능)
  final bool isBoss; // 보스 여부
  final List<EnemyAbility> abilities;

  /// 사망 시 스폰되는 적 ID (2페이즈)
  final EnemyId? deathSpawnId;
  final int deathSpawnCount;

  /// 디버프: 주변 타워 공속 감소 (0이면 없음, 0.3이면 30% 감소)
  final double debuffSlowAura;
  /// 디버프 영향 범위
  final double debuffRange;

  /// 방패: HP 이 비율 이하로 내려가면 방어력 증가
  final double shieldHpRatio;
  /// 방패 활성화 시 받는 데미지 감소율
  final double shieldDamageReduction;

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
    this.isStealth = false,
    this.isBoss = false,
    this.abilities = const [],
    this.deathSpawnId,
    this.deathSpawnCount = 0,
    this.debuffSlowAura = 0,
    this.debuffRange = 0,
    this.shieldHpRatio = 0,
    this.shieldDamageReduction = 0,
  });

  /// JSON → EnemyData
  factory EnemyData.fromJson(Map<String, dynamic> json) {
    return EnemyData(
      id: EnemyId.values.firstWhere((e) => e.name == json['id']),
      name: json['name'] as String,
      description: json['description'] as String,
      chapter: Chapter.values.firstWhere((e) => e.name == json['chapter']),
      hp: (json['hp'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      attack: (json['attack'] as num?)?.toDouble() ?? 0,
      armorType: ArmorType.values.firstWhere((e) => e.name == json['armorType']),
      sinmyeongReward: json['sinmyeongReward'] as int,
      evasion: (json['evasion'] as num?)?.toDouble() ?? 0,
      isFlying: json['isFlying'] as bool? ?? false,
      isStealth: json['isStealth'] as bool? ?? false,
      isBoss: json['isBoss'] as bool? ?? false,
      abilities: (json['abilities'] as List<dynamic>?)
          ?.map((a) => EnemyAbility.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      deathSpawnId: json['deathSpawnId'] != null
          ? EnemyId.values.firstWhere((e) => e.name == json['deathSpawnId'])
          : null,
      deathSpawnCount: json['deathSpawnCount'] as int? ?? 0,
      debuffSlowAura: (json['debuffSlowAura'] as num?)?.toDouble() ?? 0,
      debuffRange: (json['debuffRange'] as num?)?.toDouble() ?? 0,
      shieldHpRatio: (json['shieldHpRatio'] as num?)?.toDouble() ?? 0,
      shieldDamageReduction: (json['shieldDamageReduction'] as num?)?.toDouble() ?? 0,
    );
  }

  /// EnemyData → JSON
  Map<String, dynamic> toJson() => {
    'id': id.name,
    'name': name,
    'description': description,
    'chapter': chapter.name,
    'hp': hp,
    'speed': speed,
    if (attack != 0) 'attack': attack,
    'armorType': armorType.name,
    'sinmyeongReward': sinmyeongReward,
    if (evasion != 0) 'evasion': evasion,
    if (isFlying) 'isFlying': true,
    if (isStealth) 'isStealth': true,
    if (isBoss) 'isBoss': true,
    if (abilities.isNotEmpty) 'abilities': abilities.map((a) => a.toJson()).toList(),
    if (deathSpawnId != null) 'deathSpawnId': deathSpawnId!.name,
    if (deathSpawnCount != 0) 'deathSpawnCount': deathSpawnCount,
    if (debuffSlowAura != 0) 'debuffSlowAura': debuffSlowAura,
    if (debuffRange != 0) 'debuffRange': debuffRange,
    if (shieldHpRatio != 0) 'shieldHpRatio': shieldHpRatio,
    if (shieldDamageReduction != 0) 'shieldDamageReduction': shieldDamageReduction,
  };
}
