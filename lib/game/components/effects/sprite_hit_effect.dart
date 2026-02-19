// 해원의 문 — 스프라이트 기반 히트/스킬 이펙트
// 9종 이펙트: 물리/마법/정화 피격 + 적 사망 + 영웅 스킬 5종
// 각 4프레임 애니메이션 재생 후 자동 소멸

import 'dart:async';
import 'package:flame/components.dart';

import '../../defense_game.dart';

/// 스프라이트 기반 이펙트 컴포넌트
///
/// 월드에 추가하면 4프레임 애니메이션 재생 후 자동 소멸.
/// 기존 [ParticleEffect]와 병행 사용 가능 — 더 화려한 연출에 적합.
///
/// 사용법:
/// ```dart
/// parent?.add(SpriteHitEffect.physical(position: enemy.position));
/// parent?.add(SpriteHitEffect.magic(position: enemy.position));
/// parent?.add(SpriteHitEffect.skillKkaebi(position: hero.position));
/// ```
class SpriteHitEffect extends SpriteAnimationComponent
    with HasGameReference<DefenseGame> {

  /// 동시 활성 이펙트 수 제한 (성능)
  static int _activeCount = 0;
  static const int _maxActive = 20;

  /// 새 이펙트 생성 가능 여부
  static bool get canCreate => _activeCount < _maxActive;

  /// 이펙트 유형
  final HitEffectType type;

  SpriteHitEffect({
    required super.position,
    this.type = HitEffectType.physical,
    Vector2? effectSize,
    double stepTime = 0.06,
  }) : _stepTime = stepTime,
       super(
          size: effectSize ?? Vector2.all(48),
          anchor: Anchor.center,
          priority: 100, // 최상위 렌더링
          removeOnFinish: true,
        ) {
    _activeCount++;
  }

  final double _stepTime;

  // ─── 히트 이펙트 팩토리 ───

  /// 물리 피격 이펙트 (오렌지/레드 폭발)
  factory SpriteHitEffect.physical({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.physical,
      effectSize: Vector2.all(48 * scale),
    );
  }

  /// 큰 물리 히트 이펙트 (보스/강 공격)
  factory SpriteHitEffect.physicalLarge({
    required Vector2 position,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.physical,
      effectSize: Vector2.all(72),
    );
  }

  /// 마법 피격 이펙트 (파란색 마법 터짐)
  factory SpriteHitEffect.magic({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.magic,
      effectSize: Vector2.all(48 * scale),
    );
  }

  /// 정화 피격 이펙트 (황금빛 성스러운 빛)
  factory SpriteHitEffect.purify({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.purify,
      effectSize: Vector2.all(48 * scale),
    );
  }

  /// 적 사망 이펙트 (귀신 영혼 분해)
  factory SpriteHitEffect.death({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.death,
      effectSize: Vector2.all(56 * scale),
      stepTime: 0.08, // 사망은 좀 더 느리게
    );
  }

  // ─── 스킬 이펙트 팩토리 ───

  /// 깨비 — 뒤집기 (녹색 충격파)
  factory SpriteHitEffect.skillKkaebi({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.skillKkaebi,
      effectSize: Vector2.all(64 * scale),
      stepTime: 0.07,
    );
  }

  /// 미호 — 여우구슬 (핑크 여우불)
  factory SpriteHitEffect.skillMiho({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.skillMiho,
      effectSize: Vector2.all(56 * scale),
      stepTime: 0.06,
    );
  }

  /// 강림 — 호명 (보라 사신 소환)
  factory SpriteHitEffect.skillGangrim({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.skillGangrim,
      effectSize: Vector2.all(56 * scale),
      stepTime: 0.08,
    );
  }

  /// 수아 — 발목 잡기 (파란 물결)
  factory SpriteHitEffect.skillSua({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.skillSua,
      effectSize: Vector2.all(56 * scale),
      stepTime: 0.07,
    );
  }

  /// 바리 — 작두 타기 (금색 정화)
  factory SpriteHitEffect.skillBari({
    required Vector2 position,
    double scale = 1.0,
  }) {
    return SpriteHitEffect(
      position: position,
      type: HitEffectType.skillBari,
      effectSize: Vector2.all(64 * scale),
      stepTime: 0.07,
    );
  }

  @override
  FutureOr<void> onLoad() async {
    final sprites = <Sprite>[];
    final prefix = type.assetPrefix;

    // 4프레임 로드
    for (int i = 0; i < 4; i++) {
      final image = await game.images.load('fx/${prefix}_$i.png');
      sprites.add(Sprite(image));
    }

    // 스프라이트 애니메이션 설정
    animation = SpriteAnimation.spriteList(
      sprites,
      stepTime: _stepTime,
      loop: false,
    );

    return super.onLoad();
  }

  @override
  void onRemove() {
    _activeCount--;
    super.onRemove();
  }
}

/// 이펙트 유형 (9종)
enum HitEffectType {
  // ─── 피격/사망 ───

  /// 물리 공격 (오렌지/레드 폭발)
  physical('fx_hit_physical'),

  /// 마법 공격 (파란색 마법 터짐)
  magic('fx_hit_magic'),

  /// 정화 공격 (황금빛 성스러운 빛)
  purify('fx_hit_purify'),

  /// 적 사망 (귀신 영혼 분해)
  death('fx_death_ghost'),

  // ─── 영웅 스킬 ───

  /// 깨비 뒤집기 (녹색 충격파)
  skillKkaebi('fx_kkaebi_flip'),

  /// 미호 여우구슬 (핑크 여우불)
  skillMiho('fx_miho_foxfire'),

  /// 강림 호명 (보라 사신 소환)
  skillGangrim('fx_gangrim_summon'),

  /// 수아 발목 잡기 (파란 물결)
  skillSua('fx_sua_grab'),

  /// 바리 작두 타기 (금색 정화)
  skillBari('fx_bari_ritual');

  final String assetPrefix;
  const HitEffectType(this.assetPrefix);
}
