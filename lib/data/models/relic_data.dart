// 해원의 문 — 유물(Relic) 데이터 모델
// GDD §5.5 기반: 6종 유물 + 효과 + 강화 시스템 (골드 싱크)

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

/// 유물 강화 비용 테이블 (레벨 → 골드)
const List<int> relicUpgradeCosts = [
  0,       // Lv0→1 (해금 시 Lv1)
  2000,    // Lv1→2
  5000,    // Lv2→3
  10000,   // Lv3→4
  20000,   // Lv4→5 (최대)
];

/// 유물 강화 성공률 (레벨 → 확률 %)
const List<int> relicUpgradeSuccessRate = [
  100,  // Lv1→2: 100%
  100,  // Lv2→3: 100%
  90,   // Lv3→4: 90%
  70,   // Lv4→5: 70% — 긴장감!
];

/// 유물 최대 레벨
const int relicMaxLevel = 5;

/// 유물 데이터
class RelicData {
  final RelicId id;
  final String name;
  final String nameKo;
  final String description;
  final RelicEffectType effectType;
  final double effectValue; // 0.2 = 20% (Lv1 기본값)
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

  /// 레벨에 따른 실제 효과 값
  /// Lv1=기본, Lv2=1.25배, Lv3=1.5배, Lv4=1.75배, Lv5=2.0배
  double effectAtLevel(int level) {
    final clampedLv = level.clamp(1, relicMaxLevel);
    return effectValue * (1.0 + 0.25 * (clampedLv - 1));
  }

  /// 특정 레벨의 효과 설명 (UI용)
  String effectDescriptionAtLevel(int level) {
    final pct = (effectAtLevel(level) * 100).toStringAsFixed(0);
    return switch (effectType) {
      RelicEffectType.rangeBonus => '사거리 +$pct%',
      RelicEffectType.cooldownReduction => '쿨타임 -$pct%',
      RelicEffectType.defenseBonus => 'HP/방어력 +$pct%',
      RelicEffectType.sinmyeongBonus => '신명 +$pct%',
      RelicEffectType.magicDamageBonus => '마법 데미지 +$pct%',
      RelicEffectType.criticalChance => '크리티컬 $pct%',
    };
  }

  /// 다음 레벨 강화 비용 (골드). 최대 레벨이면 -1
  int upgradeCost(int currentLevel) {
    if (currentLevel >= relicMaxLevel) return -1;
    return relicUpgradeCosts[currentLevel];
  }

  /// 다음 레벨 강화 성공률 (%). 최대 레벨이면 0
  int upgradeSuccessRate(int currentLevel) {
    if (currentLevel >= relicMaxLevel) return 0;
    final idx = currentLevel - 1;
    if (idx < 0 || idx >= relicUpgradeSuccessRate.length) return 100;
    return relicUpgradeSuccessRate[idx];
  }
}

/// GDD §5.5 기반 전체 유물 데이터
const Map<RelicId, RelicData> allRelics = {
  RelicId.gat: RelicData(
    id: RelicId.gat,
    name: 'Gat',
    nameKo: '갓',
    description: '원거리 타워/영웅의 사거리가 증가합니다.',
    effectType: RelicEffectType.rangeBonus,
    effectValue: 0.2,
    unlockCondition: '챕터 2 클리어',
    iconEmoji: '🎩',
  ),
  RelicId.norigae: RelicData(
    id: RelicId.norigae,
    name: 'Norigae',
    nameKo: '노리개',
    description: '스킬 쿨타임이 감소합니다.',
    effectType: RelicEffectType.cooldownReduction,
    effectValue: 0.15,
    unlockCondition: '도감 수집 50%',
    iconEmoji: '📿',
  ),
  RelicId.hopae: RelicData(
    id: RelicId.hopae,
    name: 'Hopae',
    nameKo: '호패',
    description: 'HP와 방어력이 증가합니다.',
    effectType: RelicEffectType.defenseBonus,
    effectValue: 0.2,
    unlockCondition: '챕터 1 전 스테이지 3성',
    iconEmoji: '🛡️',
  ),
  RelicId.yeobgeomgeom: RelicData(
    id: RelicId.yeobgeomgeom,
    name: 'Yeobgeomgeom',
    nameKo: '엽전검',
    description: '적 처치 시 신명이 추가됩니다.',
    effectType: RelicEffectType.sinmyeongBonus,
    effectValue: 0.3,
    unlockCondition: '챕터 3 클리어',
    iconEmoji: '⚔️',
  ),
  RelicId.bujeokham: RelicData(
    id: RelicId.bujeokham,
    name: 'Bujeokham',
    nameKo: '부적함',
    description: '마법 데미지가 증가합니다.',
    effectType: RelicEffectType.magicDamageBonus,
    effectValue: 0.25,
    unlockCondition: '만신전 타워 10회 건설',
    iconEmoji: '📜',
  ),
  RelicId.goblinMallet: RelicData(
    id: RelicId.goblinMallet,
    name: 'Goblin Mallet',
    nameKo: '도깨비 방망이',
    description: '공격 시 일정 확률로 2배 데미지를 줍니다.',
    effectType: RelicEffectType.criticalChance,
    effectValue: 0.1,
    unlockCondition: '깨비 Lv 10 달성',
    iconEmoji: '🔨',
  ),
};
