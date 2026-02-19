// 해원의 문 - 랭킹 + 업적 데이터 모델
// 밸런스 v2: 보석 보상 60% 축소, 장식 보상 추가
// 무한의 탑 랭킹, 일일 도전 랭킹, 업적 시스템

import 'package:flutter/material.dart';
import '../../common/enums.dart';

// ═══════════════════════════════════════════
// 업적 시스템
// ═══════════════════════════════════════════

/// 업적 카테고리
enum AchievementCategory {
  combat,      // 전투 관련
  tower,       // 타워 관련
  hero,        // 영웅 관련
  collection,  // 수집 관련
  challenge,   // 도전 관련
  story,       // 스토리 관련
}

extension AchievementCategoryExt on AchievementCategory {
  String get displayName => switch (this) {
    AchievementCategory.combat     => '전투',
    AchievementCategory.tower      => '타워',
    AchievementCategory.hero       => '영웅',
    AchievementCategory.collection => '수집',
    AchievementCategory.challenge  => '도전',
    AchievementCategory.story      => '스토리',
  };

  String get emoji => switch (this) {
    AchievementCategory.combat     => '⚔️',
    AchievementCategory.tower      => '🏰',
    AchievementCategory.hero       => '🦊',
    AchievementCategory.collection => '📚',
    AchievementCategory.challenge  => '🏆',
    AchievementCategory.story      => '📜',
  };

  Color get color => switch (this) {
    AchievementCategory.combat     => const Color(0xFFE53935),
    AchievementCategory.tower      => const Color(0xFF43A047),
    AchievementCategory.hero       => const Color(0xFFE91E63),
    AchievementCategory.collection => const Color(0xFF5E35B1),
    AchievementCategory.challenge  => const Color(0xFFFF8F00),
    AchievementCategory.story      => const Color(0xFF1E88E5),
  };
}

/// 업적 데이터
class AchievementData {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final int targetValue;          // 목표 수치
  final int rewardGems;           // 보석 보상 (축소됨)
  final int rewardPassXp;         // 시즌 패스 경험치 보상
  final bool isHidden;            // 히든 업적 (달성 전 ??? 표시)
  final String? rewardTitle;      // 보너스 칭호 (히든/고난도 업적)
  final String? rewardFrame;      // 보너스 프레임

  const AchievementData({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.targetValue,
    this.rewardGems = 5,
    this.rewardPassXp = 30,
    this.isHidden = false,
    this.rewardTitle,
    this.rewardFrame,
  });
}

/// 전체 업적 목록 (보석 보상 60% 축소, 칭호/프레임 보상 추가)
const List<AchievementData> allAchievements = [
  // ═══ 전투 (총 130💎) ═══
  AchievementData(
    id: 'kill_100', name: '원혼 사냥꾼', description: '적 100마리 처치',
    emoji: '⚔️', category: AchievementCategory.combat,
    targetValue: 100, rewardGems: 5, rewardPassXp: 30,
  ),
  AchievementData(
    id: 'kill_1000', name: '원혼 대사냥꾼', description: '적 1,000마리 처치',
    emoji: '⚔️', category: AchievementCategory.combat,
    targetValue: 1000, rewardGems: 20, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'kill_10000', name: '원혼 멸살자', description: '적 10,000마리 처치',
    emoji: '💀', category: AchievementCategory.combat,
    targetValue: 10000, rewardGems: 50, rewardPassXp: 80,
    rewardTitle: 'title_soul_slayer', // 전용 칭호
  ),
  AchievementData(
    id: 'boss_kill_10', name: '보스 사냥꾼', description: '보스 10마리 처치',
    emoji: '👹', category: AchievementCategory.combat,
    targetValue: 10, rewardGems: 15, rewardPassXp: 40,
  ),
  AchievementData(
    id: 'no_damage_clear', name: '완벽한 수비', description: '해원문 피해 0으로 스테이지 클리어',
    emoji: '🛡️', category: AchievementCategory.combat,
    targetValue: 1, rewardGems: 40, rewardPassXp: 50, isHidden: true,
  ),

  // ═══ 타워 (총 60💎) ═══
  AchievementData(
    id: 'build_50', name: '건축가', description: '타워 50개 건설',
    emoji: '🏗️', category: AchievementCategory.tower,
    targetValue: 50, rewardGems: 5, rewardPassXp: 30,
  ),
  AchievementData(
    id: 'tier3_tower', name: '전설의 방어탑', description: '타워 Tier 3 달성',
    emoji: '🏯', category: AchievementCategory.tower,
    targetValue: 1, rewardGems: 15, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'all_tower_tier3', name: '만능 건축가', description: '모든 타워 종류 Tier 3 달성',
    emoji: '👷', category: AchievementCategory.tower,
    targetValue: 5, rewardGems: 40, rewardPassXp: 70,
    rewardFrame: 'frame_master_builder', // 전용 프레임
  ),

  // ═══ 영웅 (총 80💎) ═══
  AchievementData(
    id: 'hero_lv10', name: '숙련된 영웅', description: '영웅 레벨 10 달성',
    emoji: '⭐', category: AchievementCategory.hero,
    targetValue: 10, rewardGems: 10, rewardPassXp: 30,
  ),
  AchievementData(
    id: 'hero_lv30', name: '전설 영웅', description: '영웅 레벨 30 달성',
    emoji: '🌟', category: AchievementCategory.hero,
    targetValue: 30, rewardGems: 30, rewardPassXp: 80,
    rewardFrame: 'frame_legend_hero', // 전용 프레임
  ),
  AchievementData(
    id: 'all_heroes', name: '다섯 영웅 집결', description: '모든 영웅 사용',
    emoji: '🦊', category: AchievementCategory.hero,
    targetValue: 5, rewardGems: 20, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'skill_100', name: '스킬 마스터', description: '영웅 스킬 100회 사용',
    emoji: '🔥', category: AchievementCategory.hero,
    targetValue: 100, rewardGems: 20, rewardPassXp: 40,
  ),

  // ═══ 수집 (총 80💎) ═══
  AchievementData(
    id: 'skins_5', name: '패셔니스타', description: '스킨 5종 수집',
    emoji: '👗', category: AchievementCategory.collection,
    targetValue: 5, rewardGems: 15, rewardPassXp: 40,
  ),
  AchievementData(
    id: 'relics_5', name: '유물 수집가', description: '유물 5종 수집',
    emoji: '🏺', category: AchievementCategory.collection,
    targetValue: 5, rewardGems: 15, rewardPassXp: 40,
  ),
  AchievementData(
    id: 'all_relics', name: '전설의 고고학자', description: '모든 유물 수집',
    emoji: '🗿', category: AchievementCategory.collection,
    targetValue: 25, rewardGems: 50, rewardPassXp: 80, isHidden: true,
    rewardTitle: 'title_archaeologist', // 전용 칭호
  ),

  // ═══ 도전 (총 280💎) ═══
  AchievementData(
    id: 'tower_floor_10', name: '탑 탐험가', description: '무한의 탑 10층 도달',
    emoji: '🗼', category: AchievementCategory.challenge,
    targetValue: 10, rewardGems: 10, rewardPassXp: 30,
  ),
  AchievementData(
    id: 'tower_floor_50', name: '탑 정복자', description: '무한의 탑 50층 도달',
    emoji: '🏔️', category: AchievementCategory.challenge,
    targetValue: 50, rewardGems: 40, rewardPassXp: 80,
  ),
  AchievementData(
    id: 'tower_floor_100', name: '탑의 전설', description: '무한의 탑 100층 도달',
    emoji: '👑', category: AchievementCategory.challenge,
    targetValue: 100, rewardGems: 100, rewardPassXp: 100, isHidden: true,
    rewardFrame: 'frame_tower_legend', // 전용 프레임
    rewardTitle: 'title_tower_legend', // 전용 칭호
  ),
  AchievementData(
    id: 'daily_streak_7', name: '꾸준한 수호자', description: '일일 도전 7일 연속 참여',
    emoji: '🔥', category: AchievementCategory.challenge,
    targetValue: 7, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'daily_streak_30', name: '월간 수호자', description: '일일 도전 30일 연속 참여',
    emoji: '🏅', category: AchievementCategory.challenge,
    targetValue: 30, rewardGems: 100, rewardPassXp: 80,
  ),

  // ═══ 스토리 (총 400💎) ═══
  AchievementData(
    id: 'clear_ep1', name: '장터의 해방', description: '에피소드 1 클리어',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'clear_ep2', name: '숲의 정화', description: '에피소드 2 클리어',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'clear_ep3', name: '얼굴 찾기', description: '에피소드 3 클리어',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'clear_ep4', name: '왕궁의 진실', description: '에피소드 4 클리어',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'clear_ep5', name: '저승의 문 봉인', description: '에피소드 5 클리어 (시즌 1 완결)',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 100, rewardPassXp: 80,
  ),
  AchievementData(
    id: 'all_stars', name: '완전 정복', description: '모든 스테이지 별 3개 달성',
    emoji: '⭐', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 180, rewardPassXp: 100, isHidden: true,
    rewardTitle: 'title_perfect_conqueror', // 전용 칭호
    rewardFrame: 'frame_all_stars', // 전용 프레임
  ),
];

// ═══════════════════════════════════════════
// 랭킹 엔트리
// ═══════════════════════════════════════════

/// 랭킹 유형
enum RankingType {
  endlessTower,     // 무한의 탑 최고 층수
  dailyChallenge,   // 일일 도전 최고 웨이브
  totalStars,       // 총 별 수
}

/// 로컬 랭킹 엔트리 (오프라인 자기 기록)
class RankingEntry {
  final String playerName;
  final int score;
  final DateTime achievedAt;
  final HeroId? usedHero;

  const RankingEntry({
    required this.playerName,
    required this.score,
    required this.achievedAt,
    this.usedHero,
  });

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'score': score,
    'achievedAt': achievedAt.toIso8601String(),
    'usedHero': usedHero?.name,
  };

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
    playerName: json['playerName'] as String? ?? '무명',
    score: json['score'] as int? ?? 0,
    achievedAt: DateTime.tryParse(json['achievedAt'] as String? ?? '') ?? DateTime.now(),
    usedHero: json['usedHero'] != null
        ? HeroId.values.firstWhere(
            (e) => e.name == json['usedHero'],
            orElse: () => HeroId.kkaebi,
          )
        : null,
  );
}
