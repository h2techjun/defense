// 해원의 문 - 게임 이벤트 ↔ Provider 브릿지
// 게임 이벤트(kill, clear, build, skill)를 업적/시즌패스/VIP/랭킹에 연결
// 성능: kill/skill 이벤트는 배치 처리, 나머지는 즉시 처리

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enums.dart';
import '../state/season_pass_provider.dart';
import '../state/achievement_provider.dart';
import '../state/endless_tower_provider.dart';
import '../state/skin_provider.dart';
import '../state/relic_provider.dart';

/// 게임 이벤트 → Provider 연결 브릿지
/// DefenseGame에서 단일 진입점으로 호출
class GameEventBridge {
  final Ref _ref;

  // ── 배치 누적 카운터 (성능 보호) ──
  int _batchKills = 0;
  int _batchBossKills = 0;
  int _batchSkillUses = 0;
  int _batchTowerBuilds = 0;

  GameEventBridge(this._ref);

  // ═══════════════════════════════════════════
  // 1. 적 처치 이벤트 (고빈도 → 배치 처리)
  // ═══════════════════════════════════════════

  /// 적 처치 시 호출 (매 프레임 다수 발생 가능)
  void onEnemyKilled({bool isBoss = false}) {
    _batchKills++;
    if (isBoss) _batchBossKills++;
  }

  // ═══════════════════════════════════════════
  // 2. 스킬 사용 (중빈도 → 배치 처리)
  // ═══════════════════════════════════════════

  /// 영웅 스킬 사용 시 호출
  void onSkillUsed() {
    _batchSkillUses++;
  }

  // ═══════════════════════════════════════════
  // 3. 타워 건설 (중빈도 → 배치 처리)
  // ═══════════════════════════════════════════

  /// 타워 건설 시 호출
  void onTowerBuilt() {
    _batchTowerBuilds++;
  }

  // ═══════════════════════════════════════════
  // 배치 플러시 — 1초 주기로 defense_game.dart에서 호출
  // ═══════════════════════════════════════════

  void flushBatch() {
    if (_batchKills <= 0 && _batchBossKills <= 0 
        && _batchSkillUses <= 0 && _batchTowerBuilds <= 0) return;

    // 배치 업데이트 맵 구성 (1회 Map 복사 + 1회 persist)
    final updates = <String, int>{};

    if (_batchKills > 0) {
      updates['kill_100'] = _batchKills;
      updates['kill_1000'] = _batchKills;
      updates['kill_10000'] = _batchKills;
    }

    if (_batchBossKills > 0) {
      updates['boss_kill_10'] = _batchBossKills;
    }

    if (_batchSkillUses > 0) {
      updates['skill_100'] = _batchSkillUses;
    }

    if (_batchTowerBuilds > 0) {
      updates['build_50'] = _batchTowerBuilds;
    }

    // 단일 배치 호출 (Map 복사 1회 + state.copyWith 1회 + persist 1회)
    _ref.read(achievementProvider.notifier).batchIncrementProgress(updates);

    // 배치 초기화
    _batchKills = 0;
    _batchBossKills = 0;
    _batchSkillUses = 0;
    _batchTowerBuilds = 0;
  }

  // ═══════════════════════════════════════════
  // 4. 스테이지 클리어 (승리 시 1회)
  // ═══════════════════════════════════════════

  /// 스테이지 클리어 시 호출
  void onStageClear({
    required int chapter,
    required int stageNum,
    required int gatewayHp,
    required int maxGatewayHp,
  }) {
    // 시즌 패스 XP 추가 (챕터/스테이지 기반)
    final passXp = (chapter * 5 + stageNum * 3 + 10).clamp(15, 45);
    _ref.read(seasonPassProvider.notifier).addXp(passXp);

    // 피해 0 클리어 업적
    if (gatewayHp >= maxGatewayHp) {
      _ref.read(achievementProvider.notifier).incrementProgress('no_damage_clear');
    }

    // 스토리 업적 (에피소드 클리어 — 최종 스테이지만)
    final epId = 'clear_ep${chapter + 1}';
    _ref.read(achievementProvider.notifier).setProgress(epId, 1);

    // 남은 배치 이벤트도 플러시
    flushBatch();
  }

  // ═══════════════════════════════════════════
  // 5. 무한의 탑 층 클리어
  // ═══════════════════════════════════════════

  /// 무한의 탑 층 클리어 시 호출
  void onEndlessTowerFloorClear(int floor, {HeroId? heroId}) {
    // 탑 업적 (최고 기록 기준)
    final achieveNotifier = _ref.read(achievementProvider.notifier);
    achieveNotifier.setProgress('tower_floor_10', floor);
    achieveNotifier.setProgress('tower_floor_50', floor);
    achieveNotifier.setProgress('tower_floor_100', floor);

    // 시즌 패스 XP (층당 2XP)
    _ref.read(seasonPassProvider.notifier).addXp(2);

    // 랭킹 업데이트
    _ref.read(rankingProvider.notifier).addTowerRecord(floor, heroId);
  }

  // ═══════════════════════════════════════════
  // 6. 일일 도전 완료
  // ═══════════════════════════════════════════

  /// 일일 도전 완료 시 호출
  void onDailyChallengeComplete(int wavesSurvived, {HeroId? heroId}) {
    final challengeState = _ref.read(dailyChallengeProvider);
    final newStreak = challengeState.streak + 1;

    // 도전 업적 (연속 참여)
    final achieveNotifier = _ref.read(achievementProvider.notifier);
    achieveNotifier.setProgress('daily_streak_7', newStreak);
    achieveNotifier.setProgress('daily_streak_30', newStreak);

    // 시즌 패스 XP (일일 도전 보너스)
    _ref.read(seasonPassProvider.notifier).addXp(15);

    // 랭킹 업데이트
    _ref.read(rankingProvider.notifier).addDailyRecord(wavesSurvived, heroId);
  }

  // ═══════════════════════════════════════════
  // 7. 영웅 레벨업
  // ═══════════════════════════════════════════

  /// 영웅 레벨업 시 호출
  void onHeroLevelUp(int newLevel, int totalHeroesUsed) {
    final achieveNotifier = _ref.read(achievementProvider.notifier);
    achieveNotifier.setProgress('hero_lv10', newLevel);
    achieveNotifier.setProgress('hero_lv30', newLevel);
    achieveNotifier.setProgress('all_heroes', totalHeroesUsed);
  }

  // ═══════════════════════════════════════════
  // 8. 수집 이벤트 (스킨/유물 획득)
  // ═══════════════════════════════════════════

  /// 스킨 획득 시 호출
  void onSkinUnlocked() {
    final skinCount = _ref.read(skinProvider).ownedSkins.length;
    _ref.read(achievementProvider.notifier).setProgress('skins_5', skinCount);
  }

  /// 유물 획득 시 호출
  void onRelicUnlocked() {
    final relicCount = _ref.read(relicProvider).unlockedRelics.length;
    final achieveNotifier = _ref.read(achievementProvider.notifier);
    achieveNotifier.setProgress('relics_5', relicCount);
    achieveNotifier.setProgress('all_relics', relicCount);
  }

  // ═══════════════════════════════════════════
  // 9. 결제 이벤트 (VIP 연동)
  // ═══════════════════════════════════════════

  /// 결제 완료 시 호출 (VIP 등급 자동 갱신)
  void onPurchaseComplete(int amountKRW) {
    _ref.read(vipProvider.notifier).addPurchase(amountKRW);
  }
}

/// GameEventBridge Provider
final gameEventBridgeProvider = Provider<GameEventBridge>((ref) {
  return GameEventBridge(ref);
});
