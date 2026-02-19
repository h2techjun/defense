// 해원의 문 — 영웅 대사 말풍선 컴포넌트
// 영웅 머리 위에 대사를 표시하고 일정 시간 후 페이드아웃

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 영웅 위에 말풍선을 표시하는 Flame 컴포넌트
class BarkBubble extends PositionComponent {
  final String text;
  final double displayDuration;
  final double fadeDuration;

  double _timer = 0;
  double _opacity = 1.0;
  bool _fading = false;

  BarkBubble({
    required this.text,
    required Vector2 heroPosition,
    this.displayDuration = 2.5,
    this.fadeDuration = 0.5,
  }) : super(
          position: Vector2(heroPosition.x, heroPosition.y - 30),
          priority: 1000, // UI 최상단
        );

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (!_fading && _timer >= displayDuration) {
      _fading = true;
      _timer = 0;
    }

    if (_fading) {
      _opacity = max(0, 1.0 - (_timer / fadeDuration));
      if (_opacity <= 0) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_opacity <= 0) return;

    const maxWidth = 140.0;
    const padding = 6.0;
    const borderRadius = 8.0;
    const tailHeight = 6.0;

    // 텍스트 레이아웃
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withOpacity(_opacity),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    final bubbleWidth = textPainter.width + padding * 2;
    final bubbleHeight = textPainter.height + padding * 2;

    // 버블 위치 (영웅 중심 위)
    final bubbleX = -bubbleWidth / 2;
    final bubbleY = -(bubbleHeight + tailHeight);

    // 버블 배경
    final bgPaint = Paint()
      ..color = const Color(0xDD2D1B69).withOpacity(_opacity * 0.9);
    final borderPaint = Paint()
      ..color = const Color(0xFFE8D5B7).withOpacity(_opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bubbleX, bubbleY, bubbleWidth, bubbleHeight),
      const Radius.circular(borderRadius),
    );

    canvas.drawRRect(bubbleRect, bgPaint);
    canvas.drawRRect(bubbleRect, borderPaint);

    // 꼬리 삼각형
    final tailPath = Path()
      ..moveTo(-4, bubbleY + bubbleHeight)
      ..lineTo(0, bubbleY + bubbleHeight + tailHeight)
      ..lineTo(4, bubbleY + bubbleHeight)
      ..close();
    canvas.drawPath(tailPath, bgPaint);

    // 텍스트 렌더링
    textPainter.paint(
      canvas,
      Offset(bubbleX + padding, bubbleY + padding),
    );
  }
}
