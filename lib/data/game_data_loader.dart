// 해원의 문 - 게임 데이터 로더
// 모든 영웅, 적, 타워, 웨이브 데이터를 하드코딩으로 정의합니다.
// (향후 JSON 파일에서 로딩하도록 전환 가능)

import '../common/enums.dart';
import 'models/hero_data.dart';
import 'models/enemy_data.dart';
import 'models/tower_data.dart';
import 'models/wave_data.dart';

/// 게임 데이터 레지스트리
class GameDataLoader {
  GameDataLoader._();

  // ──────────────────────────────
  // 영웅 데이터
  // ──────────────────────────────
  static final Map<HeroId, HeroData> heroes = {
    HeroId.kkaebi: const HeroData(
      id: HeroId.kkaebi,
      name: '깨비',
      title: '씨름왕 도깨비',
      backstory: '낡은 빗자루에 깃든 도깨비 영혼. 씨름으로 악귀를 제압한다.',
      baseHp: 500,
      baseAttack: 25,
      baseSpeed: 60,
      baseRange: 40,
      damageType: DamageType.physical,
      skill: HeroSkillData(
        name: '뒤집기 (Suplex)',
        description: '적을 들어 뒤로 넘겨버립니다 (넉백).',
        cooldown: 12,
        damage: 80,
        range: 50,
        targetType: SkillTargetType.single,
        damageType: DamageType.physical,
      ),
      evolutions: [
        HeroEvolutionData(
          tier: EvolutionTier.base,
          visualName: '장난꾸러기 깨비',
          description: '낡은 짚신을 신고 몽당 빗자루를 든 모습.',
        ),
        HeroEvolutionData(
          tier: EvolutionTier.intermediate,
          visualName: '씨름꾼 깨비',
          description: '덩치가 커지고 근육질, 샅바를 맴.',
          hpMultiplier: 1.5,
          attackMultiplier: 1.3,
        ),
        HeroEvolutionData(
          tier: EvolutionTier.ultimate,
          visualName: '대왕 도깨비',
          description: '호랑이 가죽을 두르고 도깨비 감투를 쓴 모습. 은신 기습.',
          hpMultiplier: 2.5,
          attackMultiplier: 2.0,
          rangeMultiplier: 1.3,
        ),
      ],
      barks: {
        'deploy': '씨름판 열었다! 붙어볼 테면 붙어봐!',
        'skill': '어라? 이거 무겁나? 안 무거운데!',
        'idle': '심심하다... 누가 씨름 한판 안 할래?',
        'boss': '어이 형씨, 뿔 관리가 엉망이네?',
      },
    ),

    HeroId.miho: const HeroData(
      id: HeroId.miho,
      name: '미호',
      title: '천년의 유혹 구미호',
      backstory: '인간이 되고 싶어 하는 구미호. 여우불로 악귀를 태운다.',
      baseHp: 250,
      baseAttack: 55,
      baseSpeed: 70,
      baseRange: 150,
      damageType: DamageType.magical,
      skill: HeroSkillData(
        name: '여우구슬 (FoxFire)',
        description: '에너지를 모아 발사. 적의 정기를 흡수해 마나 회복.',
        cooldown: 15,
        damage: 120,
        range: 180,
        duration: 3,
        targetType: SkillTargetType.area,
        damageType: DamageType.magical,
      ),
      evolutions: [
        HeroEvolutionData(
          tier: EvolutionTier.base,
          visualName: '여우 소녀',
          description: '꼬리가 1개인 귀여운 여우 소녀.',
        ),
        HeroEvolutionData(
          tier: EvolutionTier.intermediate,
          visualName: '요염한 여인',
          description: '꼬리가 5개, 푸른 여우불을 던진다.',
          attackMultiplier: 1.6,
          rangeMultiplier: 1.2,
        ),
        HeroEvolutionData(
          tier: EvolutionTier.ultimate,
          visualName: '구미호',
          description: '9개의 꼬리. 적 체력 % 단위 감소.',
          attackMultiplier: 2.5,
          rangeMultiplier: 1.5,
        ),
      ],
      barks: {
        'deploy': '내 불꽃은 따뜻해. 적들에겐 좀 뜨겁겠지만!',
        'skill': '여우비가 내린다~♪',
        'idle': '인간이 되면 제일 먼저 떡볶이를 먹을 거야.',
      },
    ),

    HeroId.gangrim: const HeroData(
      id: HeroId.gangrim,
      name: '강림',
      title: '저승차사',
      backstory: '검은 갓과 도포를 입은 관료적인 죽음의 인도자.',
      baseHp: 200,
      baseAttack: 80,
      baseSpeed: 50,
      baseRange: 250,
      damageType: DamageType.purification,
      skill: HeroSkillData(
        name: '호명 (Calling Name)',
        description: '적의 이름을 불러 체력 30% 이하 적 즉사.',
        cooldown: 20,
        damage: 9999,
        range: 300,
        targetType: SkillTargetType.single,
        damageType: DamageType.purification,
      ),
      evolutions: [
        HeroEvolutionData(
          tier: EvolutionTier.base,
          visualName: '신입 차사',
          description: '허름한 두루마기. 명부가 찢어져 있음.',
        ),
        HeroEvolutionData(
          tier: EvolutionTier.intermediate,
          visualName: '정식 차사',
          description: '검은 갓과 두루마기. 사거리 대폭 증가.',
          attackMultiplier: 1.4,
          rangeMultiplier: 1.5,
        ),
        HeroEvolutionData(
          tier: EvolutionTier.ultimate,
          visualName: '염라대왕의 대리인',
          description: '검은 오라. 적 영혼을 자원으로 환원.',
          attackMultiplier: 2.2,
          rangeMultiplier: 1.8,
        ),
      ],
      barks: {
        'deploy': '명부에 이름이 적혀 있으니... 피할 수 없다.',
        'skill': '이름 석 자, 다시 한번 부르겠다.',
        'boss': '호적에서 이름 좀 지우겠다.',
      },
    ),

    HeroId.sua: const HeroData(
      id: HeroId.sua,
      name: '수아',
      title: '물귀신',
      backstory: '물속으로 사람을 끌어당기는 비극적 영혼.',
      baseHp: 300,
      baseAttack: 15,
      baseSpeed: 65,
      baseRange: 120,
      damageType: DamageType.magical,
      skill: HeroSkillData(
        name: '발목 잡기 (Water Grasp)',
        description: '바닥에서 젖은 손들이 올라와 적 이동속도 90% 감소.',
        cooldown: 18,
        damage: 20,
        range: 150,
        duration: 4,
        targetType: SkillTargetType.area,
        damageType: DamageType.magical,
      ),
      evolutions: [
        HeroEvolutionData(
          tier: EvolutionTier.base,
          visualName: '물에 젖은 처녀',
          description: '소복을 입은 처녀. 머리카락으로 적을 건드림.',
        ),
        HeroEvolutionData(
          tier: EvolutionTier.intermediate,
          visualName: '늪의 주인',
          description: '주변을 늪지대로 만들어 광역 슬로우.',
          rangeMultiplier: 1.5,
        ),
        HeroEvolutionData(
          tier: EvolutionTier.ultimate,
          visualName: '심해의 원한',
          description: '거대한 물기둥으로 적을 시작 지점으로 송환.',
          attackMultiplier: 1.5,
          rangeMultiplier: 2.0,
        ),
      ],
      barks: {
        'deploy': '...같이 물속에 들어가지 않을래?',
        'skill': '발이 차갑지? 후훗...',
        'idle': '혼자는 외로워... 친구 좀 만들어야지.',
      },
    ),

    HeroId.bari: const HeroData(
      id: HeroId.bari,
      name: '바리',
      title: '무당 바리데기',
      backstory: '버려진 공주. 씻김굿으로 죽은 자를 위로한다.',
      baseHp: 280,
      baseAttack: 10,
      baseSpeed: 55,
      baseRange: 130,
      damageType: DamageType.purification,
      skill: HeroSkillData(
        name: '작두 타기 (Ritual)',
        description: '춤을 추며 주변 아군 공격속도 2배.',
        cooldown: 25,
        damage: 0,
        range: 200,
        duration: 5,
        targetType: SkillTargetType.area,
        damageType: DamageType.purification,
      ),
      evolutions: [
        HeroEvolutionData(
          tier: EvolutionTier.base,
          visualName: '꼬마 무녀',
          description: '방울과 부채를 든 꼬마.',
        ),
        HeroEvolutionData(
          tier: EvolutionTier.intermediate,
          visualName: '만신',
          description: '오방색 옷. 타워 체력 회복.',
          hpMultiplier: 1.4,
          rangeMultiplier: 1.3,
        ),
        HeroEvolutionData(
          tier: EvolutionTier.ultimate,
          visualName: '강신',
          description: '신이 내려 아군 전체 무적 3초.',
          hpMultiplier: 2.0,
          rangeMultiplier: 1.8,
        ),
      ],
      barks: {
        'deploy': '씻김굿을 시작하겠습니다.',
        'skill': '에이~ 얼쑤~ 좋다!',
        'idle': '꽃이 피면 모든 한이 풀리겠지요.',
      },
    ),
  };

  // ──────────────────────────────
  // 적 데이터
  // ──────────────────────────────
  static final Map<EnemyId, EnemyData> enemies = {
    // ── 챕터 1: 굶주린 자들의 장터 ──
    EnemyId.hungryGhost: const EnemyData(
      id: EnemyId.hungryGhost,
      name: '아귀',
      description: '배가 산만하고 입이 찢어진 귀신. 죽을 때 마나를 훔침.',
      chapter: Chapter.marketOfHunger,
      hp: 100,
      speed: 55,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 10,
      evasion: 0.1,
      abilities: [
        EnemyAbility(name: '마나 흡수', description: '죽을 때 3 신명 감소', value: 3),
      ],
    ),
    EnemyId.strawShoeSpirit: const EnemyData(
      id: EnemyId.strawShoeSpirit,
      name: '짚신 귀신',
      description: '낡은 짚신 떼. 빠르지만 허약.',
      chapter: Chapter.marketOfHunger,
      hp: 40,
      speed: 90,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 5,
      evasion: 0.3,
    ),
    EnemyId.burdenedLaborer: const EnemyData(
      id: EnemyId.burdenedLaborer,
      name: '무지기 (짐진 머슴)',
      description: '무거운 짐을 진 머슴 귀신. 느리지만 단단.',
      chapter: Chapter.marketOfHunger,
      hp: 350,
      speed: 30,
      armorType: ArmorType.physical,
      sinmyeongReward: 20,
      deathSpawnId: EnemyId.hungryGhost,
      deathSpawnCount: 3,
      abilities: [
        EnemyAbility(name: '짐 폭발', description: '죽으면 아귀 3마리 스폰'),
      ],
    ),
    EnemyId.maidenGhost: const EnemyData(
      id: EnemyId.maidenGhost,
      name: '손각시 (처녀귀신)',
      description: '공중 부유. 비명으로 타워 공속 50% 감소.',
      chapter: Chapter.marketOfHunger,
      hp: 120,
      speed: 50,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 15,
      isFlying: true,
      evasion: 0.2,
      abilities: [
        EnemyAbility(
          name: '비명',
          description: '주변 타워 공격속도 50% 감소',
          value: 0.5,
          duration: 3,
        ),
      ],
    ),
    EnemyId.eggGhost: const EnemyData(
      id: EnemyId.eggGhost,
      name: '달걀귀신',
      description: '얼굴 없는 귀신. 영웅이 길을 막아야 모습이 드러남.',
      chapter: Chapter.marketOfHunger,
      hp: 150,
      speed: 45,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 15,
      evasion: 0.4,
      abilities: [
        EnemyAbility(name: '은신', description: '영웅이 차단하기 전까지 공격 불가'),
      ],
    ),
    EnemyId.bossOgreLord: const EnemyData(
      id: EnemyId.bossOgreLord,
      name: '두억시니',
      description: '붉은 머리카락과 뿔. 땅을 내려쳐 전체 기절.',
      chapter: Chapter.marketOfHunger,
      hp: 3000,
      speed: 25,
      attack: 50,
      armorType: ArmorType.yokai,
      sinmyeongReward: 200,
      isBoss: true,
      abilities: [
        EnemyAbility(
          name: '지진',
          description: '모든 지상 유닛 기절',
          duration: 2,
        ),
      ],
    ),

    // ── 챕터 2: 통곡하는 숲 ──
    EnemyId.tigerSlave: const EnemyData(
      id: EnemyId.tigerSlave,
      name: '창귀',
      description: '호랑이에게 물려 죽은 귀신. 피격 시 호랑이 소환.',
      chapter: Chapter.wailingWoods,
      hp: 130,
      speed: 60,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 12,
      abilities: [
        EnemyAbility(name: '호랑이 소환', description: '피격 시 호랑이 영물 돌진', value: 0.2),
      ],
    ),
    EnemyId.fireDog: const EnemyData(
      id: EnemyId.fireDog,
      name: '불개',
      description: '온몸이 불타는 개. 비행. 타워에 화상.',
      chapter: Chapter.wailingWoods,
      hp: 100,
      speed: 80,
      armorType: ArmorType.yokai,
      sinmyeongReward: 15,
      isFlying: true,
      abilities: [
        EnemyAbility(name: '불붙이기', description: '타워에 DoT 피해', value: 5, duration: 3),
      ],
    ),
    EnemyId.shadowGolem: const EnemyData(
      id: EnemyId.shadowGolem,
      name: '그슨대',
      description: '그림자 덩어리. 물리 공격 무시.',
      chapter: Chapter.wailingWoods,
      hp: 400,
      speed: 30,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 25,
      abilities: [
        EnemyAbility(name: '물리 면역', description: '물리 공격 0 데미지'),
      ],
    ),
    EnemyId.oldFoxWoman: const EnemyData(
      id: EnemyId.oldFoxWoman,
      name: '노구화호',
      description: '할머니로 변신한 늙은 여우. 영웅을 현혹.',
      chapter: Chapter.wailingWoods,
      hp: 160,
      speed: 50,
      armorType: ArmorType.yokai,
      sinmyeongReward: 18,
      abilities: [
        EnemyAbility(name: '현혹', description: '영웅이 아군 타워를 공격', duration: 3),
      ],
    ),
    EnemyId.failedDragon: const EnemyData(
      id: EnemyId.failedDragon,
      name: '강철이 (이무기)',
      description: '용이 되지 못한 이무기. 초고속 돌격.',
      chapter: Chapter.wailingWoods,
      hp: 250,
      speed: 120,
      armorType: ArmorType.yokai,
      sinmyeongReward: 25,
      abilities: [
        EnemyAbility(name: '독구름', description: '지나간 자리에 독 지대', value: 10, duration: 5),
      ],
    ),
    EnemyId.bossMountainLord: const EnemyData(
      id: EnemyId.bossMountainLord,
      name: '산군 (호랑이 영물)',
      description: '집채만한 호랑이. 포효로 안개를 소환.',
      chapter: Chapter.wailingWoods,
      hp: 5000,
      speed: 20,
      attack: 80,
      armorType: ArmorType.physical,
      sinmyeongReward: 300,
      isBoss: true,
      abilities: [
        EnemyAbility(name: '포효', description: '안개 소환: 타워 사거리 50% 감소', duration: 8),
        EnemyAbility(name: '창귀 소환', description: '창귀 3마리 소환', value: 3),
      ],
    ),

    // ── 챕터 3: 얼굴 없는 숲 ──
    EnemyId.changGwiEvolved: const EnemyData(
      id: EnemyId.changGwiEvolved,
      name: '육혼',
      description: '진화한 창귀. 타워를 유혹.',
      chapter: Chapter.facelessForest,
      hp: 200,
      speed: 55,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 15,
      abilities: [
        EnemyAbility(name: '유혹', description: '타워 3초간 작동 불능', duration: 3),
      ],
    ),
    EnemyId.saetani: const EnemyData(
      id: EnemyId.saetani,
      name: '새타니',
      description: '낡은 바구니를 쓴 아이. 공중 비행.',
      chapter: Chapter.facelessForest,
      hp: 80,
      speed: 85,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 8,
      isFlying: true,
      evasion: 0.3,
    ),
    EnemyId.shadowChild: const EnemyData(
      id: EnemyId.shadowChild,
      name: '태자귀',
      description: '아이 신. 랜덤 타워에 불운(빗나감 50%).',
      chapter: Chapter.facelessForest,
      hp: 150,
      speed: 50,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 15,
      abilities: [
        EnemyAbility(name: '점괘', description: '타워 공격 빗나감 50%', value: 0.5, duration: 5),
      ],
    ),
    EnemyId.maliciousBird: const EnemyData(
      id: EnemyId.maliciousBird,
      name: '새우니 (괴조)',
      description: '아이 얼굴을 한 거대한 새. 광역 스턴.',
      chapter: Chapter.facelessForest,
      hp: 300,
      speed: 70,
      armorType: ArmorType.yokai,
      sinmyeongReward: 30,
      isFlying: true,
      abilities: [
        EnemyAbility(name: '비명', description: '광역 스턴 + 깃털 데미지', value: 30, duration: 2),
      ],
    ),
    EnemyId.faceStealerGhost: const EnemyData(
      id: EnemyId.faceStealerGhost,
      name: '무면귀',
      description: '얼굴을 훔치는 귀신. 타워 속성 면역 복제.',
      chapter: Chapter.facelessForest,
      hp: 250,
      speed: 40,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 20,
      evasion: 0.3,
      abilities: [
        EnemyAbility(name: '복제', description: '피격 타워 속성에 면역 획득'),
      ],
    ),
    EnemyId.bossGreatEggGhost: const EnemyData(
      id: EnemyId.bossGreatEggGhost,
      name: '대왕 달걀귀신',
      description: '거대한 알 모양. 영웅 스킬을 복제 반사.',
      chapter: Chapter.facelessForest,
      hp: 6000,
      speed: 18,
      attack: 60,
      armorType: ArmorType.spiritual,
      sinmyeongReward: 400,
      isBoss: true,
      evasion: 0.3,
      abilities: [
        EnemyAbility(name: '스킬 반사', description: '영웅 스킬을 복제하여 반사'),
        EnemyAbility(name: '흡수', description: '아군 병사를 삼켜 적으로 변환', value: 1),
      ],
    ),
  };

  // ──────────────────────────────
  // 타워 데이터
  // ──────────────────────────────
  static final Map<TowerType, TowerData> towers = {
    TowerType.archer: const TowerData(
      type: TowerType.archer,
      name: '산적 초소',
      description: '빠른 연사. 공중 유닛 요격 특화.',
      baseCost: 70,
      baseDamage: 15,
      baseRange: 150,
      baseFireRate: 1.5,
      damageType: DamageType.physical,
      branchA: TowerBranch.rocketBattery,
      branchB: TowerBranch.spiritHunter,
      upgrades: [
        TowerUpgradeData(level: 1, name: '산적 초소', cost: 0, damage: 15, range: 150, fireRate: 1.5),
        TowerUpgradeData(level: 2, name: '의병 망루', cost: 100, damage: 25, range: 170, fireRate: 1.8),
        TowerUpgradeData(level: 3, name: '호국 망루', cost: 160, damage: 40, range: 200, fireRate: 2.0),
      ],
    ),
    TowerType.barracks: const TowerData(
      type: TowerType.barracks,
      name: '씨름터',
      description: '병사 3명을 소환하여 길목 차단 (Blocking).',
      baseCost: 90,
      baseDamage: 10,
      baseRange: 80,
      baseFireRate: 0.8,
      damageType: DamageType.physical,
      branchA: TowerBranch.generalTotem,
      branchB: TowerBranch.goblinRing,
      upgrades: [
        TowerUpgradeData(level: 1, name: '씨름터', cost: 0, damage: 10, range: 80, fireRate: 0.8),
        TowerUpgradeData(level: 2, name: '무관청', cost: 120, damage: 18, range: 90, fireRate: 1.0),
        TowerUpgradeData(level: 3, name: '수호 전당', cost: 200, damage: 28, range: 100, fireRate: 1.2),
      ],
    ),
    TowerType.shaman: const TowerData(
      type: TowerType.shaman,
      name: '서당',
      description: '광역 마법/정화. 고방어 적에게 관통.',
      baseCost: 100,
      baseDamage: 30,
      baseRange: 120,
      baseFireRate: 0.6,
      damageType: DamageType.magical,
      branchA: TowerBranch.shamanTemple,
      branchB: TowerBranch.grimReaperOffice,
      upgrades: [
        TowerUpgradeData(level: 1, name: '서당', cost: 0, damage: 30, range: 120, fireRate: 0.6),
        TowerUpgradeData(level: 2, name: '부적집', cost: 140, damage: 50, range: 140, fireRate: 0.7),
        TowerUpgradeData(level: 3, name: '신당', cost: 220, damage: 75, range: 160, fireRate: 0.8, specialAbility: '정화 가능'),
      ],
    ),
  };

  // ──────────────────────────────
  // 챕터 1: 웨이브 데이터
  // ──────────────────────────────
  static final LevelData chapter1Level1 = LevelData(
    levelNumber: 1,
    chapter: Chapter.marketOfHunger,
    name: '덕대골의 비명',
    briefing: '굶주린 영혼들이 장터에 깨어났습니다. 해원문을 지키십시오.',
    startingSinmyeong: 200,
    gatewayHp: 20,
    path: [
      [0, 4], [2, 4], [2, 2], [5, 2], [5, 6], [8, 6],
      [8, 3], [11, 3], [11, 5], [14, 5],
    ],
    waves: [
      // 웨이브 1: 튜토리얼 - 기본적
      const WaveData(
        waveNumber: 1,
        dayCycle: DayCycle.day,
        narrative: '"굶주린 자들이 장터로 몰려오고 있다..."',
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.hungryGhost, count: 5, spawnInterval: 2.0),
        ],
      ),
      // 웨이브 2: 빠른 적
      const WaveData(
        waveNumber: 2,
        dayCycle: DayCycle.day,
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.hungryGhost, count: 3, spawnInterval: 1.5),
          SpawnGroup(enemyId: EnemyId.strawShoeSpirit, count: 8, spawnInterval: 0.8, startDelay: 3),
        ],
      ),
      // 웨이브 3: 탱커 등장
      const WaveData(
        waveNumber: 3,
        dayCycle: DayCycle.day,
        narrative: '"무거운 발소리가 들린다..."',
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.burdenedLaborer, count: 2, spawnInterval: 5),
          SpawnGroup(enemyId: EnemyId.hungryGhost, count: 5, spawnInterval: 1.2, startDelay: 2),
        ],
      ),
      // 웨이브 4: 밤으로 전환! 영혼형 다수
      const WaveData(
        waveNumber: 4,
        dayCycle: DayCycle.night,
        narrative: '"날이 저문다. 귀신들이 깨어난다..."',
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.maidenGhost, count: 3, spawnInterval: 3),
          SpawnGroup(enemyId: EnemyId.eggGhost, count: 4, spawnInterval: 2, startDelay: 5),
        ],
      ),
      // 웨이브 5: 혼합 웨이브
      const WaveData(
        waveNumber: 5,
        dayCycle: DayCycle.night,
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.strawShoeSpirit, count: 12, spawnInterval: 0.6),
          SpawnGroup(enemyId: EnemyId.maidenGhost, count: 2, spawnInterval: 4, startDelay: 3),
          SpawnGroup(enemyId: EnemyId.burdenedLaborer, count: 1, spawnInterval: 1, startDelay: 8),
        ],
      ),
      // 웨이브 6: 다시 낮
      const WaveData(
        waveNumber: 6,
        dayCycle: DayCycle.day,
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.burdenedLaborer, count: 3, spawnInterval: 4),
          SpawnGroup(enemyId: EnemyId.hungryGhost, count: 8, spawnInterval: 1.0, startDelay: 2),
        ],
      ),
      // 웨이브 7: 달걀귀신 은신 웨이브
      const WaveData(
        waveNumber: 7,
        dayCycle: DayCycle.night,
        narrative: '"얼굴 없는 것들이 다가옵니다..."',
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.eggGhost, count: 6, spawnInterval: 2),
          SpawnGroup(enemyId: EnemyId.strawShoeSpirit, count: 10, spawnInterval: 0.5, startDelay: 5),
        ],
      ),
      // 웨이브 8: 라쉬
      const WaveData(
        waveNumber: 8,
        dayCycle: DayCycle.day,
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.hungryGhost, count: 10, spawnInterval: 0.8),
          SpawnGroup(enemyId: EnemyId.burdenedLaborer, count: 3, spawnInterval: 3, startDelay: 4),
          SpawnGroup(enemyId: EnemyId.maidenGhost, count: 3, spawnInterval: 3, startDelay: 8),
        ],
      ),
      // 웨이브 9: 보스 전초
      const WaveData(
        waveNumber: 9,
        dayCycle: DayCycle.night,
        narrative: '"땅이 울리기 시작한다..."',
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.eggGhost, count: 4, spawnInterval: 1.5),
          SpawnGroup(enemyId: EnemyId.maidenGhost, count: 4, spawnInterval: 2, startDelay: 3),
          SpawnGroup(enemyId: EnemyId.burdenedLaborer, count: 2, spawnInterval: 4, startDelay: 6),
        ],
      ),
      // 웨이브 10: 보스
      const WaveData(
        waveNumber: 10,
        dayCycle: DayCycle.night,
        narrative: '"두억시니가 나타났다! 해원문을 지켜라!"',
        spawnGroups: [
          SpawnGroup(enemyId: EnemyId.bossOgreLord, count: 1, spawnInterval: 1),
          SpawnGroup(enemyId: EnemyId.hungryGhost, count: 6, spawnInterval: 2, startDelay: 5),
          SpawnGroup(enemyId: EnemyId.strawShoeSpirit, count: 10, spawnInterval: 0.5, startDelay: 10),
        ],
      ),
    ],
  );
}
