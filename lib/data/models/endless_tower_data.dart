// 해원의 문 - 무한의 탑 데이터 모델
// 층(Floor) 기반 무한 스케일링 엔드게임 모드

import '../../common/enums.dart';

/// 층 타입
enum TowerFloorType {
  normal,  // 일반 전투
  elite,   // 엘리트 (강화 적, 추가 보상)
  boss,    // 보스 (10층마다)
  rest,    // 휴식 (보상 선택, 5층마다)
}

/// 무한의 탑 층 데이터
class TowerFloorData {
  final int floor;
  final TowerFloorType type;
  final double difficultyScale;       // 난이도 배율 (1.0 = 기본)
  final List<EnemyId> availableEnemies;
  final EnemyId? bossId;
  final int bonusGems;                // 클리어 보석 보상
  final int bonusExp;                 // 클리어 경험치 보상
  final int waveCount;                // 웨이브 수
  final String floorTitle;            // "3층 - 굶주린 혼령의 길"
  final String? narrative;            // 시작 대사

  const TowerFloorData({
    required this.floor,
    required this.type,
    required this.difficultyScale,
    required this.availableEnemies,
    this.bossId,
    required this.bonusGems,
    required this.bonusExp,
    required this.waveCount,
    required this.floorTitle,
    this.narrative,
  });
}

/// 휴식 층 보상 옵션
enum RestRewardType {
  healGateway,     // 해원문 HP 회복 30%
  extraSinmyeong,  // 추가 신명 +100
  towerDiscount,   // 다음 층 타워 비용 -20%
  heroBoost,       // 영웅 공격력 +15% (3층간 지속)
  gemBonus,        // 즉시 보석 +50
}

/// 휴식 보상 데이터
class RestReward {
  final RestRewardType type;
  final String name;
  final String description;
  final String emoji;

  const RestReward({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
  });
}

/// 휴식 보상 목록
const List<RestReward> allRestRewards = [
  RestReward(
    type: RestRewardType.healGateway,
    name: '해원문 수리',
    description: '해원문 HP 30% 회복',
    emoji: '💚',
  ),
  RestReward(
    type: RestRewardType.extraSinmyeong,
    name: '신명 축적',
    description: '다음 층 시작 신명 +100',
    emoji: '✨',
  ),
  RestReward(
    type: RestRewardType.towerDiscount,
    name: '장인의 축복',
    description: '다음 3층간 타워 비용 -20%',
    emoji: '🔨',
  ),
  RestReward(
    type: RestRewardType.heroBoost,
    name: '영웅 강화',
    description: '다음 3층간 영웅 공격력 +15%',
    emoji: '⚔️',
  ),
  RestReward(
    type: RestRewardType.gemBonus,
    name: '보물 발견',
    description: '즉시 50 보석 획득',
    emoji: '💎',
  ),
];

/// 무한의 탑 층 자동 생성기
class TowerFloorGenerator {
  TowerFloorGenerator._();

  /// 층 번호 → 층 타입 결정 (10층 주기)
  static TowerFloorType getFloorType(int floor) {
    final mod = floor % 10;
    if (mod == 0) return TowerFloorType.boss;    // 10, 20, 30...
    if (mod == 5) return TowerFloorType.rest;     // 5, 15, 25...
    if (mod == 4 || mod == 9) return TowerFloorType.elite; // 4, 9, 14, 19...
    return TowerFloorType.normal;
  }

  /// 층 번호 → 난이도 배율
  static double getDifficultyScale(int floor) {
    // 층 1: 1.0, 층 10: 1.5, 층 20: 2.2, 층 50: 4.0, 층 100: 7.0
    return 1.0 + (floor - 1) * 0.06 + (floor / 20).floor() * 0.2;
  }

  /// 층 번호 → 사용 가능한 적 목록
  static List<EnemyId> getAvailableEnemies(int floor) {
    // 10층마다 새로운 챕터의 적 추가
    final chapter = ((floor - 1) / 10).floor().clamp(0, 4);
    final enemies = <EnemyId>[];

    // 챕터 1 적 (항상 포함)
    enemies.addAll([
      EnemyId.hungryGhost,
      EnemyId.strawShoeSpirit,
      EnemyId.burdenedLaborer,
    ]);

    if (chapter >= 1) {
      enemies.addAll([
        EnemyId.maidenGhost,
        EnemyId.eggGhost,
        EnemyId.tigerSlave,
        EnemyId.fireDog,
      ]);
    }

    if (chapter >= 2) {
      enemies.addAll([
        EnemyId.shadowGolem,
        EnemyId.changGwiEvolved,
        EnemyId.saetani,
        EnemyId.shadowChild,
      ]);
    }

    if (chapter >= 3) {
      enemies.addAll([
        EnemyId.courtAssassin,
        EnemyId.corruptOfficial,
        EnemyId.royalGuardGhost,
        EnemyId.curseScribe,
      ]);
    }

    if (chapter >= 4) {
      enemies.addAll([
        EnemyId.underworldMessenger,
        EnemyId.wailingBanshee,
        EnemyId.boneGolem,
        EnemyId.soulChainGhost,
      ]);
    }

    return enemies;
  }

  /// 보스 층 → 보스 ID
  static EnemyId getBossForFloor(int floor) {
    final bosses = [
      EnemyId.bossOgreLord,        // 10층
      EnemyId.bossMountainLord,    // 20층
      EnemyId.bossGreatEggGhost,   // 30층
      EnemyId.bossTyrantKing,      // 40층
      EnemyId.bossGatekeeper,      // 50층
    ];
    final idx = ((floor ~/ 10) - 1) % bosses.length;
    return bosses[idx];
  }

  /// 보석 보상 계산
  static int getGemReward(int floor, TowerFloorType type) {
    final base = switch (type) {
      TowerFloorType.normal => 5,
      TowerFloorType.elite  => 15,
      TowerFloorType.boss   => 50,
      TowerFloorType.rest   => 0,
    };
    // 층이 높을수록 보상 증가
    return (base * (1 + floor * 0.02)).round();
  }

  /// 경험치 보상 계산
  static int getExpReward(int floor, TowerFloorType type) {
    final base = switch (type) {
      TowerFloorType.normal => 20,
      TowerFloorType.elite  => 40,
      TowerFloorType.boss   => 100,
      TowerFloorType.rest   => 10,
    };
    return (base * (1 + floor * 0.03)).round();
  }

  /// 층 데이터 생성
  static TowerFloorData generateFloor(int floor) {
    final type = getFloorType(floor);
    final scale = getDifficultyScale(floor);
    final enemies = getAvailableEnemies(floor);
    final bossId = type == TowerFloorType.boss ? getBossForFloor(floor) : null;

    final waveCount = switch (type) {
      TowerFloorType.normal => 8 + (floor ~/ 15).clamp(0, 4),
      TowerFloorType.elite  => 10 + (floor ~/ 15).clamp(0, 4),
      TowerFloorType.boss   => 12 + (floor ~/ 20).clamp(0, 3),
      TowerFloorType.rest   => 0,
    };

    final typeEmoji = switch (type) {
      TowerFloorType.normal => '⚔️',
      TowerFloorType.elite  => '🔥',
      TowerFloorType.boss   => '💀',
      TowerFloorType.rest   => '🏕️',
    };

    final typeName = switch (type) {
      TowerFloorType.normal => '전투',
      TowerFloorType.elite  => '엘리트 전투',
      TowerFloorType.boss   => '보스',
      TowerFloorType.rest   => '휴식',
    };

    return TowerFloorData(
      floor: floor,
      type: type,
      difficultyScale: scale,
      availableEnemies: enemies,
      bossId: bossId,
      bonusGems: getGemReward(floor, type),
      bonusExp: getExpReward(floor, type),
      waveCount: waveCount,
      floorTitle: '$typeEmoji $floor층 — $typeName',
      narrative: type == TowerFloorType.boss
          ? '"탑의 주인이 기다리고 있다..."'
          : (type == TowerFloorType.elite
              ? '"강력한 적이 길을 막고 있다."'
              : null),
    );
  }

  /// 여러 층 미리보기 생성 (UI 표시용)
  static List<TowerFloorData> generateFloorRange(int from, int to) {
    return List.generate(
      to - from + 1,
      (i) => generateFloor(from + i),
    );
  }
}
