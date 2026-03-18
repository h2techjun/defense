// ?�원??�?- ?�사�?컴포?�트
// ?��????�기?�기 ?��?????빛나???�사�?+ ?�레??

import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';

import '../../../common/enums.dart';
import '../../../audio/sound_manager.dart';
import '../../defense_game.dart'; // [FIX] ?�락??import 추�?
import '../actors/base_enemy.dart';
import '../effects/particle_effect.dart';
import '../effects/sprite_effect.dart';
import '../effects/sprite_hit_effect.dart';

/// ?�사�?컴포?�트 - ?�?�에??발사?�어 ?�에�??��?지�?줍니??

enum ProjectileVisual {
  arrow,
  orb,
  cross,
  cannonball,
  shamanOrb,
}

class Projectile extends PositionComponent with HasGameReference<DefenseGame> {
  final BaseEnemy target;
  final double damage;
  final DamageType damageType;
  final double speed;

  /// ?�중 ???�출?�는 콜백 (?�포???�플?�시 ??
  final void Function()? onHit;

  /// 관???��? (?�궁 ?�용)
  final bool hasPiercing;

  /// 발사 방향 (관????직선 ?�동??
  final Vector2? direction;

  /// 최�? ?�거�?(관?????�거 조건)
  final double? maxRange;

  final ProjectileVisual? visualType;
  bool _hitTarget = false;
  double _trailTimer = 0;
  double _traveledDistance = 0;
  double _angle = 0; // ?�동 방향 각도 (?�디??

  /// ?��? ?�격한 ??목록 (관????중복 ?��?방�?)
  final Set<BaseEnemy> _hitEnemies = {};

  Projectile({
    required this.target,
    required this.damage,
    required this.damageType,
    required this.speed,
    required Vector2 startPosition,
    this.onHit,
    this.hasPiercing = false,
    this.direction,
    this.maxRange,
    this.visualType,
  }) : super(
          size: Vector2(10, 10),
          position: startPosition,
          anchor: Anchor.center,
          priority: 15,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // ?�각???�소??render()?�서 직접 그림 (커스?� ?�더�?
  }

  Color _getColorForDamage(DamageType type) {
    switch (type) {
      case DamageType.physical:
        return const Color(0xFFFFB74D); // ?�뜻??금색
      case DamageType.magical:
        return const Color(0xFF64B5F6); // 밝�? ?�늘??
      case DamageType.purification:
        return const Color(0xFFE0E0E0); // 부?�러???�색
    }
  }

  Color _getGlowColor(DamageType type) {
    switch (type) {
      case DamageType.physical:
        return const Color(0xFFFF9800);
      case DamageType.magical:
        return const Color(0xFF42A5F5);
      case DamageType.purification:
        return const Color(0xFFFFD700);
    }
  }

  @override
  void render(Canvas canvas) {
    final color = _getColorForDamage(damageType);
    final glowColor = _getGlowColor(damageType);
    final center = Offset(size.x / 2, size.y / 2);

    if (visualType == ProjectileVisual.cannonball) {
      // 거대한 화포 폭탄 (반경 12)
      canvas.drawCircle(center, 12, Paint()..color = const Color(0xFF222222));
      canvas.drawCircle(center + const Offset(-3, -3), 4,
          Paint()..color = const Color(0xFF666666));
      // 불타는 가장자리 효과
      canvas.drawCircle(
          center,
          14,
          Paint()
            ..color = const Color(0xFFFF4500)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
      return;
    } else if (visualType == ProjectileVisual.shamanOrb) {
      // 빛나는 크리스탈 영혼 구슬 (반경 11)
      canvas.drawCircle(center, 11, Paint()..color = const Color(0x9900E5FF));
      canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFB2EBF2));
      // 거대한 금빛 부적 십자(X) 패턴
      final tPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawLine(
          center + const Offset(-5, -5), center + const Offset(5, 5), tPaint);
      canvas.drawLine(
          center + const Offset(-5, 5), center + const Offset(5, -5), tPaint);
      return;
    }

    switch (damageType) {
      case DamageType.physical:
        // ? ?살 ???동 방향?로 ?전?는 리얼 ?살
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_angle + math.pi / 2); // ?�쪽??기본 ???�동방향 보정

        // 글로우 ?�레??
        canvas.drawCircle(
            const Offset(0, 4),
            4,
            Paint()
              ..color = Color.fromARGB(
                  30, glowColor.red, glowColor.green, glowColor.blue));

        // ?�살?� (몸통)
        final shaftPaint = Paint()
          ..color = const Color(0xFF8B6914) // ?�무??
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(0, -6), const Offset(0, 8), shaftPaint);

        // ?�살�?(?�각??
        final headPath = Path()
          ..moveTo(0, -10) // ?�쪽 ??
          ..lineTo(-3, -5)
          ..lineTo(3, -5)
          ..close();
        canvas.drawPath(headPath, Paint()..color = color);
        canvas.drawPath(
            headPath,
            Paint()
              ..color = const Color(0xFFFFE0B2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.6);

        // 깃털 (?�쪽)
        final featherPaint = Paint()
          ..color = const Color(0xFFCC4444)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            const Offset(0, 8), const Offset(-2.5, 11), featherPaint);
        canvas.drawLine(
            const Offset(0, 8), const Offset(2.5, 11), featherPaint);

        canvas.restore();
        break;

      case DamageType.magical:
        // 마법 ?�브 ??빛나????+ ?�곽 �?
        // ?�곽 글로우
        canvas.drawCircle(
            center,
            7,
            Paint()
              ..color = Color.fromARGB(
                  35, glowColor.red, glowColor.green, glowColor.blue));
        // 코어
        canvas.drawCircle(center, 4, Paint()..color = color);
        // ?�이?�이??
        canvas.drawCircle(center + const Offset(-1, -1), 1.5,
            Paint()..color = const Color(0x88FFFFFF));
        // ?�곽 �?
        canvas.drawCircle(
            center,
            5,
            Paint()
              ..color = Color.fromARGB(
                  80, glowColor.red, glowColor.green, glowColor.blue)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        break;

      case DamageType.purification:
        // ?�화 ??빛나????��가 + ?�광
        // ?�광
        canvas.drawCircle(center, 6, Paint()..color = const Color(0x22FFD700));
        // ??�� (?�근 ??
        final crossPaint = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(5, 1), const Offset(5, 9), crossPaint);
        canvas.drawLine(const Offset(1, 5), const Offset(9, 5), crossPaint);
        // 중심 �?
        canvas.drawCircle(
            center, 1.5, Paint()..color = const Color(0xFFFFD700));
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_hitTarget && !hasPiercing) {
      removeFromParent();
      return;
    }

    if (target.isDead && !hasPiercing) {
      removeFromParent();
      return;
    }

    _trailTimer += dt;
    final moveStep = speed * dt;
    _traveledDistance += moveStep;

    // 관???�사체는 ?�면 밖이???�거�?밖으�??��?�??�거
    if (maxRange != null && _traveledDistance > maxRange!) {
      removeFromParent();
      return;
    }

    if (hasPiercing && direction != null) {
      // 1) 관?? 직선 ?�동
      position += direction! * moveStep;

      // ?�동 경로????충돌 체크
      _checkPiercingCollisions();

      // ?�면 �??�거 체크 (간단???�치�?
      if (position.x < -100 ||
          position.x > 2000 ||
          position.y < -100 ||
          position.y > 2000) {
        removeFromParent();
      }
    } else {
      // 2) ?�반: ?��?추적 ?�동
      final toTarget = target.position - position;
      final distance = toTarget.length;

      // ?�동 방향 각도 갱신 (?�살 ?�전??
      if (distance > 0.1) {
        _angle = math.atan2(toTarget.y, toTarget.x);
      }

      if (distance < moveStep) {
        // ?�중
        _applyHit(target);
        removeFromParent();
      } else {
        toTarget.normalize();
        position += toTarget * moveStep;
      }
    }
  }

  /// 관????경로?�의 모든 ??체크 (공간 ?�싱 최적??
  void _checkPiercingCollisions() {
    // GridSystem???�용?�여 O(1) ?��??�로 ?�접???�만 ?�터�?
    final enemies = game.gridSystem.getEnemiesNear(position, 30.0);

    for (final enemy in enemies) {
      if (enemy.isDead || _hitEnemies.contains(enemy)) continue;

      // 충돌 ?�정 (거리 ?�곱 ?�산?�로 sqrt 부???�거, 반경 20?��? ?�내)
      final distSq = position.distanceToSquared(enemy.position);
      if (distSq < 400) {
        // 20 * 20
        _applyHit(enemy);
      }
    }
  }

  /// ?��??�용 ?�합 메서??
  void _applyHit(BaseEnemy hitEnemy) {
    _hitEnemies.add(hitEnemy);
    hitEnemy.takeDamage(damage, damageType);

    // �??��??�중 ?�에�?onHit ?�출 (?�플?�시 ?�과 겹치지 ?�게 주의)
    if (hitEnemy == target && !_hitTarget) {
      _hitTarget = true;
      onHit?.call();
    }

    // ?�중 ?�티???�펙??
    if (ParticleEffect.canCreate) {
      final hitColor = _getColorForDamage(damageType);
      if (damageType == DamageType.magical) {
        parent?.add(ParticleEffect.magic(position: position, color: hitColor));
        parent?.add(
            SpriteEffect(type: SpriteEffectType.lightning, position: position));
      } else if (damageType == DamageType.purification) {
        parent?.add(ParticleEffect.heal(position: position, color: hitColor));
      } else {
        parent?.add(ParticleEffect.hit(position: position, color: hitColor));
        parent
            ?.add(SpriteEffect(type: SpriteEffectType.hit, position: position));
      }
    }

    // ?�프?�이???�트 ?�펙??(?�웅 ?��?차별??
    if (SpriteHitEffect.canCreate) {
      switch (damageType) {
        case DamageType.physical:
          parent?.add(SpriteHitEffect.physical(position: position));
          break;
        case DamageType.magical:
          parent?.add(SpriteHitEffect.magic(position: position));
          break;
        case DamageType.purification:
          parent?.add(SpriteHitEffect.purify(position: position));
          break;
      }
    }

    // ?�격 SFX (?�무 ?�주 ?�리�??�끄?�우??관???�에???�률???��? 볼륨 조절 ?�요?????�음)
    SoundManager.instance.playSfx(SfxType.enemyHit);
  }
}
