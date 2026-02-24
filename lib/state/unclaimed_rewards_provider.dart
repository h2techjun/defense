// 해원의 문 - 미수령 보상 알림 프로바이더
// 메인 메뉴 빨간 뱃지용 미수령 보상 체크

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'daily_quest_provider.dart';
import 'season_pass_provider.dart';
import 'achievement_provider.dart';

/// 미수령 보상 카운트
class UnclaimedRewards {
  final int dailyQuest;     // 미수령 일일 미션 보상
  final int seasonPass;     // 미수령 시즌 패스 보상
  final int achievements;   // 미수령 업적 보상

  const UnclaimedRewards({
    this.dailyQuest = 0,
    this.seasonPass = 0,
    this.achievements = 0,
  });

  /// 총 미수령 보상 수
  int get total => dailyQuest + seasonPass + achievements;

  /// 미수령 보상 존재 여부
  bool get hasAny => total > 0;

  /// 시스템별 미수령 여부
  bool get hasDailyQuest => dailyQuest > 0;
  bool get hasSeasonPass => seasonPass > 0;
  bool get hasAchievements => achievements > 0;
}

/// 미수령 보상 프로바이더
final unclaimedRewardsProvider = Provider<UnclaimedRewards>((ref) {
  // ── 일일 미션 : hasUnclaimedRewards 속성 활용 ──
  int dailyQuestUnclaimed = 0;
  try {
    final questState = ref.watch(dailyQuestProvider);
    if (questState.hasUnclaimedRewards) {
      // 미수령 개수 계산
      for (final q in questState.quests) {
        if (questState.isCompleted(q.id) && !questState.claimed.contains(q.id)) {
          dailyQuestUnclaimed++;
        }
      }
      if (questState.isAllMainCompleted && !questState.allClearClaimed) {
        dailyQuestUnclaimed++;
      }
      if (questState.claimableStreakDay != null) {
        dailyQuestUnclaimed++;
      }
    }
  } catch (_) {}

  // ── 시즌 패스 : 도달한 레벨 중 미수령 보상 카운트 ──
  int seasonPassUnclaimed = 0;
  try {
    final passState = ref.watch(seasonPassProvider);
    for (int lvl = 1; lvl <= passState.currentLevel; lvl++) {
      // 무료 트랙
      if (!passState.claimedFree.contains(lvl)) {
        seasonPassUnclaimed++;
      }
      // 프리미엄 트랙 (구매 시에만)
      if (passState.isPremiumPass && !passState.claimedPremium.contains(lvl)) {
        seasonPassUnclaimed++;
      }
    }
  } catch (_) {}

  // ── 업적 : unclaimedCount 속성 활용 ──
  int achievementUnclaimed = 0;
  try {
    final achState = ref.watch(achievementProvider);
    achievementUnclaimed = achState.unclaimedCount;
  } catch (_) {}

  return UnclaimedRewards(
    dailyQuest: dailyQuestUnclaimed,
    seasonPass: seasonPassUnclaimed,
    achievements: achievementUnclaimed,
  );
});
