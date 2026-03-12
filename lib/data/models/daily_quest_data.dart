// 해원의 문 - 일일 미션 데이터 모델
// 매일 자정 리셋, 날짜 시드 기반 자동 생성
// 시즌 패스 XP 핵심 공급원 (전체의 ~40%)

/// 미션 유형
enum QuestType {
  killEnemies,          // "적 XX마리 처치"
  clearStageStars3,     // "별 3개로 스테이지 클리어"
  buildTowers,          // "타워 X개 건설"
  useHeroSkill,         // "영웅 스킬 X회 사용"
  clearNoDamage,        // "피해 0으로 클리어"
  endlessTowerFloor,    // "무한의 탑 X층 도달"
  spendGold,            // "골드 X 사용"
  upgradeHero,          // "영웅 레벨업 X회"
  equipRelic,           // "유물 장착 변경"
  clearAnyStage,        // "아무 스테이지 1회 클리어"
  watchAd,              // "광고 시청(수익화) X회" [M1 뉴!]
  readLore,             // "도감에서 몬스터 정보 열람" [M2 뉴!]
  killBoss,             // "보스 몬스터 X마리 처치" [M3 뉴!]
}

extension QuestTypeExt on QuestType {
  String get emoji => switch (this) {
    QuestType.killEnemies       => '⚔️',
    QuestType.clearStageStars3  => '⭐',
    QuestType.buildTowers       => '🏰',
    QuestType.useHeroSkill      => '🔥',
    QuestType.clearNoDamage     => '🛡️',
    QuestType.endlessTowerFloor => '🗼',
    QuestType.spendGold         => '🪙',
    QuestType.upgradeHero       => '📈',
    QuestType.equipRelic        => '🏺',
    QuestType.clearAnyStage     => '🎮',
    QuestType.watchAd           => '📺',
    QuestType.readLore          => '📖',
    QuestType.killBoss          => '👹',
  };

  /// 미션 수행을 위한 바로가기 라우트 경로 힌트
  String? get routePath => switch (this) {
    QuestType.killEnemies       => '/stage_select',
    QuestType.clearStageStars3  => '/stage_select',
    QuestType.clearAnyStage     => '/stage_select',
    QuestType.clearNoDamage     => '/stage_select',
    QuestType.killBoss          => '/stage_select',
    QuestType.buildTowers       => '/tower_manage',
    QuestType.spendGold         => '/tower_manage', // 로비나 상점 등으로도 가능
    QuestType.upgradeHero       => '/hero_manage',
    QuestType.useHeroSkill      => '/hero_manage',
    QuestType.equipRelic        => '/hero_manage',
    QuestType.endlessTowerFloor => '/endless_tower',
    QuestType.readLore          => '/lore_collection',
    QuestType.watchAd           => null, // 상단 젬 버튼 등, 별도 UI 처리 고려
  };
}

/// 일일 미션 데이터
class DailyQuest {
  final String id;
  final QuestType type;
  final String description;
  final int targetValue;
  final int rewardPassXp;    // 시즌 패스 XP (핵심!)
  final int rewardGold;
  final int rewardGems;

  const DailyQuest({
    required this.id,
    required this.type,
    required this.description,
    required this.targetValue,
    this.rewardPassXp = 20,
    this.rewardGold = 300,
    this.rewardGems = 0,
  });
}

/// 연속 출석 보너스 (7일 주기)
class LoginStreakReward {
  final int day;              // 1~7
  final int gems;
  final int gold;
  final int summonTickets;
  final String displayName;
  final String emoji;

  const LoginStreakReward({
    required this.day,
    this.gems = 0,
    this.gold = 0,
    this.summonTickets = 0,
    required this.displayName,
    required this.emoji,
  });
}

/// 7일 연속 출석 보상 테이블
const List<LoginStreakReward> loginStreakRewards = [
  LoginStreakReward(day: 1, gold: 500,   displayName: '골드 500',         emoji: '🪙'),
  LoginStreakReward(day: 2, gold: 800,   displayName: '골드 800',         emoji: '🪙'),
  LoginStreakReward(day: 3, gems: 3,     displayName: '보석 3개',         emoji: '💎'),
  LoginStreakReward(day: 4, gold: 1200,  displayName: '골드 1,200',       emoji: '🪙'),
  LoginStreakReward(day: 5, summonTickets: 1, displayName: '소환권 1장',  emoji: '🎫'),
  LoginStreakReward(day: 6, gems: 5,     displayName: '보석 5개',         emoji: '💎'),
  LoginStreakReward(day: 7, gems: 10, summonTickets: 1, displayName: '보석 10 + 소환권', emoji: '🎁'),
];

/// 월간 출석 보상 (28일, 7/14/21/28일 특별 보너스)
class MonthlyLoginReward {
  final int day;              // 1~28
  final int gems;
  final int gold;
  final int summonTickets;
  final int passXp;
  final String displayName;
  final String emoji;
  final bool isSpecial;       // 7/14/21/28일 특별 보너스

  const MonthlyLoginReward({
    required this.day,
    this.gems = 0,
    this.gold = 0,
    this.summonTickets = 0,
    this.passXp = 0,
    required this.displayName,
    required this.emoji,
    this.isSpecial = false,
  });
}

/// 28일 월간 출석 보상 테이블
const List<MonthlyLoginReward> monthlyLoginRewards = [
  MonthlyLoginReward(day: 1,  gold: 500,  displayName: '골드 500',  emoji: '🪙'),
  MonthlyLoginReward(day: 2,  gold: 600,  displayName: '골드 600',  emoji: '🪙'),
  MonthlyLoginReward(day: 3,  gold: 700,  displayName: '골드 700',  emoji: '🪙'),
  MonthlyLoginReward(day: 4,  gold: 800,  displayName: '골드 800',  emoji: '🪙'),
  MonthlyLoginReward(day: 5,  gold: 900,  displayName: '골드 900',  emoji: '🪙'),
  MonthlyLoginReward(day: 6,  gold: 1000, displayName: '골드 1,000', emoji: '🪙'),
  MonthlyLoginReward(day: 7,  gems: 30, summonTickets: 1, displayName: '🌟 보석 30 + 소환권', emoji: '🎁', isSpecial: true),
  MonthlyLoginReward(day: 8,  gold: 1000, displayName: '골드 1,000', emoji: '🪙'),
  MonthlyLoginReward(day: 9,  gold: 1100, displayName: '골드 1,100', emoji: '🪙'),
  MonthlyLoginReward(day: 10, gold: 1200, displayName: '골드 1,200', emoji: '🪙'),
  MonthlyLoginReward(day: 11, gold: 1300, displayName: '골드 1,300', emoji: '🪙'),
  MonthlyLoginReward(day: 12, gold: 1400, displayName: '골드 1,400', emoji: '🪙'),
  MonthlyLoginReward(day: 13, gold: 1500, displayName: '골드 1,500', emoji: '🪙'),
  MonthlyLoginReward(day: 14, gems: 50, passXp: 200, displayName: '🌟 보석 50 + 패스XP 200', emoji: '🎁', isSpecial: true),
  MonthlyLoginReward(day: 15, gold: 1500, displayName: '골드 1,500', emoji: '🪙'),
  MonthlyLoginReward(day: 16, gold: 1600, displayName: '골드 1,600', emoji: '🪙'),
  MonthlyLoginReward(day: 17, gold: 1700, displayName: '골드 1,700', emoji: '🪙'),
  MonthlyLoginReward(day: 18, gold: 1800, displayName: '골드 1,800', emoji: '🪙'),
  MonthlyLoginReward(day: 19, gold: 1900, displayName: '골드 1,900', emoji: '🪙'),
  MonthlyLoginReward(day: 20, gold: 2000, displayName: '골드 2,000', emoji: '🪙'),
  MonthlyLoginReward(day: 21, gems: 80, summonTickets: 2, displayName: '🌟 보석 80 + 소환권 2장', emoji: '🎁', isSpecial: true),
  MonthlyLoginReward(day: 22, gold: 2000, displayName: '골드 2,000', emoji: '🪙'),
  MonthlyLoginReward(day: 23, gold: 2100, displayName: '골드 2,100', emoji: '🪙'),
  MonthlyLoginReward(day: 24, gold: 2200, displayName: '골드 2,200', emoji: '🪙'),
  MonthlyLoginReward(day: 25, gold: 2300, displayName: '골드 2,300', emoji: '🪙'),
  MonthlyLoginReward(day: 26, gold: 2400, displayName: '골드 2,400', emoji: '🪙'),
  MonthlyLoginReward(day: 27, gold: 2500, displayName: '골드 2,500', emoji: '🪙'),
  MonthlyLoginReward(day: 28, gems: 150, summonTickets: 3, passXp: 500, displayName: '🌟 보석 150 + 소환권 3장 + XP 500', emoji: '👑', isSpecial: true),
];

/// 일일 미션 풀 (여기서 랜덤 3 + 보너스 1을 뽑음)
const List<DailyQuest> _questPool = [
  // ── 쉬운 미션 (필수 포함 가능) ──
  DailyQuest(id: 'q_kill_30',    type: QuestType.killEnemies,      description: '적 30마리 처치',        targetValue: 30,  rewardPassXp: 20, rewardGold: 300),
  DailyQuest(id: 'q_kill_60',    type: QuestType.killEnemies,      description: '적 60마리 처치',        targetValue: 60,  rewardPassXp: 25, rewardGold: 500),
  DailyQuest(id: 'q_clear_1',    type: QuestType.clearAnyStage,    description: '스테이지 1회 클리어',    targetValue: 1,   rewardPassXp: 15, rewardGold: 200),
  DailyQuest(id: 'q_clear_3',    type: QuestType.clearAnyStage,    description: '스테이지 3회 클리어',    targetValue: 3,   rewardPassXp: 25, rewardGold: 500),
  DailyQuest(id: 'q_build_5',    type: QuestType.buildTowers,      description: '타워 5개 건설',          targetValue: 5,   rewardPassXp: 15, rewardGold: 200),
  DailyQuest(id: 'q_build_10',   type: QuestType.buildTowers,      description: '타워 10개 건설',         targetValue: 10,  rewardPassXp: 20, rewardGold: 400),
  DailyQuest(id: 'q_skill_3',    type: QuestType.useHeroSkill,     description: '영웅 스킬 3회 사용',     targetValue: 3,   rewardPassXp: 15, rewardGold: 200),
  DailyQuest(id: 'q_skill_5',    type: QuestType.useHeroSkill,     description: '영웅 스킬 5회 사용',     targetValue: 5,   rewardPassXp: 20, rewardGold: 400),
  DailyQuest(id: 'q_gold_2000',  type: QuestType.spendGold,        description: '골드 2,000 사용',        targetValue: 2000, rewardPassXp: 15, rewardGold: 500),
  DailyQuest(id: 'q_hero_lv',    type: QuestType.upgradeHero,      description: '영웅 레벨업 1회',        targetValue: 1,   rewardPassXp: 20, rewardGold: 300),
  DailyQuest(id: 'q_watch_ad',   type: QuestType.watchAd,          description: '무료 보석 광고 시청',    targetValue: 1,   rewardPassXp: 30, rewardGems: 1), // 신규 추가

  // ── 중간 난이도 ──
  DailyQuest(id: 'q_star3_1',    type: QuestType.clearStageStars3, description: '별 3개로 클리어 1회',    targetValue: 1,   rewardPassXp: 25, rewardGold: 500, rewardGems: 1),
  DailyQuest(id: 'q_star3_2',    type: QuestType.clearStageStars3, description: '별 3개로 클리어 2회',    targetValue: 2,   rewardPassXp: 30, rewardGold: 700, rewardGems: 2),
  DailyQuest(id: 'q_relic',      type: QuestType.equipRelic,       description: '유물 장착 변경',         targetValue: 1,   rewardPassXp: 15, rewardGold: 300),
  DailyQuest(id: 'q_tower_f3',   type: QuestType.endlessTowerFloor,description: '무한의 탑 3층 도달',     targetValue: 3,   rewardPassXp: 25, rewardGold: 500, rewardGems: 1),
  DailyQuest(id: 'q_read_lore',  type: QuestType.readLore,         description: '도감에서 정보 읽기',     targetValue: 1,   rewardPassXp: 15, rewardGold: 200), // 신규 추가
  DailyQuest(id: 'q_kill_boss1', type: QuestType.killBoss,         description: '보스 몬스터 1마리 처치',   targetValue: 1,   rewardPassXp: 30, rewardGold: 500, rewardGems: 1), // 신규 추가

  // ── 어려운 미션 (보너스 전용) ──
  DailyQuest(id: 'q_nodmg',      type: QuestType.clearNoDamage,    description: '피해 0으로 스테이지 클리어', targetValue: 1, rewardPassXp: 40, rewardGold: 1000, rewardGems: 3),
  DailyQuest(id: 'q_kill_100',   type: QuestType.killEnemies,      description: '적 100마리 처치',        targetValue: 100, rewardPassXp: 35, rewardGold: 800, rewardGems: 2),
  DailyQuest(id: 'q_tower_f5',   type: QuestType.endlessTowerFloor,description: '무한의 탑 5층 도달',     targetValue: 5,   rewardPassXp: 35, rewardGold: 800, rewardGems: 2),
  DailyQuest(id: 'q_kill_boss3', type: QuestType.killBoss,         description: '보스 몬스터 3마리 처치',   targetValue: 3,   rewardPassXp: 45, rewardGold: 1200, rewardGems: 2), // 신규 추가
];

/// 올클리어 보너스 보상 (8개 전부 완료 시)
const int allClearBonusGems = 8;
const int allClearBonusPassXp = 50;
const int allClearBonusGold = 1500;

/// 일일 미션 생성기
class DailyQuestGenerator {
  DailyQuestGenerator._();

  /// 날짜 → 시드
  static int _dateToSeed(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// 시드 기반 의사 난수 (결정론적)
  static int _seededRandom(int seed, int index) {
    var v = seed + index * 7919;
    v = (v * 1103515245 + 12345) & 0x7FFFFFFF;
    return v;
  }

  /// 쉬운 풀에서 N개 뽑기 (타입 중복 방지)
  static void _pickFromPool(
    List<DailyQuest> pool,
    int count,
    int seed,
    int seedOffset,
    List<DailyQuest> result,
    Set<QuestType> usedTypes,
  ) {
    for (int n = 0; n < count; n++) {
      final startIdx = _seededRandom(seed, seedOffset + n) % pool.length;
      for (int i = 0; i < pool.length; i++) {
        final candidate = pool[(startIdx + i) % pool.length];
        if (!usedTypes.contains(candidate.type)) {
          result.add(candidate);
          usedTypes.add(candidate.type);
          break;
        }
      }
    }
  }

  /// 오늘의 미션 8개 생성 (쉬운4 + 중간2 + 어려운2)
  static List<DailyQuest> generateForDate(DateTime date) {
    final seed = _dateToSeed(date);

    // 쉬운 미션 풀 (인덱스 0~10)
    final easyPool = _questPool.sublist(0, 11);
    // 중간 미션 풀 (인덱스 11~16)
    final mediumPool = _questPool.sublist(11, 17);
    // 어려운 미션 풀 (인덱스 17~20)
    final hardPool = _questPool.sublist(17);

    final result = <DailyQuest>[];
    final usedTypes = <QuestType>{};

    // 쉬운 미션 4개
    _pickFromPool(easyPool, 4, seed, 0, result, usedTypes);

    // 중간 미션 2개
    _pickFromPool(mediumPool, 2, seed, 10, result, usedTypes);

    // 어려운(보너스) 미션 2개
    _pickFromPool(hardPool, 2, seed, 20, result, usedTypes);

    // 최소 8개 보장 (중복 방지 실패 시 폴백)
    while (result.length < 8) {
      final fallbackIdx = _seededRandom(seed, 30 + result.length) % easyPool.length;
      result.add(easyPool[fallbackIdx]);
    }

    return result;
  }

  /// 오늘의 미션
  static List<DailyQuest> get today => generateForDate(DateTime.now());
}
