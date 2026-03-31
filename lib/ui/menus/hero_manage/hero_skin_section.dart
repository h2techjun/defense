// 해원의 문 - 영웅 스킨 섹션
// 장착 스킨 카드 + 등급별 4개 스킨 미리보기

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/sound_manager.dart';
import '../../../common/responsive.dart';
import '../../../data/models/hero_data.dart';
import '../../../data/models/skin_data.dart';
import '../../../l10n/app_strings.dart';
import '../../../state/skin_provider.dart';
import '../../common/hero_sprite_viewer.dart';
import '../../theme/app_colors.dart';
import '../../../common/asset_paths.dart';
import 'hero_helpers.dart';

class HeroSkinSection extends ConsumerWidget {
  final HeroData hero;
  final Color color;

  const HeroSkinSection({
    super.key,
    required this.hero,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinState = ref.watch(skinProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEquippedSkinCard(context, ref, hero, color, skinState),
        SizedBox(height: 16 * Responsive.scale(context)),
        _buildSkinPreviewSection(context, ref, hero, color, skinState),
      ],
    );
  }

  Widget _buildEquippedSkinCard(BuildContext context, WidgetRef ref, HeroData hero, Color color, SkinState skinState) {
    final s = Responsive.scale(context);
    final skinId = skinState.equippedSkins[hero.id];
    final skins = getSkinsForHero(hero.id);
    final skin = skinId != null
        ? skins.firstWhere((s) => s.id == skinId, orElse: () => skins.first)
        : skins.where((s) => s.rarity == SkinRarity.common).firstOrNull ?? skins.first;

    final double glowIntensity = switch (skin.rarity) {
      SkinRarity.common => 0.0,
      SkinRarity.rare => 8.0,
      SkinRarity.epic => 14.0,
      SkinRarity.legendary => 18.0,
    };

    final int tier = switch (skin.rarity) {
      SkinRarity.common => 1,
      SkinRarity.rare => 2,
      SkinRarity.epic => 3,
      SkinRarity.legendary => 4,
    };

    return Container(
      height: 140 * s,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(
          color: AppColors.sinmyeongGold,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sinmyeongGold.withAlpha(60),
            blurRadius: glowIntensity > 0 ? glowIntensity : 4.0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12 * s),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 그라디언트
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    skin.primaryColor.withAlpha(80),
                    Colors.black.withAlpha(180),
                    skin.secondaryColor.withAlpha(60),
                  ],
                ),
              ),
            ),
            // 영웅 스프라이트 렌더링
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: 8 * s),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white,
                        skin.primaryColor.withAlpha(160),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 0.85, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ColorFiltered(
                    colorFilter: skin.rarity == SkinRarity.common
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                        : ColorFilter.mode(
                            skin.primaryColor.withAlpha(40),
                            BlendMode.srcATop,
                          ),
                    child: HeroSpriteViewer(
                      imagePath: AssetPaths.asset('heroes/${getHeroFileName(hero.id)}_tier${tier}_sprites'),
                      width: double.infinity,
                      height: 140 * s,
                      fallbackText: skin.rarity.emoji,
                    ),
                  ),
                ),
              ),
            ),
            // 왼쪽 상단 스킨 이름 배지
            Positioned(
              left: 12 * s,
              top: 12 * s,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(8 * s),
                  border: Border.all(color: skin.rarity.color.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skin.rarity.emoji,
                      style: TextStyle(fontSize: 12 * s),
                    ),
                    SizedBox(width: 4 * s),
                    Text(
                      tr(ref, skin.name),
                      style: TextStyle(
                        color: skin.rarity.color,
                        fontSize: 12 * s,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 스킨 미리보기 섹션 (코스메틱 -- 기본/정제/명작/전설)
  /// 탭하여 보유 스킨 장착 가능, 장착 중인 스킨 하이라이트
  Widget _buildSkinPreviewSection(BuildContext context, WidgetRef ref, HeroData hero, Color color, SkinState skinState) {
    final heroFileName = getHeroFileName(hero.id);
    final rarities = SkinRarity.values;
    final heroSkins = getSkinsForHero(hero.id);
    final equippedSkinId = skinState.equippedSkins[hero.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          children: [
            Text(
              '🎨 ${AppStrings.get(ref.watch(gameLanguageProvider), 'skin_preview')}',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * Responsive.scale(context)),
        // 스킨 카드 4개 가로 배치
        Row(
          children: List.generate(rarities.length, (i) {
            final rarity = rarities[i];
            final tierNumber = i + 1;

            // 이 등급에 해당하는 스킨 찾기
            final skinForRarity = heroSkins
                .where((s) => s.rarity == rarity)
                .firstOrNull;
            final skinId = skinForRarity?.id;
            final isOwned = skinId != null && skinState.ownedSkins.contains(skinId);
            final isEquipped = skinId != null && skinId == equippedSkinId;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (isOwned && !isEquipped && skinId != null) {
                    ref.read(skinProvider.notifier).equipSkin(hero.id, skinId);
                    SoundManager.instance.playSfx(SfxType.uiClick);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < rarities.length - 1 ? 6 : 0),
                  padding: EdgeInsets.symmetric(vertical: 8 * Responsive.scale(context)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isEquipped
                          ? [
                              rarity.color.withValues(alpha: 0.35),
                              rarity.color.withValues(alpha: 0.12),
                            ]
                          : [
                              rarity.color.withValues(alpha: 0.15),
                              rarity.color.withValues(alpha: 0.03),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isEquipped
                          ? rarity.color.withValues(alpha: 0.8)
                          : rarity.color.withValues(alpha: 0.3),
                      width: isEquipped ? 2.0 : 1.0,
                    ),
                    boxShadow: isEquipped
                        ? [BoxShadow(color: rarity.color.withValues(alpha: 0.4), blurRadius: 10)]
                        : rarity.hasGlow
                            ? [BoxShadow(color: rarity.color.withValues(alpha: 0.2), blurRadius: 8)]
                            : null,
                  ),
                  child: Stack(
                    children: [
                      // 메인 콘텐츠
                      Opacity(
                        opacity: isOwned ? 1.0 : 0.4,
                        child: Column(
                          children: [
                            // 스프라이트
                            Container(
                              width: 36 * Responsive.scale(context),
                              height: 36 * Responsive.scale(context),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: rarity.hasBorder
                                    ? Border.all(color: rarity.color, width: 1.5)
                                    : null,
                                boxShadow: rarity.hasGlow
                                    ? [BoxShadow(color: rarity.color.withValues(alpha: 0.5), blurRadius: 8)]
                                    : null,
                              ),
                              child: ClipOval(
                                child: HeroSpriteViewer(
                                  imagePath: AssetPaths.asset('heroes/${heroFileName}_tier${tierNumber}_sprites'),
                                  width: 36 * Responsive.scale(context),
                                  height: 36 * Responsive.scale(context),
                                  fallbackText: rarity.emoji,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // 등급 이름
                            Text(
                              tr(ref, rarity.displayName),
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 9),
                                color: isEquipped ? Colors.white : rarity.color,
                                fontWeight: isEquipped ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 장착 중 체크마크
                      if (isEquipped)
                        Positioned(
                          top: 0,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: rarity.color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 10 * Responsive.scale(context),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // 미보유 잠금 아이콘
                      if (!isOwned)
                        Positioned.fill(
                          child: Center(
                            child: Icon(
                              Icons.lock_outline,
                              size: 18 * Responsive.scale(context),
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
