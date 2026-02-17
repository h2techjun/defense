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

  /// 원혼 수집 가능 시간 (초)
  static const double spiritCollectTimeout = 5.0;

  /// 원혼 수집 시 신명 획득량
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
  static const double waveCooldown = 10.0;

  /// 적 스폰 간격 (초)
  static const double defaultSpawnInterval = 1.2;
}

/// 데미지 계산 유틸리티
class DamageCalculator {
  DamageCalculator._();

  /// 속성 상성에 따른 최종 데미지 계산
  static double calculate({
    required double baseDamage,
    required DamageType damageType,
    required ArmorType armorType,
    bool isNight = false,
  }) {
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

    return baseDamage * multiplier;
  }
}

