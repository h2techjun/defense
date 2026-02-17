// 해원의 문 - 타워 (BaseTower) 컴포넌트

import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../common/enums.dart';
import '../../../common/constants.dart';
import '../../../data/models/tower_data.dart';
import '../../../state/game_state.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';
import 'projectile.dart';

/// 타워 기본 컴포넌트
class BaseTower extends PositionComponent with HasGameReference<DefenseGame> {
  final TowerData data;
  int upgradeLevel = 0;
  TowerBranch? selectedBranch;

  // 전투 변수
  double _fireTimer = 0;
  BaseEnemy? _currentTarget;
  bool _isSilenced = false;
  double _silenceTimer = 0;

  // 런타임 스탯
  double get currentDamage {
    if (upgradeLevel < data.upgrades.length) {
      return data.upgrades[upgradeLevel].damage;
    }
    return data.baseDamage;
  }

  double get currentRange {
    final base = upgradeLevel < data.upgrades.length
        ? data.upgrades[upgradeLevel].range
        : data.baseRange;
    // 밤 패널티
    return base * game.dayNightSystem.getTowerRangeMultiplier();
  }

  double get currentFireRate {
    var rate = upgradeLevel < data.upgrades.length
        ? data.upgrades[upgradeLevel].fireRate
        : data.baseFireRate;
    // 한 100% 패널티
    final gameState = game.ref.read(gameStateProvider);
    if (gameState.isWailingMax) {
      rate *= (1.0 - GameConstants.wailingAttackSpeedPenalty);
    }
    return rate;
  }

  // 시각
  late RectangleComponent _body;
  late CircleComponent _rangeIndicator;

  BaseTower({
    required this.data,
    required Vector2 position,
  }) : super(
    size: Vector2.all(GameConstants.tileSize * 0.8),
    position: position,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final color = _getColorForType(data.type);
    _body = RectangleComponent(
      size: size,
      paint: Paint()..color = color,
    );
    add(_body);

    // 범위 인디케이터 (투명)
    _rangeIndicator = CircleComponent(
      radius: currentRange,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0x220088FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    add(_rangeIndicator);

    // 타워 타입 표시 (아이콘 대용)
    final typeMarker = RectangleComponent(
      size: Vector2(12, 12),
      position: Vector2(size.x / 2 - 6, size.y / 2 - 6),
      paint: Paint()..color = const Color(0xFFFFFFFF),
    );
    add(typeMarker);
  }

  Color _getColorForType(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return const Color(0xFF228B22); // 녹색
      case TowerType.barracks:
        return const Color(0xFF4169E1); // 파란색
      case TowerType.shaman:
        return const Color(0xFF9400D3); // 보라색
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 침묵 상태 처리
    if (_isSilenced) {
      _silenceTimer -= dt;
      if (_silenceTimer <= 0) {
        _isSilenced = false;
      }
      return;
    }

    // 타겟 갱신
    _updateTarget();

    // 발사 타이머
    if (_currentTarget != null) {
      _fireTimer += dt;
      final interval = 1.0 / currentFireRate;
      if (_fireTimer >= interval) {
        _fireTimer = 0;
        _fire();
      }
    }

    // 범위 인디케이터 업데이트
    _rangeIndicator.radius = currentRange;
  }

  /// 범위 내 가장 진행도가 높은 적 탐색
  void _updateTarget() {
    _currentTarget = null;
    double bestProgress = -1;

    final enemies = parent?.children.whereType<BaseEnemy>() ?? [];

    for (final enemy in enemies) {
      if (enemy.isDead) continue;

      final dist = position.distanceTo(enemy.position);
      if (dist <= currentRange) {
        // 진행도 높은(게이트웨이에 가까운) 적 우선
        if (bestProgress < 0 || dist < bestProgress) {
          _currentTarget = enemy;
          bestProgress = dist;
        }
      }
    }
  }

  /// 투사체 발사
  void _fire() {
    if (_currentTarget == null) return;

    final projectile = Projectile(
      target: _currentTarget!,
      damage: currentDamage,
      damageType: data.damageType,
      speed: 300,
      startPosition: position.clone(),
    );

    parent?.add(projectile);
  }

  /// 타워 업그레이드
  bool upgrade() {
    if (upgradeLevel >= data.upgrades.length - 1) return false;

    final nextLevel = upgradeLevel + 1;
    final cost = data.upgrades[nextLevel].cost;

    if (game.ref.read(gameStateProvider.notifier).spendSinmyeong(cost)) {
      upgradeLevel = nextLevel;
      // 시각 변화
      _body.paint.color = _getColorForType(data.type).withAlpha(
        (180 + upgradeLevel * 25).clamp(0, 255),
      );
      return true;
    }
    return false;
  }

  /// 침묵 (적 능력에 의해)
  void silence(double duration) {
    _isSilenced = true;
    _silenceTimer = duration;
  }
}
