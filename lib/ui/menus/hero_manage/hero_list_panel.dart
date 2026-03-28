// 해원의 문 - 영웅 목록 패널 (왼쪽)
// 영웅 리스트 + 영웅 카드

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/enums.dart';
import '../../../common/responsive.dart';
import '../../../data/game_data_loader.dart';
import '../../../data/models/hero_data.dart';
import '../../../l10n/app_strings.dart';
import '../../../state/skin_provider.dart';
import '../../common/hero_sprite_viewer.dart';
import '../../theme/app_colors.dart';
import '../../widgets/touch_button.dart';
import 'hero_helpers.dart';

class HeroListPanel extends ConsumerWidget {
  final HeroId selectedHeroId;
  final ValueChanged<HeroId> onHeroSelected;

  const HeroListPanel({
    super.key,
    required this.selectedHeroId,
    required this.onHeroSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinState = ref.watch(skinProvider);
    final heroes = GameDataLoader.getHeroes().values.toList();

    return Container(
      margin: EdgeInsets.only(left: 12 * Responsive.scale(context), bottom: 12 * Responsive.scale(context)),
      decoration: BoxDecoration(
        color: const Color(0x15FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceOverlayDim),
      ),
      child: ListView.builder(
        padding: EdgeInsets.all(8 * Responsive.scale(context)),
        itemCount: heroes.length,
        itemBuilder: (context, index) {
          final hero = heroes[index];
          final isSelected = hero.id == selectedHeroId;
          return _buildHeroCard(context, ref, hero, isSelected, skinState);
        },
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, WidgetRef ref, HeroData hero, bool isSelected, SkinState skinState) {
    final color = getHeroColor(hero.id);

    return TouchButton(
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.zero,
      onTap: () {
        onHeroSelected(hero.id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(bottom: 6 * Responsive.scale(context)),
            padding: EdgeInsets.all(10 * Responsive.scale(context)),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: isSelected ? null : const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color.withValues(alpha: 0.6) : const Color(0x11FFFFFF),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // 영웅 아이콘
                Container(
                  width: 40 * Responsive.scale(context),
                  height: 40 * Responsive.scale(context),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color, color.withValues(alpha: 0.3)],
                    ),
                    border: isSelected
                        ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5)
                        : null,
                  ),
                  child: ClipOval(
                    child: HeroSpriteViewer(
                      imagePath: 'assets/images/heroes/${getHeroFileName(hero.id)}_tier1_sprites.png',
                      width: 40 * Responsive.scale(context),
                      height: 40 * Responsive.scale(context),
                      fallbackText: getHeroEmoji(hero.id),
                    ),
                  ),
                ),
                SizedBox(width: 8 * Responsive.scale(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.trs(hero.name),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        getRoleLabel(ref, hero.id),
                        style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontSize: Responsive.fontSize(context, 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
