// 해원의 문 - 영웅 (BaseHero) 컴포넌트

import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../../common/enums.dart';
import '../../../common/constants.dart';
import '../../../data/models/hero_data.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';
import '../towers/projectile.dart';

/// 영웅 컴포넌트 - 자동 공격 + 액티브 스킬
class BaseHero extends PositionComponent
    with HasGameReference<DefenseGame>, DragCallbacks, TapCallbacks {
  final HeroData data;
  int level;

  double _hp = 0;
  double _maxHp = 0;
  double _fireTimer = 0;
  double _skillCooldown = 0;
  bool _skillReady = true;
  bool _isDragging = false;

  // 시각
  late RectangleComponent _body;
  late RectangleComponent _hpBar;
  late CircleComponent _rangeIndicator;

  double get effectiveAttack {
    final evo = _getEvolution();
    return data.baseAttack * evo.attackMultiplier;
  }

  double get effectiveRange {
    final evo = _getEvolution();
    return data.baseRange * evo.rangeMultiplier;
  }

  double get effectiveMaxHp {
    final evo = _getEvolution();
    return data.baseHp * evo.hpMultiplier;
  }

  HeroEvolutionData _getEvolution() {
    if (level >= 10 && data.evolutions.length > 2) return data.evolutions[2];
    if (level >= 5 && data.evolutions.length > 1) return data.evolutions[1];
    return data.evolutions[0];
  }

  EvolutionTier get currentTier {
    if (level >= 10) return EvolutionTier.ultimate;
    if (level >= 5) return EvolutionTier.intermediate;
    return EvolutionTier.base;
  }

  BaseHero({
    required this.data,
    required Vector2 position,
    this.level = 1,
  }) : super(
    size: Vector2.all(36),
    position: position,
    anchor: Anchor.center,
    priority: 5,
  ) {
    _maxHp = effectiveMaxHp;
    _hp = _maxHp;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 영웅 색상 (ID별)
    final color = _getHeroColor(data.id);
    _body = RectangleComponent(
      size: size,
      paint: Paint()..color = color,
    );
    add(_body);

    // 진화 테두리
    add(RectangleComponent(
      size: Vector2(size.x + 4, size.y + 4),
      position: Vector2(-2, -2),
      paint: Paint()
        ..color = _getTierColor(currentTier)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    // HP 바
    _hpBar = RectangleComponent(
      size: Vector2(size.x, 4),
      position: Vector2(0, -10),
      paint: Paint()..color = const Color(0xFF44FF44),
    );
    add(_hpBar);

    // 범위 표시
    _rangeIndicator = CircleComponent(
      radius: effectiveRange,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0x11FFAA00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    add(_rangeIndicator);

    add(RectangleHitbox());
  }

  Color _getHeroColor(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:
        return const Color(0xFF4CAF50); // 초록 (탱커)
      case HeroId.miho:
        return const Color(0xFFE91E63); // 핑크 (마법)
      case HeroId.gangrim:
        return const Color(0xFF212121); // 검정 (저승차사)
      case HeroId.sua:
        return const Color(0xFF2196F3); // 파랑 (물)
      case HeroId.bari:
        return const Color(0xFFFFEB3B); // 노랑 (서포터)
    }
  }

  Color _getTierColor(EvolutionTier tier) {
    switch (tier) {
      case EvolutionTier.base:
        return const Color(0xFF888888);
      case EvolutionTier.intermediate:
        return const Color(0xFF4488FF);
      case EvolutionTier.ultimate:
        return const Color(0xFFFFD700);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 스킬 쿨다운
    if (!_skillReady) {
      _skillCooldown -= dt;
      if (_skillCooldown <= 0) {
        _skillReady = true;
      }
    }

    // 자동 공격
    _fireTimer += dt;
    final interval = 1.0; // 초당 1회
    if (_fireTimer >= interval) {
      _fireTimer = 0;
      _autoAttack();
    }

    // HP 바
    final hpRatio = (_hp / _maxHp).clamp(0.0, 1.0);
    _hpBar.size = Vector2(size.x * hpRatio, 4);
  }

  /// 자동 공격 - 범위 내 가장 가까운 적 타겟
  void _autoAttack() {
    BaseEnemy? target;
    double minDist = effectiveRange;

    final enemies = parent?.children.whereType<BaseEnemy>() ?? [];
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist < minDist) {
        target = enemy;
        minDist = dist;
      }
    }

    if (target != null) {
      final projectile = Projectile(
        target: target,
        damage: effectiveAttack,
        damageType: data.damageType,
        speed: 250,
        startPosition: position.clone(),
      );
      parent?.add(projectile);
    }
  }

  /// 액티브 스킬 사용
  void useSkill() {
    if (!_skillReady) return;

    _skillReady = false;
    _skillCooldown = data.skill.cooldown;

    // 스킬 효과 (영웅별)
    switch (data.id) {
      case HeroId.kkaebi:
        _skillSuplex();
        break;
      case HeroId.miho:
        _skillFoxFire();
        break;
      case HeroId.gangrim:
        _skillCallName();
        break;
      case HeroId.sua:
        _skillWaterGrasp();
        break;
      case HeroId.bari:
        _skillRitual();
        break;
    }
  }

  // ── 스킬 구현 ──

  /// 깨비: 뒤집기 - 가장 가까운 적 넉백
  void _skillSuplex() {
    final enemies = parent?.children.whereType<BaseEnemy>() ?? [];
    BaseEnemy? nearest;
    double minDist = data.skill.range;

    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist < minDist) {
        nearest = enemy;
        minDist = dist;
      }
    }

    if (nearest != null) {
      nearest.takeDamage(data.skill.damage, DamageType.physical);
      // 넉백 효과
      final pushDir = nearest.position - position;
      if (pushDir.length > 0) {
        pushDir.normalize();
        nearest.position -= pushDir * 80;
      }
      nearest.stun(1.0);
    }
  }

  /// 미호: 여우구슬 - 광역 화상
  void _skillFoxFire() {
    final enemies = parent?.children.whereType<BaseEnemy>() ?? [];
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= data.skill.range) {
        enemy.takeDamage(data.skill.damage, DamageType.magical);
      }
    }
    // 마나 회복
    game.ref.read(gameStateProvider.notifier).addSinmyeong(10);
  }

  /// 강림: 호명 - 체력 30% 이하 적 즉사
  void _skillCallName() {
    final enemies = parent?.children.whereType<BaseEnemy>() ?? [];
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= data.skill.range && enemy.hp / enemy.maxHp <= 0.3) {
        enemy.takeDamage(99999, DamageType.purification);
        break; // 1명만 즉사
      }
    }
  }

  /// 수아: 발목 잡기 - 광역 슬로우
  void _skillWaterGrasp() {
    final enemies = parent?.children.whereType<BaseEnemy>() ?? [];
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= data.skill.range) {
        enemy.stun(data.skill.duration); // 간소화: 슬로우 대신 스턴
      }
    }
  }

  /// 바리: 작두 타기 - 주변 아군 공속 버프 (간소화: 즉시 공격)
  void _skillRitual() {
    // 범위 내 타워들의 효과를 높이는 대신, 범위 내 모든 적에게 정화 데미지
    final enemies = parent?.children.whereType<BaseEnemy>() ?? [];
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= data.skill.range) {
        enemy.takeDamage(30, DamageType.purification);
      }
    }
  }

  /// 데미지 받기 (적의 공격)
  void takeDamage(double damage) {
    _hp -= damage;
    if (_hp <= 0) {
      _hp = 0;
      // 영웅 부활 대기 (10초)
      Future.delayed(const Duration(seconds: 10), () {
        _hp = _maxHp;
      });
    }
  }

  // 드래그로 영웅 위치 이동
  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
  }

  @override
  void onTapDown(TapDownEvent event) {
    useSkill();
  }
}
