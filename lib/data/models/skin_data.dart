// 해원의 문 - 스킨 데이터 모델
// 영웅별 코스메틱 스킨 시스템 (7등급)

import 'package:flutter/material.dart';
import '../../common/enums.dart';

/// 스킨 등급 (4단계)
enum SkinRarity {
  common,    // 기본
  rare,      // 정제
  epic,      // 명작
  legendary, // 전설 (걸작)
}

/// 스킨 ID
enum SkinId {
  // ── 깨비 (도깨비) ──
  kkaebiDefault,       // 기본
  kkaebiJade,          // 비취 도깨비
  kkaebiInferno,       // 화염 도깨비
  kkaebiGoldhorn,      // 금각 도깨비

  // ── 미호 (구미호) ──
  mihoDefault,         // 기본
  mihoMoonlight,       // 달빛 미호
  mihoCrimson,         // 핏빛 미호
  mihoNine,            // 구미선녀

  // ── 강림 (저승차사) ──
  gangrimDefault,      // 기본
  gangrimSilver,       // 은월 차사
  gangrimBlood,        // 혈염 차사
  gangrimReaper,       // 대차사

  // ── 수아 (물의 정령) ──
  suaDefault,          // 기본
  suaCoral,            // 산호빛 수아
  suaFrost,            // 빙결 수아
  suaTide,             // 조류 수아

  // ── 바리 (바리공주) ──
  bariDefault,         // 기본
  bariCherry,          // 벚꽃 바리
  bariAurora,          // 여명 바리
  bariDivine,          // 신녀 바리
}

/// 스킨 데이터
class SkinData {
  final SkinId id;
  final HeroId heroId;
  final String name;
  final SkinRarity rarity;
  final Color primaryColor;    // 본체 색상
  final Color secondaryColor;  // 보조/테두리
  final Color glowColor;       // 오라 색상 (legendary+)
  final bool hasParticle;      // 파티클 효과 (mythic+)
  final int price;             // 신명석 가격 (0 = 기본)

  const SkinData({
    required this.id,
    required this.heroId,
    required this.name,
    required this.rarity,
    required this.primaryColor,
    required this.secondaryColor,
    this.glowColor = Colors.transparent,
    this.hasParticle = false,
    this.price = 0,
  });
}

/// 등급별 메타 정보
extension SkinRarityExt on SkinRarity {
  String get displayName {
    switch (this) {
      case SkinRarity.common:    return '기본';
      case SkinRarity.rare:      return '정제';
      case SkinRarity.epic:      return '명작';
      case SkinRarity.legendary: return '전설';
    }
  }

  Color get color {
    switch (this) {
      case SkinRarity.common:    return const Color(0xFF9E9E9E);
      case SkinRarity.rare:      return const Color(0xFF2196F3);
      case SkinRarity.epic:      return const Color(0xFF9C27B0);
      case SkinRarity.legendary: return const Color(0xFFFFD700);
    }
  }

  String get emoji {
    switch (this) {
      case SkinRarity.common:    return '⚪';
      case SkinRarity.rare:      return '🔵';
      case SkinRarity.epic:      return '🟣';
      case SkinRarity.legendary: return '🌟';
    }
  }

  /// 테두리 표시 여부 (rare 이상)
  bool get hasBorder => index >= SkinRarity.rare.index;

  /// 오라 효과 (legendary 이상)
  bool get hasGlow => index >= SkinRarity.legendary.index;
}

/// 전체 스킨 데이터베이스
final Map<SkinId, SkinData> allSkins = {
  // ═══ 깨비 ═══
  SkinId.kkaebiDefault: const SkinData(
    id: SkinId.kkaebiDefault, heroId: HeroId.kkaebi,
    name: '도깨비', rarity: SkinRarity.common,
    primaryColor: Color(0xFF4CAF50), secondaryColor: Color(0xFF388E3C),
  ),
  SkinId.kkaebiJade: const SkinData(
    id: SkinId.kkaebiJade, heroId: HeroId.kkaebi,
    name: '비취 도깨비', rarity: SkinRarity.rare,
    primaryColor: Color(0xFF00BFA5), secondaryColor: Color(0xFFB0BEC5),
    price: 200,
  ),
  SkinId.kkaebiInferno: const SkinData(
    id: SkinId.kkaebiInferno, heroId: HeroId.kkaebi,
    name: '화염 도깨비', rarity: SkinRarity.epic,
    primaryColor: Color(0xFFFF5722), secondaryColor: Color(0xFFFFD700),
    glowColor: Color(0x44FF5722),
    price: 500,
  ),
  SkinId.kkaebiGoldhorn: const SkinData(
    id: SkinId.kkaebiGoldhorn, heroId: HeroId.kkaebi,
    name: '금각 도깨비', rarity: SkinRarity.legendary,
    primaryColor: Color(0xFFFFD700), secondaryColor: Color(0xFFFF8F00),
    glowColor: Color(0x66FFD700), hasParticle: false,
    price: 1000,
  ),

  // ═══ 미호 ═══
  SkinId.mihoDefault: const SkinData(
    id: SkinId.mihoDefault, heroId: HeroId.miho,
    name: '구미호', rarity: SkinRarity.common,
    primaryColor: Color(0xFFE91E63), secondaryColor: Color(0xFFC2185B),
  ),
  SkinId.mihoMoonlight: const SkinData(
    id: SkinId.mihoMoonlight, heroId: HeroId.miho,
    name: '달빛 미호', rarity: SkinRarity.rare,
    primaryColor: Color(0xFFCE93D8), secondaryColor: Color(0xFF8E24AA),
    price: 100,
  ),
  SkinId.mihoCrimson: const SkinData(
    id: SkinId.mihoCrimson, heroId: HeroId.miho,
    name: '핏빛 미호', rarity: SkinRarity.epic,
    primaryColor: Color(0xFFB71C1C), secondaryColor: Color(0xFFFFD700),
    glowColor: Color(0x44B71C1C),
    price: 500,
  ),
  SkinId.mihoNine: const SkinData(
    id: SkinId.mihoNine, heroId: HeroId.miho,
    name: '구미선녀', rarity: SkinRarity.legendary,
    primaryColor: Color(0xFFE1BEE7), secondaryColor: Color(0xFFAB47BC),
    glowColor: Color(0x66E040FB), hasParticle: true,
    price: 2000,
  ),

  // ═══ 강림 ═══
  SkinId.gangrimDefault: const SkinData(
    id: SkinId.gangrimDefault, heroId: HeroId.gangrim,
    name: '저승차사', rarity: SkinRarity.common,
    primaryColor: Color(0xFF212121), secondaryColor: Color(0xFF424242),
  ),
  SkinId.gangrimSilver: const SkinData(
    id: SkinId.gangrimSilver, heroId: HeroId.gangrim,
    name: '은월 차사', rarity: SkinRarity.rare,
    primaryColor: Color(0xFF607D8B), secondaryColor: Color(0xFFB0BEC5),
    price: 200,
  ),
  SkinId.gangrimBlood: const SkinData(
    id: SkinId.gangrimBlood, heroId: HeroId.gangrim,
    name: '혈염 차사', rarity: SkinRarity.epic,
    primaryColor: Color(0xFF4A0000), secondaryColor: Color(0xFFFF1744),
    glowColor: Color(0x66FF1744),
    price: 1000,
  ),
  SkinId.gangrimReaper: const SkinData(
    id: SkinId.gangrimReaper, heroId: HeroId.gangrim,
    name: '대차사', rarity: SkinRarity.legendary,
    primaryColor: Color(0xFF1A237E), secondaryColor: Color(0xFFFFD700),
    glowColor: Color(0x88FFD700), hasParticle: true,
    price: 5000,
  ),

  // ═══ 수아 ═══
  SkinId.suaDefault: const SkinData(
    id: SkinId.suaDefault, heroId: HeroId.sua,
    name: '물의 정령', rarity: SkinRarity.common,
    primaryColor: Color(0xFF2196F3), secondaryColor: Color(0xFF1565C0),
  ),
  SkinId.suaCoral: const SkinData(
    id: SkinId.suaCoral, heroId: HeroId.sua,
    name: '산호빛 수아', rarity: SkinRarity.rare,
    primaryColor: Color(0xFFFF7043), secondaryColor: Color(0xFFE64A19),
    price: 100,
  ),
  SkinId.suaFrost: const SkinData(
    id: SkinId.suaFrost, heroId: HeroId.sua,
    name: '빙결 수아', rarity: SkinRarity.epic,
    primaryColor: Color(0xFF80DEEA), secondaryColor: Color(0xFF00BCD4),
    glowColor: Color(0x4480DEEA),
    price: 500,
  ),
  SkinId.suaTide: const SkinData(
    id: SkinId.suaTide, heroId: HeroId.sua,
    name: '조류 수아', rarity: SkinRarity.legendary,
    primaryColor: Color(0xFF0D47A1), secondaryColor: Color(0xFF00E5FF),
    glowColor: Color(0x6600E5FF), hasParticle: true,
    price: 2000,
  ),

  // ═══ 바리 ═══
  SkinId.bariDefault: const SkinData(
    id: SkinId.bariDefault, heroId: HeroId.bari,
    name: '바리공주', rarity: SkinRarity.common,
    primaryColor: Color(0xFFFFEB3B), secondaryColor: Color(0xFFF9A825),
  ),
  SkinId.bariCherry: const SkinData(
    id: SkinId.bariCherry, heroId: HeroId.bari,
    name: '벚꽃 바리', rarity: SkinRarity.rare,
    primaryColor: Color(0xFFF48FB1), secondaryColor: Color(0xFFEC407A),
    price: 200,
  ),
  SkinId.bariAurora: const SkinData(
    id: SkinId.bariAurora, heroId: HeroId.bari,
    name: '여명 바리', rarity: SkinRarity.epic,
    primaryColor: Color(0xFFFFCC80), secondaryColor: Color(0xFFFF6F00),
    glowColor: Color(0x66FFCC80),
    price: 1000,
  ),
  SkinId.bariDivine: const SkinData(
    id: SkinId.bariDivine, heroId: HeroId.bari,
    name: '신녀 바리', rarity: SkinRarity.legendary,
    primaryColor: Color(0xFFFFFFFF), secondaryColor: Color(0xFFFFD700),
    glowColor: Color(0x88FFFFFF), hasParticle: true,
    price: 5000,
  ),
};

/// 특정 영웅의 스킨 목록
List<SkinData> getSkinsForHero(HeroId heroId) {
  return allSkins.values.where((s) => s.heroId == heroId).toList();
}

/// 영웅의 기본 스킨 ID
SkinId getDefaultSkin(HeroId heroId) {
  switch (heroId) {
    case HeroId.kkaebi:  return SkinId.kkaebiDefault;
    case HeroId.miho:    return SkinId.mihoDefault;
    case HeroId.gangrim: return SkinId.gangrimDefault;
    case HeroId.sua:     return SkinId.suaDefault;
    case HeroId.bari:    return SkinId.bariDefault;
  }
}
