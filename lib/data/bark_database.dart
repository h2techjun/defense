// 해원의 문 — 영웅 대사 데이터베이스
// GDD §7.3 기반 — 5명 영웅의 상황별 대사

import 'models/bark_data.dart';
import '../../common/enums.dart';

/// GDD §7.3 영웅 대사 데이터
/// heroId는 HeroId enum의 name과 매칭
const List<BarkData> allBarkData = [
  // ─── 깨비 (도깨비) ───
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.bossAppear, lines: [
    '어이 형씨, 뿔 관리가 엉망이네?',
    '큰 놈이 왔다! 신난다!',
    '오호~ 힘 좀 쓰겠구만!',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.bossKill, lines: [
    '힘만 센 바보는 여전하구나.',
    '이래도 안 죽니? 아, 죽었구나.',
    '뿔 뽑아서 이쑤시개 만들까?',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.allyDanger, lines: [
    '야, 거기 좀 버텨봐!',
    '으아~ 큰일 났다!',
    '방망이질 좀 더 해야겠어!',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.nightTransition, lines: [
    '와~ 밤이다! 신난다!',
    '밤에는 씨름이 더 재밌지~',
    '어둠? 도깨비한테 어둠은 놀이터야!',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.ultimateUsed, lines: [
    '도깨비 방망이, 나와라!',
    '한 방에 보내주마!',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.battleStart, lines: [
    '자, 어디 한번 놀아볼까!',
    '오늘도 한판 붙자~',
  ]),

  // ─── 미호 (구미호) ───
  BarkData(heroId: 'miho', trigger: BarkTrigger.bossAppear, lines: [
    '할머니~ 저는 안 속아요♡',
    '큰 것이 왔네요~ 흥미로워요.',
    '이 구슬에 비친 건... 위험해요.',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.bossKill, lines: [
    '꼬리 하나도 안 줄게~',
    '여우에게 속은 건 누구일까요~',
    '구슬이 더 밝아졌어요♡',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.allyDanger, lines: [
    '이런… 구슬이 부족해.',
    '여우도 불안할 때가 있어요...',
    '빨리 도와줘야 해요!',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.nightTransition, lines: [
    '…저도 원래 밤이 더 좋은데요.',
    '달빛 아래서 구슬이 더 빛나요~',
    '밤이면 꼬리가 더 아름다워요♡',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.ultimateUsed, lines: [
    '여우구슬, 빛나거라~!',
    '꼬리 아홉의 힘을 보여줄게!',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.battleStart, lines: [
    '준비됐나요~?',
    '여우의 직감이... 뭔가 온대요.',
  ]),

  // ─── 강림 (저승차사) ───
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.bossAppear, lines: [
    '...명부에 적혀 있군.',
    '순서를 어기면 안 되는데.',
    '큰 건이 들어왔군.',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.bossKill, lines: [
    '다음 차례는 누구인가.',
    '명부의 이름, 한 줄 지웠다.',
    '아직 갈 길이 멀다.',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.allyDanger, lines: [
    '명부가 너무 빨리 차는군.',
    '이 속도면... 위험하다.',
    '...아직 이 자리를 비울 순 없다.',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.nightTransition, lines: [
    '밤에는 일감이 많아지는군.',
    '어둠 속에서 더 잘 보인다.',
    '...저승까지의 거리가 가까워졌군.',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.ultimateUsed, lines: [
    '명부의 이름으로 명한다.',
    '...끝이다.',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.battleStart, lines: [
    '...시작하겠다.',
    '명부를 펼치지.',
  ]),

  // ─── 수아 (물귀신) ───
  BarkData(heroId: 'sua', trigger: BarkTrigger.bossAppear, lines: [
    '...물 속으로 끌어당기겠어.',
    '큰 파도가 필요해...',
    '이 원한... 깊구나.',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.bossKill, lines: [
    '물 위로 올라오지 마...',
    '잔잔해졌어...',
    '원한이... 조금 풀렸어.',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.allyDanger, lines: [
    '물이... 마르고 있어...',
    '안 돼... 여기서 멈출 순 없어.',
    '도와줘요...',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.nightTransition, lines: [
    '밤의 물은... 차갑지.',
    '달빛이 물에 비치면 더 강해져.',
    '...밤이 되면 더 외로워.',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.ultimateUsed, lines: [
    '깊은 물 속으로...!',
    '물기둥이여, 솟아라!',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.battleStart, lines: [
    '...준비됐어.',
    '물결이 일렁이기 시작해.',
  ]),

  // ─── 바리 (바리공주/무녀) ───
  BarkData(heroId: 'bari', trigger: BarkTrigger.bossAppear, lines: [
    '신이시여, 힘을 주소서...',
    '방울이 미친 듯이 울려요!',
    '큰 원혼이에요! 조심!',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.bossKill, lines: [
    '해원됐어요... 편히 가세요.',
    '부디 좋은 곳으로...',
    '방울 소리가 잠잠해졌어요.',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.allyDanger, lines: [
    '모두 제 뒤로! 치유합니다!',
    '신이시여... 조금만 더 힘을...',
    '포기하지 마세요!',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.nightTransition, lines: [
    '밤이에요... 굿판을 열어야 해요.',
    '방울에 달빛이 깃들어요.',
    '어둠 속에서도 꽃은 피어요.',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.ultimateUsed, lines: [
    '강신~! 신이 내립니다!',
    '모두에게 은총을!',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.battleStart, lines: [
    '해원의 길을 열겠습니다.',
    '방울 소리와 함께~',
  ]),
];

/// heroId + trigger 조합으로 대사 검색
List<String> getBarkLines(HeroId heroId, BarkTrigger trigger) {
  final id = heroId.name;
  for (final bark in allBarkData) {
    if (bark.heroId == id && bark.trigger == trigger) {
      return bark.lines;
    }
  }
  return [];
}
