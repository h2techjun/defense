import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../../common/enums.dart';
import '../../../../audio/sound_manager.dart';
import '../base_tower.dart';
import '../../actors/base_enemy.dart';
import '../projectile.dart';

/// ?�??발사 ?�략 ?�터?�이??(Strategy Pattern)
/// BaseTower???�포, 만신?? ?�?�사?????�양??발사 분기 로직??/// ?�래?�로 분리?�여 OCP(Open-Closed Principle)�?준?�합?�다.
abstract class TowerAttackStrategy {
  const TowerAttackStrategy();

  /// ?�??발사 ?�점???�출?�니??
  void fire(BaseTower tower, BaseEnemy target);
}

/// 기본 발사 ?�략: ?�일 ?�사�??�살) 발사
class BasicAttackStrategy extends TowerAttackStrategy {
  final DamageType defaultDamageType;

  const BasicAttackStrategy({required this.defaultDamageType});

  @override
  void fire(BaseTower tower, BaseEnemy target) {
    final proj = Projectile(
      target: target,
      damage: tower.currentDamage,
      damageType: defaultDamageType,
      speed: 300,
      startPosition: tower.position.clone(),
    );
    tower.parent?.add(proj);
    SoundManager.instance.playSfx(SfxType.towerShoot);
  }
}

/// ?�포???�?�군?????�플?�시 발사 ?�략
class ArtillerySplashStrategy extends TowerAttackStrategy {
  final double splashRadius;
  final DamageType damageType;

  const ArtillerySplashStrategy({
    required this.splashRadius,
    required this.damageType,
  });

  @override
  void fire(BaseTower tower, BaseEnemy target) {
    if (target.isDead) return;

    final proj = Projectile(
      target: target,
      damage: tower.currentDamage,
      damageType: damageType,
      speed: 250,
      startPosition: tower.position.clone(),
      visualType: ProjectileVisual.cannonball,
      onHit: () {
        final enemies = tower.game.gridSystem
            .getEnemiesNear(target.position, splashRadius);
        for (final enemy in enemies) {
          enemy.takeDamage(tower.currentDamage, damageType);
        }
        SoundManager.instance.playSfx(SfxType.towerShoot);
      },
    );
    tower.parent?.add(proj);
  }
}

/// 만신????광역 감속/마법 발사 ?�략
class ShamanMagicStrategy extends TowerAttackStrategy {
  final double slowAura;
  final DamageType damageType;

  const ShamanMagicStrategy({
    required this.slowAura,
    required this.damageType,
  });

  @override
  void fire(BaseTower tower, BaseEnemy target) {
    if (target.isDead) return;

    // 즉발성 보라색 빔 이펙트 (원래 로직 유지)
    tower.game.camera.viewfinder.add(
      ShamanBeam(start: tower.position.clone(), end: target.position.clone()),
    );

    // 슬로우 디버프 후 타격
    target.applySpeedDebuff(slowAura, 1.5);
    target.takeDamage(tower.currentDamage, damageType);

    // 발사체 (영혼 구슬) 추가
    final proj = Projectile(
      target: target,
      damage: 0, // 이미 데미지 들어감
      damageType: damageType,
      speed: 350,
      startPosition: tower.position.clone(),
      visualType: ProjectileVisual.shamanOrb,
    );
    tower.parent?.add(proj);
  }
}

/// 마법?�탑 공격 �???Canvas drawLine 기반
class ShamanBeam extends PositionComponent {
  final Vector2 start;
  final Vector2 end;
  final Paint _beamPaint;

  ShamanBeam({required this.start, required this.end})
      : _beamPaint = Paint()
          ..color = const Color(0xAA9955FF)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
        super(priority: 100);

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      Offset(start.x, start.y),
      Offset(end.x, end.y),
      _beamPaint,
    );
  }
}

/// ?�궁 관??발사 ?�략
class PiercingAttackStrategy extends TowerAttackStrategy {
  final DamageType damageType;

  const PiercingAttackStrategy({required this.damageType});

  @override
  void fire(BaseTower tower, BaseEnemy target) {
    final direction = (target.position - tower.position).normalized();
    final proj = Projectile(
      target: target,
      damage: tower.currentDamage,
      damageType: damageType,
      speed: 400,
      startPosition: tower.position.clone(),
      hasPiercing: true,
      direction: direction,
      maxRange: tower.currentRange * 1.5,
    );
    tower.parent?.add(proj);
    SoundManager.instance.playSfx(SfxType.towerShoot);
  }
}

/// ?�?�사??즉사/체력 비�? 발사 ?�략
class ReaperAttackStrategy extends TowerAttackStrategy {
  final double instantKillThreshold;
  final DamageType damageType;

  const ReaperAttackStrategy({
    required this.instantKillThreshold,
    required this.damageType,
  });

  @override
  void fire(BaseTower tower, BaseEnemy target) {
    // 즉사 ?�률 체크
    bool instantKill = false;
    if (instantKillThreshold > 0 &&
        !target.data.isBoss &&
        !target.data.isFlying) {
      if (math.Random().nextDouble() < instantKillThreshold) {
        instantKill = true;
      }
    }

    final dmg = instantKill ? target.hp : tower.currentDamage;

    final proj = Projectile(
      target: target,
      damage: dmg,
      damageType: damageType,
      speed: 350,
      startPosition: tower.position.clone(),
    );
    tower.parent?.add(proj);
    SoundManager.instance.playSfx(SfxType.towerShoot); // ?�시
  }
}
