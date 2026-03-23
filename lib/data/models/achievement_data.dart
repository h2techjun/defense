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
    AchievementCategory.combat     => 'ach_cat_combat',
    AchievementCategory.tower      => 'ach_cat_tower',
    AchievementCategory.hero       => 'ach_cat_hero',
    AchievementCategory.collection => 'ach_cat_collection',
    AchievementCategory.challenge  => 'ach_cat_challenge',
    AchievementCategory.story      => 'ach_cat_story',
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
    id: 'kill_100', name: 'ach_kill_100_name', description: 'ach_kill_100_desc',
    emoji: '⚔️', category: AchievementCategory.combat,
    targetValue: 100, rewardGems: 5, rewardPassXp: 30,
  ),
  AchievementData(
    id: 'kill_1000', name: 'ach_kill_1000_name', description: 'ach_kill_1000_desc',
    emoji: '⚔️', category: AchievementCategory.combat,
    targetValue: 1000, rewardGems: 20, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'kill_10000', name: 'ach_kill_10000_name', description: 'ach_kill_10000_desc',
    emoji: '💀', category: AchievementCategory.combat,
    targetValue: 10000, rewardGems: 50, rewardPassXp: 80,
    rewardTitle: 'title_soul_slayer', // 전용 칭호
  ),
  AchievementData(
    id: 'boss_kill_10', name: 'ach_boss_kill_10_name', description: 'ach_boss_kill_10_desc',
    emoji: '👹', category: AchievementCategory.combat,
    targetValue: 10, rewardGems: 15, rewardPassXp: 40,
  ),
  AchievementData(
    id: 'no_damage_clear', name: 'ach_no_damage_clear_name', description: 'ach_no_damage_clear_desc',
    emoji: '🛡️', category: AchievementCategory.combat,
    targetValue: 1, rewardGems: 40, rewardPassXp: 50, isHidden: true,
  ),

  // ═══ 타워 (총 60💎) ═══
  AchievementData(
    id: 'build_50', name: 'ach_build_50_name', description: 'ach_build_50_desc',
    emoji: '🏗️', category: AchievementCategory.tower,
    targetValue: 50, rewardGems: 5, rewardPassXp: 30,
  ),
  AchievementData(
    id: 'tier3_tower', name: 'ach_tier3_tower_name', description: 'ach_tier3_tower_desc',
    emoji: '🏯', category: AchievementCategory.tower,
    targetValue: 1, rewardGems: 15, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'all_tower_tier3', name: 'ach_all_tower_tier3_name', description: 'ach_all_tower_tier3_desc',
    emoji: '👷', category: AchievementCategory.tower,
    targetValue: 5, rewardGems: 40, rewardPassXp: 70,
    rewardFrame: 'frame_master_builder', // 전용 프레임
  ),

  // ═══ 영웅 (총 80💎) ═══
  AchievementData(
    id: 'hero_lv10', name: 'ach_hero_lv10_name', description: 'ach_hero_lv10_desc',
    emoji: '⭐', category: AchievementCategory.hero,
    targetValue: 10, rewardGems: 10, rewardPassXp: 30,
  ),
  AchievementData(
    id: 'hero_lv30', name: 'ach_hero_lv30_name', description: 'ach_hero_lv30_desc',
    emoji: '🌟', category: AchievementCategory.hero,
    targetValue: 30, rewardGems: 30, rewardPassXp: 80,
    rewardFrame: 'frame_legend_hero', // 전용 프레임
  ),
  AchievementData(
    id: 'all_heroes', name: 'ach_all_heroes_name', description: 'ach_all_heroes_desc',
    emoji: '🦊', category: AchievementCategory.hero,
    targetValue: 5, rewardGems: 20, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'skill_100', name: 'ach_skill_100_name', description: 'ach_skill_100_desc',
    emoji: '🔥', category: AchievementCategory.hero,
    targetValue: 100, rewardGems: 20, rewardPassXp: 40,
  ),

  // ═══ 수집 (총 80💎) ═══
  AchievementData(
    id: 'skins_5', name: 'ach_skins_5_name', description: 'ach_skins_5_desc',
    emoji: '👗', category: AchievementCategory.collection,
    targetValue: 5, rewardGems: 15, rewardPassXp: 40,
  ),
  AchievementData(
    id: 'relics_5', name: 'ach_relics_5_name', description: 'ach_relics_5_desc',
    emoji: '🏺', category: AchievementCategory.collection,
    targetValue: 5, rewardGems: 15, rewardPassXp: 40,
  ),
  AchievementData(
    id: 'all_relics', name: 'ach_all_relics_name', description: 'ach_all_relics_desc',
    emoji: '🗿', category: AchievementCategory.collection,
    targetValue: 25, rewardGems: 50, rewardPassXp: 80, isHidden: true,
    rewardTitle: 'title_archaeologist', // 전용 칭호
  ),

  // ═══ 도전 (총 280💎) ═══
  AchievementData(
    id: 'tower_floor_10', name: 'ach_tower_floor_10_name', description: 'ach_tower_floor_10_desc',
    emoji: '🗼', category: AchievementCategory.challenge,
    targetValue: 10, rewardGems: 10, rewardPassXp: 30,
  ),
  AchievementData(
    id: 'tower_floor_50', name: 'ach_tower_floor_50_name', description: 'ach_tower_floor_50_desc',
    emoji: '🏔️', category: AchievementCategory.challenge,
    targetValue: 50, rewardGems: 40, rewardPassXp: 80,
  ),
  AchievementData(
    id: 'tower_floor_100', name: 'ach_tower_floor_100_name', description: 'ach_tower_floor_100_desc',
    emoji: '👑', category: AchievementCategory.challenge,
    targetValue: 100, rewardGems: 100, rewardPassXp: 100, isHidden: true,
    rewardFrame: 'frame_tower_legend', // 전용 프레임
    rewardTitle: 'title_tower_legend', // 전용 칭호
  ),
  AchievementData(
    id: 'daily_streak_7', name: 'ach_daily_streak_7_name', description: 'ach_daily_streak_7_desc',
    emoji: '🔥', category: AchievementCategory.challenge,
    targetValue: 7, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'daily_streak_30', name: 'ach_daily_streak_30_name', description: 'ach_daily_streak_30_desc',
    emoji: '🏅', category: AchievementCategory.challenge,
    targetValue: 30, rewardGems: 100, rewardPassXp: 80,
  ),

  // ═══ 스토리 (총 400💎) ═══
  AchievementData(
    id: 'clear_ep1', name: 'ach_clear_ep1_name', description: 'ach_clear_ep1_desc',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'clear_ep2', name: 'ach_clear_ep2_name', description: 'ach_clear_ep2_desc',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'clear_ep3', name: 'ach_clear_ep3_name', description: 'ach_clear_ep3_desc',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'clear_ep4', name: 'ach_clear_ep4_name', description: 'ach_clear_ep4_desc',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 30, rewardPassXp: 50,
  ),
  AchievementData(
    id: 'clear_ep5', name: 'ach_clear_ep5_name', description: 'ach_clear_ep5_desc',
    emoji: '📖', category: AchievementCategory.story,
    targetValue: 1, rewardGems: 100, rewardPassXp: 80,
  ),
  AchievementData(
    id: 'all_stars', name: 'ach_all_stars_name', description: 'ach_all_stars_desc',
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
    playerName: json['playerName'] as String? ?? 'default_player_name',
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
