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

  /// 화포 타워 (돌팔매 → 투석기 → 화차/비격진천뢰)
  artillery,

  /// 솟대 타워 (원혼 자동정화 + 아군 버프)
  sotdae,
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

  // 화포 분기
  /// 화차: 화염 범위 공격 (DoT)
  fireDragon,

  /// 비격진천뢰: 단일 초고데미지 폭발
  heavenlyThunder,

  // 솟대 분기
  /// 수호신단: 디버프 면역 + 한 억제 50%
  phoenixTotem,

  /// 지신제단: 적 공격력 감소 + 감속 오라
  earthSpiritAltar,
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

  /// 챕터 4: 왕궁의 그림자
  shadowPalace,

  /// 챕터 5: 저승의 문턱
  thresholdOfDeath,
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

  // 챕터 4
  courtAssassin,
  corruptOfficial,
  royalGuardGhost,
  curseScribe,
  puppetDancer,
  bossTyrantKing,

  // 챕터 5
  underworldMessenger,
  wailingBanshee,
  boneGolem,
  soulChainGhost,
  infernoSpirit,
  bossGatekeeper,
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

/// 인터랙티브 맵 오브젝트 타입 (GDD 7.2)
enum MapObjectType {
  /// 성황당: 범위 내 적 이속 -30% (50 신명)
  shrine,

  /// 오래된 우물: 정화 시 물귀신 미등장 (30 신명)
  oldWell,

  /// 횃불: 안개 해제, 은신 감지 (20 신명)
  torch,

  /// 솟대 (맵 고정): 범위 내 원혼 자동 정화 (40 신명)
  mapSotdae,

  /// 봉분: 정화 시 아군 유령 소환 20초 (60 신명)
  tomb,

  /// 당산나무: 밤→낮 강제 전환 1회용 (무료)
  sacredTree,
}

/// 게임 모드
enum GameMode {
  /// 캠페인 (스토리 모드)
  campaign,

  /// 무한의 탑 (엔드게임 모드)
  endlessTower,

  /// 일일 도전
  dailyChallenge,
}
