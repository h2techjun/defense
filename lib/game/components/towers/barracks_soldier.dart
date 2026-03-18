// ?댁썝??臾?- 蹂묒쁺 蹂묒궗 (BarracksSoldier) 而댄룷?뚰듃
// 蹂묒쁺 ??뚯뿉???뚰솚?섎ŉ, 洹쇱쿂 ?곸쓣 釉붾줈???대룞 以묒?)?섍퀬 洹쇱젒 怨듦꺽

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

import '../../../common/enums.dart';

import '../../../audio/sound_manager.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';

/// 蹂묒쁺?먯꽌 ?뚰솚?섎뒗 蹂묒궗 ?좊떅
class BarracksSoldier extends PositionComponent
    with HasGameReference<DefenseGame> {
  /// ??蹂묒궗???좊━ ?ъ씤??(?쒕옒洹몃줈 蹂寃?媛??
  Vector2 rallyPoint;

  /// ??뚯쓽 ?쒕룞 諛섍꼍 (??踰붿쐞 諛뽰쑝濡??대룞 遺덇?)
  final double operationRange;

  /// 蹂묒궗 ?ㅽ꺈
  double hp;
  double maxHp;
  double attackDamage;
  double attackCooldown;
  double moveSpeed;

  /// ?꾧묠鍮??⑤쫫??遺꾧린: ?쒖븬 紐⑤뱶 (?곕?吏 2諛? ??諛섍꺽 50% 媛먯냼)
  final bool isGrappler;

  /// 泥섏튂 ??異붽? ?좊챸 蹂대꼫??鍮꾩쑉
  final double goldBonusRatio;

  /// ?꾩옱 釉붾줈??以묒씤 ??
  BaseEnemy? _blockedEnemy;

  /// 怨듦꺽 ??대㉧
  double _attackTimer = 0;

  /// ?щ쭩 ?щ?
  bool get isDead => hp <= 0;

  /// ?꾩옱 釉붾줈??以묒씤 ??
  BaseEnemy? get blockedEnemy => _blockedEnemy;

  /// ?쇨꺽 ?뚮옒??
  double _hitFlashTimer = 0;

  /// 怨좎쑀 ?쒕뜡
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
          size: Vector2(80, 80), // ?곴낵 ?숈씪???ш린 (2.5諛??뺣?)
          anchor: Anchor.center,
          priority: 10,
        );

  @override
  Future<void> onLoad() async {
    // ?꾧묠鍮??쒖븬 蹂묒궗: 遺됱? 怨꾩뿴 / ?쇰컲 蹂묒궗: ?뚮? 怨꾩뿴
    final bodyColor = isGrappler ? const Color(0xFFCC3333) : const Color(0xFF4477CC);
    final shieldColor = isGrappler ? const Color(0xFFDD5555) : const Color(0xFF6699DD);
    final weaponColor = isGrappler ? const Color(0xFFFFAA44) : const Color(0xFFCCCCCC);

    // 蹂묒궗 ?쒓컖 ?쒗쁽 (?대갚???ш컖??
    final bodyRect = RectangleComponent(
      size: Vector2(18, 20),
      position: Vector2(2, 1),
      paint: Paint()..color = bodyColor,
    );
    add(bodyRect);
    // 諛⑺뙣 ?쒖떆
    final shieldRect = RectangleComponent(
      size: Vector2(6, 10),
      position: Vector2(0, 6),
      paint: Paint()..color = shieldColor,
    );
    add(shieldRect);
    // 移??쒖떆
    final weaponRect = RectangleComponent(
      size: Vector2(3, 12),
      position: Vector2(18, 3),
      paint: Paint()..color = weaponColor,
    );
    add(weaponRect);

    // ?ㅽ봽?쇱씠???대?吏 濡쒕뱶 ?쒕룄
    try {
      final imagePath = isGrappler
          ? 'soldiers/soldier_grappler.png'
          : 'soldiers/soldier_normal.png';
      final image = await game.images.load(imagePath);
      final sprite = Sprite(image);

      // ?ㅽ봽?쇱씠???ㅻ쾭?덉씠 異붽?
      add(SpriteComponent(
        sprite: sprite,
        size: size,
        position: Vector2.zero(),
        priority: 1,
      ));

      // ?대갚 ?ш컖???щ챸??
      bodyRect.paint.color = const Color(0x00000000);
      shieldRect.paint.color = const Color(0x00000000);
      weaponRect.paint.color = const Color(0x00000000);
    } catch (e) {
      // ?ㅽ봽?쇱씠??濡쒕뱶 ?ㅽ뙣 ??湲곗〈 ?ш컖???좎?
    }

    // ?좊━ ?ъ씤?몄뿉??怨좊Ⅴ寃?遺꾩궛 諛곗튂 (寃뱀묠 諛⑹?)
    // 蹂묒궗 ?몃뜳??湲곕컲?쇰줈 ?먰삎 諛곗튂
    position = assignedPosition.clone();
    _clampToRange();
  }

  /// 겹침을 방지하기 위한 분산된 위치 반환
  Vector2 get assignedPosition {
    final siblings = parent?.children.whereType<BarracksSoldier>().toList() ?? [];
    final idx = siblings.indexOf(this);
    if (idx < 0) return rallyPoint;
    final total = siblings.length.clamp(1, 6);
    final angle = (idx / total) * 2 * math.pi;
    const spreadRadius = 15.0; // 랠리포인트 근처에 모이도록 좁게
    return rallyPoint + Vector2(math.cos(angle) * spreadRadius, math.sin(angle) * spreadRadius);
  }

  /// 蹂묒궗 ?꾩튂瑜????踰붿쐞 ?대줈 ?쒗븳
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

    // ?쇨꺽 ?뚮옒??
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }

    // 釉붾줈??以묒씤 ?곸씠 二쎌뿀嫄곕굹 ?쒓굅?먯쑝硫??댁젣
    if (_blockedEnemy != null) {
      if (_blockedEnemy!.isDead || !_blockedEnemy!.isMounted) {
        _releaseBlockedEnemy();
      }
    }

    // 釉붾줈??以묒씤 ?곸씠 踰붿쐞 諛뽰쑝濡?踰쀬뼱?ъ쑝硫??댁젣?섍퀬 蹂듦?
    if (_blockedEnemy != null) {
      final enemyDistFromTower = _blockedEnemy!.position.distanceTo(rallyPoint);
      if (enemyDistFromTower > operationRange * 1.5) {
        // ?곸씠 ???踰붿쐞瑜??ш쾶 踰쀬뼱????異붿쟻 ?ш린
        _releaseBlockedEnemy();
      }
    }

    if (_blockedEnemy != null) {
      // ?곴낵??嫄곕━ 怨꾩궛
      final toEnemy = _blockedEnemy!.position - position;
      final dist = toEnemy.length;

      if (dist > 25) {
        // ?꾩쭅 ?곸뿉寃??꾨떖?섏? 紐삵븿 ???곸뿉寃??щ젮媛湲?
        // (異붽꺽 以묒뿉??踰붿쐞 ?쒗븳 ?댁젣 ???곸쓣 ?뺤떎???↔린 ?꾪빐)
        toEnemy.normalize();
        position += toEnemy * moveSpeed * 1.5 * dt;
      } else {
        // ??洹쇱쿂 ?꾩갑 ??怨듦꺽 ?ㅽ뻾
        _attackTimer += dt;
        if (_attackTimer >= attackCooldown) {
          _attackTimer = 0;
          _attackBlockedEnemy();
        }
        // ?곴낵 諛李??좎?
        if (dist > 15) {
          toEnemy.normalize();
          position += toEnemy * moveSpeed * dt;
        }
      }
    } else {
      // 釉붾줈?뱁븷 ???먯깋 (???踰붿쐞 ??
      _findEnemyToBlock();

      if (_blockedEnemy == null) {
        // ?곸씠 ?놁쑝硫??좊━ ?ъ씤?몃줈 蹂듦?
        final toRally = rallyPoint - position;
        if (toRally.length > 5) {
          toRally.normalize();
          position += toRally * moveSpeed * 0.5 * dt;
        }
      }
    }
  }

  /// 釉붾줈?뱁븷 ???먯깋 (???踰붿쐞 ??+ 蹂묒궗 洹쇱젒 踰붿쐞)
  void _findEnemyToBlock() {
    final enemies = game.cachedAliveEnemies;
    double minDist = double.infinity;
    BaseEnemy? closest;

    // 洹쇱젒 援먯쟾 踰붿쐞: 蹂묒궗 ?꾩튂 湲곗? 40px ?대궡 ?곷룄 援먯쟾
    const double engageRange = 40;

    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      if (enemy.data.isFlying) continue; // 鍮꾪뻾 ?좊떅 釉붾줈??遺덇?
      if (enemy.isBlockedBy != null) continue; // ?대? ?ㅻⅨ 蹂묒궗媛 釉붾줈??

      // 議곌굔 1: ????좊━?ъ씤?? 湲곗? 踰붿쐞 泥댄겕
      final distFromTower = enemy.position.distanceTo(rallyPoint);
      final inTowerRange = distFromTower <= operationRange;

      // 議곌굔 2: 蹂묒궗 ?꾩옱 ?꾩튂 湲곗? 洹쇱젒 踰붿쐞 泥댄겕 (?대룞 以?援먯쟾)
      final distFromSoldier = position.distanceTo(enemy.position);
      final inEngageRange = distFromSoldier <= engageRange;

      // ??以??섎굹?쇰룄 留뚯”?섎㈃ 援먯쟾 ???
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

  /// 釉붾줈??以묒씤 ??怨듦꺽
  void _attackBlockedEnemy() {
    if (_blockedEnemy == null || _blockedEnemy!.isDead) return;
    // ?쒖븬 紐⑤뱶: ?곕?吏 2諛?+ ?쒖븬 ?ъ슫??
    final dmg = isGrappler ? attackDamage * 2.0 : attackDamage;
    if (isGrappler) {
      SoundManager.instance.playSfx(SfxType.branchGrapple);
    }
    _blockedEnemy!.takeDamage(dmg, DamageType.physical);

    // ??泥섏튂 ??蹂대꼫???좊챸
    if (_blockedEnemy!.isDead && goldBonusRatio > 0) {
      final bonus = (_blockedEnemy!.data.sinmyeongReward * goldBonusRatio).round();
      if (bonus > 0) {
        game.onBonusSinmyeong(bonus);
      }
    }
  }

  /// ??釉붾줈???댁젣
  void _releaseBlockedEnemy() {
    _blockedEnemy?.clearBlockedBy();
    _blockedEnemy = null;
  }

  /// 蹂묒궗媛 ?쇨꺽??(?곸쓽 諛섍꺽)
  void takeDamage(double amount) {
    if (isDead) return;
    // ?쒖븬 紐⑤뱶: 諛섍꺽 ?곕?吏 50% 媛먯냼
    final effectiveAmount = isGrappler ? amount * 0.5 : amount;
    hp -= effectiveAmount;
    _hitFlashTimer = 0.1;

    if (hp <= 0) {
      hp = 0;
      _onDeath();
    }
  }

  /// ?щ쭩 泥섎━
  void _onDeath() {
    _releaseBlockedEnemy();
    // 遺?쒖? ???BaseTower)媛 ?꾨떞?섎?濡???媛쒖껜???꾩쟾???쒓굅??
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // HP 諛?
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

    // ?쇨꺽 ?뚮옒??
    if (_hitFlashTimer > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0x44FFFFFF),
      );
    }
  }
}


