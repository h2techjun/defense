// 해원의 문 - 영웅 상세 패널 (오른쪽)
// 이름/타이틀/태그/레벨바 + 배경 설화 + 각 섹션 조합

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/enums.dart';
import '../../../common/responsive.dart';
import '../../../data/models/hero_data.dart';
import '../../../data/models/skin_data.dart';
import '../../../data/models/story_data.dart';
import '../../../game/components/actors/base_hero.dart';
import '../../../l10n/app_strings.dart';
import '../../../state/skin_provider.dart';
import '../../common/hero_sprite_viewer.dart';
import '../../theme/app_colors.dart';
import 'hero_helpers.dart';
import 'hero_skin_section.dart';
import 'hero_stats_section.dart';

class HeroDetailPanel extends ConsumerWidget {
  final HeroData hero;
  final int selectedEvolutionIndex;
  final Animation<double> glowAnimation;
  final Map<HeroId, Map<String, int>> heroLevelCache;
  final ValueChanged<int> onEvolutionIndexChanged;

  const HeroDetailPanel({
    super.key,
    required this.hero,
    required this.selectedEvolutionIndex,
    required this.glowAnimation,
    required this.heroLevelCache,
    required this.onEvolutionIndexChanged,
  });

  int _getHeroLevel(HeroId id) => heroLevelCache[id]?['level'] ?? 1;
  int _getHeroXp(HeroId id) => heroLevelCache[id]?['xp'] ?? 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinState = ref.watch(skinProvider);
    final color = getHeroColor(hero.id);

    return Container(
      margin: EdgeInsets.only(left: 8 * Responsive.scale(context), right: 12 * Responsive.scale(context), bottom: 12 * Responsive.scale(context)),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceOverlayDim),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20 * Responsive.scale(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 영웅 이름 & 초상화 (포트레이트)
            _buildNameSection(context, ref, hero, color, skinState),
            SizedBox(height: 16 * Responsive.scale(context)),

            // 장착된 스킨 프리뷰 (스킨상점 카드 스타일)
            HeroSkinSection(hero: hero, color: color),
            SizedBox(height: 16 * Responsive.scale(context)),

            // 진화 단계 선택
            HeroStatsSection(
              hero: hero,
              color: color,
              selectedEvolutionIndex: selectedEvolutionIndex,
              onEvolutionIndexChanged: onEvolutionIndexChanged,
            ),
            SizedBox(height: 20 * Responsive.scale(context)),

            // 배경 설화
            _buildBackstorySection(context, ref, hero, color),
          ],
        ),
      ),
    );
  }

  /// 이름 섹션
  Widget _buildNameSection(BuildContext context, WidgetRef ref, HeroData hero, Color color, SkinState skinState) {
    // 장착 중인 스킨 데이터 가져오기
    final skinId = skinState.equippedSkins[hero.id];
    final skins = getSkinsForHero(hero.id);
    final equippedSkin = skinId != null
        ? skins.firstWhere((s) => s.id == skinId, orElse: () => skins.first)
        : skins.where((s) => s.rarity == SkinRarity.common).firstOrNull;

    final displayName = equippedSkin != null ? tr(ref, equippedSkin.name) : AppStrings.trs(hero.name);
    final displayTitle = equippedSkin?.rarity.displayName != null
        ? '${tr(ref, equippedSkin!.rarity.displayName)} ${tr(ref, 'grade')} ' + AppStrings.trs(hero.title)
        : AppStrings.trs(hero.title);

    return Row(
      children: [
        // 큰 영웅 아바타
        AnimatedBuilder(
          animation: glowAnimation,
          builder: (context, child) {
            return Container(
              width: 72 * Responsive.scale(context),
              height: 72 * Responsive.scale(context),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.2 + glowAnimation.value * 0.3),
                  ],
                ),
                border: Border.all(
                  color: color.withValues(alpha: 0.5 + glowAnimation.value * 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3 + glowAnimation.value * 0.2),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: HeroSpriteViewer(
                  imagePath: 'assets/images/heroes/${getHeroFileName(hero.id)}_tier1_sprites.png',
                  width: 72 * Responsive.scale(context),
                  height: 72 * Responsive.scale(context),
                  fallbackText: getHeroEmoji(hero.id),
                ),
              ),
            );
          },
        ),
        SizedBox(width: 16 * Responsive.scale(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 28),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4 * Responsive.scale(context)),
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  color: color.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 4 * Responsive.scale(context)),
              Row(
                children: [
                  _buildTag(context, getRoleLabel(ref, hero.id), color),
                  SizedBox(width: 6 * Responsive.scale(context)),
                  _buildTag(context, getDamageLabel(ref, hero.damageType), getDamageColor(hero.damageType)),
                ],
              ),
              SizedBox(height: 8 * Responsive.scale(context)),
              // 레벨 & XP 바
              _buildLevelXpBar(context, hero.id, color),
            ],
          ),
        ),
      ],
    );
  }

  /// 레벨 & XP 진행률 바
  Widget _buildLevelXpBar(BuildContext context, HeroId heroId, Color color) {
    final level = _getHeroLevel(heroId);
    final xp = _getHeroXp(heroId);
    final isMaxLevel = level >= BaseHero.maxLevel;
    final xpNeeded = isMaxLevel ? 0 : BaseHero.xpForLevel(level);
    final xpRatio = isMaxLevel ? 1.0 : (xpNeeded > 0 ? (xp / xpNeeded).clamp(0.0, 1.0) : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 레벨 배지
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * Responsive.scale(context), vertical: 2 * Responsive.scale(context)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Lv.$level',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 12),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 8 * Responsive.scale(context)),
            // XP 바
            Expanded(
              child: Container(
                height: 6 * Responsive.scale(context),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOverlayDim,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: xpRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMaxLevel
                            ? [const Color(0xFFFF8C00), AppColors.sinmyeongGold]
                            : [color.withValues(alpha: 0.6), color],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8 * Responsive.scale(context)),
            // XP 텍스트
            Text(
              isMaxLevel ? 'MAX' : '$xp / $xpNeeded',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 10),
                color: isMaxLevel ? AppColors.sinmyeongGold : AppColors.textSecondary,
                fontWeight: isMaxLevel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 태그 뱃지
  Widget _buildTag(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * Responsive.scale(context), vertical: 3 * Responsive.scale(context)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, 10),
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 배경 이야기 (버튼 클릭 시 상세 팝업 오픈)
  Widget _buildBackstorySection(BuildContext context, WidgetRef ref, HeroData hero, Color color) {
    return Container(
      padding: EdgeInsets.all(12 * Responsive.scale(context)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('📜', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'hero_lore_title',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    AppStrings.trs('hero_lore_prompt').replaceAll('{name}', AppStrings.trs(hero.name)),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 10),
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _showLoreDialog(context, ref, hero, color),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppStrings.trs('hero_lore_read')),
          ),
        ],
      ),
    );
  }

  /// 영웅 상세 스토리 모달 팝업
  void _showLoreDialog(BuildContext context, WidgetRef ref, HeroData hero, Color color) {
    // story_data.dart 에 정의된 상세 텍스트 로드 (없으면 기본 backstory 대체)
    final loreText = StoryData.heroLoreData[hero.id.name] ?? AppStrings.trs(hero.backstory);

    showDialog(
      context: context,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: AppColors.surfaceDark.withAlpha(230),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
            ),
            title: Row(
              children: [
                Text(getHeroEmoji(hero.id), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  AppStrings.trs('hero_legend_title').replaceAll('{name}', AppStrings.trs(hero.name)),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                loreText,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppStrings.get(ref.watch(gameLanguageProvider), 'btn_close'), style: TextStyle(color: color)),
              ),
            ],
          ),
        );
      },
    );
  }
}
