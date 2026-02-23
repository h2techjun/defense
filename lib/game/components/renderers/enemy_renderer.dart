// 해원의 문 — 적 커스텀 렌더러
// 스프라이트 이미지 기반 고품질 렌더링 (Canvas 폴백 포함)

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show LinearGradient, RadialGradient, Alignment;
import '../../../common/enums.dart';
import '../../../data/models/enemy_data.dart';
import '../../defense_game.dart';

/// 적 타입별 스프라이트 이미지 기반 렌더링
class EnemyRenderer extends PositionComponent
    with HasGameReference<DefenseGame> {
  final EnemyData data;

  // 스프라이트 관련
  Sprite? _sprite;
  bool _spriteLoaded = false;

  // 피격 플래시 효과
  double _hitFlash = 0;
  static const double _flashDuration = 0.08;

  EnemyRenderer({
    required this.data,
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

  /// EnemyId → 이미지 파일 경로 매핑
  String _getImagePath() {
    switch (data.id) {
      // 보스
      case EnemyId.bossOgreLord:
        return 'enemies/boss_ogre_lord.png';
      case EnemyId.bossMountainLord:
        return 'enemies/boss_mountain_lord.png';
      case EnemyId.bossGreatEggGhost:
        return 'enemies/boss_great_egg.png';
      // 챕터 1 일반 적
      case EnemyId.hungryGhost:
        return 'enemies/enemy_hungry_ghost.png';
      case EnemyId.strawShoeSpirit:
        return 'enemies/enemy_straw_shoe.png';
      case EnemyId.burdenedLaborer:
        return 'enemies/enemy_burdened.png';
      case EnemyId.maidenGhost:
        return 'enemies/enemy_maiden.png';
      case EnemyId.eggGhost:
        return 'enemies/enemy_egg_ghost.png';
      // 챕터 2
      case EnemyId.tigerSlave:
        return 'enemies/enemy_tiger_slave.png';
      case EnemyId.fireDog:
        return 'enemies/enemy_fire_dog.png';
      case EnemyId.shadowGolem:
        return 'enemies/enemy_shadow_golem.png';
      case EnemyId.oldFoxWoman:
        return 'enemies/enemy_old_fox.png';
      case EnemyId.failedDragon:
        return 'enemies/enemy_failed_dragon.png';
      // 챕터 3
      case EnemyId.changGwiEvolved:
        return 'enemies/enemy_evolved_tiger.png';
      case EnemyId.saetani:
        return 'enemies/enemy_saetani.png';
      case EnemyId.shadowChild:
        return 'enemies/enemy_shadow_child.png';
      case EnemyId.maliciousBird:
        return 'enemies/enemy_malicious_bird.png';
      case EnemyId.faceStealerGhost:
        return 'enemies/enemy_face_stealer.png';
      // 챕터 4, 5 (이미지 미지원 → 폴백)
      default:
        return 'enemies/enemy_hungry_ghost.png'; // 기본 이미지 폴백
    }
  }

  /// 피격 플래시 효과 트리거
  void flash() {
    _hitFlash = _flashDuration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hitFlash > 0) {
      _hitFlash = (_hitFlash - dt).clamp(0.0, _flashDuration);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_spriteLoaded && _sprite != null) {
      // 스프라이트 이미지 렌더링

      // 보스는 살짝 더 크게
      final renderSize = data.isBoss
          ? Vector2(size.x * 1.3, size.y * 1.3)
          : size;
      final offset = data.isBoss
          ? Vector2(-size.x * 0.15, -size.y * 0.15)
          : Vector2.zero();

      if (_hitFlash > 0) {
        // 피격 시 백색 플래시
        canvas.save();
        canvas.translate(offset.x, offset.y);
        _sprite!.render(canvas, size: renderSize);
        canvas.drawRect(
          Rect.fromLTWH(offset.x, offset.y, renderSize.x, renderSize.y),
          Paint()..color = const Color(0x88FFFFFF),
        );
        canvas.restore();
      } else {
        canvas.save();
        canvas.translate(offset.x, offset.y);
        _sprite!.render(canvas, size: renderSize);
        canvas.restore();
      }

      // 비행 유닛 날개 오버레이
      if (data.isFlying) {
        _renderWings(canvas, size.x, Offset(size.x / 2, size.y / 2));
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
    final baseColor = _getBaseColor();

    switch (data.id) {
      case EnemyId.hungryGhost:
        _renderHungryGhost(canvas, s, center, baseColor);
        break;
      case EnemyId.strawShoeSpirit:
        _renderStrawShoe(canvas, s, center, baseColor);
        break;
      case EnemyId.maidenGhost:
        _renderMaiden(canvas, s, center, baseColor);
        break;
      case EnemyId.eggGhost:
        _renderEggGhost(canvas, s, center, baseColor);
        break;
      case EnemyId.burdenedLaborer:
        _renderBurdened(canvas, s, center, baseColor);
        break;
      case EnemyId.bossOgreLord:
      case EnemyId.bossMountainLord:
      case EnemyId.bossGreatEggGhost:
      case EnemyId.bossTyrantKing:
      case EnemyId.bossGatekeeper:
        _renderBoss(canvas, s, center, baseColor);
        break;
      default:
        _renderDefaultEnemy(canvas, s, center, baseColor);
        break;
    }

    if (data.isFlying) {
      _renderWings(canvas, s, center);
    }

    // 피격 플래시
    if (_hitFlash > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, s, s),
        Paint()..color = const Color(0x66FFFFFF),
      );
    }
  }

  // ── 폴백 렌더링 메서드들 ──

  void _renderHungryGhost(Canvas canvas, double s, Offset center, Color color) {
    // 둥근 몸체
    canvas.drawCircle(center, s * 0.36, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [Color.fromARGB(255, (color.red * 1.2).clamp(0, 255).toInt(), (color.green * 1.2).clamp(0, 255).toInt(), color.blue), color],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.36)));
    // 눈
    canvas.drawCircle(center + Offset(-s * 0.12, -s * 0.08), s * 0.06,
      Paint()..color = const Color(0xCCFF0000));
    canvas.drawCircle(center + Offset(s * 0.12, -s * 0.08), s * 0.06,
      Paint()..color = const Color(0xCCFF0000));
    // 입
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, s * 0.15), width: s * 0.2, height: s * 0.12),
      Paint()..color = const Color(0xCC000000));
  }

  void _renderStrawShoe(Canvas canvas, double s, Offset center, Color color) {
    // 타원형
    canvas.drawOval(
      Rect.fromCenter(center: center, width: s * 0.6, height: s * 0.45),
      Paint()..color = color);
    // 짚 질감
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(s * (0.25 + i * 0.1), s * 0.35),
        Offset(s * (0.25 + i * 0.1), s * 0.65),
        Paint()..color = const Color(0x44000000)..strokeWidth = 1);
    }
  }

  void _renderMaiden(Canvas canvas, double s, Offset center, Color color) {
    // 머리
    canvas.drawCircle(center + Offset(0, -s * 0.15), s * 0.2,
      Paint()..color = const Color(0xFFFFE0B2));
    // 검은 머리카락
    final hairPath = Path()
      ..moveTo(s * 0.2, s * 0.2)
      ..quadraticBezierTo(s * 0.5, -s * 0.05, s * 0.8, s * 0.2)
      ..lineTo(s * 0.85, s * 0.7)
      ..lineTo(s * 0.15, s * 0.7)
      ..close();
    canvas.drawPath(hairPath, Paint()..color = const Color(0xFF1A1A2E));
    // 몸체
    canvas.drawRect(
      Rect.fromCenter(center: center + Offset(0, s * 0.2), width: s * 0.35, height: s * 0.4),
      Paint()..color = const Color(0xFFEEEEEE));
  }

  void _renderEggGhost(Canvas canvas, double s, Offset center, Color color) {
    // 달걀형
    final eggPath = Path()
      ..moveTo(s * 0.5, s * 0.05)
      ..quadraticBezierTo(s * 0.95, s * 0.3, s * 0.8, s * 0.7)
      ..quadraticBezierTo(s * 0.65, s * 0.95, s * 0.5, s * 0.92)
      ..quadraticBezierTo(s * 0.35, s * 0.95, s * 0.2, s * 0.7)
      ..quadraticBezierTo(s * 0.05, s * 0.3, s * 0.5, s * 0.05)
      ..close();
    canvas.drawPath(eggPath, Paint()..color = color);
  }

  void _renderBurdened(Canvas canvas, double s, Offset center, Color color) {
    // 구부정한 몸
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, s * 0.05), width: s * 0.5, height: s * 0.55),
      Paint()..color = color);
    // 짐
    canvas.drawRect(
      Rect.fromCenter(center: center + Offset(0, -s * 0.2), width: s * 0.45, height: s * 0.25),
      Paint()..color = const Color(0xFF795548));
  }

  void _renderBoss(Canvas canvas, double s, Offset center, Color color) {
    // 크고 위협적인 형태
    canvas.drawCircle(center, s * 0.42, Paint()
      ..shader = RadialGradient(
        colors: [color, Color.fromARGB(255, (color.red * 0.5).toInt(), (color.green * 0.5).toInt(), (color.blue * 0.5).toInt())],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.42)));
    // 보스 왕관
    canvas.drawCircle(center + Offset(0, -s * 0.35), s * 0.08,
      Paint()..color = const Color(0xFFFFD700));
    // 빛나는 외곽
    canvas.drawCircle(center, s * 0.44, Paint()
      ..color = const Color(0x33FF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  void _renderDefaultEnemy(Canvas canvas, double s, Offset center, Color color) {
    canvas.drawCircle(center, s * 0.35, Paint()..color = color);
    // 간단한 눈
    canvas.drawCircle(center + Offset(-s * 0.1, -s * 0.05), s * 0.04,
      Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(center + Offset(s * 0.1, -s * 0.05), s * 0.04,
      Paint()..color = const Color(0xFFFFFFFF));
  }

  /// 비행 유닛 날개 오버레이
  void _renderWings(Canvas canvas, double s, Offset center) {
    final t = DateTime.now().millisecondsSinceEpoch / 200.0;
    final flap = math.sin(t) * 0.15;
    // 왼쪽 날개
    final leftWing = Path()
      ..moveTo(center.dx - s * 0.15, center.dy)
      ..quadraticBezierTo(center.dx - s * 0.45, center.dy - s * (0.3 + flap),
          center.dx - s * 0.35, center.dy + s * 0.1)
      ..close();
    // 오른쪽 날개
    final rightWing = Path()
      ..moveTo(center.dx + s * 0.15, center.dy)
      ..quadraticBezierTo(center.dx + s * 0.45, center.dy - s * (0.3 + flap),
          center.dx + s * 0.35, center.dy + s * 0.1)
      ..close();
    final wingPaint = Paint()..color = const Color(0x55AAAAFF);
    canvas.drawPath(leftWing, wingPaint);
    canvas.drawPath(rightWing, wingPaint);
  }

  /// 적 타입별 기본 색상
  Color _getBaseColor() {
    switch (data.id) {
      case EnemyId.hungryGhost:
        return const Color(0xFF8BC34A);
      case EnemyId.strawShoeSpirit:
        return const Color(0xFFD7CCC8);
      case EnemyId.maidenGhost:
        return const Color(0xFFEEEEEE);
      case EnemyId.eggGhost:
        return const Color(0xFFF5F5DC);
      case EnemyId.burdenedLaborer:
        return const Color(0xFF8D6E63);
      case EnemyId.tigerSlave:
        return const Color(0xFFFF8F00);
      case EnemyId.fireDog:
        return const Color(0xFFD32F2F);
      case EnemyId.shadowGolem:
        return const Color(0xFF616161);
      case EnemyId.oldFoxWoman:
        return const Color(0xFFFFB74D);
      case EnemyId.failedDragon:
        return const Color(0xFF1565C0);
      case EnemyId.changGwiEvolved:
        return const Color(0xFF4E342E);
      case EnemyId.saetani:
        return const Color(0xFF880E4F);
      case EnemyId.shadowChild:
        return const Color(0xFF37474F);
      case EnemyId.maliciousBird:
        return const Color(0xFF6A1B9A);
      case EnemyId.faceStealerGhost:
        return const Color(0xFFBDBDBD);
      // 보스
      case EnemyId.bossOgreLord:
        return const Color(0xFFD32F2F);
      case EnemyId.bossMountainLord:
        return const Color(0xFF2E7D32);
      case EnemyId.bossGreatEggGhost:
        return const Color(0xFF4A148C);
      case EnemyId.bossTyrantKing:
        return const Color(0xFFB71C1C);
      case EnemyId.bossGatekeeper:
        return const Color(0xFF1A237E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
