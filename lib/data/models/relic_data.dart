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
      RelicEffectType.rangeBonus => 'relic_eff_range',
      RelicEffectType.cooldownReduction => 'relic_eff_cooldown',
      RelicEffectType.defenseBonus => 'relic_eff_defense',
      RelicEffectType.sinmyeongBonus => 'relic_eff_sinmyeong',
      RelicEffectType.magicDamageBonus => 'relic_eff_magic',
      RelicEffectType.criticalChance => 'relic_eff_critical',
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
    nameKo: 'relic_gat_name',
    description: 'relic_gat_desc',
    effectType: RelicEffectType.rangeBonus,
    effectValue: 0.2,
    unlockCondition: 'relic_gat_unlock',
    iconEmoji: '🎩',
  ),
  RelicId.norigae: RelicData(
    id: RelicId.norigae,
    name: 'Norigae',
    nameKo: 'relic_norigae_name',
    description: 'relic_norigae_desc',
    effectType: RelicEffectType.cooldownReduction,
    effectValue: 0.15,
    unlockCondition: 'relic_norigae_unlock',
    iconEmoji: '📿',
  ),
  RelicId.hopae: RelicData(
    id: RelicId.hopae,
    name: 'Hopae',
    nameKo: 'relic_hopae_name',
    description: 'relic_hopae_desc',
    effectType: RelicEffectType.defenseBonus,
    effectValue: 0.2,
    unlockCondition: 'relic_hopae_unlock',
    iconEmoji: '🛡️',
  ),
  RelicId.yeobgeomgeom: RelicData(
    id: RelicId.yeobgeomgeom,
    name: 'Yeobgeomgeom',
    nameKo: 'relic_yeob_name',
    description: 'relic_yeob_desc',
    effectType: RelicEffectType.sinmyeongBonus,
    effectValue: 0.3,
    unlockCondition: 'relic_yeob_unlock',
    iconEmoji: '⚔️',
  ),
  RelicId.bujeokham: RelicData(
    id: RelicId.bujeokham,
    name: 'Bujeokham',
    nameKo: 'relic_buje_name',
    description: 'relic_buje_desc',
    effectType: RelicEffectType.magicDamageBonus,
    effectValue: 0.25,
    unlockCondition: 'relic_buje_unlock',
    iconEmoji: '📜',
  ),
  RelicId.goblinMallet: RelicData(
    id: RelicId.goblinMallet,
    name: 'Goblin Mallet',
    nameKo: 'relic_goblin_name',
    description: 'relic_goblin_desc',
    effectType: RelicEffectType.criticalChance,
    effectValue: 0.1,
    unlockCondition: 'relic_goblin_unlock',
    iconEmoji: '🔨',
  ),
};
