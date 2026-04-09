// 해원의 문 - 병영 병사 (BarracksSoldier) 컴포넌트
// 병영 타워에서 소환되는, 그리고 적을 직접 막는(블로킹) 근접 유닛

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

import '../../../common/debug_log.dart';
import '../../../common/enums.dart';
import '../../../common/asset_paths.dart';

import '../../../audio/sound_manager.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';

/// 병영에서 소환되는 병사 컴포넌트
class BarracksSoldier extends PositionComponent
    with HasGameReference<DefenseGame> {
  /// 이 병사의 랠리 포인트 (깃발로 변경 가능)
  Vector2 rallyPoint;

  /// 병사의 작전 반경 (이 범위 내에서만 적을 추격)
  final double operationRange;

  /// 병사 스탯
  double hp;
  double maxHp;
  double attackDamage;
  double attackCooldown;
  double moveSpeed;

  /// 씨름꾼 여부: 씨름 브랜치 (적 2배 + 피해 50% 감소)
  final bool isGrappler;

  /// 적 처치 신명 보너스 비율
  final double goldBonusRatio;

  /// 현재 블로킹 중인 적
  BaseEnemy? _blockedEnemy;

  /// 공격 타이머
  double _attackTimer = 0;

  /// 사망 여부
  bool get isDead => hp <= 0;

  /// 현재 블로킹 중인 적
  BaseEnemy? get blockedEnemy => _blockedEnemy;

  /// 피격 플래시 타이머
  double _hitFlashTimer = 0;

  /// 적 탐색 쿨다운 (매 프레임 탐색 방지)
  double _findEnemyCooldown = 0;
  static const double _findEnemyInterval = 0.15; // 초당 7회로 제한

  /// assignedPosition 캐시 (매 프레임 리스트 생성 방지)
  Vector2? _cachedAssignedPosition;

  BarracksSoldier({
    required this.rallyPoint,
    required this.hp,
    required this.attackDamage,
    this.operationRange = 45,
    this.attackCooldown = 1.0,
    this.moveSpeed = 130,
    this.isGrappler = false,
    this.goldBonusRatio = 0,
  })  : maxHp = hp,
        super(
          size: Vector2(80, 80),
          anchor: Anchor.center,
          priority: 10,
        );

  @override
  Future<void> onLoad() async {
    // 씨름꾼 병사: 붉은 계열 / 일반 병사: 파란 계열
    final bodyColor = isGrappler ? const Color(0xFFCC3333) : const Color(0xFF4477CC);
    final shieldColor = isGrappler ? const Color(0xFFDD5555) : const Color(0xFF6699DD);
    final weaponColor = isGrappler ? const Color(0xFFFFAA44) : const Color(0xFFCCCCCC);

    // 병사 폴백 렌더링 (스프라이트 없을 때)
    final bodyRect = RectangleComponent(
      size: Vector2(18, 20),
      position: Vector2(2, 1),
      paint: Paint()..color = bodyColor,
    );
    add(bodyRect);
    final shieldRect = RectangleComponent(
      size: Vector2(6, 10),
      position: Vector2(0, 6),
      paint: Paint()..color = shieldColor,
    );
    add(shieldRect);
    final weaponRect = RectangleComponent(
      size: Vector2(3, 12),
      position: Vector2(18, 3),
      paint: Paint()..color = weaponColor,
    );
    add(weaponRect);

    // 스프라이트 이미지 로드 시도
    try {
      final imagePath = isGrappler
          ? AssetPaths.image('soldiers/soldier_grappler')
          : AssetPaths.image('soldiers/soldier_normal');
      final image = await game.images.load(imagePath);
      final sprite = Sprite(image);

      add(SpriteComponent(
        sprite: sprite,
        size: size,
        position: Vector2.zero(),
        priority: 1,
      ));

      // 스프라이트가 로드되면 폴백 숨김
      bodyRect.paint.color = const Color(0x00000000);
      shieldRect.paint.color = const Color(0x00000000);
      weaponRect.paint.color = const Color(0x00000000);
    } on Exception catch (e) {
      dlog('[BarracksSoldier] 스프라이트 로드 실패 → 기존 렌더링: $e');
    }

    // 랠리 포인트에 가깝게 초기 위치 배정
    position = assignedPosition.clone();
    _clampToRange();
  }

  /// 겹침을 방지하기 위한 분산된 위치 반환 (캐싱)
  Vector2 get assignedPosition {
    if (_cachedAssignedPosition != null) return _cachedAssignedPosition!;
    final siblings = parent?.children.whereType<BarracksSoldier>().toList() ?? [];
    final idx = siblings.indexOf(this);
    if (idx < 0) {
      _cachedAssignedPosition = rallyPoint;
      return rallyPoint;
    }
    // 3방향 고정 배치 (120도 간격: 위, 좌하, 우하)
    const angles = [-1.5708, 2.618, 0.5236];
    final angle = angles[idx % 3];
    const spreadRadius = 18.0;
    _cachedAssignedPosition = rallyPoint + Vector2(math.cos(angle) * spreadRadius, math.sin(angle) * spreadRadius);
    return _cachedAssignedPosition!;
  }

  /// 병사 위치를 작전 범위 내로 제한
  void _clampToRange() {
    final toSoldier = position - rallyPoint;
    if (toSoldier.length > operationRange) {
      toSoldier.normalize();
      position = rallyPoint + toSoldier * operationRange;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) return;

    // 피격 플래시
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }

    // 블로킹 중인 적이 죽었거나 언마운트되면 해제
    if (_blockedEnemy != null) {
      if (_blockedEnemy!.isDead || !_blockedEnemy!.isMounted) {
        _releaseBlockedEnemy();
      }
    }

    // 블로킹 중인 적이 범위를 너무 벗어나면 해제
    if (_blockedEnemy != null) {
      final enemyDistFromTower = _blockedEnemy!.position.distanceTo(rallyPoint);
      if (enemyDistFromTower > operationRange * 1.5) {
        _releaseBlockedEnemy();
      }
    }

    if (_blockedEnemy != null) {
      // 적에게 이동 + 공격
      final toEnemy = _blockedEnemy!.position - position;
      final dist = toEnemy.length;

      if (dist > 25) {
        toEnemy.normalize();
        position += toEnemy * moveSpeed * 1.5 * dt;
      } else {
        _attackTimer += dt;
        if (_attackTimer >= attackCooldown) {
          _attackTimer = 0;
          _attackBlockedEnemy();
        }
        if (dist > 15) {
          toEnemy.normalize();
          position += toEnemy * moveSpeed * dt;
        }
      }
    } else {
      // 적 탐색 (쿨다운으로 제한 — 매 프레임 O(n) 탐색 방지)
      _findEnemyCooldown -= dt;
      if (_findEnemyCooldown <= 0) {
        _findEnemyCooldown = _findEnemyInterval;
        _findEnemyToBlock();
      }

      if (_blockedEnemy == null) {
        // 적이 없으면 랠리 포인트로 복귀
        final toRally = assignedPosition - position;
        if (toRally.length > 5) {
          toRally.normalize();
          position += toRally * moveSpeed * dt;
        }
      }
    }
  }

  /// 블로킹할 적 탐색 (쿨다운으로 호출 빈도 제한)
  void _findEnemyToBlock() {
    final enemies = game.cachedAliveEnemies;
    double minDist = double.infinity;
    BaseEnemy? closest;

    const double engageRange = 40;

    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      if (enemy.data.isFlying) continue; // 비행 유닛 블로킹 불가
      if (enemy.isBlockedBy != null) continue; // 이미 다른 병사가 블로킹 중

      final distFromTower = enemy.position.distanceTo(rallyPoint);
      final inTowerRange = distFromTower <= operationRange;

      final distFromSoldier = position.distanceTo(enemy.position);
      final inEngageRange = distFromSoldier <= engageRange;

      if (!inTowerRange && !inEngageRange) continue;

      if (distFromSoldier < minDist) {
        minDist = distFromSoldier;
        closest = enemy;
      }
    }

    if (closest != null) {
      _blockedEnemy = closest;
      closest.setBlockedBy(this);
    }
  }

  /// 블로킹 중인 적 공격
  void _attackBlockedEnemy() {
    if (_blockedEnemy == null || _blockedEnemy!.isDead) return;
    final dmg = isGrappler ? attackDamage * 2.0 : attackDamage;
    if (isGrappler) {
      SoundManager.instance.playSfx(SfxType.branchGrapple);
    }
    _blockedEnemy!.takeDamage(dmg, DamageType.physical);

    // 적 처치 시 신명 보너스
    if (_blockedEnemy!.isDead && goldBonusRatio > 0) {
      final bonus = (_blockedEnemy!.data.sinmyeongReward * goldBonusRatio).round();
      if (bonus > 0) {
        game.onBonusSinmyeong(bonus);
      }
    }
  }

  /// 적 블로킹 해제
  void _releaseBlockedEnemy() {
    _blockedEnemy?.clearBlockedBy();
    _blockedEnemy = null;
  }

  /// 깃발 이동 시 호출: 교전 해제 + 즉시 새 랠리포인트로 이동 시작
  void forceFollowRally(Vector2 newRallyPoint) {
    rallyPoint = newRallyPoint.clone();
    _cachedAssignedPosition = null; // 캐시 무효화
    _releaseBlockedEnemy();
    _attackTimer = 0;
  }

  /// 병사가 피격됨 (적의 공격)
  void takeDamage(double amount) {
    if (isDead) return;
    // 씨름꾼 브랜치: 피해 50% 감소
    final effectiveAmount = isGrappler ? amount * 0.5 : amount;
    hp -= effectiveAmount;
    _hitFlashTimer = 0.1;

    if (hp <= 0) {
      hp = 0;
      _onDeath();
    }
  }

  /// 사망 처리
  void _onDeath() {
    _releaseBlockedEnemy();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // HP 바
    final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, -4, size.x, 2),
      Paint()..color = const Color(0x88000000),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, -4, size.x * hpRatio, 2),
      Paint()
        ..color = hpRatio > 0.5
            ? const Color(0xFF44DD44)
            : const Color(0xFFFF4444),
    );

    // 피격 플래시
    if (_hitFlashTimer > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0x44FFFFFF),
      );
    }
  }
}
