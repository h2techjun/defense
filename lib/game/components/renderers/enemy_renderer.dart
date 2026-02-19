// 해원의 문 — 적 커스텀 렌더러
// Canvas API 기반 고품질 적 그래픽 (귀신/요괴 테마)

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show LinearGradient, RadialGradient, Alignment;
import '../../../common/enums.dart';

/// 적 타입별 고품질 커스텀 렌더링
class EnemyRenderer extends PositionComponent {
  final EnemyId enemyId;
  final ArmorType armorType;
  final bool isBoss;
  final bool isFlying;
  
  // 색상 변경용 (버서크 등)
  Color? overrideColor;
  
  EnemyRenderer({
    required this.enemyId,
    required this.armorType,
    this.isBoss = false,
    this.isFlying = false,
    this.overrideColor,
    required Vector2 size,
  }) : super(size: size);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final s = size.x;
    final center = Offset(s / 2, s / 2);
    final color = overrideColor ?? _getBaseColor();
    
    // 보스 외곽 글로우
    if (isBoss) {
      canvas.drawCircle(center, s * 0.48, Paint()..color = const Color(0x33FF0000));
      canvas.drawCircle(center, s * 0.45, Paint()..color = const Color(0x22FF4444));
    }
    
    // 비행 마크
    if (isFlying) {
      _renderWings(canvas, s, center);
    }
    
    switch (enemyId) {
      case EnemyId.hungryGhost:
        _renderHungryGhost(canvas, s, center, color);
        break;
      case EnemyId.strawShoeSpirit:
        _renderStrawShoe(canvas, s, center, color);
        break;
      case EnemyId.maidenGhost:
        _renderMaiden(canvas, s, center, color);
        break;
      case EnemyId.eggGhost:
        _renderEggGhost(canvas, s, center, color);
        break;
      case EnemyId.burdenedLaborer:
        _renderBurdened(canvas, s, center, color);
        break;
      case EnemyId.bossOgreLord:
        _renderOgreLord(canvas, s, center, color);
        break;
      default:
        // 챕터 2/3 적 — 기본 렌더링
        _renderDefaultEnemy(canvas, s, center, color);
        break;
    }
  }
  
  /// 허기귀신 — 배고픈 둥근 귀신, 입 벌린 모습
  void _renderHungryGhost(Canvas canvas, double s, Offset center, Color color) {
    // 유령 몸통 (물결 그라데이션)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [color.withAlpha(220), color, color.withAlpha(150)],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.38));
    canvas.drawCircle(center, s * 0.38, bodyPaint);
    
    // 몸체 아래 물결 (유령 꼬리)
    final tailPath = Path()
      ..moveTo(s * 0.12, s * 0.5)
      ..quadraticBezierTo(s * 0.2, s * 0.85, s * 0.3, s * 0.7)
      ..quadraticBezierTo(s * 0.4, s * 0.55, s * 0.5, s * 0.75)
      ..quadraticBezierTo(s * 0.6, s * 0.9, s * 0.7, s * 0.7)
      ..quadraticBezierTo(s * 0.8, s * 0.55, s * 0.88, s * 0.5);
    canvas.drawPath(tailPath, Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.fill);
    
    // 눈 (빨간 빛)
    canvas.drawCircle(Offset(s * 0.37, s * 0.35), 3, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(s * 0.63, s * 0.35), 3, Paint()..color = const Color(0xFFFF1744));
    // 눈 하이라이트
    canvas.drawCircle(Offset(s * 0.36, s * 0.33), 1, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(Offset(s * 0.62, s * 0.33), 1, Paint()..color = const Color(0xFFFFFFFF));
    
    // 입 (벌린 입 — 타원형)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * 0.5, s * 0.55), width: s * 0.2, height: s * 0.15),
      Paint()..color = const Color(0xDD000000),
    );
  }
  
  /// 짚신귀 — 빠른 삼각형 귀신
  void _renderStrawShoe(Canvas canvas, double s, Offset center, Color color) {
    // 빠른 이동 잔상
    canvas.drawCircle(
      center + Offset(-s * 0.1, 0),
      s * 0.2,
      Paint()..color = color.withAlpha(40),
    );
    
    // 날카로운 삼각 몸체
    final bodyPath = Path()
      ..moveTo(s * 0.5, s * 0.05)
      ..lineTo(s * 0.1, s * 0.85)
      ..quadraticBezierTo(s * 0.5, s * 0.7, s * 0.9, s * 0.85)
      ..close();
    
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withAlpha(180)],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawPath(bodyPath, bodyPaint);
    
    // 테두리
    canvas.drawPath(bodyPath, Paint()
      ..color = color.withAlpha(255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    
    // 눈 (노란 발광)
    canvas.drawCircle(Offset(s * 0.4, s * 0.4), 2.5, Paint()..color = const Color(0xFFFFEB3B));
    canvas.drawCircle(Offset(s * 0.6, s * 0.4), 2.5, Paint()..color = const Color(0xFFFFEB3B));
    
    // 속도 줄무늬
    final speedPaint = Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.2, s * 0.3), Offset(s * 0.05, s * 0.25), speedPaint);
    canvas.drawLine(Offset(s * 0.2, s * 0.5), Offset(s * 0.03, s * 0.48), speedPaint);
  }
  
  /// 손각시 — 처녀귀신, 한복 치마 느낌 + 오라
  void _renderMaiden(Canvas canvas, double s, Offset center, Color color) {
    // 저주 오라
    canvas.drawCircle(
      center,
      s * 0.42,
      Paint()
        ..color = const Color(0x226A0DAD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // 치마 (삼각 + 곡선)
    final dressPath = Path()
      ..moveTo(s * 0.5, s * 0.15)          // 머리
      ..lineTo(s * 0.15, s * 0.9)          // 좌하
      ..quadraticBezierTo(s * 0.5, s * 0.8, s * 0.85, s * 0.9)  // 곡선 치마 밑단
      ..close();
    
    final dressPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withAlpha(160), color.withAlpha(100)],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawPath(dressPath, dressPaint);
    canvas.drawPath(dressPath, Paint()
      ..color = color.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    
    // 머리카락 (양쪽으로 흘러내림)
    final hairPaint = Paint()
      ..color = const Color(0xCC111111)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.42, s * 0.2), Offset(s * 0.25, s * 0.55), hairPaint);
    canvas.drawLine(Offset(s * 0.58, s * 0.2), Offset(s * 0.75, s * 0.55), hairPaint);
    
    // 얼굴 (창백한 원)
    canvas.drawCircle(Offset(s * 0.5, s * 0.22), s * 0.1, Paint()..color = const Color(0xFFE0E0E0));
    
    // 눈 (하나 — 원귀 스타일)
    canvas.drawCircle(Offset(s * 0.5, s * 0.22), 2, Paint()..color = const Color(0xFFFF0000));
  }
  
  /// 달걀귀신 — 달걀형 민머리 귀신 (은신 가능)
  void _renderEggGhost(Canvas canvas, double s, Offset center, Color color) {
    // 타원형 몸체
    final bodyRect = Rect.fromCenter(
      center: center,
      width: s * 0.55,
      height: s * 0.75,
    );
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.3),
        radius: 0.85,
        colors: [color.withAlpha(200), color, color.withAlpha(180)],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);
    
    // 테두리
    canvas.drawOval(bodyRect, Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    
    // 매끄러운 표면 하이라이트
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(-s * 0.06, -s * 0.1), width: s * 0.2, height: s * 0.25),
      Paint()..color = const Color(0x22FFFFFF),
    );
    
    // 두 눈 (무표정)
    canvas.drawCircle(Offset(s * 0.4, s * 0.4), 2.5, Paint()..color = const Color(0xCC000000));
    canvas.drawCircle(Offset(s * 0.6, s * 0.4), 2.5, Paint()..color = const Color(0xCC000000));
  }
  
  /// 짐꾼귀 — 무거운 짐을 진 귀신
  void _renderBurdened(Canvas canvas, double s, Offset center, Color color) {
    // 짐 (등에 진 상자)
    final loadRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + Offset(0, -s * 0.12), width: s * 0.6, height: s * 0.35),
      const Radius.circular(3),
    );
    canvas.drawRRect(loadRect, Paint()..color = const Color(0xFF795548));
    canvas.drawRRect(loadRect, Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    // 짐 밧줄
    canvas.drawLine(
      Offset(s * 0.25, s * 0.25),
      Offset(s * 0.75, s * 0.25),
      Paint()..color = const Color(0xAAD7CCC8)..strokeWidth = 1.5,
    );
    
    // 몸체 (사각형 + 그라데이션)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + Offset(0, s * 0.15), width: s * 0.5, height: s * 0.45),
      const Radius.circular(4),
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withAlpha(180)],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawRRect(bodyRect, bodyPaint);
    
    // 눈 (피곤한 모습)
    canvas.drawLine(
      Offset(s * 0.37, s * 0.45),
      Offset(s * 0.43, s * 0.45),
      Paint()..color = const Color(0xCC000000)..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(s * 0.57, s * 0.45),
      Offset(s * 0.63, s * 0.45),
      Paint()..color = const Color(0xCC000000)..strokeWidth = 2,
    );
    
    // 다리 (두꺼운 선)
    canvas.drawLine(
      Offset(s * 0.38, s * 0.6),
      Offset(s * 0.35, s * 0.85),
      Paint()..color = color..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(s * 0.62, s * 0.6),
      Offset(s * 0.65, s * 0.85),
      Paint()..color = color..strokeWidth = 3,
    );
  }
  
  /// 두억시니 (보스) — 거대한 도깨비
  void _renderOgreLord(Canvas canvas, double s, Offset center, Color color) {
    // 불꽃 오라
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final flameX = center.dx + math.cos(angle) * s * 0.42;
      final flameY = center.dy + math.sin(angle) * s * 0.42;
      canvas.drawCircle(
        Offset(flameX, flameY),
        3,
        Paint()..color = const Color(0x66FF6600),
      );
    }
    
    // 거대한 몸통
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.2),
        radius: 0.8,
        colors: [color, color.withAlpha(200), const Color(0xFF1A0000)],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.38));
    canvas.drawCircle(center, s * 0.38, bodyPaint);
    
    // 테두리
    canvas.drawCircle(center, s * 0.38, Paint()
      ..color = const Color(0xAAFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    
    // 뿔 (좌)
    final hornLPath = Path()
      ..moveTo(s * 0.3, s * 0.2)
      ..lineTo(s * 0.2, s * 0.0)
      ..lineTo(s * 0.35, s * 0.15)
      ..close();
    canvas.drawPath(hornLPath, Paint()..color = const Color(0xFFFFAB00));
    
    // 뿔 (우)
    final hornRPath = Path()
      ..moveTo(s * 0.7, s * 0.2)
      ..lineTo(s * 0.8, s * 0.0)
      ..lineTo(s * 0.65, s * 0.15)
      ..close();
    canvas.drawPath(hornRPath, Paint()..color = const Color(0xFFFFAB00));
    
    // 무서운 눈 (빨간 발광)
    canvas.drawCircle(Offset(s * 0.38, s * 0.4), 4, Paint()..color = const Color(0xFFFF0000));
    canvas.drawCircle(Offset(s * 0.62, s * 0.4), 4, Paint()..color = const Color(0xFFFF0000));
    canvas.drawCircle(Offset(s * 0.37, s * 0.38), 1.5, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(Offset(s * 0.61, s * 0.38), 1.5, Paint()..color = const Color(0xFFFFFFFF));
    
    // 입 (이빨 있는)
    canvas.drawLine(
      Offset(s * 0.35, s * 0.58),
      Offset(s * 0.65, s * 0.58),
      Paint()..color = const Color(0xDD000000)..strokeWidth = 3,
    );
    // 이빨
    canvas.drawLine(Offset(s * 0.42, s * 0.56), Offset(s * 0.42, s * 0.63), 
      Paint()..color = const Color(0xFFFFFFFF)..strokeWidth = 2);
    canvas.drawLine(Offset(s * 0.58, s * 0.56), Offset(s * 0.58, s * 0.63),
      Paint()..color = const Color(0xFFFFFFFF)..strokeWidth = 2);
  }
  
  /// 기본 적 렌더링 (챕터 2/3용)
  void _renderDefaultEnemy(Canvas canvas, double s, Offset center, Color color) {
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [color.withAlpha(220), color],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.35));
    canvas.drawCircle(center, s * 0.35, bodyPaint);
    
    // 눈
    canvas.drawCircle(Offset(s * 0.4, s * 0.42), 2.5, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(s * 0.6, s * 0.42), 2.5, Paint()..color = const Color(0xFFFF1744));
  }
  
  /// 비행 날개
  void _renderWings(Canvas canvas, double s, Offset center) {
    final wingPaint = Paint()
      ..color = const Color(0x44FFFFFF)
      ..style = PaintingStyle.fill;
    
    // 왼쪽 날개
    final leftWing = Path()
      ..moveTo(s * 0.3, s * 0.5)
      ..quadraticBezierTo(s * 0.0, s * 0.2, s * 0.15, s * 0.5)
      ..close();
    canvas.drawPath(leftWing, wingPaint);
    
    // 오른쪽 날개
    final rightWing = Path()
      ..moveTo(s * 0.7, s * 0.5)
      ..quadraticBezierTo(s * 1.0, s * 0.2, s * 0.85, s * 0.5)
      ..close();
    canvas.drawPath(rightWing, wingPaint);
  }
  
  Color _getBaseColor() {
    switch (armorType) {
      case ArmorType.physical:
        return const Color(0xFF8B4513);
      case ArmorType.spiritual:
        return const Color(0xFF6A0DAD);
      case ArmorType.yokai:
        return const Color(0xFFDC143C);
    }
  }
}
