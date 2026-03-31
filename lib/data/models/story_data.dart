import 'package:flutter/material.dart';

enum SpeakerSide { left, right }

/// 컷씬 다이얼로그에서 쓰일 단일 대화 씬 (한 장면)
class StoryScene {
  final String speakerName;
  final String text;
  final String? portraitAsset; // 예: 'assets/images/portraits/portrait_kkaebi.webp'
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
      speakerName: 'story_speaker_mysterious',
      text: 'story_intro_1',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: 'story_speaker_mysterious',
      text: 'story_intro_2',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: 'story_speaker_kkaebi',
      text: 'story_intro_3',
      portraitAsset: 'assets/images/portraits/portrait_kkaebi.webp',
      side: SpeakerSide.right,
      nameColor: Colors.orangeAccent,
    ),
    StoryScene(
      speakerName: 'story_speaker_gangrim',
      text: 'story_intro_4',
      portraitAsset: 'assets/images/portraits/portrait_gangnim.webp',
      side: SpeakerSide.left,
      nameColor: Colors.deepPurpleAccent,
    ),
  ];

  /// 1챕터 클리어 후 (Ep.1 -> Ep.2 전환)
  static const List<StoryScene> ep1ToEp2 = [
    StoryScene(
      speakerName: 'story_speaker_narrator',
      text: 'story_ep1to2_1',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: 'story_speaker_miho',
      text: 'story_ep1to2_2',
      portraitAsset: 'assets/images/portraits/portrait_miho.webp',
      side: SpeakerSide.right,
      nameColor: Colors.pinkAccent,
    )
  ];

  /// 2챕터 클리어 후 (Ep.2 -> Ep.3 전환)
  static const List<StoryScene> ep2ToEp3 = [
    StoryScene(
      speakerName: 'story_speaker_narrator',
      text: 'story_ep2to3_1',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: 'story_speaker_sua',
      text: 'story_ep2to3_2',
      portraitAsset: 'assets/images/portraits/portrait_sua.webp',
      side: SpeakerSide.right,
      nameColor: Colors.blueAccent,
    )
  ];
  
  /// 3챕터 클리어 후 (Ep.3 -> Ep.4 전환)
  static const List<StoryScene> ep3ToEp4 = [
    StoryScene(
      speakerName: 'story_speaker_narrator',
      text: 'story_ep3to4_1',
      side: SpeakerSide.left,
    ),
  ];

  /// 4챕터 클리어 후 (Ep.4 -> Ep.5 전환)
  static const List<StoryScene> ep4ToEp5 = [
    StoryScene(
      speakerName: 'story_speaker_narrator',
      text: 'story_ep4to5_1',
      side: SpeakerSide.left,
    ),
    StoryScene(
      speakerName: 'story_speaker_bari',
      text: 'story_ep4to5_2',
      portraitAsset: 'assets/images/portraits/portrait_bari.webp',
      side: SpeakerSide.right,
      nameColor: Colors.tealAccent,
    ),
    StoryScene(
      speakerName: 'story_speaker_gangrim',
      text: 'story_ep4to5_3',
      portraitAsset: 'assets/images/portraits/portrait_gangnim.webp',
      side: SpeakerSide.left,
      nameColor: Colors.deepPurpleAccent,
    ),
  ];

  /// 영웅 백스토리 로어 딕셔너리
  static const Map<String, String> heroLoreData = {
    'kkaebi': 'lore_kkaebi', // '낡은 빗자루에서 태어난 장난꾸러기 도깨비! 이승의 장난감이 너무 좋아서 해원의 문을 지키는 일에 신나게 동참했어요~ 🎉\n\n누군가 버린 짚신을 신고 씨름 기술을 열심히 연습해서, 이제는 말썽꾸러기 귀신들을 번쩍 들어올릴 정도로 힘이 세졌답니다! 장차 도깨비 왕의 감투를 물려받을 운명이에요!',
    'miho': 'lore_miho', // '꼬리가 하나뿐인 어린 여우! 인간 친구를 만들고 싶어서 해원의 문 앞에서 기도하다가 파수꾼이 되었어요~ 🦊\n\n모험을 하면 할수록 꼬리가 하나씩 늘어나서, 훗날 아홉 개의 꼬리가 반짝반짝 빛날 때마다 길 잃은 영혼들을 하늘로 안내해주는 멋진 구미호가 될 거예요!',
    'gangnim': 'lore_gangnim',
    'sua': 'lore_sua', // '순수한 마음을 가진 물의 정령! 다른 친구들이 물에서 위험해지지 않도록 늘 걱정하는 다정한 수호자예요~ 💧\n\n점점 강해져서 늪의 주인이 되었고, 맑은 노래로 나쁜 귀신들의 발을 묶어버린답니다! 최종적으로는 큰 바다의 정령으로 멋지게 성장할 거예요!',
    'bari': 'lore_bari', // '귀여운 꼬마 무녀 공주님! 방울 소리 하나로 주변의 나쁜 기운을 싹~ 정화하는 천재예요~ 🌸\n\n힘든 친구들을 위로하며 최고의 무녀가 되어, 생명의 꽃을 피워 모든 아군에게 무적의 보호막을 만들어주는 대단한 능력을 얻게 된답니다!'
  };

}
