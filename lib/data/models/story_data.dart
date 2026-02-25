import 'package:flutter/material.dart';

enum SpeakerSide { left, right }

/// 컷씬 다이얼로그에서 쓰일 단일 대화 씬 (한 장면)
class StoryScene {
  final String speakerName;
  final String text;
  final String? portraitAsset; // 예: 'avatars/kkaebi_portrait.png'
  final SpeakerSide side;
  final Color? nameColor;

  const StoryScene({
    required this.speakerName,
    required this.text,
    this.portraitAsset,
    this.side = SpeakerSide.left,
    this.nameColor,
  });
}

/// 인게임 스테이지 혹은 특정 조건에서 불려올 전체 스토리 시퀀스 목록
class StoryData {
  
  /// 튜토리얼 / 1챕터 인트로
  static const List<StoryScene> introSequence = [
    StoryScene(
      speakerName: '알 수 없는 목소리',
      text: '비가 내린다. 하늘이 우능 건가, 땅이 우는 건가...',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '알 수 없는 목소리',
      text: '해원문의 빗장이 흔들린다. 그들이 오고 있다.\n이 문이 열리면… 이승과 저승의 경계가 무너진다.',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '깨비',
      text: '우와아! 저기 문 밖으로 재밌어 보이는 것들이 잔뜩 넘어오는데?!',
      portraitAsset: 'assets/images/portraits/portrait_kkaebi.png',
      side: SpeakerSide.right,
      nameColor: Colors.orangeAccent,
    ),
    StoryScene(
      speakerName: '강림',
      text: '경거망동하지 마라. 명부에 적히지 않은 악귀들이 이승을 탐내고 있다.\n...방어를 준비해라.',
      portraitAsset: 'assets/images/portraits/portrait_gangnim.png',
      side: SpeakerSide.left,
      nameColor: Colors.deepPurpleAccent,
    ),
  ];

  /// 1챕터 클리어 후 (Ep.1 -> Ep.2 전환)
  static const List<StoryScene> ep1ToEp2 = [
    StoryScene(
      speakerName: '내러티브',
      text: '장터의 아귀들은 조용해졌지만, 산 너머에서 들려오는 저 짐승들의 통곡소리는 무엇인가?',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '미호',
      text: '할머니~ 저 산에서 나는 냄새는 짐승의 피 냄새인데요?\n조금 위험할지도 모르겠어요♡',
      portraitAsset: 'assets/images/portraits/portrait_miho.png',
      side: SpeakerSide.right,
      nameColor: Colors.pinkAccent,
    )
  ];

  /// 2챕터 클리어 후 (Ep.2 -> Ep.3 전환)
  static const List<StoryScene> ep2ToEp3 = [
    StoryScene(
      speakerName: '내러티브',
      text: '산군의 위엄도 원한을 막진 못했다. 하지만 안개가 자욱해지며 숲의 얼굴이 지워지고 있다.',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '수아',
      text: '...안개 속에서 누군가 울고 있어요. 저와 같은... 깊고 깊은 슬픔이...',
      portraitAsset: 'assets/images/portraits/portrait_sua.png',
      side: SpeakerSide.right,
      nameColor: Colors.blueAccent,
    )
  ];
  
  /// 3챕터 클리어 후 (Ep.3 -> Ep.4 전환)
  static const List<StoryScene> ep3ToEp4 = [
    StoryScene(
      speakerName: '내러티브',
      text: '안개 속의 괴물들을 정화했지만, 소문이 들려온다. 왕궁의 그림자가 이 모든 혼란의 배후라고.',
      side: SpeakerSide.left,
    ),
  ];

  /// 4챕터 클리어 후 (Ep.4 -> Ep.5 전환)
  static const List<StoryScene> ep4ToEp5 = [
    StoryScene(
      speakerName: '내러티브',
      text: '왕궁의 타락을 씻어냈으나, 이승의 힘으론 더 이상 막을 수 없는 거대한 뒤틀린 문이 열렸다.',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '바리',
      text: '결국 열리고 말았군요... 이승과 저승, 모든 영혼들이 저들의 한을 풀어달라 울부짖고 있습니다.',
      portraitAsset: 'assets/images/portraits/portrait_bari.png',
      side: SpeakerSide.right,
      nameColor: Colors.tealAccent,
    ),
    StoryScene(
      speakerName: '강림',
      text: '내가 나설 차례인가. 심판의 종을 울릴 시간이다.',
      portraitAsset: 'assets/images/portraits/portrait_gangnim.png',
      side: SpeakerSide.left,
      nameColor: Colors.deepPurpleAccent,
    ),
  ];

  /// 영웅 백스토리 로어 딕셔너리
  static const Map<String, String> heroLoreData = {
    'kkaebi': '낡은 빗자루에서 태어난 말괄량이 도깨비. 이승의 장난감을 좋아해 해원문을 지키는 일에 동참한다.\n\n누군가 버린 짚신을 신고 씨름 기술을 익혀 이제는 잡귀들을 번쩍 들어 메칠 정도로 힘이 세졌다. 장차 도깨비 왕의 감투를 전수받아 전설적인 수호자가 될 운명이다.',
    'miho': '꼬리가 하나뿐인 어린 여우. 인간이 되고 싶어 해원문 앞에서 기도를 올리다 파수꾼이 되었다.\n\n고난을 이겨내며 점차 꼬리가 늘어나, 훗날 9개의 꼬리가 춤출 때마다 원혼들을 해방하며 승천시키는 위대한 구미호에 도달하게 된다.',
    'gangnim': '갓을 쓴 신입 저승차사. 아직은 서툴지만 명부의 이름을 지워나가는 일에 남다른 책임감을 느낀다.\n\n수많은 임무를 완수하며 정식 차사의 두루마기를 하사받았고, 언젠가 염라대왕의 대행자로 임명되어 피할 수 없는 심판의 낫을 쥐게 된다.',
    'sua': '젖은 소복을 입은 처녀 귀신. 억울하게 물에 빠져 죽은 그녀는 다른 영혼들이 같은 길을 걷지 않길 바란다.\n\n원한을 넘어선 그녀는 늪의 주인이 되었으며, 슬픈 노래로 적들의 발걸음을 묶는다. 최종적으로 거대한 물기둥을 다루는 대해수의 정령으로 거듭날 것이다.',
    'bari': '버려진 공주이자 꼬마 무녀. 방울 소리 하나로 이승의 뒤틀린 기운을 잠재우는 천부적인 재능을 가졌다.\n\n고통받는 자들을 위로하며 만신의 경지에 오르게 되고, 생명꽃의 주인이 되어 전장의 모든 아군에게 죽음조차 거부하는 무적의 영역을 만들어낸다.'
  };

}
