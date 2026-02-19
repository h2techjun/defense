// 해원의 문 - 게임 밸런스 상수
// 모든 게임 밸런스 수치를 중앙에서 관리합니다.

import 'enums.dart';

/// 게임 밸런스 상수
class GameConstants {
  GameConstants._();

  // ── 화면/맵 ──
  static const double tileSize = 64.0;
  static const int mapColumns = 15;
  static const int mapRows = 9;
  static const double gameWidth = tileSize * mapColumns; // 960
  static const double gameHeight = tileSize * mapRows; // 576

  // ── 낮/밤 사이클 ──
  /// 낮 지속 시간 (초)
  static const double dayDuration = 60.0;

  /// 밤 지속 시간 (초)
  static const double nightDuration = 45.0;

  /// 밤에 영혼형 적 회피율 보너스
  static const double nightEvasionBonus = 0.5;

  /// 밤에 타워 범위 감소 비율
  static const double nightRangeReduction = 0.3;

  // ── 원한의 순환 ──
  /// 원혼(Spirit) 생성 확률 (0~1)
  static const double spiritSpawnChance = 0.6;

  /// 원혼 부유 시간 (초) — 스폰 후 떠오르는 시간
  static const double spiritFloatDuration = 0.5;

  /// 원혼 자동 수거 이동 시간 (초)
  static const double spiritMoveToCollectDuration = 0.6;

  /// 원혼 수거 시 신명 획득량
  static const int spiritSinmyeongReward = 15;

  /// 광폭화 공격력 배율
  static const double berserkAttackMultiplier = 1.8;

  /// 광폭화 이동속도 배율
  static const double berserkSpeedMultiplier = 1.5;

  // ── 한(Wailing) 게이지 ──
  /// 적 1마리당 한 게이지 증가량
  static const double wailingPerEnemy = 2.0;

  /// 한 게이지 최대치
  static const double maxWailing = 100.0;

  /// 한 100% 시 타워 공격속도 감소 비율
  static const double wailingAttackSpeedPenalty = 0.4;

  /// 한 게이지 자연 감소 속도 (초당)
  static const double wailingDecayPerSecond = 0.5;

  // ── 자원 ──
  /// 시작 신명 (자원)
  static const int startingSinmyeong = 200;

  /// 게이트웨이(해원문) 최대 HP
  static const int gatewayMaxHp = 20;

  // ── 타워 비용 ──
  static const int archerTowerCost = 70;
  static const int barracksTowerCost = 90;
  static const int shamanTowerCost = 100;
  static const int artilleryTowerCost = 125;
  static const int sotdaeTowerCost = 80;

  // ── 타워 업그레이드 비용 배율 ──
  static const double upgradeCostMultiplier = 1.5;

  // ── 속성 상성 데미지 배율 ──
  /// 물리 공격 → 영혼형 적 (50% 회피)
  static const double physicalVsSpiritualMultiplier = 0.5;

  /// 마법 공격 → 물리형 적 (약간 불리)
  static const double magicalVsPhysicalMultiplier = 0.7;

  /// 정화 공격 → 영혼형 적 (보너스)
  static const double purificationVsSpiritualMultiplier = 2.0;

  /// 요괴형 적 기본 감소율
  static const double yokaiDamageReduction = 0.8;

  // ── 영웅 ──
  /// 영웅 스킬 기본 쿨타임 (초)
  static const double defaultSkillCooldown = 15.0;

  /// 영웅 진화 레벨 임계값
  static const List<int> evolutionLevels = [1, 5, 10];

  // ── 웨이브 ──
  /// 웨이브 간 대기 시간 (초)
  static const double waveCooldown = 5.0;

  /// 적 스폰 간격 (초)
  static const double defaultSpawnInterval = 1.2;

  // ── 솟대 (Sotdae) — 수호결계 타워 ──
  /// 솟대 수호결계 범위
  static const double sotdaeWardRange = 150.0;

  /// 솟대 수호결계 갱신 간격 (초)
  static const double sotdaeWardInterval = 1.0;

  /// 솟대 디버프 내성 (레벨별: 50%, 70%, 90%)
  static const List<double> sotdaeDebuffResist = [0.5, 0.7, 0.9];

  /// 솟대 한(恨) 증가량 감소율
  static const double sotdaeWailingReduction = 0.3;

  /// 솟대 아군 버프 범위
  static const double sotdaeBuffRange = 120.0;

  /// 솟대 아군 공격속도 버프 배율
  static const double sotdaeAttackSpeedBuff = 1.15;

  // ── 화포 (Artillery) ──
  /// 화포 스플래시 범위
  static const double artillerySplashRadius = 80.0;

  /// 화포 스플래시 데미지 비율 (중심 대비)
  static const double artillerySplashDamageRatio = 0.5;

  // ── 타워 판매 ──
  /// 타워 판매 시 환불 비율
  static const double towerSellRefundRatio = 0.75;
}

/// 데미지 계산 유틸리티
class DamageCalculator {
  DamageCalculator._();

  /// 해당 타워 타입이 비행 적을 공격할 수 있는지 판정
  static bool canTarget({
    required TowerType towerType,
    required bool isFlying,
  }) {
    // 병영(근접)은 비행 유닛 공격 불가
    if (isFlying && towerType == TowerType.barracks) return false;
    return true;
  }

  /// 속성 상성에 따른 최종 데미지 계산
  static double calculate({
    required double baseDamage,
    required DamageType damageType,
    required ArmorType armorType,
    bool isNight = false,
    bool isFlying = false,
    bool hasPiercing = false,
  }) {
    // 관통: 상성 무시, 순수 데미지
    if (hasPiercing) return baseDamage;

    double multiplier = 1.0;

    switch (damageType) {
      case DamageType.physical:
        if (armorType == ArmorType.spiritual) {
          multiplier = GameConstants.physicalVsSpiritualMultiplier;
        }
        break;
      case DamageType.magical:
        if (armorType == ArmorType.physical) {
          multiplier = GameConstants.magicalVsPhysicalMultiplier;
        }
        // 마법 데미지는 비행 유닛에게 +20% 보너스
        if (isFlying) multiplier *= 1.2;
        break;
      case DamageType.purification:
        if (armorType == ArmorType.spiritual) {
          multiplier = GameConstants.purificationVsSpiritualMultiplier;
        }
        break;
    }

    // 요괴형은 기본 데미지 감소
    if (armorType == ArmorType.yokai) {
      multiplier *= GameConstants.yokaiDamageReduction;
    }

    // 밤 시간 적 방어 보너스 (물리 -10%)
    if (isNight && damageType == DamageType.physical) {
      multiplier *= 0.9;
    }

    return baseDamage * multiplier;
  }
}

