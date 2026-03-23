// 해원의 문 — 영웅 대사 데이터베이스
// GDD §7.3 기반 — 5명 영웅의 상황별 대사

import 'models/bark_data.dart';
import '../../common/enums.dart';

/// GDD §7.3 영웅 대사 데이터
/// heroId는 HeroId enum의 name과 매칭
const List<BarkData> allBarkData = [
  // ─── 깨비 (도깨비) ───
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.bossAppear, lines: [
    'bark_kkaebi_boss_1',
    'bark_kkaebi_boss_2',
    'bark_kkaebi_boss_3',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.bossKill, lines: [
    'bark_kkaebi_kill_1',
    'bark_kkaebi_kill_2',
    'bark_kkaebi_kill_3',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.allyDanger, lines: [
    'bark_kkaebi_danger_1',
    'bark_kkaebi_danger_2',
    'bark_kkaebi_danger_3',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.nightTransition, lines: [
    'bark_kkaebi_night_1',
    'bark_kkaebi_night_2',
    'bark_kkaebi_night_3',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.ultimateUsed, lines: [
    'bark_kkaebi_skill_1',
    'bark_kkaebi_skill_2',
  ]),
  BarkData(heroId: 'kkaebi', trigger: BarkTrigger.battleStart, lines: [
    'bark_kkaebi_start_1',
    'bark_kkaebi_start_2',
  ]),

  // ─── 미호 (구미호) ───
  BarkData(heroId: 'miho', trigger: BarkTrigger.bossAppear, lines: [
    'bark_miho_boss_1',
    'bark_miho_boss_2',
    'bark_miho_boss_3',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.bossKill, lines: [
    'bark_miho_kill_1',
    'bark_miho_kill_2',
    'bark_miho_kill_3',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.allyDanger, lines: [
    'bark_miho_danger_1',
    'bark_miho_danger_2',
    'bark_miho_danger_3',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.nightTransition, lines: [
    'bark_miho_night_1',
    'bark_miho_night_2',
    'bark_miho_night_3',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.ultimateUsed, lines: [
    'bark_miho_skill_1',
    'bark_miho_skill_2',
  ]),
  BarkData(heroId: 'miho', trigger: BarkTrigger.battleStart, lines: [
    'bark_miho_start_1',
    'bark_miho_start_2',
  ]),

  // ─── 강림 (저승차사) ───
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.bossAppear, lines: [
    'bark_gangrim_boss_1',
    'bark_gangrim_boss_2',
    'bark_gangrim_boss_3',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.bossKill, lines: [
    'bark_gangrim_kill_1',
    'bark_gangrim_kill_2',
    'bark_gangrim_kill_3',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.allyDanger, lines: [
    'bark_gangrim_danger_1',
    'bark_gangrim_danger_2',
    'bark_gangrim_danger_3',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.nightTransition, lines: [
    'bark_gangrim_night_1',
    'bark_gangrim_night_2',
    'bark_gangrim_night_3',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.ultimateUsed, lines: [
    'bark_gangrim_skill_1',
    'bark_gangrim_skill_2',
  ]),
  BarkData(heroId: 'gangrim', trigger: BarkTrigger.battleStart, lines: [
    'bark_gangrim_start_1',
    'bark_gangrim_start_2',
  ]),

  // ─── 수아 (물귀신) ───
  BarkData(heroId: 'sua', trigger: BarkTrigger.bossAppear, lines: [
    'bark_sua_boss_1',
    'bark_sua_boss_2',
    'bark_sua_boss_3',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.bossKill, lines: [
    'bark_sua_kill_1',
    'bark_sua_kill_2',
    'bark_sua_kill_3',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.allyDanger, lines: [
    'bark_sua_danger_1',
    'bark_sua_danger_2',
    'bark_sua_danger_3',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.nightTransition, lines: [
    'bark_sua_night_1',
    'bark_sua_night_2',
    'bark_sua_night_3',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.ultimateUsed, lines: [
    'bark_sua_skill_1',
    'bark_sua_skill_2',
  ]),
  BarkData(heroId: 'sua', trigger: BarkTrigger.battleStart, lines: [
    'bark_sua_start_1',
    'bark_sua_start_2',
  ]),

  // ─── 바리 (바리공주/무녀) ───
  BarkData(heroId: 'bari', trigger: BarkTrigger.bossAppear, lines: [
    'bark_bari_boss_1',
    'bark_bari_boss_2',
    'bark_bari_boss_3',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.bossKill, lines: [
    'bark_bari_kill_1',
    'bark_bari_kill_2',
    'bark_bari_kill_3',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.allyDanger, lines: [
    'bark_bari_danger_1',
    'bark_bari_danger_2',
    'bark_bari_danger_3',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.nightTransition, lines: [
    'bark_bari_night_1',
    'bark_bari_night_2',
    'bark_bari_night_3',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.ultimateUsed, lines: [
    'bark_bari_skill_1',
    'bark_bari_skill_2',
  ]),
  BarkData(heroId: 'bari', trigger: BarkTrigger.battleStart, lines: [
    'bark_bari_start_1',
    'bark_bari_start_2',
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
