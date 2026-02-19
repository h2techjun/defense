// 해원의 문 - 일일 도전 데이터 모델
// 날짜 기반 시드로 매일 새로운 도전 자동 생성

import '../../common/enums.dart';
import 'endless_tower_data.dart';

/// 일일 도전 특수 규칙
enum ChallengeModifier {
  nightOnly,       // 밤만 — 모든 웨이브가 밤
  noHeal,          // 힐 불가 — 해원문 회복 차단
  doubleDamage,    // 적 공격력 2배
  limitedTowers,   // 타워 3종만 사용 가능
  speedUp,         // 적 이속 +50%
  eliteOnly,       // 엘리트 적만 등장
  noSotdae,        // 솟대 배치 금지
  poorStart,       // 초기 신명 50%
}

/// modifier 표시 정보
extension ChallengeModifierExt on ChallengeModifier {
  String get displayName => switch (this) {
    ChallengeModifier.nightOnly     => '영원한 밤',
    ChallengeModifier.noHeal        => '회복 불가',
    ChallengeModifier.doubleDamage  => '극한 공격',
    ChallengeModifier.limitedTowers => '제한된 병과',
    ChallengeModifier.speedUp       => '쇄도',
    ChallengeModifier.eliteOnly     => '정예 물결',
    ChallengeModifier.noSotdae      => '금단의 솟대',
    ChallengeModifier.poorStart     => '빈곤한 시작',
  };

  String get description => switch (this) {
    ChallengeModifier.nightOnly     => '모든 웨이브가 밤입니다',
    ChallengeModifier.noHeal        => '해원문 HP 회복이 차단됩니다',
    ChallengeModifier.doubleDamage  => '적 공격력이 2배입니다',
    ChallengeModifier.limitedTowers => '타워 3종만 배치 가능합니다',
    ChallengeModifier.speedUp       => '적 이동 속도가 50% 증가합니다',
    ChallengeModifier.eliteOnly     => '모든 적이 엘리트입니다',
    ChallengeModifier.noSotdae      => '솟대 타워를 배치할 수 없습니다',
    ChallengeModifier.poorStart     => '시작 신명이 절반입니다',
  };

  String get emoji => switch (this) {
    ChallengeModifier.nightOnly     => '🌙',
    ChallengeModifier.noHeal        => '💔',
    ChallengeModifier.doubleDamage  => '💥',
    ChallengeModifier.limitedTowers => '🚫',
    ChallengeModifier.speedUp       => '💨',
    ChallengeModifier.eliteOnly     => '👹',
    ChallengeModifier.noSotdae      => '🚷',
    ChallengeModifier.poorStart     => '🪙',
  };
}

/// 일일 도전 보상
class DailyChallengeReward {
  final int gems;
  final int exp;
  final String title;   // "일일 수호자" 등

  const DailyChallengeReward({
    required this.gems,
    required this.exp,
    required this.title,
  });
}

/// 일일 도전 데이터
class DailyChallengeData {
  final DateTime date;
  final int seed;
  final String title;
  final List<ChallengeModifier> modifiers;
  final int targetWaves;       // 목표 웨이브 수
  final double difficultyScale;
  final List<EnemyId> availableEnemies;
  final EnemyId? bossId;
  final DailyChallengeReward reward;

  const DailyChallengeData({
    required this.date,
    required this.seed,
    required this.title,
    required this.modifiers,
    required this.targetWaves,
    required this.difficultyScale,
    required this.availableEnemies,
    this.bossId,
    required this.reward,
  });
}

/// 일일 도전 생성기
class DailyChallengeGenerator {
  DailyChallengeGenerator._();

  /// 도전 테마 제목들
  static const _titles = [
    '굶주린 밤', '혼령의 행진', '불타는 숲',
    '얼어붙은 전장', '피의 달', '원혼의 물결',
    '저승의 안개', '도깨비불 축제', '만신의 시련',
    '왕궁의 그림자', '영원한 망각', '여명의 전투',
    '통곡의 노래', '마지막 방어선', '혼돈의 밤',
  ];

  /// 날짜 → 시드
  static int _dateToSeed(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// 시드 기반 의사 난수 (결정론적)
  static int _seededRandom(int seed, int index) {
    // 간단한 LCG (Linear Congruential Generator)
    var v = seed + index * 7919;
    v = (v * 1103515245 + 12345) & 0x7FFFFFFF;
    return v;
  }

  /// 오늘의 도전 생성
  static DailyChallengeData generateForDate(DateTime date) {
    final seed = _dateToSeed(date);

    // 제목 선택
    final titleIdx = _seededRandom(seed, 0) % _titles.length;
    final title = _titles[titleIdx];

    // modifier 개수 (1~3개)
    final modCount = 1 + (_seededRandom(seed, 1) % 3);
    final allMods = ChallengeModifier.values.toList();
    final modifiers = <ChallengeModifier>[];
    for (int i = 0; i < modCount && i < allMods.length; i++) {
      final idx = _seededRandom(seed, 10 + i) % allMods.length;
      final mod = allMods[idx];
      if (!modifiers.contains(mod)) {
        modifiers.add(mod);
      }
      allMods.removeAt(idx);
    }

    // 난이도 (1.2 ~ 2.5)
    final diffBase = 1.2 + (_seededRandom(seed, 2) % 14) * 0.1;

    // 적 구성 (챕터 혼합)
    final chapterIdx = _seededRandom(seed, 3) % 5;
    final enemies = TowerFloorGenerator.getAvailableEnemies(
      (chapterIdx + 1) * 10,
    );

    // 보스 유무 (50% 확률)
    final hasBoss = _seededRandom(seed, 4) % 2 == 0;
    final bosses = [
      EnemyId.bossOgreLord,
      EnemyId.bossMountainLord,
      EnemyId.bossGreatEggGhost,
      EnemyId.bossTyrantKing,
      EnemyId.bossGatekeeper,
    ];
    final bossId = hasBoss
        ? bosses[_seededRandom(seed, 5) % bosses.length]
        : null;

    // 웨이브 수 (10~15)
    final waves = 10 + (_seededRandom(seed, 6) % 6);

    // 보상 (modifier 개수에 비례)
    final gemReward = 30 + modifiers.length * 20;
    final expReward = 50 + modifiers.length * 30;

    return DailyChallengeData(
      date: date,
      seed: seed,
      title: title,
      modifiers: modifiers,
      targetWaves: waves,
      difficultyScale: diffBase,
      availableEnemies: enemies,
      bossId: bossId,
      reward: DailyChallengeReward(
        gems: gemReward,
        exp: expReward,
        title: '일일 수호자',
      ),
    );
  }

  /// 오늘의 도전
  static DailyChallengeData get today =>
      generateForDate(DateTime.now());
}
