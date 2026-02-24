// 해원의 문 - 설화도감 데이터 모델
// 3단계 해금: 조우(실루엣) → 기본 정보(10킬) → 비밀 설화(100킬) → 숨겨진 이야기(1000킬)
// 수집률 보상: 25%/50%/75%/100% 마일스톤

import '../../common/enums.dart';

/// 도감 카테고리
enum LoreCategory {
  enemy,    // 적/요괴
  hero,     // 영웅
  tower,    // 타워
  world,    // 세계관/지역
}

extension LoreCategoryExt on LoreCategory {
  String get label => switch (this) {
    LoreCategory.enemy => '요괴',
    LoreCategory.hero  => '영웅',
    LoreCategory.tower => '타워',
    LoreCategory.world => '세계관',
  };

  String get emoji => switch (this) {
    LoreCategory.enemy => '👹',
    LoreCategory.hero  => '⚔️',
    LoreCategory.tower => '🏰',
    LoreCategory.world => '🌏',
  };
}

/// 해금 단계
enum LoreUnlockTier {
  locked,         // 🔒 미발견 (???)
  encountered,    // 실루엣: 첫 조우
  basic,          // 기본 정보: 10킬
  secretLore,     // 비밀 설화: 100킬
  hiddenStory,    // 숨겨진 이야기: 1000킬 + 보석 보상
}

/// 도감 엔트리
class LoreEntry {
  final String id;
  final LoreCategory category;
  final String name;
  final String emoji;

  // 기본 설명 (Tier: encountered)
  final String basicDescription;

  // 비밀 설화 (Tier: secretLore)
  final String secretDescription;

  // 숨겨진 이야기 (Tier: hiddenStory)
  final String hiddenDescription;

  // 해금 조건 (킬 수)
  final int encounterKills;   // 조우 (보통 1)
  final int basicKills;       // 기본 정보
  final int secretKills;      // 비밀 설화
  final int hiddenKills;      // 숨겨진 이야기

  // 보상
  final int encounterGems;    // 최초 조우 보석
  final int basicGems;        // 기본 해금 보석
  final int secretGems;       // 비밀 해금 보석
  final int hiddenGems;       // 숨겨진 이야기 보석

  const LoreEntry({
    required this.id,
    required this.category,
    required this.name,
    required this.emoji,
    required this.basicDescription,
    required this.secretDescription,
    required this.hiddenDescription,
    this.encounterKills = 1,
    this.basicKills = 10,
    this.secretKills = 100,
    this.hiddenKills = 1000,
    this.encounterGems = 1,
    this.basicGems = 2,
    this.secretGems = 5,
    this.hiddenGems = 10,
  });

  /// 킬 수에 따른 해금 단계 반환
  LoreUnlockTier getTier(int kills) {
    if (kills >= hiddenKills) return LoreUnlockTier.hiddenStory;
    if (kills >= secretKills) return LoreUnlockTier.secretLore;
    if (kills >= basicKills) return LoreUnlockTier.basic;
    if (kills >= encounterKills) return LoreUnlockTier.encountered;
    return LoreUnlockTier.locked;
  }

  /// 다음 단계까지 남은 킬 수
  int killsToNextTier(int currentKills) {
    final tier = getTier(currentKills);
    return switch (tier) {
      LoreUnlockTier.locked      => encounterKills - currentKills,
      LoreUnlockTier.encountered => basicKills - currentKills,
      LoreUnlockTier.basic       => secretKills - currentKills,
      LoreUnlockTier.secretLore  => hiddenKills - currentKills,
      LoreUnlockTier.hiddenStory => 0,
    };
  }

  /// 해당 단계의 보석 보상
  int gemsForTier(LoreUnlockTier tier) => switch (tier) {
    LoreUnlockTier.locked      => 0,
    LoreUnlockTier.encountered => encounterGems,
    LoreUnlockTier.basic       => basicGems,
    LoreUnlockTier.secretLore  => secretGems,
    LoreUnlockTier.hiddenStory => hiddenGems,
  };
}

/// 수집률 마일스톤 보상
class CollectionMilestone {
  final double percentage;     // 0.25, 0.50, 0.75, 1.00
  final int rewardGems;
  final int rewardGold;
  final String rewardTitle;    // 칭호
  final String emoji;

  const CollectionMilestone({
    required this.percentage,
    required this.rewardGems,
    required this.rewardGold,
    required this.rewardTitle,
    required this.emoji,
  });
}

const List<CollectionMilestone> collectionMilestones = [
  CollectionMilestone(percentage: 0.25, rewardGems: 20,  rewardGold: 5000,  rewardTitle: '초보 도감 수집가',   emoji: '📖'),
  CollectionMilestone(percentage: 0.50, rewardGems: 50,  rewardGold: 15000, rewardTitle: '열정의 것고리',     emoji: '📚'),
  CollectionMilestone(percentage: 0.75, rewardGems: 100, rewardGold: 30000, rewardTitle: '설화의 수호자',     emoji: '🏆'),
  CollectionMilestone(percentage: 1.00, rewardGems: 200, rewardGold: 50000, rewardTitle: '전설의 기록관',     emoji: '👑'),
];

// ═══════════════════════════════════════════════
// 📜 설화 도감 전체 데이터베이스
// ═══════════════════════════════════════════════

final List<LoreEntry> allLoreEntries = [

  // ──────── 챕터 1: 굶주린 자들의 장터 ────────

  const LoreEntry(
    id: 'hungryGhost', category: LoreCategory.enemy,
    name: '허기귀', emoji: '👻',
    basicDescription: '굶주림 속에 죽어간 원혼. 입에서 끊임없이 차가운 기운이 흘러나온다.',
    secretDescription: '허기귀는 실은 대기근 시기 관의 구호를 받지 못한 만백성이었다. 그들의 한은 살아있는 자의 따뜻한 밥 냄새를 맡을 때마다 되살아난다.',
    hiddenDescription: '전설에 의하면, 허기귀 천 마리를 해원하면 그 중 한 영혼이 감사의 뜻으로 황금 수저를 남긴다 하여, 장터의 상인들은 밤마다 공양을 올렸다고 한다.',
  ),
  const LoreEntry(
    id: 'strawShoeSpirit', category: LoreCategory.enemy,
    name: '짚신영감', emoji: '👴',
    basicDescription: '낡은 짚신을 신고 느릿느릿 다가오는 노인의 영혼. 지팡이로 타워를 두들긴다.',
    secretDescription: '짚신영감은 생전 장터까지 백 리를 걸어 약을 구하러 나섰으나, 결국 도착하지 못하고 길 위에서 멈추었다. 그의 짚신만이 길 위에 남았다.',
    hiddenDescription: '짚신영감의 짚신 한 켤레를 찾으면 어떤 길이든 미끄러지지 않는 신비한 힘이 깃든다고 전해진다.',
  ),
  const LoreEntry(
    id: 'burdenedLaborer', category: LoreCategory.enemy,
    name: '등짐꾼', emoji: '🎒',
    basicDescription: 'HP가 높고 느리지만 꾸준히 밀고 들어오는 원혼. 지게에 한을 가득 짊어지고 있다.',
    secretDescription: '등짐꾼은 양반의 무거운 짐을 대신 져주다 허리가 꺾여 죽은 노비였다. 그 짐 속에는 사실 양반이 빼돌린 관곡이 들어있었다.',
    hiddenDescription: '등짐꾼의 지게를 내려놓게 해주면, 그 안에서 잃어버린 보물이 산더미처럼 쏟아진다는 전설이 내려온다.',
  ),
  const LoreEntry(
    id: 'maidenGhost', category: LoreCategory.enemy,
    name: '처녀귀신', emoji: '👰',
    basicDescription: '시집을 가지 못하고 죽은 처녀의 세 영혼이 한이 되어 떠돈다. 빠르고 회피율이 높다.',
    secretDescription: '이 처녀귀신은 실은 사또의 아들에게 겁탈당한 뒤 수치스러움에 투신한 규수였다. 그 아들은 벌을 받지 않았고, 처녀의 한은 영원히 풀리지 않았다.',
    hiddenDescription: '난간 위에서 핀 붉은 동백꽃은 처녀귀신의 눈물이 스며든 것이라 한다. 이 꽃을 꺾으면 반드시 불행이 찾아온다.',
  ),
  const LoreEntry(
    id: 'eggGhost', category: LoreCategory.enemy,
    name: '달걀귀신', emoji: '🥚',
    basicDescription: '이목구비가 없는 흰 얼굴의 귀신. 보면 공포에 질려 타워가 잠시 기능을 멈춘다.',
    secretDescription: '달걀귀신의 정체는 이름조차 기록되지 않은 익명의 원혼들. 이름이 없기에 얼굴도 없고, 저승에서도 받아주지 않아 이승을 떠돌게 되었다.',
    hiddenDescription: '달걀귀신에게 진심으로 이름을 지어주면, 흐릿했던 얼굴에 미소가 피어오른다 한다. 그리고 감사의 표시로 숨겨둔 보물을 알려준다.',
  ),
  const LoreEntry(
    id: 'bossOgreLord', category: LoreCategory.enemy,
    name: '🔥 도깨비 두목', emoji: '👹',
    basicDescription: '장터를 지배하는 거대한 도깨비. 방망이 한 번이면 산이 무너진다.',
    secretDescription: '도깨비 두목은 원래 장터를 지키던 수호신이었다. 그러나 인간의 탐욕을 너무 많이 보고 타락하여, 지키던 것을 부수기 시작했다.',
    hiddenDescription: '도깨비 두목의 방망이는 사실 두 개가 한 쌍이다. 금 나오는 방망이와 금 사라지는 방망이. 탐욕에 눈이 먼 인간들은 항상 잘못된 쪽을 고른다.',
    basicKills: 3, secretKills: 30, hiddenKills: 100,
    encounterGems: 3, basicGems: 5, secretGems: 10, hiddenGems: 25,
  ),

  // ──────── 챕터 2: 통곡하는 숲 ────────

  const LoreEntry(
    id: 'tigerSlave', category: LoreCategory.enemy,
    name: '호랑이 종', emoji: '🐅',
    basicDescription: '산군(호랑이)에게 잡아먹힌 뒤 그의 종이 된 창귀. 다른 먹잇감을 유인한다.',
    secretDescription: '창귀가 된 자들은 생전 자신을 잡아먹은 호랑이를 위해 새로운 희생양을 찾아야만 해원할 수 있다는 거짓 약속에 속아 영원히 종 노릇을 한다.',
    hiddenDescription: '실은 호랑이 종 중 한 명이 용기를 내어 산군을 배신하면 모든 창귀가 해방된다. 하지만 아무도 먼저 나서지 않는다.',
  ),
  const LoreEntry(
    id: 'fireDog', category: LoreCategory.enemy,
    name: '불개', emoji: '🔥',
    basicDescription: '입에서 불을 뿜는 설화 속의 짐승. 지나간 자리에 불길을 남긴다.',
    secretDescription: '불개는 원래 해와 달을 쫓던 천상의 맹수였으나, 번번이 실패하여 지상으로 쫓겨났다. 그 분노가 입에서 불이 되어 터져 나온다.',
    hiddenDescription: '만약 불개가 해를 삼키는 데 성공한다면, 세상은 영원한 밤이 된다. 설화 속 현자들은 이를 막기 위해 징과 북을 치며 불개를 쫓았다 한다.',
  ),
  const LoreEntry(
    id: 'shadowGolem', category: LoreCategory.enemy,
    name: '그림자 거인', emoji: '🗿',
    basicDescription: '숲의 그림자가 응집된 거인. 극도로 느리지만 한 방의 무게가 산을 부순다.',
    secretDescription: '그림자 거인은 천 년 묵은 고목의 원혼이다. 벌목꾼들이 숲을 밀어낸 한이 그림자가 되어 형체를 이룬 것.',
    hiddenDescription: '그림자 거인의 심장에는 천 년 전 씨앗이 잠들어 있다. 이 씨앗을 심으면 하루 만에 숲이 되살아난다고 전해진다.',
  ),
  const LoreEntry(
    id: 'oldFoxWoman', category: LoreCategory.enemy,
    name: '여우 할멈', emoji: '🦊',
    basicDescription: '천 년 묵은 여우가 인간으로 변한 것. 매혹 능력으로 타워를 무력화한다.',
    secretDescription: '이 여우는 실은 인간이 되려 했으나 마지막 간 하나가 모자라 변신이 불완전해졌다. 반인반수의 모습으로 영겁을 떠돈다.',
    hiddenDescription: '구미호의 여의주는 모든 병을 고치는 만병통치약이라 한다. 하지만 여의주를 빼앗으면 여우는 영원히 인간이 될 수 없기에, 목숨을 걸고 지킨다.',
  ),
  const LoreEntry(
    id: 'failedDragon', category: LoreCategory.enemy,
    name: '이무기', emoji: '🐉',
    basicDescription: '용이 되지 못한 천년 묵은 뱀. 승천의 한을 품고 모든 것을 집어삼키려 한다.',
    secretDescription: '이무기가 용이 되려면 여의주를 물고 폭포를 거슬러 올라야 한다. 그러나 천 년 묵은 이무기는 매번 마지막 한 칸을 남기고 떨어졌다.',
    hiddenDescription: '전설에 따르면 이무기의 비늘 천 개를 모으면 용이 남긴 비린내를 쫓을 수 있다 하여, 무사들이 이무기를 사냥했다 한다.',
  ),
  const LoreEntry(
    id: 'bossMountainLord', category: LoreCategory.enemy,
    name: '🔥 산군 대왕', emoji: '🐯',
    basicDescription: '숲을 지배하는 초자연적 호랑이. 포효 한 번에 바위가 갈라진다.',
    secretDescription: '산군 대왕은 원래 산신령이 타고 다니던 성수였으나, 산신이 잠든 사이 권좌를 찬탈했다. 이제 산 자체가 그의 영역이다.',
    hiddenDescription: '산군 대왕의 이빨 하나에 산신령의 힘 한 조각이 깃들어 있다. 이를 모두 모으면 잠든 산신을 깨울 수 있다 하여 많은 용사가 도전했으나, 돌아온 자는 없다.',
    basicKills: 3, secretKills: 30, hiddenKills: 100,
    encounterGems: 3, basicGems: 5, secretGems: 10, hiddenGems: 25,
  ),

  // ──────── 영웅 ────────

  const LoreEntry(
    id: 'hero_kkaebi', category: LoreCategory.hero,
    name: '깨비', emoji: '👹',
    basicDescription: '장난꾸러기 도깨비. 씨름을 좋아하고 인간에게 우호적인 드문 도깨비족.',
    secretDescription: '깨비는 원래 도깨비 두목의 의형제였다. 그러나 두목이 타락하자 인간 편에 섰고, 그 대가로 도깨비 사회에서 추방당했다.',
    hiddenDescription: '깨비의 진정한 힘은 우정의 감투에서 나온다. 감투를 쓰면 힘이 열 배가 되지만, 외로워지면 감투가 사라진다. 그래서 깨비는 항상 웃고 다닌다.',
    encounterKills: 0, basicKills: 5, secretKills: 50, hiddenKills: 500,
  ),
  const LoreEntry(
    id: 'hero_miho', category: LoreCategory.hero,
    name: '미호', emoji: '🦊',
    basicDescription: '구미호의 후예. 여의주의 힘으로 강력한 마법 공격을 날린다.',
    secretDescription: '미호는 어머니 여우가 인간이 되려다 실패한 한을 물려받았다. 그러나 미호는 달라 — 인간을 사냥하는 대신 인간과 함께 싸우기로 했다.',
    hiddenDescription: '미호의 꼬리 아홉 개에는 각각 다른 감정이 깃들어 있다. 마지막 아홉 번째 꼬리에 깃든 감정은 "사랑"이다. 이 꼬리가 빛날 때 미호는 가장 강해진다.',
    encounterKills: 0, basicKills: 5, secretKills: 50, hiddenKills: 500,
  ),
  const LoreEntry(
    id: 'hero_gangrim', category: LoreCategory.hero,
    name: '강림', emoji: '💀',
    basicDescription: '저승차사. 죽은 자의 영혼을 안내하는 것이 본업이지만, 사정이 있어 이승에 파견되었다.',
    secretDescription: '강림은 원래 인간이었다. 염라대왕의 시험에 합격하여 차사가 된 최초의 인간으로, 그래서 누구보다 인간의 한을 잘 이해한다.',
    hiddenDescription: '강림이 차사가 된 진짜 이유는 사랑하는 사람의 혼을 되찾기 위해서였다. 하지만 차사의 규율에 의해 그 혼을 만날 수 없게 되었고, 이것이 강림의 영원한 한이다.',
    encounterKills: 0, basicKills: 5, secretKills: 50, hiddenKills: 500,
  ),
  const LoreEntry(
    id: 'hero_sua', category: LoreCategory.hero,
    name: '수아', emoji: '🌊',
    basicDescription: '물귀신의 후예. 물의 힘으로 적을 감속하고 끌어당긴다.',
    secretDescription: '수아의 어머니는 강에 빠져 죽은 원혼이었으나, 해원사의 도움으로 한을 풀고 성불했다. 수아는 어머니를 이어 한을 품은 물귀신들을 해원한다.',
    hiddenDescription: '수아가 정말 두려워하는 것은 물이 아니라 "잊혀지는 것"이다. 물귀신의 숙명은 다른 희생자를 만들어야 해원하는 것인데, 수아는 그 숙명을 거부한 유일한 존재다.',
    encounterKills: 0, basicKills: 5, secretKills: 50, hiddenKills: 500,
  ),
  const LoreEntry(
    id: 'hero_bari', category: LoreCategory.hero,
    name: '바리', emoji: '🌸',
    basicDescription: '버림받은 공주가 무당이 된 존재. 치유와 부활의 힘을 가졌다.',
    secretDescription: '바리데기 설화에 따르면, 바리는 아홉 번째로 태어난 딸이라 버려졌으나, 죽은 부모를 살리기 위해 저승까지 약수를 구하러 갔다.',
    hiddenDescription: '바리가 저승에서 가져온 약수는 세 가지이다. 하나는 살리는 물, 하나는 잊게 하는 물, 그리고 마지막은 기억하게 하는 물. 바리는 항상 세 번째 물부터 쓴다.',
    encounterKills: 0, basicKills: 5, secretKills: 50, hiddenKills: 500,
  ),

  // ──────── 세계관 ────────

  const LoreEntry(
    id: 'world_market', category: LoreCategory.world,
    name: '굶주린 자들의 장터', emoji: '🏚️',
    basicDescription: '대기근으로 무너진 조선 장터. 굶주린 원혼들이 마지막 온기를 찾아 떠돈다.',
    secretDescription: '이 장터는 실은 관의 식량 창고를 불태운 탐관오리의 행적이 낳은 비극의 현장이다. 장터의 모든 원혼은 그 한 사람의 탐욕이 만든 것.',
    hiddenDescription: '장터 한가운데 세워진 솟대에는 "다시는 굶기지 마라"는 기도가 새겨져 있다. 이 솟대가 빛나는 날, 원혼들은 잠깐이나마 따뜻한 밥 냄새를 맡을 수 있다 한다.',
    encounterKills: 0, basicKills: 1, secretKills: 10, hiddenKills: 50,
    encounterGems: 2, basicGems: 5, secretGems: 10, hiddenGems: 20,
  ),
  const LoreEntry(
    id: 'world_forest', category: LoreCategory.world,
    name: '통곡하는 숲', emoji: '🌲',
    basicDescription: '밤마다 통곡 소리가 울리는 숲. 산짐승과 요괴가 지배하는 위험 지대.',
    secretDescription: '통곡하는 숲의 나무들은 사실 살아있다. 벌목으로 잘린 나무의 그루터기에서 들려오는 울음소리가 숲 전체에 메아리친다.',
    hiddenDescription: '숲의 가장 깊은 곳에는 "첫 번째 나무"가 있다 한다. 이 나무를 찾는 자에게 숲은 모든 비밀을 속삭여준다. 다만 그 비밀을 발설하면 나무가 되어 영원히 숲에 갇힌다.',
    encounterKills: 0, basicKills: 1, secretKills: 10, hiddenKills: 50,
    encounterGems: 2, basicGems: 5, secretGems: 10, hiddenGems: 20,
  ),
  const LoreEntry(
    id: 'world_faceless', category: LoreCategory.world,
    name: '얼굴 없는 숲', emoji: '🎭',
    basicDescription: '정체를 잃은 영혼들이 떠도는 안개의 숲. 누구의 얼굴인지 알 수 없는 그림자들이 배회한다.',
    secretDescription: '이 숲은 한양의 역적 가문이 삼족을 멸하며 생긴 곳이다. 이름이 지워지고 얼굴이 지워진 자들의 한이 안개가 되어 숲을 덮었다.',
    hiddenDescription: '얼굴 없는 숲에서 자신의 진짜 얼굴을 마주하면, 그것이 가장 두려운 적이 된다 한다. 그래서 이 숲에 들어간 자는 눈을 감고 걸어야 한다.',
    encounterKills: 0, basicKills: 1, secretKills: 10, hiddenKills: 50,
    encounterGems: 2, basicGems: 5, secretGems: 10, hiddenGems: 20,
  ),
  const LoreEntry(
    id: 'world_palace', category: LoreCategory.world,
    name: '왕궁의 그림자', emoji: '🏯',
    basicDescription: '권력에 물든 왕궁. 암살과 음모가 난무하는 저주받은 궁.',
    secretDescription: '왕궁의 지하에는 왕이 처형한 충신들의 목이 봉인되어 있다. 매년 한식날이면 이 목들이 진실을 외친다.',
    hiddenDescription: '왕궁에 전해지는 금기 — "옥좌에 앉은 자는 반드시 그림자를 바꾼다." 이 말의 진짜 의미를 아는 자는 왕궁에서 살아나올 수 없다.',
    encounterKills: 0, basicKills: 1, secretKills: 10, hiddenKills: 50,
    encounterGems: 2, basicGems: 5, secretGems: 10, hiddenGems: 20,
  ),
  const LoreEntry(
    id: 'world_death', category: LoreCategory.world,
    name: '저승의 문턱', emoji: '⛩️',
    basicDescription: '이승과 저승의 경계. 이곳을 넘으면 살아서 돌아올 수 없다.',
    secretDescription: '저승의 문턱에는 세줄바리(세 관문의 파수꾼)가 지키고 있다. 첫 번째는 과거를, 두 번째는 현재를, 세 번째는 미래를 심판한다.',
    hiddenDescription: '바리데기가 이 문턱을 넘었을 때, 문지기는 물었다 — "살아 돌아가면 무엇을 하겠느냐?" 바리는 답했다 — "버린 자를 용서하겠다." 이 대답이 문턱을 열었다.',
    encounterKills: 0, basicKills: 1, secretKills: 10, hiddenKills: 50,
    encounterGems: 2, basicGems: 5, secretGems: 10, hiddenGems: 20,
  ),
];
