// 해원의 문 - 알림 뱃지 위젯
// 미수령 보상 표시용 빨간 점 뱃지

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 빨간 점 알림 뱃지
/// 아이콘이나 텍스트 위에 겹쳐서 미수령 보상 알림 표시
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final bool show;
  final int? count;
  final double size;
  final Color color;

  const NotificationBadge({
    super.key,
    required this.child,
    this.show = true,
    this.count,
    this.size = 12,
    this.color = AppColors.berserkRed,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: count != null && count! > 0
              ? _buildCountBadge()
              : _buildDotBadge(),
        ),
      ],
    );
  }

  Widget _buildDotBadge() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.scaffoldBg, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(150),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge() {
    final text = count! > 99 ? '99+' : '$count';
    return Container(
      constraints: BoxConstraints(minWidth: size + 4, minHeight: size + 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: const Color(0xFF0D0221), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(150),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.7,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}
