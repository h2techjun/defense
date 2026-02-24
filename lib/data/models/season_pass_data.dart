// 해원의 문 - 시즌 패스 + 상점 데이터 모델
// 밸런스 v2: 광고 수익 중심 + 소액결제(₩1K~₩3K) + 최대 ₩10K
// VIP 등급, 소액 패키지, 구매 제한 포함

import 'package:flutter/material.dart';
import '../../common/enums.dart';

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

  /// 레벨별 필요 XP (점진적 증가: 60 + level × 3)
  /// Lv1=63, Lv10=90, Lv25=135, Lv40=180, Lv50=210
  int xpForLevel(int level) => 60 + (level * 3);

  /// 전체 필요 XP 합계 (Lv1→50 = 약 6,825)
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

// ═══════════════════════════════════════════
// VIP 등급) — 광고 감소형 (제거 아님)
// ═══════════════════════════════════════════

/// VIP 등급 (총 누적 결제 기반, 소액결제 친화적 기준)
enum VipTier {
  none,       // VIP 아님 (무과금)
  bronze,     // ₩3,000+ 결제 (첫 구독 1회)
  silver,     // ₩10,000+ (2~3개월 구독)
  gold,       // ₩30,000+ (6개월 구독)
  platinum,   // ₩60,000+ (1년 구독)
  diamond,    // ₩120,000+ (2년+ 구독)
}

extension VipTierExt on VipTier {
  String get displayName => switch (this) {
    VipTier.none     => '일반',
    VipTier.bronze   => 'VIP 브론즈',
    VipTier.silver   => 'VIP 실버',
    VipTier.gold     => 'VIP 골드',
    VipTier.platinum => 'VIP 플래티넘',
    VipTier.diamond  => 'VIP 다이아몬드',
  };

  String get emoji => switch (this) {
    VipTier.none     => '',
    VipTier.bronze   => '🥉',
    VipTier.silver   => '🥈',
    VipTier.gold     => '🥇',
    VipTier.platinum => '💠',
    VipTier.diamond  => '💎',
  };

  Color get color => switch (this) {
    VipTier.none     => const Color(0xFF9E9E9E),
    VipTier.bronze   => const Color(0xFFCD7F32),
    VipTier.silver   => const Color(0xFFC0C0C0),
    VipTier.gold     => const Color(0xFFFFD700),
    VipTier.platinum => const Color(0xFFE5E4E2),
    VipTier.diamond  => const Color(0xFFB9F2FF),
  };

  /// 해당 등급에 필요한 최소 누적 결제액 (원)
  int get requiredSpend => switch (this) {
    VipTier.none     => 0,
    VipTier.bronze   => 3000,
    VipTier.silver   => 10000,
    VipTier.gold     => 30000,
    VipTier.platinum => 60000,
    VipTier.diamond  => 120000,
  };

  /// 일일 보석 보너스 (축소)
  int get dailyGemBonus => switch (this) {
    VipTier.none     => 0,
    VipTier.bronze   => 3,
    VipTier.silver   => 5,
    VipTier.gold     => 10,
    VipTier.platinum => 15,
    VipTier.diamond  => 20,
  };

  /// 경험치 보너스 배율 (완만한 증가)
  double get xpMultiplier => switch (this) {
    VipTier.none     => 1.0,
    VipTier.bronze   => 1.05,
    VipTier.silver   => 1.1,
    VipTier.gold     => 1.15,
    VipTier.platinum => 1.2,
    VipTier.diamond  => 1.3,
  };

  /// 전면 광고 감소율 (%) — 완전 제거 아님
  int get adReductionPercent => switch (this) {
    VipTier.none     => 0,
    VipTier.bronze   => 20,
    VipTier.silver   => 40,
    VipTier.gold     => 60,
    VipTier.platinum => 80,
    VipTier.diamond  => 90,
  };

  /// 다음 등급까지 필요한 추가 결제액
  int nextTierSpend(int currentSpend) {
    final tiers = VipTier.values;
    final idx = tiers.indexOf(this);
    if (idx >= tiers.length - 1) return 0; // 최고 등급
    return tiers[idx + 1].requiredSpend - currentSpend;
  }

  /// 누적 결제액 → VIP 등급 판정
  static VipTier fromTotalSpend(int totalSpendKRW) {
    if (totalSpendKRW >= 120000) return VipTier.diamond;
    if (totalSpendKRW >= 60000) return VipTier.platinum;
    if (totalSpendKRW >= 30000) return VipTier.gold;
    if (totalSpendKRW >= 10000) return VipTier.silver;
    if (totalSpendKRW >= 3000) return VipTier.bronze;
    return VipTier.none;
  }
}

// ═══════════════════════════════════════════
// 소액 패키지 상점 (₩1,000~₩10,000)
// ═══════════════════════════════════════════

/// 상점 패키지 유형
enum PackageType {
  starter,     // 스타터 패키지 (1회 한정)
  weekly,      // 주간 패키지
  monthly,     // 월간 패키지
  gems,        // 보석 충전
  seasonPass,  // 시즌 프리미엄 패스
}

/// 상점 패키지 데이터
class ShopPackage {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final PackageType type;
  final int priceKRW;              // 원화 가격 (최대 ₩10,000)
  final Map<String, int> contents; // 내용물 {보석: 100, 골드: 5000, ...}
  final int? limitCount;           // 총 구매 제한 (null = 무제한)
  final int dailyLimit;            // 1일 최대 구매 횟수
  final int monthlyLimit;          // 월 최대 구매 횟수
  final bool isHighlight;          // 추천 표시
  final Duration? expiresAfter;    // 첫 노출 후 만료 시간 (예: 72시간)
  final int firstPurchaseMultiplier; // 첫 구매 보너스 배율 (1 = 없음, 3 = 3배)
  final int discountPercent;       // 할인율 (0 = 없음)

  const ShopPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.type,
    required this.priceKRW,
    required this.contents,
    this.limitCount,
    this.dailyLimit = 1,
    this.monthlyLimit = 30,
    this.isHighlight = false,
    this.expiresAfter,
    this.firstPurchaseMultiplier = 1,
    this.discountPercent = 0,
  });

  /// 할인 적용 가격
  int get discountedPrice => discountPercent > 0
      ? (priceKRW * (100 - discountPercent) / 100).round()
      : priceKRW;

  /// 첫 구매 시 실제 지급량 계산
  Map<String, int> getEffectiveContents(bool isFirstPurchase) {
    if (!isFirstPurchase || firstPurchaseMultiplier <= 1) return contents;
    return contents.map((key, value) =>
        MapEntry(key, key == 'premiumPass' ? value : value * firstPurchaseMultiplier));
  }
}

/// 상점 패키지 목록 (모든 상품 ₩10,000 이하)
const List<ShopPackage> allShopPackages = [
  // ── 시즌 프리미엄 패스 (₩10,000, 시즌당 1회) ──
  ShopPackage(
    id: 'premium_pass',
    name: '시즌 프리미엄 패스',
    description: '프리미엄 보상 트랙 해금 + 한정 스킨',
    emoji: '👑',
    type: PackageType.seasonPass,
    priceKRW: 10000,
    contents: {'premiumPass': 1},
    limitCount: 1,
    dailyLimit: 1,
    monthlyLimit: 1,
    isHighlight: true,
  ),

  // ── 스타터 패키지 (1회 한정, ₩1K~₩3K) ──
  ShopPackage(
    id: 'starter_hero',
    name: '영웅의 첫걸음',
    description: '게임 시작을 위한 필수 패키지!',
    emoji: '🎁',
    type: PackageType.starter,
    priceKRW: 1200,
    contents: {'gems': 80, 'gold': 3000, 'summonTicket': 1},
    limitCount: 1,
    dailyLimit: 1,
    monthlyLimit: 1,
    isHighlight: true,
  ),
  ShopPackage(
    id: 'starter_tower',
    name: '수호자 패키지',
    description: '타워 강화 재료 세트',
    emoji: '🏰',
    type: PackageType.starter,
    priceKRW: 2900,
    contents: {'gems': 150, 'towerUpgrade': 5, 'gold': 5000},
    limitCount: 1,
    dailyLimit: 1,
    monthlyLimit: 1,
  ),

  // ── 주간 구독 (₩1,500) ──
  ShopPackage(
    id: 'weekly_gems',
    name: '주간 보석 구독',
    description: '매일 15보석 × 7일 = 105보석',
    emoji: '💎',
    type: PackageType.weekly,
    priceKRW: 1500,
    contents: {'dailyGems': 15},  // 7일간 15보석/일
    dailyLimit: 1,
    monthlyLimit: 4, // 한 달에 4주
  ),

  // ── 월간 패스 (₩4,900) ──
  ShopPackage(
    id: 'monthly_pass',
    name: '월간 수호 패스',
    description: '매일 20보석 × 30일 = 600보석',
    emoji: '🛡️',
    type: PackageType.monthly,
    priceKRW: 4900,
    contents: {'dailyGems': 20}, // 30일간 20보석/일
    dailyLimit: 1,
    monthlyLimit: 1,
    isHighlight: true,
  ),

  // ── 보석 충전 (₩1,000~₩3,000, 소액 중심) ──
  ShopPackage(
    id: 'gems_tiny',
    name: '소량 보석',
    description: '50 보석',
    emoji: '💎',
    type: PackageType.gems,
    priceKRW: 1000,
    contents: {'gems': 50},
    dailyLimit: 2,     // 하루 2회
    monthlyLimit: 10,  // 월 10회 (최대 ₩10,000)
  ),
  ShopPackage(
    id: 'gems_small',
    name: '보석 주머니',
    description: '110 보석 (+10%)',
    emoji: '💎',
    type: PackageType.gems,
    priceKRW: 2000,
    contents: {'gems': 110},
    dailyLimit: 1,     // 하루 1회
    monthlyLimit: 5,   // 월 5회 (최대 ₩10,000)
  ),
  ShopPackage(
    id: 'gems_medium',
    name: '보석 상자',
    description: '170 보석 (+13%)',
    emoji: '💎',
    type: PackageType.gems,
    priceKRW: 3000,
    contents: {'gems': 170},
    dailyLimit: 1,     // 하루 1회
    monthlyLimit: 3,   // 월 3회 (최대 ₩9,000)
    isHighlight: true,
  ),
];

// ── 72시간 한정 특가 패키지 ──
const List<ShopPackage> timeLimitedPackages = [
  ShopPackage(
    id: 'limited_72h_hero',
    name: '⏰ 한정 영웅 패키지',
    description: '72시간 한정! 소환권 2장 + 보석 200',
    emoji: '🔥',
    type: PackageType.starter,
    priceKRW: 3900,
    contents: {'gems': 200, 'summonTicket': 2, 'gold': 5000},
    limitCount: 1,
    isHighlight: true,
    expiresAfter: Duration(hours: 72),
    discountPercent: 35,
  ),
  ShopPackage(
    id: 'limited_72h_tower',
    name: '⏰ 한정 수호자 패키지',
    description: '72시간 한정! 타워 강화 10개 + 골드 10K',
    emoji: '🔥',
    type: PackageType.starter,
    priceKRW: 4900,
    contents: {'towerUpgrade': 10, 'gold': 10000, 'gems': 50},
    limitCount: 1,
    isHighlight: true,
    expiresAfter: Duration(hours: 72),
    discountPercent: 40,
  ),
];

// ── 첫 구매 3배 패키지 ──
const List<ShopPackage> firstPurchaseBonusPackages = [
  ShopPackage(
    id: 'first_buy_gems_sm',
    name: '첫 구매 보석 A',
    description: '첫 구매 시 3배! 150 → 50 보석',
    emoji: '🌟',
    type: PackageType.gems,
    priceKRW: 1000,
    contents: {'gems': 50},
    limitCount: 1,
    firstPurchaseMultiplier: 3,
    isHighlight: true,
  ),
  ShopPackage(
    id: 'first_buy_gems_md',
    name: '첫 구매 보석 B',
    description: '첫 구매 시 3배! 330 → 110 보석',
    emoji: '🌟',
    type: PackageType.gems,
    priceKRW: 2000,
    contents: {'gems': 110},
    limitCount: 1,
    firstPurchaseMultiplier: 3,
    isHighlight: true,
  ),
];

/// 모든 상점 패키지 합산
List<ShopPackage> get allAvailablePackages =>
    [...allShopPackages, ...timeLimitedPackages, ...firstPurchaseBonusPackages];
