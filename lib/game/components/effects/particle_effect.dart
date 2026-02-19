// 해원의 문 - 파티클 이펙트 시스템
// 현대적 아기자기 스타일 — 소프트 파티클 + 글로우

import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

/// 개별 파티클 데이터
class _Particle {
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  double size;
  Color color;
  double gravity;
  _ParticleShape shape;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
    this.gravity = 0,
    this.shape = _ParticleShape.circle,
  }) : maxLife = life;

  double get progress => 1.0 - (life / maxLife).clamp(0, 1);
  bool get isDead => life <= 0;
}

enum _ParticleShape { circle, diamond, star, ring }

/// 파티클 이펙트 컴포넌트 — 월드에 추가하면 자동 재생 후 소멸
class ParticleEffect extends PositionComponent {
  final List<_Particle> _particles = [];

  /// 동시 활성 파티클 수 제한 (성능)
  static int _activeCount = 0;
  static const int _maxActive = 15;

  /// 새 파티클 생성 가능 여부
  static bool get canCreate => _activeCount < _maxActive;

  ParticleEffect({required super.position}) : super(priority: 100) {
    _activeCount++;
  }

  /// 폭발 파티클 (적 피격 — 밝고 부드러운 스파크)
  factory ParticleEffect.hit({
    required Vector2 position,
    required Color color,
    int count = 8,
  }) {
    final effect = ParticleEffect(position: position);
    final rng = Random();

    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * pi * 2;
      final speed = 35 + rng.nextDouble() * 70;
      final shape = rng.nextBool() ? _ParticleShape.diamond : _ParticleShape.circle;
      effect._particles.add(_Particle(
        x: 0, y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.25 + rng.nextDouble() * 0.25,
        size: 2 + rng.nextDouble() * 3,
        color: Color.lerp(color, const Color(0xFFFFFFFF), rng.nextDouble() * 0.4)!,
        shape: shape,
      ));
    }
    return effect;
  }

  /// 적 사망 폭발 (화려한 스파크 + 링)
  factory ParticleEffect.death({
    required Vector2 position,
    required Color color,
  }) {
    final effect = ParticleEffect(position: position);
    final rng = Random();

    // 핵심 폭발 (큰 다이아몬드 파티클)
    for (int i = 0; i < 10; i++) {
      final angle = rng.nextDouble() * pi * 2;
      final speed = 50 + rng.nextDouble() * 100;
      effect._particles.add(_Particle(
        x: 0, y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.4 + rng.nextDouble() * 0.3,
        size: 3 + rng.nextDouble() * 4,
        color: Color.lerp(color, const Color(0xFFFFE082), rng.nextDouble() * 0.5)!,
        gravity: 60,
        shape: _ParticleShape.diamond,
      ));
    }

    // 확장 링
    effect._particles.add(_Particle(
      x: 0, y: 0,
      vx: 0, vy: 0,
      life: 0.4,
      size: 20,
      color: Color.fromARGB(80, color.red, color.green, color.blue),
      shape: _ParticleShape.ring,
    ));

    // 부드러운 연기 (파스텔 — 느림)
    for (int i = 0; i < 5; i++) {
      final angle = rng.nextDouble() * pi * 2;
      final speed = 15 + rng.nextDouble() * 30;
      effect._particles.add(_Particle(
        x: 0, y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 15,
        life: 0.6 + rng.nextDouble() * 0.4,
        size: 4 + rng.nextDouble() * 5,
        color: Color.fromARGB(60, color.red, color.green, color.blue),
      ));
    }
    return effect;
  }

  /// 화포 스플래시 폭발 (코랄/오렌지 불꽃)
  factory ParticleEffect.explosion({
    required Vector2 position,
    double radius = 50,
  }) {
    final effect = ParticleEffect(position: position);
    final rng = Random();

    // 불꽃 스파크
    for (int i = 0; i < 16; i++) {
      final angle = rng.nextDouble() * pi * 2;
      final speed = 40 + rng.nextDouble() * radius * 1.8;
      effect._particles.add(_Particle(
        x: 0, y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.3 + rng.nextDouble() * 0.4,
        size: 2 + rng.nextDouble() * 4,
        color: Color.lerp(
          const Color(0xFFFF7043),
          const Color(0xFFFFE082),
          rng.nextDouble(),
        )!,
        gravity: 50,
        shape: _ParticleShape.diamond,
      ));
    }

    // 충격파 링
    effect._particles.add(_Particle(
      x: 0, y: 0,
      vx: 0, vy: 0,
      life: 0.35,
      size: radius * 0.8,
      color: const Color(0x44FF7043),
      shape: _ParticleShape.ring,
    ));

    // 연기 (파스텔 그레이)
    for (int i = 0; i < 4; i++) {
      final angle = rng.nextDouble() * pi * 2;
      final speed = 10 + rng.nextDouble() * 25;
      effect._particles.add(_Particle(
        x: 0, y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 18,
        life: 0.7 + rng.nextDouble() * 0.5,
        size: 5 + rng.nextDouble() * 6,
        color: const Color(0x44A0A0A0),
      ));
    }
    return effect;
  }

  /// 힐/정화 이펙트 (상승 빛 + 별)
  factory ParticleEffect.heal({
    required Vector2 position,
    Color color = const Color(0xFF81C784),
  }) {
    final effect = ParticleEffect(position: position);
    final rng = Random();

    for (int i = 0; i < 8; i++) {
      effect._particles.add(_Particle(
        x: -8 + rng.nextDouble() * 16,
        y: 5,
        vx: -4 + rng.nextDouble() * 8,
        vy: -35 - rng.nextDouble() * 50,
        life: 0.5 + rng.nextDouble() * 0.5,
        size: 2 + rng.nextDouble() * 3,
        color: Color.lerp(color, const Color(0xFFFFFFFF), rng.nextDouble() * 0.5)!,
        shape: rng.nextBool() ? _ParticleShape.star : _ParticleShape.diamond,
      ));
    }
    // 중심 플래시
    effect._particles.add(_Particle(
      x: 0, y: 0,
      vx: 0, vy: -10,
      life: 0.3,
      size: 8,
      color: Color.fromARGB(100, color.red, color.green, color.blue),
      shape: _ParticleShape.ring,
    ));
    return effect;
  }

  /// 마법 이펙트 (나선형 빛 + 반짝이)
  factory ParticleEffect.magic({
    required Vector2 position,
    Color color = const Color(0xFF64B5F6),
  }) {
    final effect = ParticleEffect(position: position);
    final rng = Random();

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * pi * 2;
      final speed = 40 + rng.nextDouble() * 35;
      effect._particles.add(_Particle(
        x: 0, y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.35 + rng.nextDouble() * 0.25,
        size: 2 + rng.nextDouble() * 2.5,
        color: Color.lerp(color, const Color(0xFFE1F5FE), rng.nextDouble() * 0.4)!,
        shape: _ParticleShape.diamond,
      ));
    }
    return effect;
  }

  /// 영웅 스킬 발동 이펙트 (방사형 웨이브 + 별 반짝이)
  factory ParticleEffect.heroSkill({
    required Vector2 position,
    Color color = const Color(0xFFFFB74D),
  }) {
    final effect = ParticleEffect(position: position);
    final rng = Random();

    // 외곽 방사 (별 모양)
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * pi * 2;
      final speed = 70 + rng.nextDouble() * 50;
      effect._particles.add(_Particle(
        x: 0, y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 0.4 + rng.nextDouble() * 0.25,
        size: 3 + rng.nextDouble() * 3,
        color: Color.lerp(color, const Color(0xFFFFFFFF), rng.nextDouble() * 0.5)!,
        shape: _ParticleShape.star,
      ));
    }

    // 충격파 링
    effect._particles.add(_Particle(
      x: 0, y: 0,
      vx: 0, vy: 0,
      life: 0.4,
      size: 25,
      color: Color.fromARGB(100, color.red, color.green, color.blue),
      shape: _ParticleShape.ring,
    ));

    // 중심 플래시 (크고 밝은)
    effect._particles.add(_Particle(
      x: 0, y: 0,
      vx: 0, vy: 0,
      life: 0.25,
      size: 12,
      color: Color.fromARGB(180, color.red, color.green, color.blue),
    ));

    return effect;
  }

  @override
  void update(double dt) {
    super.update(dt);

    bool allDead = true;
    for (final p in _particles) {
      if (p.isDead) continue;
      allDead = false;

      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += p.gravity * dt;
      
      // 링 파티클 확장 효과
      if (p.shape == _ParticleShape.ring) {
        p.size += 80 * dt; // 링 점점 커짐
      }
    }

    if (allDead) {
      removeFromParent();
    }
  }

  @override
  void onRemove() {
    _activeCount--;
    super.onRemove();
  }

  // 재사용 Paint 객체 (매 프레임 new Paint() 방지)
  static final Paint _sharedPaint = Paint();

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      if (p.isDead) continue;

      final alpha = ((1.0 - p.progress) * (p.color.alpha / 255) * 255).toInt().clamp(0, 255);
      final currentSize = p.size * (1.0 - p.progress * 0.4);
      final c = Offset(p.x, p.y);

      _sharedPaint.color = Color.fromARGB(alpha, p.color.red, p.color.green, p.color.blue);

      switch (p.shape) {
        case _ParticleShape.circle:
          // 소프트 글로우 원
          canvas.drawCircle(c, currentSize * 1.5,
            Paint()..color = Color.fromARGB((alpha * 0.2).toInt().clamp(0, 255),
              p.color.red, p.color.green, p.color.blue));
          canvas.drawCircle(c, currentSize, _sharedPaint);
          break;

        case _ParticleShape.diamond:
          // 다이아몬드
          final path = Path()
            ..moveTo(c.dx, c.dy - currentSize)
            ..lineTo(c.dx + currentSize * 0.7, c.dy)
            ..lineTo(c.dx, c.dy + currentSize)
            ..lineTo(c.dx - currentSize * 0.7, c.dy)
            ..close();
          canvas.drawPath(path, _sharedPaint);
          break;

        case _ParticleShape.star:
          // 별 (4개 뿔)
          final path = Path();
          for (int i = 0; i < 8; i++) {
            final angle = (i / 8) * pi * 2 - pi / 2;
            final r = (i % 2 == 0) ? currentSize : currentSize * 0.4;
            if (i == 0) {
              path.moveTo(c.dx + cos(angle) * r, c.dy + sin(angle) * r);
            } else {
              path.lineTo(c.dx + cos(angle) * r, c.dy + sin(angle) * r);
            }
          }
          path.close();
          canvas.drawPath(path, _sharedPaint);
          break;

        case _ParticleShape.ring:
          // 링 (확장하며 사라짐)
          canvas.drawCircle(c, currentSize,
            Paint()
              ..color = Color.fromARGB(alpha, p.color.red, p.color.green, p.color.blue)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0 * (1.0 - p.progress));
          break;
      }
    }
  }
}
