// 해원의 문 - 게임 결과 다이얼로그 (승리/패배)
// 광고 트리거: 패배 부활 + 승리 2배 보상

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_state.dart';
import '../../l10n/app_strings.dart';
import '../../services/ad_manager.dart';
import '../../common/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/glass_panel.dart';

/// 승리 오버레이
class VictoryOverlay extends ConsumerWidget {
  final VoidCallback onMenu;
  final VoidCallback onReplay;
  final VoidCallback onNextStage;
  final VoidCallback? onDoubleReward; // 광고 보상 2배

  const VictoryOverlay({
    super.key,
    required this.onMenu,
    required this.onReplay,
    required this.onNextStage,
    this.onDoubleReward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final lang = ref.watch(gameLanguageProvider);
    final s = Responsive.uiScale(context);

    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.35).clamp(240.0, 320.0);

    return Container(
      color: const Color(0xBB000000),
      child: Center(
        child: SingleChildScrollView(
          child: GlassPanel(
          borderRadius: 20 * s,
          blurAmount: 12,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDeepPlum, AppColors.surfaceMid],
          ),
          borderColor: AppColors.sinmyeongGold,
          borderWidth: 2,
          padding: EdgeInsets.all(12 * s),
          boxShadow: [
            BoxShadow(
              color: AppColors.sinmyeongGold.withAlpha(68),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
          child: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌸', style: TextStyle(fontSize: Responsive.fontSize(context, 26))),
                SizedBox(height: 6 * s),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.sinmyeongGold, AppColors.peachCoral],
                  ).createShader(bounds),
                  child: Text(
                    AppStrings.get(lang, 'victory_title'),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  AppStrings.get(lang, 'victory_quote'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 10),
                    color: AppColors.lavender,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                // ── 별 평가 ──
                SizedBox(height: 10 * s),
                _StarRating(stars: state.starRating),
                SizedBox(height: 10 * s),

                // ── 통계 ──
                _StatRow(AppStrings.get(lang, 'stat_kills'), '${state.enemiesKilled}', s),
                _StatRow(AppStrings.get(lang, 'stat_hp'), '${state.gatewayHp}/${state.maxGatewayHp}', s),
                _StatRow(AppStrings.get(lang, 'stat_score'), '${state.score}', s),
                SizedBox(height: 12 * s),

                // ── 광고 보상 2배 버튼 ──
                if (onDoubleReward != null && AdManager.instance.canShowRewardedAd)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12 * s),
                    child: GestureDetector(
                      onTap: onDoubleReward,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10 * s),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                          ),
                          borderRadius: BorderRadius.circular(10 * s),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withAlpha(80),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('📺', style: TextStyle(fontSize: Responsive.fontSize(context, 16))),
                            SizedBox(width: 8 * s),
                            Text(
                              '광고 보고 보상 2배!',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: Responsive.fontSize(context, 13),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── 3버튼 ──
                Row(
                  children: [
                    // 나가기
                    Expanded(
                      child: _DialogButton(
                        label: AppStrings.get(lang, 'return_menu'),
                        icon: Icons.exit_to_app,
                        onTap: onMenu,
                        s: s,
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    // 다시 하기
                    Expanded(
                      child: _DialogButton(
                        label: AppStrings.get(lang, 'replay'),
                        icon: Icons.replay,
                        onTap: onReplay,
                        s: s,
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    // 다음 스테이지
                    Expanded(
                      flex: 1,
                      child: _DialogButton(
                        label: AppStrings.get(lang, 'next_stage'),
                        icon: Icons.arrow_forward,
                        onTap: onNextStage,
                        isPrimary: true,
                        s: s,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// 패배 오버레이
class DefeatOverlay extends ConsumerWidget {
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback? onRevive; // 광고 부활

  const DefeatOverlay({
    super.key,
    required this.onRetry,
    required this.onMenu,
    this.onRevive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final lang = ref.watch(gameLanguageProvider);
    final s = Responsive.uiScale(context);
    
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.35).clamp(240.0, 320.0);

    return Container(
      color: const Color(0xBB000000),
      child: Center(
        child: SingleChildScrollView(
          child: GlassPanel(
          borderRadius: 20 * s,
          blurAmount: 12,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDeepPlum, Color(0xFF2D0B1E)],
          ),
          borderColor: AppColors.berserkRed,
          borderWidth: 2,
          padding: EdgeInsets.all(12 * s),
          boxShadow: [
            BoxShadow(
              color: AppColors.berserkRed.withAlpha(68),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
          child: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('💀', style: TextStyle(fontSize: Responsive.fontSize(context, 26))),
                SizedBox(height: 6 * s),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.berserkRed, AppColors.peachCoral],
                  ).createShader(bounds),
                  child: Text(
                    AppStrings.get(lang, 'defeat_title'),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  AppStrings.get(lang, 'defeat_quote'),
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 10),
                    color: const Color(0xFF886666),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 12 * s),

                // ── 팁 ──
                Container(
                  padding: EdgeInsets.all(8 * s),
                  decoration: BoxDecoration(
                    color: AppColors.sinmyeongGold.withAlpha(34),
                    borderRadius: BorderRadius.circular(8 * s),
                    border: Border.all(color: AppColors.sinmyeongGold.withAlpha(68)),
                  ),
                  child: Row(
                    children: [
                      Text('💡', style: TextStyle(fontSize: Responsive.fontSize(context, 14))),
                      SizedBox(width: 8 * s),
                      Expanded(
                        child: Text(
                          AppStrings.get(lang, 'defeat_tip'),
                          style: TextStyle(
                            color: AppColors.sinmyeongGold,
                            fontSize: Responsive.fontSize(context, 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12 * s),

                // ── 광고 부활 버튼 ──
                if (onRevive != null && AdManager.instance.canShowRewardedAd)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12 * s),
                    child: GestureDetector(
                      onTap: onRevive,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10 * s),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22BB22), Color(0xFF44DD44)],
                          ),
                          borderRadius: BorderRadius.circular(10 * s),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withAlpha(80),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('📺', style: TextStyle(fontSize: Responsive.fontSize(context, 16))),
                            SizedBox(width: 8 * s),
                            Text(
                              '광고 보고 부활! (HP 50%)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.fontSize(context, 13),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── 2버튼 ──
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: AppStrings.get(lang, 'return_menu'),
                        icon: Icons.exit_to_app,
                        onTap: onMenu,
                        s: s,
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    Expanded(
                      flex: 2,
                      child: _DialogButton(
                        label: AppStrings.get(lang, 'retry'),
                        icon: Icons.replay,
                        onTap: onRetry,
                        isPrimary: true,
                        s: s,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// 별 평가 위젯 (순차 팝업 애니메이션)
class _StarRating extends StatefulWidget {
  final int stars;
  const _StarRating({required this.stars});

  @override
  State<_StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<_StarRating>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    _scaleAnims = _controllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();

    _opacityAnims = _controllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: const Interval(0, 0.4)),
      );
    }).toList();

    // 순차 시작 (0.4초 간격)
    for (int i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 400 + i * 400), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isEarned = i < widget.stars;
        if (!isEarned) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.star_outline_rounded,
              size: 36,
              color: const Color(0x44FFFFFF),
            ),
          );
        }
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: _opacityAnims[i].value,
                child: Transform.scale(
                  scale: _scaleAnims[i].value,
                  child: Icon(
                    Icons.star_rounded,
                    size: 44,
                    color: AppColors.sinmyeongGold,
                    shadows: [
                      Shadow(
                        color: AppColors.sinmyeongGold.withAlpha(136),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final double s;

  const _StatRow(this.label, this.value, this.s);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3 * s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.lavender, fontSize: Responsive.fontSize(context, 11))),
          Text(value, style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 11), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final double s;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.s,
    this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10 * s),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.lavender, Color(0xFF9944CC)],
                )
              : null,
          color: isPrimary ? null : const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(10 * s),
          border: Border.all(
            color: isPrimary
                ? AppColors.lavender
                : const Color(0x44FFFFFF),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: Responsive.fontSize(context, 14),
                color: isPrimary ? Colors.white : const Color(0xFFBB99DD)),
              SizedBox(width: 4 * s),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.lavender,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                  fontSize: Responsive.fontSize(context, 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
