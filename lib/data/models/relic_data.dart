// 해원의 문 — 유물(Relic) 데이터 모델
// GDD §5.5 기반: 6종 유물 + 효과

/// 유물 고유 ID
enum RelicId {
  /// 갓 — 원거리 사거리 +20%
  gat,

  /// 노리개 — 스킬 쿨타임 -15%
  norigae,

  /// 호패 — HP/방어력 +20%
  hopae,

  /// 엽전검 — 적 처치 시 신명 +30%
  yeobgeomgeom,

  /// 부적함 — 마법 데미지 +25%
  bujeokham,

  /// 도깨비 방망이 — 10% 확률 2배 데미지
  goblinMallet,
}

/// 유물 효과 종류
enum RelicEffectType {
  /// 사거리 증가 %
  rangeBonus,

  /// 쿨다운 감소 %
  cooldownReduction,

  /// HP/방어력 증가 %
  defenseBonus,

  /// 적 처치 시 신명 추가 %
  sinmyeongBonus,

  /// 마법 데미지 증가 %
  magicDamageBonus,

  /// 크리티컬 확률 (고정 %)
  criticalChance,
}

/// 유물 데이터
class RelicData {
  final RelicId id;
  final String name;
  final String nameKo;
  final String description;
  final RelicEffectType effectType;
  final double effectValue; // 0.2 = 20%
  final String unlockCondition;
  final String iconEmoji;

  const RelicData({
    required this.id,
    required this.name,
    required this.nameKo,
    required this.description,
    required this.effectType,
    required this.effectValue,
    required this.unlockCondition,
    required this.iconEmoji,
  });
}

/// GDD §5.5 기반 전체 유물 데이터
const Map<RelicId, RelicData> allRelics = {
  RelicId.gat: RelicData(
    id: RelicId.gat,
    name: 'Gat',
    nameKo: '갓',
    description: '원거리 타워/영웅의 사거리가 20% 증가합니다.',
    effectType: RelicEffectType.rangeBonus,
    effectValue: 0.2,
    unlockCondition: '챕터 2 클리어',
    iconEmoji: '🎩',
  ),
  RelicId.norigae: RelicData(
    id: RelicId.norigae,
    name: 'Norigae',
    nameKo: '노리개',
    description: '스킬 쿨타임이 15% 감소합니다.',
    effectType: RelicEffectType.cooldownReduction,
    effectValue: 0.15,
    unlockCondition: '도감 수집 50%',
    iconEmoji: '📿',
  ),
  RelicId.hopae: RelicData(
    id: RelicId.hopae,
    name: 'Hopae',
    nameKo: '호패',
    description: 'HP와 방어력이 20% 증가합니다.',
    effectType: RelicEffectType.defenseBonus,
    effectValue: 0.2,
    unlockCondition: '챕터 1 전 스테이지 3성',
    iconEmoji: '🛡️',
  ),
  RelicId.yeobgeomgeom: RelicData(
    id: RelicId.yeobgeomgeom,
    name: 'Yeobgeomgeom',
    nameKo: '엽전검',
    description: '적 처치 시 신명이 30% 추가됩니다.',
    effectType: RelicEffectType.sinmyeongBonus,
    effectValue: 0.3,
    unlockCondition: '챕터 3 클리어',
    iconEmoji: '⚔️',
  ),
  RelicId.bujeokham: RelicData(
    id: RelicId.bujeokham,
    name: 'Bujeokham',
    nameKo: '부적함',
    description: '마법 데미지가 25% 증가합니다.',
    effectType: RelicEffectType.magicDamageBonus,
    effectValue: 0.25,
    unlockCondition: '만신전 타워 10회 건설',
    iconEmoji: '📜',
  ),
  RelicId.goblinMallet: RelicData(
    id: RelicId.goblinMallet,
    name: 'Goblin Mallet',
    nameKo: '도깨비 방망이',
    description: '공격 시 10% 확률로 2배 데미지를 줍니다.',
    effectType: RelicEffectType.criticalChance,
    effectValue: 0.1,
    unlockCondition: '깨비 Lv 10 달성',
    iconEmoji: '🔨',
  ),
};
