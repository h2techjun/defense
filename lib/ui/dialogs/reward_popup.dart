// 해원의 문 - 통합 보상 팝업 위젯
// 구매/미션/패스/업적 등 모든 보상 획득 시 사용하는 프리미엄 연출

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../common/responsive.dart';

/// 보상 아이템 데이터
class RewardItem {
  final String emoji;
  final String name;
  final int amount;
  final Color color;

  const RewardItem({
    required this.emoji,
    required this.name,
    required this.amount,
    this.color = Colors.white,
  });
}

/// 통합 보상 팝업 표시
Future<void> showRewardPopup(
  BuildContext context, {
  required String title,
  required List<RewardItem> rewards,
  String? subtitle,
  Color accentColor = AppColors.sinmyeongGold,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'RewardPopup',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return _RewardPopupContent(
        title: title,
        subtitle: subtitle,
        rewards: rewards,
        accentColor: accentColor,
      );
    },
  );
}

class _RewardPopupContent extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<RewardItem> rewards;
  final Color accentColor;

  const _RewardPopupContent({
    required this.title,
    this.subtitle,
    required this.rewards,
    required this.accentColor,
  });

  @override
  State<_RewardPopupContent> createState() => _RewardPopupContentState();
}

class _RewardPopupContentState extends State<_RewardPopupContent>
    with TickerProviderStateMixin {
  late final AnimationController _shineController;
  late final AnimationController _itemController;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _itemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // 파티클 생성
    final rng = Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 2 + rng.nextDouble() * 4,
        speed: 0.3 + rng.nextDouble() * 0.7,
        color: widget.accentColor.withAlpha(80 + rng.nextInt(120)),
      ));
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300 * s,
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgDeepPlum,
                const Color(0xFF16213E),
              ],
            ),
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(
              color: widget.accentColor.withAlpha(120),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withAlpha(60),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 파티클 배경
              ...List.generate(_particles.length, (i) {
                return AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    final p = _particles[i];
                    final offset = (_shineController.value + p.speed) % 1.0;
                    return Positioned(
                      left: p.x * 280 * s,
                      top: (1 - offset) * 200 * s,
                      child: Container(
                        width: p.size * s,
                        height: p.size * s,
                        decoration: BoxDecoration(
                          color: p.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),

              // 메인 콘텐츠
              Padding(
                padding: EdgeInsets.all(24 * s),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 타이틀
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: Responsive.fontSize(context, 22),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (widget.subtitle != null) ...[
                      SizedBox(height: 4 * s),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: Responsive.fontSize(context, 12),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    SizedBox(height: 20 * s),

                    // 보상 아이템 목록
                    ...List.generate(widget.rewards.length, (index) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _itemController,
                          curve: Interval(
                            0.1 * index,
                            0.3 + 0.1 * index,
                            curve: Curves.easeOutCubic,
                          ),
                        )),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _itemController,
                            curve: Interval(
                              0.1 * index,
                              0.3 + 0.1 * index,
                            ),
                          ),
                          child: _buildRewardRow(widget.rewards[index], s),
                        ),
                      );
                    }),

                    SizedBox(height: 20 * s),

                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 44 * s,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accentColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * s),
                          ),
                        ),
                        child: Text(
                          '확인',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardRow(RewardItem reward, double s) {
    return Container(
      margin: EdgeInsets.only(bottom: 8 * s),
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10 * s),
        border: Border.all(color: reward.color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Text(reward.emoji, style: TextStyle(fontSize: 24 * s)),
          SizedBox(width: 12 * s),
          Expanded(
            child: Text(
              reward.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.fontSize(context, 14),
              ),
            ),
          ),
          Text(
            '+${reward.amount}',
            style: TextStyle(
              color: reward.color,
              fontSize: Responsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}
