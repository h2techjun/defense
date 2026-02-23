// 해원의 문 — 타워 커스텀 렌더러
// 스프라이트 이미지 기반 고품질 렌더링 (Canvas 폴백 포함)

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show LinearGradient, RadialGradient, Alignment;
import '../../../common/enums.dart';
import '../../defense_game.dart';

/// 타워 타입별 스프라이트 이미지 기반 렌더링
class TowerRenderer extends PositionComponent
    with HasGameReference<DefenseGame> {
  final TowerType type;
  final int upgradeLevel;
  TowerBranch? branch;

  // 스프라이트 관련
  Sprite? _sprite;
  bool _spriteLoaded = false;

  TowerRenderer({
    required this.type,
    this.upgradeLevel = 0,
    this.branch,
    required Vector2 size,
  }) : super(size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSprite();
  }

  /// 스프라이트 이미지 로드
  Future<void> _loadSprite() async {
    try {
      final imagePath = _getImagePath();
      final image = await game.images.load(imagePath);
      _sprite = Sprite(image);
      _spriteLoaded = true;
    } catch (e) {
      // 이미지 로드 실패 → Canvas 폴백 사용
      _spriteLoaded = false;
    }
  }

  /// 타워 타입/레벨/분기에 따른 이미지 경로 결정
  String _getImagePath() {
    // 분기 선택 시 분기 이미지 우선
    if (branch != null) {
      return 'towers/${_getBranchImageName(branch!)}.png';
    }
    // 기본 타워: 타입_t{레벨+1}
    final tier = (upgradeLevel + 1).clamp(1, 3);
    return 'towers/tower_${_getTypeName(type)}_t$tier.png';
  }

  /// TowerType → 파일명 매핑
  String _getTypeName(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return 'archer';
      case TowerType.barracks:
        return 'barracks';
      case TowerType.shaman:
        return 'shaman';
      case TowerType.artillery:
        return 'artillery';
      case TowerType.sotdae:
        return 'sotdae';
    }
  }

  /// TowerBranch → 파일명 매핑
  String _getBranchImageName(TowerBranch branch) {
    switch (branch) {
      case TowerBranch.rocketBattery:
        return 'tower_rocket_battery';
      case TowerBranch.spiritHunter:
        return 'tower_spirit_hunter';
      case TowerBranch.generalTotem:
        return 'tower_general_totem';
      case TowerBranch.goblinRing:
        return 'tower_goblin_ring';
      case TowerBranch.shamanTemple:
        return 'tower_shaman_temple';
      case TowerBranch.grimReaperOffice:
        return 'tower_grim_reaper';
      case TowerBranch.fireDragon:
        return 'tower_fire_dragon';
      case TowerBranch.heavenlyThunder:
        return 'tower_heavenly_thunder';
      case TowerBranch.phoenixTotem:
        return 'tower_phoenix_totem';
      case TowerBranch.earthSpiritAltar:
        return 'tower_earth_spirit';
    }
  }

  /// 업그레이드 또는 분기 변경 시 스프라이트 갱신
  void updateVisual({int? newLevel, TowerBranch? newBranch}) {
    if (newBranch != null) {
      branch = newBranch;
    }
    _loadSprite();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_spriteLoaded && _sprite != null) {
      // 스프라이트 이미지 렌더링
      _sprite!.render(canvas, size: size);

      // 업그레이드 인디케이터 (이미지 위에 오버레이)
      if (upgradeLevel > 0) {
        _renderUpgradeGlow(canvas, size.x, Offset(size.x / 2, size.y / 2));
      }
    } else {
      // Canvas 폴백 렌더링
      _renderFallback(canvas);
    }
  }

  /// Canvas 기반 폴백 렌더링 (이미지 로드 실패 시)
  void _renderFallback(Canvas canvas) {
    final s = size.x;
    final center = Offset(s / 2, s / 2);

    switch (type) {
      case TowerType.archer:
        _renderArcherFallback(canvas, s, center);
        break;
      case TowerType.barracks:
        _renderBarracksFallback(canvas, s, center);
        break;
      case TowerType.shaman:
        _renderShamanFallback(canvas, s, center);
        break;
      case TowerType.artillery:
        _renderArtilleryFallback(canvas, s, center);
        break;
      case TowerType.sotdae:
        _renderSotdaeFallback(canvas, s, center);
        break;
    }

    if (upgradeLevel > 0) {
      _renderUpgradeGlow(canvas, s, center);
    }
  }

  // ── 폴백 렌더링 (기존 Canvas API 코드 압축) ──

  void _renderArcherFallback(Canvas canvas, double s, Offset center) {
    // 몸체
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
    // 지붕
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
  }

  void _renderBarracksFallback(Canvas canvas, double s, Offset center) {
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
    canvas.drawPath(shieldPath, Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
  }

  void _renderShamanFallback(Canvas canvas, double s, Offset center) {
    // 오라 링
    for (int i = 3; i > 0; i--) {
      canvas.drawCircle(center, s * (0.25 + i * 0.07),
        Paint()
          ..color = Color.fromARGB(15 + i * 8, 187, 134, 252)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    }
    // 수정 오브
    canvas.drawCircle(center, s * 0.22, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.8,
        colors: const [Color(0xFFE1BEE7), Color(0xFFCE93D8), Color(0xFF9C27B0), Color(0xFF4A148C)],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.22)));
  }

  void _renderArtilleryFallback(Canvas canvas, double s, Offset center) {
    // 베이스
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
    // 포신
    final barrelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + Offset(0, -s * 0.15), width: s * 0.2, height: s * 0.42),
      const Radius.circular(5),
    );
    canvas.drawRRect(barrelRect, Paint()..color = const Color(0xFF9E9E9E));
    // 포구
    canvas.drawCircle(center + Offset(0, -s * 0.35), s * 0.11,
      Paint()..color = const Color(0xFFFF5722));
  }

  void _renderSotdaeFallback(Canvas canvas, double s, Offset center) {
    // 기둥
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
    // 새 몸체
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * 0.5, s * 0.15), width: s * 0.22, height: s * 0.18),
      Paint()..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        colors: [Color(0xFFFFE082), Color(0xFFFFA000)],
      ).createShader(Rect.fromCircle(center: Offset(s * 0.5, s * 0.15), radius: s * 0.12)));
  }

  /// 업그레이드 글로우 + 별 표시
  void _renderUpgradeGlow(Canvas canvas, double s, Offset center) {
    final color = _getTowerColor();

    // 외곽 글로우
    final glowAlpha = (20 + upgradeLevel * 12).clamp(0, 80);
    canvas.drawCircle(center, s * 0.48,
      Paint()..color = Color.fromARGB(glowAlpha, color.red, color.green, color.blue));

    // 업그레이드 별 (아래쪽)
    for (int i = 0; i < upgradeLevel && i < 3; i++) {
      final x = s * 0.25 + i * s * 0.25;
      canvas.drawCircle(Offset(x, s * 0.9), 4,
        Paint()..color = const Color(0x44FFD700));
      // 다이아몬드
      final path = Path()
        ..moveTo(x, s * 0.9 - 3)
        ..lineTo(x + 2.1, s * 0.9)
        ..lineTo(x, s * 0.9 + 3)
        ..lineTo(x - 2.1, s * 0.9)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFFFD700));
    }
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
