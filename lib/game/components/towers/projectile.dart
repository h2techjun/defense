// 해원의 문 - 투사체 컴포넌트
// 현대적 아기자기 스타일 — 빛나는 투사체 + 트레일

import 'dart:ui';
import 'package:flame/components.dart';

import '../../../common/enums.dart';
import '../../../audio/sound_manager.dart';
import '../../defense_game.dart'; // [FIX] 누락된 import 추가
import '../actors/base_enemy.dart';
import '../effects/particle_effect.dart';
import '../effects/sprite_effect.dart';

/// 투사체 컴포넌트 - 타워에서 발사되어 적에게 데미지를 줍니다
class Projectile extends PositionComponent {
  final BaseEnemy target;
  final double damage;
  final DamageType damageType;
  final double speed;

  /// 적중 시 호출되는 콜백 (화포탑 스플래시 등)
  final void Function()? onHit;

  /// 관통 여부 (신궁 전용)
  final bool hasPiercing;

  /// 발사 방향 (관통 시 직선 이동용)
  final Vector2? direction;

  /// 최대 사거리 (관통 시 제거 조건)
  final double? maxRange;

  bool _hitTarget = false;
  double _trailTimer = 0;
  double _traveledDistance = 0;

  /// 이미 타격한 적 목록 (관통 시 중복 타격 방지)
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
  }) : super(
    size: Vector2(10, 10),
    position: startPosition,
    anchor: Anchor.center,
    priority: 15,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 시각적 요소는 render()에서 직접 그림 (커스텀 렌더링)
  }

  Color _getColorForDamage(DamageType type) {
    switch (type) {
      case DamageType.physical:
        return const Color(0xFFFFB74D); // 따뜻한 금색
      case DamageType.magical:
        return const Color(0xFF64B5F6); // 밝은 하늘색
      case DamageType.purification:
        return const Color(0xFFE0E0E0); // 부드러운 흰색
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

    switch (damageType) {
      case DamageType.physical:
        // 화살 — 둥근 빛나는 삼각형 + 트레일
        // 글로우
        canvas.drawCircle(center, 5,
          Paint()..color = Color.fromARGB(40, glowColor.red, glowColor.green, glowColor.blue));
        // 화살촉 (삼각형)
        final arrowPath = Path()
          ..moveTo(5, 0)    // 위쪽 꼭짓점
          ..lineTo(1, 9)    // 좌하
          ..lineTo(9, 9)    // 우하
          ..close();
        canvas.drawPath(arrowPath, Paint()..color = color);
        canvas.drawPath(arrowPath, Paint()
          ..color = const Color(0xFFFFE0B2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
        // 꼬리 (부드러운 선)
        canvas.drawLine(
          const Offset(5, 9), const Offset(5, 14),
          Paint()
            ..color = Color.fromARGB(120, color.red, color.green, color.blue)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);
        break;

      case DamageType.magical:
        // 마법 오브 — 빛나는 원 + 외곽 링
        // 외곽 글로우
        canvas.drawCircle(center, 7,
          Paint()..color = Color.fromARGB(35, glowColor.red, glowColor.green, glowColor.blue));
        // 코어
        canvas.drawCircle(center, 4, Paint()..color = color);
        // 하이라이트
        canvas.drawCircle(center + const Offset(-1, -1), 1.5,
          Paint()..color = const Color(0x88FFFFFF));
        // 외곽 링
        canvas.drawCircle(center, 5, Paint()
          ..color = Color.fromARGB(80, glowColor.red, glowColor.green, glowColor.blue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
        break;

      case DamageType.purification:
        // 정화 — 빛나는 십자가 + 후광
        // 후광
        canvas.drawCircle(center, 6,
          Paint()..color = const Color(0x22FFD700));
        // 십자 (둥근 끝)
        final crossPaint = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(5, 1), const Offset(5, 9), crossPaint);
        canvas.drawLine(const Offset(1, 5), const Offset(9, 5), crossPaint);
        // 중심 빛
        canvas.drawCircle(center, 1.5, Paint()..color = const Color(0xFFFFD700));
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

    // 관통 투사체는 화면 밖이나 사거리 밖으로 나가면 제거
    if (maxRange != null && _traveledDistance > maxRange!) {
      removeFromParent();
      return;
    }

    if (hasPiercing && direction != null) {
      // 1) 관통: 직선 이동
      position += direction! * moveStep;

      // 이동 경로상 적 충돌 체크
      _checkPiercingCollisions();

      // 화면 밖 제거 체크 (간단히 수치로)
      if (position.x < -100 || position.x > 2000 || position.y < -100 || position.y > 2000) {
        removeFromParent();
      }
    } else {
      // 2) 일반: 타겟 추적 이동
      final toTarget = target.position - position;
      final distance = toTarget.length;

      if (distance < moveStep) {
        // 적중
        _applyHit(target);
        removeFromParent();
      } else {
        toTarget.normalize();
        position += toTarget * moveStep;
      }
    }
  }

  /// 관통 시 경로상의 모든 적 체크
  void _checkPiercingCollisions() {
    // game reference를 통해 현재 살아있는 적들 순회
    final enemies = (parent as HasGameReference<DefenseGame>?)?.game.cachedAliveEnemies 
                  ?? (target.parent as HasGameReference<DefenseGame>?)?.game.cachedAliveEnemies 
                  ?? [];

    for (final enemy in enemies) {
      if (enemy.isDead || _hitEnemies.contains(enemy)) continue;

      // 충돌 판정 (단순 거리 기반 or RectangleHitbox 활용)
      // Projectile 사이즈가 10x10이므로 반지름 15~20 정도면 적당
      final dist = position.distanceTo(enemy.position);
      if (dist < 20) {
        _applyHit(enemy);
      }
    }
  }

  /// 타격 적용 통합 메서드
  void _applyHit(BaseEnemy hitEnemy) {
    _hitEnemies.add(hitEnemy);
    hitEnemy.takeDamage(damage, damageType);
    
    // 첫 타겟 적중 시에만 onHit 호출 (스플래시 등과 겹치지 않게 주의)
    if (hitEnemy == target && !_hitTarget) {
      _hitTarget = true;
      onHit?.call();
    }

    // 적중 파티클 이펙트
    if (ParticleEffect.canCreate) {
      final hitColor = _getColorForDamage(damageType);
      if (damageType == DamageType.magical) {
        parent?.add(ParticleEffect.magic(position: position, color: hitColor));
        parent?.add(SpriteEffect(type: SpriteEffectType.lightning, position: position));
      } else if (damageType == DamageType.purification) {
        parent?.add(ParticleEffect.heal(position: position, color: hitColor));
      } else {
        parent?.add(ParticleEffect.hit(position: position, color: hitColor));
        parent?.add(SpriteEffect(type: SpriteEffectType.hit, position: position));
      }
    }

    // 피격 SFX (너무 자주 들리면 시끄러우니 관통 시에는 확률적 혹은 볼륨 조절 필요할 수 있음)
    SoundManager.instance.playSfx(SfxType.enemyHit);
  }
}
