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

/// 올클리어 보너스 보상
const int allClearBonusGems = 5;
const int allClearBonusPassXp = 30;
const int allClearBonusGold = 1000;

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

  /// 오늘의 미션 3개 + 보너스 1개 생성
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

    // 미션 1: 쉬운 미션에서 1개
    final easy1Idx = _seededRandom(seed, 0) % easyPool.length;
    result.add(easyPool[easy1Idx]);
    usedTypes.add(easyPool[easy1Idx].type);

    // 미션 2: 쉬운 미션에서 1개 (중복 타입 방지)
    var easy2Idx = _seededRandom(seed, 1) % easyPool.length;
    for (int i = 0; i < easyPool.length; i++) {
      final candidate = easyPool[(easy2Idx + i) % easyPool.length];
      if (!usedTypes.contains(candidate.type)) {
        result.add(candidate);
        usedTypes.add(candidate.type);
        break;
      }
    }

    // 미션 3: 중간 미션에서 1개
    final med1Idx = _seededRandom(seed, 2) % mediumPool.length;
    for (int i = 0; i < mediumPool.length; i++) {
      final candidate = mediumPool[(med1Idx + i) % mediumPool.length];
      if (!usedTypes.contains(candidate.type)) {
        result.add(candidate);
        usedTypes.add(candidate.type);
        break;
      }
    }

    // 보너스 미션: 어려운 미션에서 1개
    final hardIdx = _seededRandom(seed, 3) % hardPool.length;
    result.add(hardPool[hardIdx]);

    // 최소 4개 보장 (중복 방지 실패 시 폴백)
    while (result.length < 4) {
      result.add(easyPool[_seededRandom(seed, 10 + result.length) % easyPool.length]);
    }

    return result;
  }

  /// 오늘의 미션
  static List<DailyQuest> get today => generateForDate(DateTime.now());
}
