import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// 모바일/태블릿 타겟 공용 터치 버튼 (Ripple + Haptic 피드백 + 최소 48px 영역 적용)
class TouchButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double minWidth;
  final double minHeight;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? hoverColor;
  final EdgeInsetsGeometry padding;
  final Decoration? decoration;
  final String? semanticLabel;

  const TouchButton({
    super.key,
    required this.child,
    required this.onTap,
    this.minWidth = 48.0,
    this.minHeight = 48.0,
    this.borderRadius,
    this.splashColor,
    this.hoverColor,
    this.padding = EdgeInsets.zero,
    this.decoration,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // 안드로이드/iOS 권장 기본 햅틱 피드백 트리거
            HapticFeedback.lightImpact();
            onTap();
          },
          splashColor: splashColor ?? AppColors.surfaceOverlayDim,
          hoverColor: hoverColor ?? AppColors.surfaceOverlayDim,
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          child: Container(
            padding: padding,
            constraints: BoxConstraints(
              minWidth: minWidth,
              minHeight: minHeight,
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );

    if (semanticLabel != null) {
      return Semantics(
        button: true,
        label: semanticLabel,
        child: content,
      );
    }
    return content;
  }
}
