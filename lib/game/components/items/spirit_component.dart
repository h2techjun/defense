// 해원의 문 - 원혼 (SpiritComponent)
// 적 사망 시 스폰 → 자동 수거 (부유 → 게이트웨이로 흡수)
// 한 게이지 80+ 시 수거 실패 → 가장 가까운 적에게 흡수 → 광폭화

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

import '../../../common/constants.dart';
import '../../../state/game_state.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';

/// 원혼 컴포넌트 (원한의 순환 시스템)
///
/// 적 사망 시 스폰 → 0.5초 부유 → 자동으로 게이트웨이 방향 이동 → 수거 완료
/// 한 게이지가 높으면 수거 실패 확률 증가 → 적 광폭화
class SpiritComponent extends PositionComponent
    with HasGameReference<DefenseGame> {
  double _timer = 0;
  bool _resolved = false; // 수거 또는 흡수 완료 여부
  double _pulseTimer = 0;

  // 자동 수거 단계
  _SpiritPhase _phase = _SpiritPhase.floating; // 부유 → 이동 → 수거
  Vector2 _velocity = Vector2.zero();

  // 시각
  late CircleComponent _glow;
  late CircleComponent _core;

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
    _core = CircleComponent(
      radius: 8,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF00FFAA),
    );
    add(_core);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_resolved) return;

    _timer += dt;
    _pulseTimer += dt;

    switch (_phase) {
      case _SpiritPhase.floating:
        _updateFloating(dt);
        break;
      case _SpiritPhase.moving:
        _updateMoving(dt);
        break;
      case _SpiritPhase.collecting:
        _updateCollecting(dt);
        break;
    }
  }

  /// 부유 단계 (0.5초) — 위로 살짝 떠오르며 펄스
  void _updateFloating(double dt) {
    // 위로 부유
    position.y -= 20 * dt;

    // 부유 펄스 애니메이션
    final pulse = 1.0 + 0.2 * math.sin(_pulseTimer * 6.0);
    _glow.scale = Vector2.all(pulse);

    // 0.5초 후 → 수거 판정
    if (_timer >= GameConstants.spiritFloatDuration) {
      _resolveDestiny();
    }
  }

  /// 수거/광폭화 판정
  void _resolveDestiny() {
    // 한 게이지에 따른 수거 실패율 (완화: 최대 25%)
    final wailing = game.ref.read(gameStateProvider).wailing;
    final failChance = (wailing / 200.0).clamp(0.0, 0.25);

    if (math.Random().nextDouble() < failChance) {
      // 수거 실패 → 적 흡수 (광폭화)
      _absorbIntoEnemy();
    } else {
      // 자동 수거 — 위로 빨려 올라가는 이펙트
      _phase = _SpiritPhase.moving;

      // 현재 위치에서 위로 올라가며 사라짐 (간단하고 안정적)
      _velocity = Vector2(0, -250.0);

      // 색상 변경 — 수거 시작 시 밝은 초록
      _glow.paint.color = const Color(0x6600FF88);
      _core.paint.color = const Color(0xFF88FFCC);
      _timer = 0;
    }
  }

  /// 이동 단계 — 위로 올라가며 수거
  void _updateMoving(double dt) {
    _timer += dt;
    position.add(_velocity * dt);

    // 점점 작아지며 밝아짐
    final progress = (_timer / GameConstants.spiritMoveToCollectDuration)
        .clamp(0.0, 1.0);
    final shrink = 1.0 - progress * 0.7;
    scale = Vector2.all(shrink.clamp(0.1, 1.0));

    // 투명도 변화
    final alpha = ((1.0 - progress * 0.8) * 255).toInt().clamp(0, 255);
    _glow.paint.color = Color.fromARGB(alpha ~/ 3, 0, 255, 136);
    _core.paint.color = Color.fromARGB(alpha, 136, 255, 204);

    // 수거 완료 (0.6초로 단축하여 빠르게)
    if (_timer >= GameConstants.spiritMoveToCollectDuration) {
      _phase = _SpiritPhase.collecting;
      _timer = 0;
      _collect();
    }
  }

  /// 수거 완료 — 자원 획득
  void _collect() {
    _resolved = true;
    game.onSpiritCollected();

    // 수거 이펙트 (확대 후 소멸)
    _glow.paint.color = const Color(0xFF00FF88);
    scale = Vector2.all(1.5);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (isMounted) removeFromParent();
    });
  }

  /// 수거 완료 후 프레임 (사용하지 않으나 안전 가드)
  void _updateCollecting(double dt) {
    // 수거 이펙트 대기 중 — 아무것도 하지 않음
  }

  /// 가장 가까운 적에게 흡수 → 광폭화
  void _absorbIntoEnemy() {
    _resolved = true;

    // 색상 → 붉게 변경 (위험 표시)
    _glow.paint.color = const Color(0x88FF0044);
    _core.paint.color = const Color(0xFFFF4444);

    BaseEnemy? nearest;
    double nearestDist = double.infinity;

    final enemies = game.cachedAliveEnemies;
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

    // 흡수 이펙트 후 제거
    Future.delayed(const Duration(milliseconds: 300), () {
      if (isMounted) removeFromParent();
    });
  }
}

/// 원혼 자동 수거 단계
enum _SpiritPhase {
  floating,   // 부유 (0.5초)
  moving,     // 게이트웨이 방향 이동
  collecting, // 수거 완료
}
