// 해원의 문 — 타워 커스텀 렌더러
// 현대적 아기자기 스타일 — 둥근 형태 + 파스텔/네온 그라데이션

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show LinearGradient, RadialGradient, Alignment;
import '../../../common/enums.dart';

/// 타워 타입별 현대적 아기자기 커스텀 렌더링
class TowerRenderer extends PositionComponent {
  final TowerType type;
  final int upgradeLevel;
  
  TowerRenderer({
    required this.type,
    this.upgradeLevel = 0,
    required Vector2 size,
  }) : super(size: size);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final s = size.x;
    final center = Offset(s / 2, s / 2);
    
    switch (type) {
      case TowerType.archer:
        _renderArcher(canvas, s, center);
        break;
      case TowerType.barracks:
        _renderBarracks(canvas, s, center);
        break;
      case TowerType.shaman:
        _renderShaman(canvas, s, center);
        break;
      case TowerType.artillery:
        _renderArtillery(canvas, s, center);
        break;
      case TowerType.sotdae:
        _renderSotdae(canvas, s, center);
        break;
    }
    
    // 업그레이드 인디케이터
    if (upgradeLevel > 0) {
      _renderUpgradeGlow(canvas, s, center);
    }
  }
  
  /// 궁수탑 — 둥근 초록 지붕 + 아이보리 몸체 + 귀여운 활
  void _renderArcher(Canvas canvas, double s, Offset center) {
    // 부드러운 그림자
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, s * 0.12), width: s * 0.6, height: s * 0.18),
      Paint()..color = const Color(0x30000000),
    );
    
    // 아이보리 몸체 (둥근 사다리꼴)
    final bodyPath = Path()
      ..moveTo(s * 0.28, s * 0.35)
      ..lineTo(s * 0.72, s * 0.35)
      ..quadraticBezierTo(s * 0.75, s * 0.72, s * 0.7, s * 0.78)
      ..lineTo(s * 0.3, s * 0.78)
      ..quadraticBezierTo(s * 0.25, s * 0.72, s * 0.28, s * 0.35)
      ..close();
    canvas.drawPath(bodyPath, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5E6D3), Color(0xFFD4B896)],
      ).createShader(Rect.fromLTWH(0, s * 0.35, s, s * 0.45)));
    
    // 몸체 테두리
    canvas.drawPath(bodyPath, Paint()
      ..color = const Color(0xFFB8956A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    
    // 창문 (귀여운 둥근 사각형)
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(s * 0.5, s * 0.55), width: s * 0.15, height: s * 0.18),
      const Radius.circular(4),
    );
    canvas.drawRRect(windowRect, Paint()..color = const Color(0xFF3E2723));
    canvas.drawRRect(windowRect, Paint()
      ..color = const Color(0x55FFDD88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    
    // 지붕 (둥근 삼각형 — 에메랄드 그린)
    final roofPath = Path()
      ..moveTo(s * 0.5, s * 0.02)
      ..quadraticBezierTo(s * 0.08, s * 0.28, s * 0.18, s * 0.38)
      ..lineTo(s * 0.82, s * 0.38)
      ..quadraticBezierTo(s * 0.92, s * 0.28, s * 0.5, s * 0.02)
      ..close();
    canvas.drawPath(roofPath, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
      ).createShader(Rect.fromLTWH(0, 0, s, s * 0.4)));
    canvas.drawPath(roofPath, Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    
    // 지붕 하이라이트 (빛 반사)
    final highlightPath = Path()
      ..moveTo(s * 0.48, s * 0.08)
      ..quadraticBezierTo(s * 0.3, s * 0.2, s * 0.35, s * 0.3)
      ..lineTo(s * 0.45, s * 0.2)
      ..close();
    canvas.drawPath(highlightPath, Paint()..color = const Color(0x33FFFFFF));
    
    // 활 (귀여운 둥근 형태)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(s * 0.65, s * 0.2), width: s * 0.16, height: s * 0.28),
      -math.pi * 0.35, math.pi * 0.7, false,
      Paint()
        ..color = const Color(0xFFFFB74D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // 시위
    canvas.drawLine(
      Offset(s * 0.625, s * 0.08), Offset(s * 0.625, s * 0.32),
      Paint()..color = const Color(0xAAFFCC80)..strokeWidth = 1,
    );
    
    // 꼭대기 장식구
    canvas.drawCircle(Offset(s * 0.5, s * 0.02), 3,
      Paint()..color = const Color(0xFFFFD700));
  }
  
  /// 병영 — 둥근 방패 + 인디고 블루 + 별 문양
  void _renderBarracks(Canvas canvas, double s, Offset center) {
    // 부드러운 그림자
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, s * 0.1), width: s * 0.65, height: s * 0.2),
      Paint()..color = const Color(0x30000000),
    );
    
    // 방패 외곽 (둥근 모양 — 파란 그라데이션)
    final shieldPath = Path()
      ..moveTo(s * 0.5, s * 0.08)
      ..quadraticBezierTo(s * 0.88, s * 0.12, s * 0.85, s * 0.5)
      ..quadraticBezierTo(s * 0.82, s * 0.82, s * 0.5, s * 0.92)
      ..quadraticBezierTo(s * 0.18, s * 0.82, s * 0.15, s * 0.5)
      ..quadraticBezierTo(s * 0.12, s * 0.12, s * 0.5, s * 0.08)
      ..close();
    canvas.drawPath(shieldPath, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [Color(0xFF7986CB), Color(0xFF3F51B5), Color(0xFF1A237E)],
      ).createShader(Rect.fromLTWH(0, 0, s, s)));
    
    // 방패 테두리 (금색 두줄)
    canvas.drawPath(shieldPath, Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    
    // 내부 테두리
    final innerPath = Path()
      ..moveTo(s * 0.5, s * 0.16)
      ..quadraticBezierTo(s * 0.78, s * 0.2, s * 0.76, s * 0.5)
      ..quadraticBezierTo(s * 0.73, s * 0.75, s * 0.5, s * 0.82)
      ..quadraticBezierTo(s * 0.27, s * 0.75, s * 0.24, s * 0.5)
      ..quadraticBezierTo(s * 0.22, s * 0.2, s * 0.5, s * 0.16)
      ..close();
    canvas.drawPath(innerPath, Paint()
      ..color = const Color(0x44FFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    
    // 중앙 별 문양 (4개 꼭짓점)
    final starCenter = Offset(s * 0.5, s * 0.48);
    final starPaint = Paint()..color = const Color(0xDDFFD54F);
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * math.pi * 2 - math.pi / 2;
      final outerR = s * 0.14;
      final innerR = s * 0.06;
      final nextAngle = ((i + 0.5) / 4) * math.pi * 2 - math.pi / 2;
      final path = Path()
        ..moveTo(starCenter.dx, starCenter.dy)
        ..lineTo(starCenter.dx + math.cos(angle) * outerR,
                 starCenter.dy + math.sin(angle) * outerR)
        ..lineTo(starCenter.dx + math.cos(nextAngle) * innerR,
                 starCenter.dy + math.sin(nextAngle) * innerR)
        ..close();
      canvas.drawPath(path, starPaint);
    }
    
    // 하이라이트 (좌상단 빛반사)
    canvas.drawCircle(Offset(s * 0.32, s * 0.22), s * 0.08,
      Paint()..color = const Color(0x33FFFFFF));
  }
  
  /// 무당 — 수정 오브 + 바이올렛 오라 + 반짝이
  void _renderShaman(Canvas canvas, double s, Offset center) {
    // 오라 링 (바이올렛 파동, 부드럽게)
    for (int i = 3; i > 0; i--) {
      canvas.drawCircle(center, s * (0.25 + i * 0.07),
        Paint()
          ..color = Color.fromARGB(15 + i * 8, 187, 134, 252)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    }
    
    // 베이스 접시 (작은 타원)
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, s * 0.18), width: s * 0.5, height: s * 0.16),
      Paint()..color = const Color(0xFF311B92));
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, s * 0.18), width: s * 0.5, height: s * 0.16),
      Paint()
        ..color = const Color(0xFFBB86FC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    
    // 수정 오브 (메인 — 빛나는 보라 구체)
    final orbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.8,
        colors: const [
          Color(0xFFE1BEE7), // 밝은 라벤더
          Color(0xFFCE93D8), // 중간 라벤더
          Color(0xFF9C27B0), // 진한 퍼플
          Color(0xFF4A148C), // 다크 퍼플
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.22));
    canvas.drawCircle(center, s * 0.22, orbPaint);
    
    // 오브 하이라이트 (빛반사 — 귀여운 둥근 빛)
    canvas.drawCircle(center + Offset(-s * 0.06, -s * 0.08), s * 0.07,
      Paint()..color = const Color(0x77FFFFFF));
    canvas.drawCircle(center + Offset(-s * 0.03, -s * 0.05), s * 0.03,
      Paint()..color = const Color(0xAAFFFFFF));
    
    // 오브 테두리 (글로우)
    canvas.drawCircle(center, s * 0.22, Paint()
      ..color = const Color(0x88CE93D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    
    // 부적 반짝이 (4개 작은 다이아몬드)
    final sparkPaint = Paint()..color = const Color(0xCCFFD700);
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * math.pi * 2 + math.pi / 4;
      final px = center.dx + math.cos(angle) * s * 0.32;
      final py = center.dy + math.sin(angle) * s * 0.32;
      _drawDiamond(canvas, Offset(px, py), 3, sparkPaint);
    }
  }
  
  /// 화포 — 포탄 모양 + 코랄/오렌지 + 연기구
  void _renderArtillery(Canvas canvas, double s, Offset center) {
    // 부드러운 그림자
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, s * 0.12), width: s * 0.6, height: s * 0.18),
      Paint()..color = const Color(0x30000000),
    );
    
    // 돌 베이스 (둥근 사각형)
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + Offset(0, s * 0.1), width: s * 0.65, height: s * 0.4),
      const Radius.circular(8),
    );
    canvas.drawRRect(baseRect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF78909C), Color(0xFF455A64)],
      ).createShader(Rect.fromLTWH(0, s * 0.3, s, s * 0.4)));
    canvas.drawRRect(baseRect, Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    
    // 베이스 하이라이트
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + Offset(0, s * 0.05), width: s * 0.55, height: s * 0.2),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0x18FFFFFF),
    );
    
    // 포신 (둥근 직사각형 — 위로 향함)
    final barrelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + Offset(0, -s * 0.15), width: s * 0.2, height: s * 0.42),
      const Radius.circular(5),
    );
    canvas.drawRRect(barrelRect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF616161), Color(0xFFBDBDBD), Color(0xFF616161)],
      ).createShader(Rect.fromLTWH(s * 0.4, 0, s * 0.2, s * 0.6)));
    canvas.drawRRect(barrelRect, Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    
    // 포구 (코랄 원 — 빛나는 느낌)
    canvas.drawCircle(center + Offset(0, -s * 0.35), s * 0.11,
      Paint()..color = const Color(0xFFFF5722));
    canvas.drawCircle(center + Offset(0, -s * 0.35), s * 0.07,
      Paint()..shader = RadialGradient(
        colors: const [Color(0xFFFFAB91), Color(0xFFFF5722)],
      ).createShader(Rect.fromCircle(center: center + Offset(0, -s * 0.35), radius: s * 0.07)));
    // 포구 하이라이트
    canvas.drawCircle(center + Offset(-s * 0.02, -s * 0.37), s * 0.03,
      Paint()..color = const Color(0x55FFFFFF));
    
    // 연기 장식 (작은 원 2개)
    canvas.drawCircle(Offset(s * 0.6, s * 0.12), s * 0.04,
      Paint()..color = const Color(0x33AAAAAA));
    canvas.drawCircle(Offset(s * 0.66, s * 0.06), s * 0.03,
      Paint()..color = const Color(0x22AAAAAA));
    
    // 볼트 (귀여운 둥근 점 4개)
    final boltPaint = Paint()..color = const Color(0xFFE0E0E0);
    canvas.drawCircle(Offset(s * 0.25, s * 0.45), 2.5, boltPaint);
    canvas.drawCircle(Offset(s * 0.75, s * 0.45), 2.5, boltPaint);
    canvas.drawCircle(Offset(s * 0.25, s * 0.62), 2.5, boltPaint);
    canvas.drawCircle(Offset(s * 0.75, s * 0.62), 2.5, boltPaint);
  }
  
  /// 솟대 — 신성한 새 + 골드 기둥 + 빛 입자
  void _renderSotdae(Canvas canvas, double s, Offset center) {
    // 신성한 빛 (외곽 — 부드러운 글로우)
    canvas.drawCircle(center + Offset(0, -s * 0.05), s * 0.42,
      Paint()..shader = RadialGradient(
        colors: const [Color(0x22FFD700), Color(0x00FFD700)],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.42)));
    
    // 기둥 (둥근 직사각형 — 나무 그라데이션)
    final poleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + Offset(0, s * 0.12), width: s * 0.14, height: s * 0.6),
      const Radius.circular(4),
    );
    canvas.drawRRect(poleRect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF6D4C41), Color(0xFFA1887F), Color(0xFF6D4C41)],
      ).createShader(Rect.fromLTWH(s * 0.43, 0, s * 0.14, s)));
    canvas.drawRRect(poleRect, Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    
    // 기둥 금색 띠 (3개)
    for (int i = 0; i < 3; i++) {
      final y = s * 0.5 + i * s * 0.1;
      canvas.drawLine(
        Offset(s * 0.44, y), Offset(s * 0.56, y),
        Paint()..color = const Color(0xCCFFD700)..strokeWidth = 1.5..strokeCap = StrokeCap.round,
      );
    }
    
    // 새 (귀여운 스타일 — 둥근 몸체 + 날개)
    // 몸체 (타원)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * 0.5, s * 0.15), width: s * 0.22, height: s * 0.18),
      Paint()..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        colors: [Color(0xFFFFE082), Color(0xFFFFA000)],
      ).createShader(Rect.fromCircle(center: Offset(s * 0.5, s * 0.15), radius: s * 0.12)));
    
    // 왼쪽 날개
    final leftWingPath = Path()
      ..moveTo(s * 0.4, s * 0.15)
      ..quadraticBezierTo(s * 0.12, s * 0.04, s * 0.15, s * 0.2)
      ..quadraticBezierTo(s * 0.2, s * 0.22, s * 0.38, s * 0.2)
      ..close();
    canvas.drawPath(leftWingPath, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH(s * 0.1, s * 0.04, s * 0.3, s * 0.2)));
    canvas.drawPath(leftWingPath, Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    
    // 오른쪽 날개
    final rightWingPath = Path()
      ..moveTo(s * 0.6, s * 0.15)
      ..quadraticBezierTo(s * 0.88, s * 0.04, s * 0.85, s * 0.2)
      ..quadraticBezierTo(s * 0.8, s * 0.22, s * 0.62, s * 0.2)
      ..close();
    canvas.drawPath(rightWingPath, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH(s * 0.6, s * 0.04, s * 0.3, s * 0.2)));
    canvas.drawPath(rightWingPath, Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    
    // 새 눈 (귀여운 점)
    canvas.drawCircle(Offset(s * 0.47, s * 0.12), 2, Paint()..color = const Color(0xFF3E2723));
    canvas.drawCircle(Offset(s * 0.47, s * 0.11), 0.8, Paint()..color = const Color(0x88FFFFFF));
    
    // 부리
    final beakPath = Path()
      ..moveTo(s * 0.39, s * 0.14)
      ..lineTo(s * 0.33, s * 0.16)
      ..lineTo(s * 0.39, s * 0.18)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFFF6F00));
    
    // 반짝이 입자 (작은 다이아몬드)
    _drawDiamond(canvas, Offset(s * 0.25, s * 0.08), 2.5,
      Paint()..color = const Color(0xAAFFD700));
    _drawDiamond(canvas, Offset(s * 0.78, s * 0.28), 2,
      Paint()..color = const Color(0x88FFD700));
    _drawDiamond(canvas, Offset(s * 0.2, s * 0.35), 1.5,
      Paint()..color = const Color(0x66FFD700));
  }
  
  /// 업그레이드 글로우 + 별 표시
  void _renderUpgradeGlow(Canvas canvas, double s, Offset center) {
    final color = _getTowerColor();
    
    // 외곽 글로우
    final glowAlpha = (20 + upgradeLevel * 12).clamp(0, 80);
    canvas.drawCircle(center, s * 0.48,
      Paint()..color = Color.fromARGB(glowAlpha, color.red, color.green, color.blue));
    
    // 업그레이드 별 (아래쪽 — 밝은 점)
    for (int i = 0; i < upgradeLevel && i < 3; i++) {
      final x = s * 0.25 + i * s * 0.25;
      // 별 글로우
      canvas.drawCircle(Offset(x, s * 0.9), 4,
        Paint()..color = const Color(0x44FFD700));
      // 별 코어
      _drawDiamond(canvas, Offset(x, s * 0.9), 3,
        Paint()..color = const Color(0xFFFFD700));
    }
  }
  
  /// 작은 다이아몬드(반짝이) 그리기 헬퍼
  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.7, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.7, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }
  
  Color _getTowerColor() {
    switch (type) {
      case TowerType.archer:
        return const Color(0xFF66BB6A);
      case TowerType.barracks:
        return const Color(0xFF5C6BC0);
      case TowerType.shaman:
        return const Color(0xFFCE93D8);
      case TowerType.artillery:
        return const Color(0xFFFF7043);
      case TowerType.sotdae:
        return const Color(0xFFFFD700);
    }
  }
}
