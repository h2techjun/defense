// 해원의 문 - 영웅 해금 축하 다이얼로그
// 새 영웅 해금 시 화려한 팝업으로 알림

import 'dart:math' show min;
import 'package:flutter/material.dart';

import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../data/game_data_loader.dart';
import '../../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/glass_panel.dart';

/// 영웅 해금 축하 다이얼로그 표시
Future<void> showHeroUnlockDialog(BuildContext context, HeroId heroId) async {
  final heroData = GameDataLoader.getHeroes()[heroId];
  if (heroData == null) return;

  final color = _getHeroColor(heroId);
  final emoji = _getHeroEmoji(heroId);

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'HeroUnlock',
    barrierColor: const Color(0xCC000000),
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (context, anim, secondaryAnim) {
      final s = Responsive.scale(context);
      final screenWidth = MediaQuery.of(context).size.width;
      final dialogWidth = min(320.0, screenWidth - 48 * s);

      return Center(
        child: Material(
          color: Colors.transparent,
          child: GlassPanel(
            borderRadius: 20 * s,
            blurAmount: 12,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.black, 0.7)!,
                AppColors.surfaceDark,
                Color.lerp(color, Colors.black, 0.8)!,
              ],
            ),
            borderColor: color.withAlpha(150),
            borderWidth: 2,
            padding: EdgeInsets.all(24 * s),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // 타이틀
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [color, AppColors.textPrimary, color],
                    ).createShader(bounds),
                    child: Text(
                      AppStrings.trs('hero_new_unlock'),
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * s),

                  // 영웅 이모지 (크게)
                  Container(
                    width: 80 * s,
                    height: 80 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withAlpha(60),
                          color.withAlpha(20),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(color: color.withAlpha(100), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: Responsive.fontSize(context, 40)),
                    ),
                  ),
                  SizedBox(height: 16 * s),

                  // 영웅 이름
                  Text(
                    AppStrings.trs(heroData.name),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),

                  // 영웅 칭호
                  Text(
                    AppStrings.trs(heroData.title),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 14),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 12 * s),

                  // 스킬 정보
                  Container(
                    padding: EdgeInsets.all(12 * s),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withAlpha(40)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '✨ ${AppStrings.trs(heroData.skill.name)}',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 14),
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        SizedBox(height: 4 * s),
                        Text(
                          AppStrings.trs(heroData.skill.description),
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 12),
                            color: AppColors.textDisabled,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8 * s),

                  // 스탯
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip('❤️', '${heroData.baseHp.toInt()}'),
                      SizedBox(width: 12 * s),
                      _StatChip('⚔️', '${heroData.baseAttack.toInt()}'),
                      SizedBox(width: 12 * s),
                      _StatChip('🎯', '${heroData.baseRange.toInt()}'),
                    ],
                  ),
                  SizedBox(height: 20 * s),

                  // 확인 버튼
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 32 * s, vertical: 12 * s),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, Color.lerp(color, Colors.white, 0.3)!],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(100),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        AppStrings.trs('hero_ready'),
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      );
    },
  );
}

/// 스탯 칩 위젯
class _StatChip extends StatelessWidget {
  final String icon;
  final String value;

  const _StatChip(this.icon, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceOverlayDim,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$icon $value',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color _getHeroColor(HeroId id) {
  switch (id) {
    case HeroId.kkaebi:
      return AppColors.mintGreen;
    case HeroId.miho:
      return AppColors.cherryBlossom;
    case HeroId.gangrim:
      return const Color(0xFF607D8B);
    case HeroId.sua:
      return AppColors.skyBlue;
    case HeroId.bari:
      return AppColors.sinmyeongGold;
  }
}

String _getHeroEmoji(HeroId id) {
  switch (id) {
    case HeroId.kkaebi:
      return '👹';
    case HeroId.miho:
      return '🦊';
    case HeroId.gangrim:
      return '💀';
    case HeroId.sua:
      return '🌊';
    case HeroId.bari:
      return '🌸';
  }
}
