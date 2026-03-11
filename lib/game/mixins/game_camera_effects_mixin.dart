// 해원의 문 - 카메라 이펙트 Mixin
// DefenseGame에서 분리된 Screen Shake, Red Flash, Night Overlay 로직

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';

import '../../common/constants.dart';
import '../world/day_night_system.dart';

/// 카메라 이펙트 — Screen Shake, Red Flash, Night Overlay
///
/// [DefenseGame]에서 `dayNightSystem`을 제공해야 함.
mixin GameCameraEffectsMixin on FlameGame {
  double _shakeTimer = 0;
  double _shakeIntensity = 0;

  /// 빨간 플래시 오버레이 (보스 기믹 등)
  double redFlashTimer = 0;

  /// 밤 오버레이 부드러운 전환
  double _nightOverlayAlpha = 0;

  /// 하위 클래스에서 구현해야 하는 접근자
  DayNightSystem get dayNightSystem;

  /// 화면 흔들림 (Screen Shake) — 외부 호출 가능
  void shakeScreen(double intensity, {double duration = 0.3}) {
    _shakeIntensity = intensity;
    _shakeTimer = duration;
  }

  /// 빨간 플래시 발동 (보스 기믹 시각 이펙트)
  void triggerRedFlash({double duration = 0.5}) {
    redFlashTimer = duration;
  }

  /// update에서 호출: Screen Shake 처리
  void updateScreenShake(double dt) {
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      final rng = math.Random();
      final offsetX = (rng.nextDouble() - 0.5) * 2 * _shakeIntensity;
      final offsetY = (rng.nextDouble() - 0.5) * 2 * _shakeIntensity;
      camera.viewfinder.position = Vector2(
        GameConstants.gameWidth / 2 + offsetX,
        GameConstants.gameHeight / 2 + offsetY,
      );
    } else if (_shakeIntensity > 0) {
      _shakeIntensity = 0;
      camera.viewfinder.position = Vector2(
        GameConstants.gameWidth / 2,
        GameConstants.gameHeight / 2,
      );
    }
  }

  /// update에서 호출: Red Flash 카운트다운
  void updateRedFlash(double dt) {
    if (redFlashTimer > 0) {
      redFlashTimer -= dt;
    }
  }

  /// render에서 호출: 밤 오버레이 렌더링
  void renderNightOverlay(Canvas canvas) {
    final targetAlpha = dayNightSystem.nightOverlayOpacity;
    _nightOverlayAlpha += (targetAlpha - _nightOverlayAlpha) * 0.03;

    if (_nightOverlayAlpha > 0.01) {
      final paint = Paint()
        ..color = Color.fromRGBO(15, 20, 50, _nightOverlayAlpha)
        ..blendMode = BlendMode.srcOver;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        paint,
      );
    }
  }

  /// render에서 호출: 보스 기믹 빨간 플래시 오버레이
  void renderRedFlash(Canvas canvas) {
    if (redFlashTimer > 0) {
      final alpha = (redFlashTimer.clamp(0, 0.5) / 0.5 * 80).toInt();
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Color.fromARGB(alpha, 255, 0, 0),
      );
    }
  }
}
