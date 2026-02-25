// 해원의 문 - 병영 병사 (BarracksSoldier) 컴포넌트
// 병영 타워에서 소환되며, 근처 적을 블로킹(이동 중지)하고 근접 공격

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

import '../../../common/enums.dart';

import '../../../audio/sound_manager.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';

/// 병영에서 소환되는 병사 유닛
class BarracksSoldier extends PositionComponent
    with HasGameReference<DefenseGame> {
  /// 이 병사의 랠리 포인트 (드래그로 변경 가능)
  Vector2 rallyPoint;

  /// 타워의 활동 반경 (이 범위 밖으로 이동 불가)
  final double operationRange;

  /// 병사 스탯
  double hp;
  double maxHp;
  double attackDamage;
  double attackCooldown;
  double moveSpeed;

  /// 도깨비 씨름판 분기: 제압 모드 (데미지 2배, 적 반격 50% 감소)
  final bool isGrappler;

  /// 처치 시 추가 신명 보너스 비율
  final double goldBonusRatio;

  /// 현재 블로킹 중인 적
  BaseEnemy? _blockedEnemy;

  /// 공격 타이머
  double _attackTimer = 0;

  /// 사망 여부
  bool get isDead => hp <= 0;

  /// 현재 블로킹 중인 적
  BaseEnemy? get blockedEnemy => _blockedEnemy;

  /// 피격 플래시
  double _hitFlashTimer = 0;

  /// 고유 랜덤
  static final math.Random _random = math.Random();

  BarracksSoldier({
    required this.rallyPoint,
    required this.hp,
    required this.attackDamage,
    this.operationRange = 80,
    this.attackCooldown = 1.0,
    this.moveSpeed = 130,
    this.isGrappler = false,
    this.goldBonusRatio = 0,
  })  : maxHp = hp,
        super(
          size: Vector2(22, 22),
          anchor: Anchor.center,
          priority: 10,
        );

  @override
  Future<void> onLoad() async {
    // 도깨비 제압 병사: 붉은 계열 / 일반 병사: 파란 계열
    final bodyColor = isGrappler ? const Color(0xFFCC3333) : const Color(0xFF4477CC);
    final shieldColor = isGrappler ? const Color(0xFFDD5555) : const Color(0xFF6699DD);
    final weaponColor = isGrappler ? const Color(0xFFFFAA44) : const Color(0xFFCCCCCC);

    // 병사 시각 표현 (폴백용 사각형)
    final bodyRect = RectangleComponent(
      size: Vector2(18, 20),
      position: Vector2(2, 1),
      paint: Paint()..color = bodyColor,
    );
    add(bodyRect);
    // 방패 표시
    final shieldRect = RectangleComponent(
      size: Vector2(6, 10),
      position: Vector2(0, 6),
      paint: Paint()..color = shieldColor,
    );
    add(shieldRect);
    // 칼 표시
    final weaponRect = RectangleComponent(
      size: Vector2(3, 12),
      position: Vector2(18, 3),
      paint: Paint()..color = weaponColor,
    );
    add(weaponRect);

    // 스프라이트 이미지 로드 시도
    try {
      final imagePath = isGrappler
          ? 'soldiers/soldier_grappler.png'
          : 'soldiers/soldier_normal.png';
      final image = await game.images.load(imagePath);
      final sprite = Sprite(image);

      // 스프라이트 오버레이 추가
      add(SpriteComponent(
        sprite: sprite,
        size: size,
        position: Vector2.zero(),
        priority: 1,
      ));

      // 폴백 사각형 투명화
      bodyRect.paint.color = const Color(0x00000000);
      shieldRect.paint.color = const Color(0x00000000);
      weaponRect.paint.color = const Color(0x00000000);
    } catch (e) {
      // 스프라이트 로드 실패 시 기존 사각형 유지
    }

    // 랠리 포인트에서 고르게 분산 배치 (겹침 방지)
    // 병사 인덱스 기반으로 원형 배치
    final siblings = parent?.children.whereType<BarracksSoldier>().toList() ?? [];
    final idx = siblings.indexOf(this);
    final total = siblings.length.clamp(1, 6);
    final angle = (idx / total) * 2 * math.pi;
    final spreadRadius = 25.0;
    position = rallyPoint + Vector2(math.cos(angle) * spreadRadius, math.sin(angle) * spreadRadius);
    _clampToRange();
  }

  /// 병사 위치를 타워 범위 내로 제한
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

    // 블로킹 중인 적이 죽었거나 제거됐으면 해제
    if (_blockedEnemy != null) {
      if (_blockedEnemy!.isDead || !_blockedEnemy!.isMounted) {
        _releaseBlockedEnemy();
      }
    }

    // 블로킹 중인 적이 범위 밖으로 벗어났으면 해제하고 복귀
    if (_blockedEnemy != null) {
      final enemyDistFromTower = _blockedEnemy!.position.distanceTo(rallyPoint);
      if (enemyDistFromTower > operationRange * 1.5) {
        // 적이 타워 범위를 크게 벗어남 → 추적 포기
        _releaseBlockedEnemy();
      }
    }

    if (_blockedEnemy != null) {
      // 적과의 거리 계산
      final toEnemy = _blockedEnemy!.position - position;
      final dist = toEnemy.length;

      if (dist > 25) {
        // 아직 적에게 도달하지 못함 → 적에게 달려가기
        // (추격 중에는 범위 제한 해제 — 적을 확실히 잡기 위해)
        toEnemy.normalize();
        position += toEnemy * moveSpeed * 1.5 * dt;
      } else {
        // 적 근처 도착 → 공격 실행
        _attackTimer += dt;
        if (_attackTimer >= attackCooldown) {
          _attackTimer = 0;
          _attackBlockedEnemy();
        }
        // 적과 밀착 유지
        if (dist > 15) {
          toEnemy.normalize();
          position += toEnemy * moveSpeed * dt;
        }
      }
    } else {
      // 블로킹할 적 탐색 (타워 범위 내)
      _findEnemyToBlock();

      if (_blockedEnemy == null) {
        // 적이 없으면 랠리 포인트로 복귀
        final toRally = rallyPoint - position;
        if (toRally.length > 5) {
          toRally.normalize();
          position += toRally * moveSpeed * 0.5 * dt;
        }
      }
    }
  }

  /// 블로킹할 적 탐색 (타워 범위 내 + 병사 근접 범위)
  void _findEnemyToBlock() {
    final enemies = game.cachedAliveEnemies;
    double minDist = double.infinity;
    BaseEnemy? closest;

    // 근접 교전 범위: 병사 위치 기준 40px 이내 적도 교전
    const double engageRange = 40;

    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      if (enemy.data.isFlying) continue; // 비행 유닛 블로킹 불가
      if (enemy.isBlockedBy != null) continue; // 이미 다른 병사가 블로킹

      // 조건 1: 타워(랠리포인트) 기준 범위 체크
      final distFromTower = enemy.position.distanceTo(rallyPoint);
      final inTowerRange = distFromTower <= operationRange;

      // 조건 2: 병사 현재 위치 기준 근접 범위 체크 (이동 중 교전)
      final distFromSoldier = position.distanceTo(enemy.position);
      final inEngageRange = distFromSoldier <= engageRange;

      // 둘 중 하나라도 만족하면 교전 대상
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
    // 제압 모드: 데미지 2배 + 제압 사운드
    final dmg = isGrappler ? attackDamage * 2.0 : attackDamage;
    if (isGrappler) {
      SoundManager.instance.playSfx(SfxType.branchGrapple);
    }
    _blockedEnemy!.takeDamage(dmg, DamageType.physical);

    // 적 처치 시 보너스 신명
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

  /// 병사가 피격됨 (적의 반격)
  void takeDamage(double amount) {
    // 제압 모드: 반격 데미지 50% 감소
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

  /// 부활 (타워 업그레이드 시 등)
  void respawn() {
    hp = maxHp;
    _blockedEnemy = null;
    _attackTimer = 0;
    final offset = Vector2(
      (_random.nextDouble() - 0.5) * 40,
      (_random.nextDouble() - 0.5) * 40,
    );
    position = rallyPoint + offset;
    _clampToRange();
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
