import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../../common/enums.dart';
import '../../../../audio/sound_manager.dart';
import '../base_tower.dart';
import '../../actors/base_enemy.dart';
import '../projectile.dart';

/// ?€??ë°œì‚¬ ?„ëµ ?¸í„°?˜ì´??(Strategy Pattern)
/// BaseTower???”í¬, ë§Œì‹ ?? ?€?¹ì‚¬?????¤ì–‘??ë°œì‚¬ ë¶„ê¸° ë¡œì§??/// ?´ë˜?¤ë¡œ ë¶„ë¦¬?˜ì—¬ OCP(Open-Closed Principle)ë¥?ì¤€?˜í•©?ˆë‹¤.
abstract class TowerAttackStrategy {
  const TowerAttackStrategy();

  /// ?€??ë°œì‚¬ ?œì ???¸ì¶œ?©ë‹ˆ??
  void fire(BaseTower tower, BaseEnemy target);
}

/// ê¸°ë³¸ ë°œì‚¬ ?„ëµ: ?¨ì¼ ?¬ì‚¬ì²??”ì‚´) ë°œì‚¬
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

/// ?”í¬???€?¥êµ°?????¤í”Œ?˜ì‹œ ë°œì‚¬ ?„ëµ
class ArtillerySplashStrategy extends TowerAttackStrategy {
  final double splashRadius;
  final DamageType damageType;

  const ArtillerySplashStrategy({
    required this.splashRadius,
    required this.damageType,
  });

  @override
  void fire(BaseTower tower, BaseEnemy target) {
    final proj = Projectile(
      target: target,
      damage: tower.currentDamage,
      damageType: damageType,
      speed: 250,
      startPosition: tower.position.clone(),
      visualType: ProjectileVisual.cannonball,
      onHit: () {
        // ?¤í”Œ?˜ì‹œ ?°ë?ì§€
        final enemies = tower.game.gridSystem.getEnemiesNear(target.position, splashRadius);
        final rSq = splashRadius * splashRadius;
        for (final enemy in enemies) {
          if (!enemy.isDead && target.position.distanceToSquared(enemy.position) <= rSq) {
            enemy.takeDamage(tower.currentDamage, damageType);
          }
        }
        SoundManager.instance.playSfx(SfxType.towerMagic); // ?”í¬ ??°œ????      },
    );
    tower.parent?.add(proj);
    SoundManager.instance.playSfx(SfxType.towerShoot);
  }
}

/// ë§Œì‹ ????ê´‘ì—­ ê°ì†/ë§ˆë²• ë°œì‚¬ ?„ëµ
class ShamanMagicStrategy extends TowerAttackStrategy {
  final double slowAura;
  final DamageType damageType;

  const ShamanMagicStrategy({
    required this.slowAura,
    required this.damageType,
  });

  @override
  void fire(BaseTower tower, BaseEnemy target) {
    if (slowAura > 0) {
      // ?¥í™©?ì œ ??ê´‘ì—­ ?¬ë¡œ??+ ?°ë?ì§€
      final range = tower.currentRange;
      final rangeSq = range * range;
      final enemies = tower.game.gridSystem.getEnemiesNear(tower.position, range);
      final hitEnemies = <BaseEnemy>[];
      
      for (final enemy in enemies) {
        if (!enemy.isDead && tower.position.distanceToSquared(enemy.position) <= rangeSq) {
          enemy.takeDamage(tower.currentDamage, damageType);
          enemy.applySpeedDebuff(slowAura, 2.0);
          hitEnemies.add(enemy);
        }
      }

      // ?œê° ?¨ê³¼ ë³µì›
      for (final enemy in hitEnemies) {
        final beamStart = tower.size / 2;
        final beamEnd = enemy.position - tower.position + tower.size / 2;
        final beam = ShamanBeam(start: beamStart, end: beamEnd);
        tower.add(beam);

        tower.add(TimerComponent(
          period: 0.25,
          repeat: false,
          removeOnFinish: true,
          onTick: () {
            if (beam.isMounted) beam.removeFromParent();
          },
        ));
      }

      SoundManager.instance.playSfx(SfxType.towerMagic);
    } else {
      // ?¼ë°˜ ë§ˆë²•
      final proj = Projectile(
        target: target,
        damage: tower.currentDamage,
        damageType: damageType,
        speed: 350,
        startPosition: tower.position.clone(),
        visualType: ProjectileVisual.shamanOrb,
      );
      tower.parent?.add(proj);
      SoundManager.instance.playSfx(SfxType.towerMagic);
    }
  }
}

/// ë§ˆë²•?œíƒ‘ ê³µê²© ë¹???Canvas drawLine ê¸°ë°˜
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

/// ? ê¶ ê´€??ë°œì‚¬ ?„ëµ
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

/// ?€?¹ì‚¬??ì¦‰ì‚¬/ì²´ë ¥ ë¹„ë? ë°œì‚¬ ?„ëµ
class ReaperAttackStrategy extends TowerAttackStrategy {
  final double instantKillThreshold;
  final DamageType damageType;

  const ReaperAttackStrategy({
    required this.instantKillThreshold,
    required this.damageType,
  });

  @override
  void fire(BaseTower tower, BaseEnemy target) {
    // ì¦‰ì‚¬ ?•ë¥  ì²´í¬
    bool instantKill = false;
    if (instantKillThreshold > 0 && !target.data.isBoss && !target.data.isFlying) {
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
    SoundManager.instance.playSfx(SfxType.towerShoot); // ?„ì‹œ
  }
}


