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
      speakerName: '신비로운 목소리',
      text: '오래된 이야기 속, 이승과 저승 사이에 커다란 문이 하나 있었대요~ ✨',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '신비로운 목소리',
      text: '해원의 문이라 불리는 이 문이 살짝 열려버렸어요!\n덜컹덜컹~ 귀여운 귀신 친구들이 몰려오고 있답니다!',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '깨비',
      text: '우와아! 저기 봐봐! 뭔가 재미있어 보이는 애들이 잔뜩 넘어오는데?!\n나도 같이 놀자~!! 🎉',
      portraitAsset: 'assets/images/portraits/portrait_kkaebi.png',
      side: SpeakerSide.right,
      nameColor: Colors.orangeAccent,
    ),
    StoryScene(
      speakerName: '강림',
      text: '장난치지 마. 저 친구들이 길을 잃어서 헤매고 있는 거야.\n우리가 바른 길을 안내해줘야 해! 자, 준비하자! 💪',
      portraitAsset: 'assets/images/portraits/portrait_gangnim.png',
      side: SpeakerSide.left,
      nameColor: Colors.deepPurpleAccent,
    ),
  ];

  /// 1챕터 클리어 후 (Ep.1 -> Ep.2 전환)
  static const List<StoryScene> ep1ToEp2 = [
    StoryScene(
      speakerName: '내러티브',
      text: '장터의 소동은 잠잠해졌어요! 하지만 산 너머에서 뭔가 부스럭거리는 소리가... 🌲',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '미호',
      text: '어머~ 산에서 귀여운 동물 친구들이 놀고 있나 봐요?\n한번 가볼까요~? 꼬리가 살랑살랑♡',
      portraitAsset: 'assets/images/portraits/portrait_miho.png',
      side: SpeakerSide.right,
      nameColor: Colors.pinkAccent,
    )
  ];

  /// 2챕터 클리어 후 (Ep.2 -> Ep.3 전환)
  static const List<StoryScene> ep2ToEp3 = [
    StoryScene(
      speakerName: '내러티브',
      text: '숲의 동물 친구들도 집으로 돌아갔어요. 그런데 안개가 살짝 끼더니 숲이 신비로워지고 있네요~ 🌿',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '수아',
      text: '...안개 속에서 누군가 길을 잃어서 울고 있어요.\n제가 도와줄게요, 걱정 마세요~ 💧',
      portraitAsset: 'assets/images/portraits/portrait_sua.png',
      side: SpeakerSide.right,
      nameColor: Colors.blueAccent,
    )
  ];
  
  /// 3챕터 클리어 후 (Ep.3 -> Ep.4 전환)
  static const List<StoryScene> ep3ToEp4 = [
    StoryScene(
      speakerName: '내러티브',
      text: '안개 속 친구들을 모두 도와줬어요! 그런데 소문이 들려오네요~\n왕궁에서 장난꾸러기가 소동을 벌이고 있대요! 🏯',
      side: SpeakerSide.left,
    ),
  ];

  /// 4챕터 클리어 후 (Ep.4 -> Ep.5 전환)
  static const List<StoryScene> ep4ToEp5 = [
    StoryScene(
      speakerName: '내러티브',
      text: '왕궁의 소동도 해결! 그런데 이번엔 해원의 문이 활짝 열려버렸어요!\n마지막 모험이 기다리고 있답니다~ ✨',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: '바리',
      text: '드디어 마지막 관문이에요! 모두 힘을 합치면 분명 할 수 있을 거예요!\n자, 같이 가요~! 🌸',
      portraitAsset: 'assets/images/portraits/portrait_bari.png',
      side: SpeakerSide.right,
      nameColor: Colors.tealAccent,
    ),
    StoryScene(
      speakerName: '강림',
      text: '좋아, 다 같이 간다. 이번엔 내가 제대로 멋지게 보여줄게! 🌟',
      portraitAsset: 'assets/images/portraits/portrait_gangnim.png',
      side: SpeakerSide.left,
      nameColor: Colors.deepPurpleAccent,
    ),
  ];

  /// 영웅 백스토리 로어 딕셔너리
  static const Map<String, String> heroLoreData = {
    'kkaebi': '낡은 빗자루에서 태어난 장난꾸러기 도깨비! 이승의 장난감이 너무 좋아서 해원의 문을 지키는 일에 신나게 동참했어요~ 🎉\n\n누군가 버린 짚신을 신고 씨름 기술을 열심히 연습해서, 이제는 말썽꾸러기 귀신들을 번쩍 들어올릴 정도로 힘이 세졌답니다! 장차 도깨비 왕의 감투를 물려받을 운명이에요!',
    'miho': '꼬리가 하나뿐인 어린 여우! 인간 친구를 만들고 싶어서 해원의 문 앞에서 기도하다가 파수꾼이 되었어요~ 🦊\n\n모험을 하면 할수록 꼬리가 하나씩 늘어나서, 훗날 아홉 개의 꼬리가 반짝반짝 빛날 때마다 길 잃은 영혼들을 하늘로 안내해주는 멋진 구미호가 될 거예요!',
    'gangnim': '갓을 쓴 신입 저승차사! 아직은 초보지만 누구보다 책임감이 강해요~ 😎\n\n열심히 임무를 완수하면서 멋진 정식 차사가 되었고, 언젠가는 염라대왕님의 대행자로 임명되어 멋진 심판의 도구를 받게 될 거예요!',
    'sua': '순수한 마음을 가진 물의 정령! 다른 친구들이 물에서 위험해지지 않도록 늘 걱정하는 다정한 수호자예요~ 💧\n\n점점 강해져서 늪의 주인이 되었고, 맑은 노래로 나쁜 귀신들의 발을 묶어버린답니다! 최종적으로는 큰 바다의 정령으로 멋지게 성장할 거예요!',
    'bari': '귀여운 꼬마 무녀 공주님! 방울 소리 하나로 주변의 나쁜 기운을 싹~ 정화하는 천재예요~ 🌸\n\n힘든 친구들을 위로하며 최고의 무녀가 되어, 생명의 꽃을 피워 모든 아군에게 무적의 보호막을 만들어주는 대단한 능력을 얻게 된답니다!'
  };

}
