// 해원의 문 - 투사체 컴포넌트

import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../common/enums.dart';
import '../actors/base_enemy.dart';

/// 투사체 컴포넌트 - 타워에서 발사되어 적에게 데미지를 줍니다
class Projectile extends PositionComponent with CollisionCallbacks {
  final BaseEnemy target;
  final double damage;
  final DamageType damageType;
  final double speed;

  bool _hitTarget = false;

  Projectile({
    required this.target,
    required this.damage,
    required this.damageType,
    required this.speed,
    required Vector2 startPosition,
  }) : super(
    size: Vector2(8, 8),
    position: startPosition,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final color = _getColorForDamage(damageType);
    add(CircleComponent(
      radius: 4,
      paint: Paint()..color = color,
    ));
    add(CircleHitbox());
  }

  Color _getColorForDamage(DamageType type) {
    switch (type) {
      case DamageType.physical:
        return const Color(0xFFFFD700); // 금색
      case DamageType.magical:
        return const Color(0xFF00BFFF); // 하늘색
      case DamageType.purification:
        return const Color(0xFFFFFFFF); // 흰색
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_hitTarget || target.isDead) {
      removeFromParent();
      return;
    }

    // 목표 추적 이동
    final direction = target.position - position;
    final distance = direction.length;

    if (distance < speed * dt) {
      // 적중
      _hitTarget = true;
      target.takeDamage(damage, damageType);
      removeFromParent();
    } else {
      direction.normalize();
      position += direction * speed * dt;
    }
  }
}
