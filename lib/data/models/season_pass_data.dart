// 해원의 문 - 시즌 패스 + 상점 데이터 모델
// 밸런스 v2: 광고 수익 중심 + 소액결제(₩1K~₩3K) + 최대 ₩10K
// VIP 등급, 소액 패키지, 구매 제한 포함

import 'package:flutter/material.dart';


// ═══════════════════════════════════════════
// 시즌 패스
// ═══════════════════════════════════════════

/// 시즌 패스 보상 유형
enum PassRewardType {
  gems,          // 보석
  gold,          // 골드
  heroXp,        // 영웅 경험치
  skin,          // 스킨 해금
  relic,         // 유물 해금
  summonTicket,  // 소환권
  towerUpgrade,  // 타워 강화 재료
  title,         // 칭호
  emote,         // 이모트
  frame,         // 프로필 프레임
}

/// 시즌 패스 보상 데이터
class PassReward {
  final int level;               // 어떤 레벨에서 획득
  final PassRewardType type;
  final String name;
  final String emoji;
  final int amount;              // 획득량 (보석/골드/경험치)
  final bool isPremium;          // true = 유료 트랙 전용
  final String? unlockId;        // 스킨/유물 ID (해금형 보상)

  const PassReward({
    required this.level,
    required this.type,
    required this.name,
    required this.emoji,
    this.amount = 1,
    this.isPremium = false,
    this.unlockId,
  });
}

/// 시즌 정보
class SeasonInfo {
  final int seasonNumber;
  final String title;             // "시즌 1: 원혼의 봄"
  final String theme;
  final DateTime startDate;
  final DateTime endDate;
  final int maxLevel;             // 최대 레벨 (50)
  final List<PassReward> rewards; // 전체 보상 목록

  const SeasonInfo({
    required this.seasonNumber,
    required this.title,
    required this.theme,
    required this.startDate,
    required this.endDate,
    this.maxLevel = 50,
    required this.rewards,
  });

  /// 레벨별 필요 XP (점진적 증가: 80 + level × 5)
  /// Lv1=85, Lv10=130, Lv25=205, Lv40=280, Lv50=330
  /// 총 필요 XP ≈ 10,225 (55일 만렙 목표, 20시즌 장기 운영 대비)
  int xpForLevel(int level) => 80 + (level * 5);

  /// 전체 필요 XP 합계 (Lv1→50 ≈ 10,225)
  int get totalXpRequired {
    int total = 0;
    for (int i = 1; i < maxLevel; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  /// 시즌 종료까지 남은 일수
  int get daysRemaining {
    final now = DateTime.now();
    return endDate.difference(now).inDays.clamp(0, 999);
  }

  /// 시즌 활성 여부
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

/// 시즌 1 데이터 (50레벨, 3개월)
final SeasonInfo season1 = SeasonInfo(
  seasonNumber: 1,
  title: '시즌 1: 원혼의 봄',
  theme: '벚꽃이 지는 한양, 해원의 문이 열리다',
  startDate: DateTime(2026, 3, 1),
  endDate: DateTime(2026, 5, 31),
  rewards: _buildSeason1Rewards(),
);

List<PassReward> _buildSeason1Rewards() {
  final rewards = <PassReward>[];

  for (int lv = 1; lv <= 50; lv++) {
    // ── 무료 트랙 (매 레벨) ──
    if (lv % 5 == 0) {
      // 5배수: 보석 5개 (고정, 인플레 방지)
      rewards.add(PassReward(
        level: lv,
        type: PassRewardType.gems,
        name: '보석 5개',
        emoji: '💎',
        amount: 5,
      ));
    } else if (lv % 2 == 0) {
      // 짝수: 골드 500 (고정)
      rewards.add(PassReward(
        level: lv,
        type: PassRewardType.gold,
        name: '골드 500',
        emoji: '🪙',
        amount: 500,
      ));
    } else {
      // 홀수: 영웅 경험치 50 (고정)
      rewards.add(PassReward(
        level: lv,
        type: PassRewardType.heroXp,
        name: '영웅 경험치 50',
        emoji: '⭐',
        amount: 50,
      ));
    }

    // ── 유료 트랙 (프리미엄) ──
    // 5레벨 단위 + 주요 마일스톤만 보상
    if (lv == 1) {
      rewards.add(const PassReward(
        level: 1,
        type: PassRewardType.frame,
        name: '시즌 1 프레임',
        emoji: '🖼️',
        isPremium: true,
        unlockId: 'frame_season1',
      ));
    } else if (lv == 5) {
      rewards.add(const PassReward(
        level: 5,
        type: PassRewardType.summonTicket,
        name: '소환권 1장',
        emoji: '🎫',
        amount: 1,
        isPremium: true,
      ));
    } else if (lv == 10) {
      rewards.add(const PassReward(
        level: 10,
        type: PassRewardType.skin,
        name: '벚꽃 깨비 스킨',
        emoji: '🌸',
        isPremium: true,
        unlockId: 'kkaebiCherry',
      ));
    } else if (lv == 15) {
      rewards.add(const PassReward(
        level: 15,
        type: PassRewardType.summonTicket,
        name: '소환권 2장',
        emoji: '🎫',
        amount: 2,
        isPremium: true,
      ));
    } else if (lv == 20) {
      rewards.add(const PassReward(
        level: 20,
        type: PassRewardType.relic,
        name: '봄바람 노리개',
        emoji: '🎐',
        isPremium: true,
        unlockId: 'relic_spring_norigae',
      ));
    } else if (lv == 25) {
      rewards.add(const PassReward(
        level: 25,
        type: PassRewardType.gems,
        name: '보석 15개',
        emoji: '💎',
        amount: 15,
        isPremium: true,
      ));
    } else if (lv == 30) {
      rewards.add(const PassReward(
        level: 30,
        type: PassRewardType.skin,
        name: '달빛 미호 스킨',
        emoji: '🌙',
        isPremium: true,
        unlockId: 'mihoMoonlight',
      ));
    } else if (lv == 35) {
      rewards.add(const PassReward(
        level: 35,
        type: PassRewardType.summonTicket,
        name: '소환권 3장',
        emoji: '🎫',
        amount: 3,
        isPremium: true,
      ));
    } else if (lv == 40) {
      rewards.add(const PassReward(
        level: 40,
        type: PassRewardType.title,
        name: '원혼 해방자 칭호',
        emoji: '👑',
        isPremium: true,
        unlockId: 'title_soul_liberator',
      ));
    } else if (lv == 45) {
      rewards.add(const PassReward(
        level: 45,
        type: PassRewardType.gems,
        name: '보석 20개',
        emoji: '💎',
        amount: 20,
        isPremium: true,
      ));
    } else if (lv == 50) {
      rewards.add(const PassReward(
        level: 50,
        type: PassRewardType.skin,
        name: '신녀 바리 스킨 (한정)',
        emoji: '✨',
        isPremium: true,
        unlockId: 'bariDivine',
      ));
    }
  }

  return rewards;
}
