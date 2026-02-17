// 해원의 문 (Gateway of Regrets) - 공통 열거형
// 게임의 핵심 분류와 상태를 정의합니다.

/// 방어구 타입 (적의 속성)
enum ArmorType {
  /// 물리형: 산짐승, 도적, 시체류
  physical,

  /// 영혼형: 처녀귀신, 달걀귀신, 도깨비불
  spiritual,

  /// 요괴형: 이무기, 불가사리 (상태이상 면역)
  yokai,
}

/// 공격 타입 (타워/영웅의 공격 속성)
enum DamageType {
  /// 물리 공격: 화살, 칼
  physical,

  /// 마법 공격: 부적, 염력
  magical,

  /// 정화 공격: 영혼형에 추가 데미지
  purification,
}

/// 낮/밤 사이클
enum DayCycle {
  /// 낮: 물리형 적 등장
  day,

  /// 밤: 영혼형 적 등장, 회피율 +50%, 타워 범위 -30%
  night,
}

/// 적 상태머신 (FSM)
enum EnemyState {
  /// 대기
  idle,

  /// 경로 이동 중
  walking,

  /// 광폭화 (원혼 흡수)
  berserk,

  /// 사망 중 (애니메이션)
  dying,

  /// 스턴 (기절)
  stunned,
}

/// 타워 타입
enum TowerType {
  /// 궁수 타워 (산적 초소 → 의병 망루 → 신기전 탑/신궁)
  archer,

  /// 병영 타워 (씨름터 → 무관청 → 천하대장군/도깨비 씨름판)
  barracks,

  /// 마법 타워 (서당 → 부적집 → 만신전/저승사자 출장소)
  shaman,
}

/// 타워 업그레이드 Tier 4 분기
enum TowerBranch {
  // 궁수 분기
  /// 신기전: 광역 폭발 로켓
  rocketBattery,

  /// 신궁: 단일 극딜, 관통, 은신 감지
  spiritHunter,

  // 병영 분기
  /// 천하대장군: 슈퍼 탱커 장승
  generalTotem,

  /// 도깨비 씨름판: 1:1 제압, 골드 보너스
  goblinRing,

  // 마법 분기
  /// 만신전: 광역 디버프, 작두 타기
  shamanTemple,

  /// 저승사자 출장소: 즉사기
  grimReaperOffice,
}

/// 영웅 ID
enum HeroId {
  /// 깨비 (도깨비) - 탱커
  kkaebi,

  /// 미호 (구미호) - 마법 딜러
  miho,

  /// 강림 (저승차사) - 저격수
  gangrim,

  /// 수아 (물귀신) - CC/특수
  sua,

  /// 바리 (무당) - 서포터
  bari,
}

/// 영웅 진화 단계
enum EvolutionTier {
  /// 기본 (Lv 1)
  base,

  /// 중급 (Lv 5)
  intermediate,

  /// 궁극 (Lv 10)
  ultimate,
}

/// 게임 전체 상태
enum GamePhase {
  /// 메인 메뉴
  mainMenu,

  /// 스테이지 선택
  levelSelect,

  /// 게임 플레이 중
  playing,

  /// 일시정지
  paused,

  /// 승리
  victory,

  /// 패배
  defeat,
}

/// 챕터/지역
enum Chapter {
  /// 챕터 1: 굶주린 자들의 장터
  marketOfHunger,

  /// 챕터 2: 통곡하는 숲
  wailingWoods,

  /// 챕터 3: 얼굴 없는 숲
  facelessForest,
}

/// 적 종류 ID
enum EnemyId {
  // 챕터 1
  hungryGhost,
  strawShoeSpirit,
  burdenedLaborer,
  maidenGhost,
  eggGhost,
  bossOgreLord,

  // 챕터 2
  tigerSlave,
  fireDog,
  shadowGolem,
  oldFoxWoman,
  failedDragon,
  bossMountainLord,

  // 챕터 3
  changGwiEvolved,
  saetani,
  shadowChild,
  maliciousBird,
  faceStealerGhost,
  bossGreatEggGhost,
}

/// 스킬 타겟 타입
enum SkillTargetType {
  /// 단일 대상
  single,

  /// 범위 대상
  area,

  /// 자기 자신/아군
  self,

  /// 전체
  global,
}
