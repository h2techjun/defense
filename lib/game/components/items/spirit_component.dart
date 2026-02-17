// 해원의 문 - 원혼 (SpiritComponent)
// 적 사망 시 스폰되어 플레이어가 탭하면 자원 획득
// 미수집 시 가장 가까운 적에게 흡수 → 광폭화

import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../../common/constants.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';

/// 원혼 컴포넌트 (원한의 순환 시스템의 핵심)
class SpiritComponent extends PositionComponent
    with HasGameReference<DefenseGame>, TapCallbacks {
  double _timer = 0;
  bool _collected = false;
  double _pulseTimer = 0;

  // 시각
  late CircleComponent _glow;

  SpiritComponent({required Vector2 position})
      : super(
          size: Vector2.all(24),
          position: position,
          anchor: Anchor.center,
          priority: 10,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 외부 빛
    _glow = CircleComponent(
      radius: 16,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0x4400FFAA),
    );
    add(_glow);

    // 내부 코어
    add(CircleComponent(
      radius: 8,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF00FFAA),
    ));

    // 탭 영역
    add(CircleHitbox(radius: 20, position: size / 2, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_collected) return;

    _timer += dt;
    _pulseTimer += dt;

    // 펄스 애니메이션 (점점 빠르게)
    final urgency = (_timer / GameConstants.spiritCollectTimeout).clamp(0.0, 1.0);
    final pulseSpeed = 2.0 + urgency * 6.0;
    final pulseScale = 1.0 + 0.3 * (1 + (pulseSpeed * _pulseTimer).remainder(3.14).abs() / 3.14);
    _glow.scale = Vector2.all(pulseScale);

    // 색상 변화 (위험해짐)
    final red = (urgency * 255).toInt();
    final green = ((1 - urgency) * 255).toInt();
    _glow.paint.color = Color.fromARGB(68, red, green, 170);

    // 시간 초과 → 가장 가까운 적에게 흡수
    if (_timer >= GameConstants.spiritCollectTimeout) {
      _absorbIntoEnemy();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_collected) return;
    _collected = true;

    // 신명 획득
    game.onSpiritCollected();

    // 수집 이펙트 (확대 후 소멸)
    _glow.paint.color = const Color(0xFF00FF88);
    scale = Vector2.all(1.5);

    Future.delayed(const Duration(milliseconds: 200), () {
      removeFromParent();
    });
  }

  /// 가장 가까운 적에게 흡수 → 광폭화
  void _absorbIntoEnemy() {
    _collected = true;

    BaseEnemy? nearest;
    double nearestDist = double.infinity;

    final enemies = parent?.children.whereType<BaseEnemy>() ?? [];
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist < nearestDist) {
        nearest = enemy;
        nearestDist = dist;
      }
    }

    if (nearest != null) {
      nearest.buffBerserk();
    }

    removeFromParent();
  }
}
