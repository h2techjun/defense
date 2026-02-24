// 🔮 글래스모피즘 패널 위젯
// GDD §1-B.4 "반투명 글래스모피즘 (backdrop-blur + 어두운 오버레이)"
// 재사용 가능한 블러+반투명 배경 위젯
//
// 🔴 BackdropFilter 성능 주의사항:
//   - 저사양 기기에서 심각한 FPS 하락 가능 (사례: 32fps → 7fps)
//   - GPU에서 매 프레임 실시간 블러 연산 → 큰 영역일수록 부하 증가
//   - 해결: RepaintBoundary 래핑, blur 영역 최소화, enabled=false 로 비활성화
//   - 추천: sigmaX/Y를 6~10 범위로 유지, 중첩 사용 금지

import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 글래스모피즘 패널 — 블러 + 반투명 배경 + 발광 보더
///
/// [enabled]가 false이면 BackdropFilter를 건너뛰고 배경만 렌더링.
/// 저사양 기기에서 성능 문제 발생 시 전역적으로 비활성화 가능.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final double blurAmount;
  final Color? backgroundColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final bool enabled;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blurAmount = 10.0,
    this.backgroundColor,
    this.gradient,
    this.padding,
    this.margin,
    this.boxShadow,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? (gradient == null ? AppColors.surfaceDark.withAlpha(160) : null),
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withAlpha(25),
          width: borderWidth,
        ),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    // 저사양 기기 성능 모드: 블러 없이 반투명 배경만 사용
    if (!enabled) {
      return Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: container,
        ),
      );
    }

    // RepaintBoundary로 블러 영역의 불필요한 재렌더링 방지
    return RepaintBoundary(
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurAmount,
              sigmaY: blurAmount,
            ),
            child: container,
          ),
        ),
      ),
    );
  }
}

/// 글래스모피즘 카드 — GlassPanel + 내부 그림자 효과
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.glowColor,
    this.borderRadius = 12.0,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panel = GlassPanel(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      borderColor: glowColor?.withAlpha(60) ?? Colors.white.withAlpha(20),
      boxShadow: glowColor != null
          ? [
              BoxShadow(
                color: glowColor!.withAlpha(30),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ]
          : null,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: panel);
    }
    return panel;
  }
}
