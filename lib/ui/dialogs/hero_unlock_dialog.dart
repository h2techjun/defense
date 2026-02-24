// 해원의 문 - 영웅 해금 축하 다이얼로그
// 새 영웅 해금 시 화려한 팝업으로 알림

import 'package:flutter/material.dart';

import '../../common/enums.dart';
import '../../data/game_data_loader.dart';
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
      return Center(
        child: Material(
          color: Colors.transparent,
          child: GlassPanel(
            borderRadius: 20,
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
            padding: const EdgeInsets.all(24),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 타이틀
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [color, Colors.white, color],
                    ).createShader(bounds),
                    child: const Text(
                      '✨ 새 영웅 해금! ✨',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 영웅 이모지 (크게)
                  Container(
                    width: 80,
                    height: 80,
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
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 영웅 이름
                  Text(
                    heroData.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),

                  // 영웅 칭호
                  Text(
                    heroData.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 스킬 정보
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withAlpha(40)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '✨ ${heroData.skill.name}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          heroData.skill.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(160),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 스탯
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip('❤️', '${heroData.baseHp.toInt()}'),
                      const SizedBox(width: 12),
                      _StatChip('⚔️', '${heroData.baseAttack.toInt()}'),
                      const SizedBox(width: 12),
                      _StatChip('🎯', '${heroData.baseRange.toInt()}'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 확인 버튼
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                      child: const Text(
                        '출전 준비! 🎩',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$icon $value',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
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
