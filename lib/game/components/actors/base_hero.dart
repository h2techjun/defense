// 해원의 문 - 영웅 (BaseHero) 컴포넌트
// 자동 공격, 액티브 스킬, 은신 감지, HP 재생, 부활 시스템

import 'dart:math' as math;
import 'dart:ui' hide TextStyle;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../../common/enums.dart';
import '../../../common/constants.dart';
import '../../../data/models/hero_data.dart';
import '../../../data/models/relic_data.dart';
import '../../../data/models/skin_data.dart';
import '../../../state/relic_provider.dart';
import '../../../state/skin_provider.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';
import '../towers/base_tower.dart';
import '../towers/projectile.dart';
import '../effects/particle_effect.dart';
import '../effects/sprite_hit_effect.dart';
import '../../../audio/sound_manager.dart';

/// 영웅 컴포넌트 - 자동 공격 + 액티브 스킬 + 은신 감지
class BaseHero extends PositionComponent
    with HasGameReference<DefenseGame>, DragCallbacks, TapCallbacks, HoverCallbacks {
  final HeroData data;
  int level;

  double _hp = 0;
  double _maxHp = 0;
  double _fireTimer = 0;
  double _skillCooldown = 0;
  bool _skillReady = true;

  // 경험치 시스템
  int _xp = 0;
  static const int maxLevel = 50;

  /// 레벨별 필요 경험치 공식: floor(20 × level^1.8)
  /// 50스테이지에 걸쳐 완만한 레벨업 곡선
  static int _xpForLevel(int lv) => (20 * math.pow(lv, 1.8)).floor();
  /// 외부 접근용
  static int xpForLevel(int lv) => _xpForLevel(lv);

  int get xp => _xp;
  int get xpForNextLevel => level >= maxLevel ? 0 : _xpForLevel(level);

  // 부활 시스템
  bool _isDead = false;
  double _reviveTimer = 0;
  static const double _reviveDuration = 10.0;

  // HP 재생
  static const double _regenPerSecond = 2.0;

  // 드래그 시각 피드백
  bool _isDragging = false;
  late CircleComponent _dragGlow;

  // 시각
  late RectangleComponent _body;
  RectangleComponent? _shadow;
  RectangleComponent? _border;
  late RectangleComponent _hpBar;
  late RectangleComponent _xpBar;
  late TextComponent _levelText;
  late CircleComponent _rangeIndicator;

  // 스프라이트 이미지
  SpriteComponent? _spriteComponent;
  bool _heroSpriteLoaded = false;
  EvolutionTier _lastTier = EvolutionTier.base;

  // 상태 접근자
  bool get isDead => _isDead;
  double get hp => _hp;
  double get maxHp => _maxHp;
  bool get skillReady => _skillReady;
  double get skillCooldownRatio =>
      _skillReady ? 0 : (_skillCooldown / data.skill.cooldown).clamp(0, 1);
  double get reviveProgress =>
      _isDead ? (1 - _reviveTimer / _reviveDuration).clamp(0, 1) : 1;

  // ── 유물 보너스 헬퍼 ──

  /// 장착 유물의 특정 효과 보너스 반환 (0.0 ~ 1.0)
  double _relicBonus(RelicEffectType type) {
    try {
      return game.ref.read(relicProvider.notifier).getEffectBonus(data.id, type);
    } catch (_) {
      return 0; // 게임 미초기화 시
    }
  }

  /// 레벨별 스탯 스케일링 공식 + 유물 보너스
  /// HP: baseHp × (1 + (level-1) × 0.08) × evoMultiplier × (1 + relicDefense)
  /// ATK: baseAtk × (1 + (level-1) × 0.06) × evoMultiplier × (1 + relicMagicDmg)
  /// Range: baseRange × (1 + (level-1) × 0.02) × evoMultiplier × (1 + relicRange)
  double get effectiveAttack {
    final evo = _getEvolution();
    double base = data.baseAttack * (1 + (level - 1) * 0.06) * evo.attackMultiplier;
    // 마법 데미지 유물 보너스 (마법 타입만)
    if (data.damageType == DamageType.magical || data.damageType == DamageType.purification) {
      base *= (1 + _relicBonus(RelicEffectType.magicDamageBonus));
    }
    return base;
  }

  double get effectiveRange {
    final evo = _getEvolution();
    final base = data.baseRange * (1 + (level - 1) * 0.02) * evo.rangeMultiplier;
    return base * (1 + _relicBonus(RelicEffectType.rangeBonus));
  }

  double get effectiveMaxHp {
    final evo = _getEvolution();
    final base = data.baseHp * (1 + (level - 1) * 0.08) * evo.hpMultiplier;
    return base * (1 + _relicBonus(RelicEffectType.defenseBonus));
  }

  /// 크리티컬 확률 (도깨비 방망이)
  double get criticalChance => _relicBonus(RelicEffectType.criticalChance);

  /// 스킬 쿨다운 감소율 (노리개)
  double get cooldownReduction => _relicBonus(RelicEffectType.cooldownReduction);

  HeroEvolutionData _getEvolution() {
    if (level >= 35 && data.evolutions.length > 2) return data.evolutions[2];
    if (level >= 15 && data.evolutions.length > 1) return data.evolutions[1];
    return data.evolutions[0];
  }

  EvolutionTier get currentTier {
    if (level >= 35) return EvolutionTier.ultimate;
    if (level >= 15) return EvolutionTier.intermediate;
    return EvolutionTier.base;
  }

  /// 경험치 획득 → 자동 레벨업
  void gainXp(int amount) {
    if (level >= maxLevel || _isDead) return;
    _xp += amount;

    // 레벨업 체크 (연속 레벨업 가능)
    while (level < maxLevel && _xp >= _xpForLevel(level)) {
      _xp -= _xpForLevel(level);
      level++;

      // 스탯 재계산: HP 비율 유지하며 maxHp 증가
      final hpRatio = _maxHp > 0 ? _hp / _maxHp : 1.0;
      _maxHp = effectiveMaxHp;
      _hp = _maxHp * hpRatio;

      // 시각 업데이트 (티어 전환 시 색상 변경)
      _body.paint.color = _getTierColor(currentTier);

      // 티어 전환 시 스프라이트 이미지 갱신
      if (currentTier != _lastTier) {
        _lastTier = currentTier;
        _loadHeroSprite();
      }

      if (kDebugMode) debugPrint('🎉 ${data.id.name} 레벨업! Lv.$level');
    }

    // 만렙 도달 시 잔여 경험치 초기화
    if (level >= maxLevel) _xp = 0;

    // XP 바 & 레벨 텍스트 실시간 갱신
    _updateXpDisplay();
  }

  /// XP 바 폭 계산
  double _getXpBarWidth() {
    if (level >= maxLevel) return size.x; // 만렙이면 꽉 참
    if (xpForNextLevel <= 0) return 0;
    return (size.x * (_xp / xpForNextLevel)).clamp(0.0, size.x);
  }

  /// XP 바 & 레벨 텍스트 갱신
  void _updateXpDisplay() {
    _xpBar.size.x = _getXpBarWidth();
    _levelText.text = 'Lv$level';
    // 만렙이면 XP 바 색상 변경 (금빛)
    if (level >= maxLevel) {
      _xpBar.paint.color = const Color(0xFFFF8C00);
    }
  }

  /// 저장된 경험치 복원 (레벨업 트리거 없이)
  void restoreXp(int savedXp) {
    _xp = savedXp;
  }

  BaseHero({
    required this.data,
    required Vector2 position,
    this.level = 1,
  }) : super(
    size: Vector2.all(96),
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
    _lastTier = currentTier;

    // 스프라이트 이미지 먼저 로드 시도
    await _loadHeroSprite();

    if (_heroSpriteLoaded) {
      // 스프라이트 성공 → 사각형 프레임 없이 스프라이트만 표시
      // _body는 투명한 더미로 (다른 코드에서 참조할 수 있으므로)
      _body = RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0x00000000),
      );
    } else {
      // 스프라이트 실패 → 사각형 폴백
      add(RectangleComponent(
        size: Vector2(size.x + 2, size.y + 2),
        position: Vector2(1, 2),
        paint: Paint()..color = const Color(0x44000000),
      ));

      _body = RectangleComponent(
        size: size,
        paint: Paint()..color = color,
      );
      add(_body);

      add(RectangleComponent(
        size: Vector2(size.x + 4, size.y + 4),
        position: Vector2(-2, -2),
        paint: Paint()
          ..color = _getTierColor(currentTier)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ));

      // 이모지 폴백
      final emoji = _getHeroEmoji(data.id);
      add(TextComponent(
        text: emoji,
        position: Vector2(size.x / 2, size.y / 2 - 2),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 22),
        ),
      ));
    }

    // 영웅 이름 라벨 (아래에 표시)
    add(TextComponent(
      text: data.name,
      position: Vector2(size.x / 2, size.y + 6),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0xFF000000), blurRadius: 3),
            Shadow(color: Color(0xFF000000), blurRadius: 6),
          ],
        ),
      ),
    ));

    // HP 바 배경
    add(RectangleComponent(
      size: Vector2(size.x + 2, 5),
      position: Vector2(-1, -12),
      paint: Paint()..color = const Color(0x66000000),
    ));

    // HP 바
    _hpBar = RectangleComponent(
      size: Vector2(size.x, 4),
      position: Vector2(0, -11),
      paint: Paint()..color = const Color(0xFF44FF44),
    );
    add(_hpBar);

    // XP 바 배경
    add(RectangleComponent(
      size: Vector2(size.x + 2, 3),
      position: Vector2(-1, -6),
      paint: Paint()..color = const Color(0x44000000),
    ));

    // XP 바 (노란색)
    _xpBar = RectangleComponent(
      size: Vector2(_getXpBarWidth(), 2),
      position: Vector2(0, -5.5),
      paint: Paint()..color = const Color(0xFFFFD700),
    );
    add(_xpBar);

    // 레벨 텍스트 (영웅 오른쪽 상단)
    _levelText = TextComponent(
      text: 'Lv$level',
      position: Vector2(size.x + 2, -6),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 8,
          color: Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Color(0xFF000000), blurRadius: 2),
          ],
        ),
      ),
    );
    add(_levelText);

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

    // 드래그 글로우 (기본 투명)
    _dragGlow = CircleComponent(
      radius: size.x * 0.6,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0x00000000),
    );
    add(_dragGlow);

    add(RectangleHitbox());
  }

  /// 영웅 스프라이트 이미지 로드 (티어별 다른 이미지)
  Future<void> _loadHeroSprite() async {
    try {
      // HeroId → 파일명 매핑
      final heroName = _getHeroFileName(data.id);
      final tierNum = _getTierNumber(currentTier);
      final imagePath = 'heroes/hero_${heroName}_$tierNum.png';

      final image = await game.images.load(imagePath);
      final sprite = Sprite(image);

      // 기존 스프라이트 제거
      if (_spriteComponent != null) {
        _spriteComponent!.removeFromParent();
      }

      // 새 스프라이트 추가
      _spriteComponent = SpriteComponent(
        sprite: sprite,
        size: size,
        position: Vector2.zero(),
        priority: 1,
      );
      add(_spriteComponent!);
      _heroSpriteLoaded = true;
    } catch (e) {
      _heroSpriteLoaded = false;
    }
  }

  /// HeroId → 파일명 부분 매핑
  String _getHeroFileName(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:
        return 'kkaebi';
      case HeroId.miho:
        return 'guMiho';
      case HeroId.gangrim:
        return 'darkYeomra';
      case HeroId.sua:
        return 'tigerHunter';
      case HeroId.bari:
        return 'hongGildong';
    }
  }

  /// EvolutionTier → 숫자 매핑
  int _getTierNumber(EvolutionTier tier) {
    switch (tier) {
      case EvolutionTier.base:
        return 1;
      case EvolutionTier.intermediate:
        return 2;
      case EvolutionTier.ultimate:
        return 3;
    }
  }

  /// 영웅 ID별 이모지
  String _getHeroEmoji(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:
        return '👹';
      case HeroId.miho:
        return '🦊';
      case HeroId.gangrim:
        return '💀';
      case HeroId.sua:
        return '🌊';
      case HeroId.bari:
        return '🌸';
    }
  }

  Color _getHeroColor(HeroId id) {
    // 스킨 장착 시 스킨 색상 반환
    try {
      final skinState = game.ref.read(skinProvider);
      final skinId = skinState.equippedSkins[id];
      if (skinId != null) {
        final skin = allSkins[skinId];
        if (skin != null && skin.rarity != SkinRarity.common) {
          return skin.primaryColor;
        }
      }
    } catch (_) {
      // 게임 초기화 전 폴백
    }

    // 기본 색상
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

    // 부활 대기 중
    if (_isDead) {
      _reviveTimer -= dt;
      if (_reviveTimer <= 0) {
        _revive();
      }
      return;
    }

    // HP 재생
    if (_hp < _maxHp) {
      _hp = (_hp + _regenPerSecond * dt).clamp(0, _maxHp);
    }

    // 스킬 쿨다운
    if (!_skillReady) {
      _skillCooldown -= dt;
      if (_skillCooldown <= 0) {
        _skillReady = true;
      }
    }

    // 은신 적 감지 (영웅 범위 내 은신 적 자동 reveal)
    _detectStealthEnemies();

    // 자동 공격
    _fireTimer += dt;
    final interval = 1.0 / (currentTier == EvolutionTier.ultimate ? 1.5 : 1.0);
    if (_fireTimer >= interval) {
      _fireTimer = 0;
      _autoAttack();
    }

    // HP 바
    final hpRatio = (_hp / _maxHp).clamp(0.0, 1.0);
    _hpBar.size = Vector2(size.x * hpRatio, 4);
  }

  /// 은신 적 감지 — 영웅만 할 수 있는 고유 능력
  void _detectStealthEnemies() {
    final enemies = game.cachedAliveEnemies;
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      if (!enemy.isStealth) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= effectiveRange) {
        enemy.reveal();
      }
    }
  }

  /// 자동 공격 - 범위 내 가장 가까운 적 타겟
  void _autoAttack() {
    BaseEnemy? target;
    double minDist = effectiveRange;

    final enemies = game.cachedAliveEnemies;
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist < minDist) {
        target = enemy;
        minDist = dist;
      }
    }

    if (target != null) {
      // 크리티컬 확률 적용 (도깨비 방망이 유물)
      double dmg = effectiveAttack;
      if (criticalChance > 0 && math.Random().nextDouble() < criticalChance) {
        dmg *= 2.0;
      }
      final projectile = Projectile(
        target: target,
        damage: dmg,
        damageType: data.damageType,
        speed: 250,
        startPosition: position.clone(),
      );
      parent?.add(projectile);
    }
  }

  /// 액티브 스킬 사용
  void useSkill() {
    if (!_skillReady || _isDead) return;

    _skillReady = false;
    // 유물 쿨다운 감소 적용 (노리개)
    _skillCooldown = data.skill.cooldown * (1 - cooldownReduction);

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

  /// 깨비: 뒤집기 - 가장 가까운 적 넉백 + 스턴
  /// 궁극기(Lv10+): 범위 내 모든 적 넉백로 강화
  void _skillSuplex() {
    final enemies = game.cachedAliveEnemies;

    // 🎆 스킬 이펙트: 녹색 충격파
    if (SpriteHitEffect.canCreate) {
      game.world.add(SpriteHitEffect.skillKkaebi(
        position: position.clone(),
      ));
    }
    if (ParticleEffect.canCreate) {
      game.world.add(ParticleEffect.heroSkill(
        position: position.clone(),
        color: const Color(0xFF4CAF50),
      ));
    }

    if (currentTier == EvolutionTier.ultimate) {
      // 궁극기: 범위 내 모든 적 넉백 + 스턴
      for (final enemy in enemies) {
        if (enemy.isDead) continue;
        final dist = position.distanceTo(enemy.position);
        if (dist <= data.skill.range) {
          enemy.takeDamage(data.skill.damage * 1.5, DamageType.physical);
          final pushDir = enemy.position - position;
          if (pushDir.length > 0) {
            pushDir.normalize();
            enemy.position -= pushDir * 80;
          }
          enemy.stun(2.0);
          // 적 피격 이펙트
          if (ParticleEffect.canCreate) {
            game.world.add(ParticleEffect.hit(
              position: enemy.position.clone(),
              color: const Color(0xFF66BB6A),
              count: 5,
            ));
          }
        }
      }
    } else {
      // 기본: 단일 타겟
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
        final pushDir = nearest.position - position;
        if (pushDir.length > 0) {
          pushDir.normalize();
          nearest.position -= pushDir * 80;
        }
        nearest.stun(1.0);
        // 적 피격 이펙트
        if (ParticleEffect.canCreate) {
          game.world.add(ParticleEffect.hit(
            position: nearest.position.clone(),
            color: const Color(0xFF66BB6A),
            count: 6,
          ));
        }
      }
    }
  }

  /// 미호: 여우구슬 - 광역 화상
  /// 궁극기(Lv10+): 데미지 2배 + 신명 회복 2배
  void _skillFoxFire() {
    final enemies = game.cachedAliveEnemies;
    final isUltimate = currentTier == EvolutionTier.ultimate;
    final damageMultiplier = isUltimate ? 2.0 : 1.0;

    // 🎆 스킬 이펙트: 핑크 여우불
    if (SpriteHitEffect.canCreate) {
      game.world.add(SpriteHitEffect.skillMiho(
        position: position.clone(),
      ));
    }
    if (ParticleEffect.canCreate) {
      game.world.add(ParticleEffect.magic(
        position: position.clone(),
        color: const Color(0xFFFF69B4),
      ));
    }

    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= data.skill.range) {
        enemy.takeDamage(data.skill.damage * damageMultiplier, DamageType.magical);
        // 적에게 화상 이펙트
        if (ParticleEffect.canCreate) {
          game.world.add(ParticleEffect.hit(
            position: enemy.position.clone(),
            color: const Color(0xFFFF4488),
            count: 4,
          ));
        }
      }
    }
    // 신명(마나) 회복 — 배치 큐 사용
    final sinmyeong = isUltimate ? 20 : 10;
    game.onBonusSinmyeong(sinmyeong);
  }

  /// 강림: 호명 - 체력 30% 이하 적 즉사
  /// 궁극기(Lv10+): 보스 포함 즉사 (50% 이하)
  void _skillCallName() {
    final enemies = game.cachedAliveEnemies;
    final isUltimate = currentTier == EvolutionTier.ultimate;
    final threshold = isUltimate ? 0.5 : 0.3;

    // 🎆 스킬 이펙트: 보라 사신 소환
    if (SpriteHitEffect.canCreate) {
      game.world.add(SpriteHitEffect.skillGangrim(
        position: position.clone(),
      ));
    }
    if (ParticleEffect.canCreate) {
      game.world.add(ParticleEffect.heroSkill(
        position: position.clone(),
        color: const Color(0xFF9C27B0),
      ));
    }

    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= data.skill.range && enemy.hp / enemy.maxHp <= threshold) {
        // 궁극기: 보스도 즉사 가능, 기본: 보스 제외
        if (!isUltimate && enemy.data.isBoss) continue;
        enemy.takeDamage(99999, DamageType.purification);
        // 즉사 이펙트: 보라색 폭발
        if (ParticleEffect.canCreate) {
          game.world.add(ParticleEffect.death(
            position: enemy.position.clone(),
            color: const Color(0xFF7B1FA2),
          ));
        }
        if (!isUltimate) break; // 기본: 1명만
      }
    }
  }

  /// 수아: 발목 잡기 - 광역 슬로우(스턴)
  /// 궁극기(Lv10+): 스턴 시간 2배 + 데미지 추가
  void _skillWaterGrasp() {
    final enemies = game.cachedAliveEnemies;
    final isUltimate = currentTier == EvolutionTier.ultimate;

    // 🎆 스킬 이펙트: 파란 물결
    if (SpriteHitEffect.canCreate) {
      game.world.add(SpriteHitEffect.skillSua(
        position: position.clone(),
      ));
    }
    if (ParticleEffect.canCreate) {
      game.world.add(ParticleEffect.magic(
        position: position.clone(),
        color: const Color(0xFF2196F3),
      ));
    }

    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= data.skill.range) {
        enemy.stun(data.skill.duration * (isUltimate ? 2.0 : 1.0));
        if (isUltimate) {
          enemy.takeDamage(data.skill.damage, DamageType.magical);
        }
        // 빙결/물 이펙트
        if (ParticleEffect.canCreate) {
          game.world.add(ParticleEffect.hit(
            position: enemy.position.clone(),
            color: const Color(0xFF64B5F6),
            count: 4,
          ));
        }
      }
    }
  }

  /// 바리: 작두 타기 - 정화 데미지 + 주변 타워 버프
  /// 궁극기(Lv10+): 아군 타워 공속 증가 + 영웅 전원 HP 회복
  void _skillRitual() {
    final isUltimate = currentTier == EvolutionTier.ultimate;

    // 🎆 스킬 이펙트: 금색 정화
    if (SpriteHitEffect.canCreate) {
      game.world.add(SpriteHitEffect.skillBari(
        position: position.clone(),
      ));
    }
    if (ParticleEffect.canCreate) {
      game.world.add(ParticleEffect.heal(
        position: position.clone(),
        color: const Color(0xFFFFD700),
      ));
    }
    if (ParticleEffect.canCreate) {
      game.world.add(ParticleEffect.heroSkill(
        position: position.clone(),
        color: const Color(0xFFFFEB3B),
      ));
    }

    // 정화 데미지
    final enemies = game.cachedAliveEnemies;
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      final dist = position.distanceTo(enemy.position);
      if (dist <= data.skill.range) {
        enemy.takeDamage(isUltimate ? 60 : 30, DamageType.purification);
      }
    }

    // 궁극기: 범위 내 타워 침묵 해제 + 버프
    if (isUltimate) {
      final towers = game.cachedTowers;
      for (final tower in towers) {
        final dist = position.distanceTo(tower.position);
        if (dist <= data.skill.range) {
          // 솟대 버프 효과 적용
          tower.applySlowDebuff(-0.3); // 음수 = 공속 증가 효과
        }
      }
    }
  }

  /// 데미지 받기 (적의 공격)
  void takeDamage(double damage) {
    if (_isDead) return;
    _hp -= damage;
    if (_hp <= 0) {
      _hp = 0;
      _die();
    }
  }

  /// 사망 처리
  void _die() {
    _isDead = true;
    _reviveTimer = _reviveDuration;
    // 반투명 처리
    _body.paint.color = _getHeroColor(data.id).withAlpha(80);
    _hpBar.paint.color = const Color(0xFF666666);
    // 스프라이트 반투명
    if (_spriteComponent != null) {
      _spriteComponent!.paint = Paint()..color = const Color(0x50FFFFFF);
    }
    SoundManager.instance.playSfx(SfxType.heroDeath);
  }

  /// 부활
  void _revive() {
    _isDead = false;
    _hp = _maxHp;
    _body.paint.color = _getHeroColor(data.id);
    _hpBar.paint.color = const Color(0xFF44FF44);
    // 스프라이트 원복
    if (_spriteComponent != null) {
      _spriteComponent!.paint = Paint()..color = const Color(0xFFFFFFFF);
    }
    SoundManager.instance.playSfx(SfxType.heroRevive);
  }

  // ── 드래그로 영웅 위치 이동 ──

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_isDead) return;
    _isDragging = true;
    // 드래그 시작: 글로우 + 범위 원 표시
    _dragGlow.paint.color = const Color(0x44FFAA00);
    _rangeIndicator.paint
      ..color = const Color(0x33FFAA00)
      ..strokeWidth = 2;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_isDead || !_isDragging) return;

    final newPos = position + event.localDelta;

    // 맵 경계 제한 (게임 월드 경계 내로)
    final bounds = game.gameMap.worldBounds;
    final margin = 20.0;
    newPos.x = newPos.x.clamp(bounds.left + margin, bounds.right - margin);
    newPos.y = newPos.y.clamp(bounds.top + margin, bounds.bottom - margin);

    position = newPos;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
    // 글로우 + 범위 원 복원
    _dragGlow.paint.color = const Color(0x00000000);
    _rangeIndicator.paint
      ..color = const Color(0x11FFAA00)
      ..strokeWidth = 1;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
    _dragGlow.paint.color = const Color(0x00000000);
    _rangeIndicator.paint
      ..color = const Color(0x11FFAA00)
      ..strokeWidth = 1;
  }

  // ── 호버 툴팁 ──

  @override
  void onHoverEnter() {
    game.onComponentHover?.call(_buildHeroTooltipInfo());
  }

  @override
  void onHoverExit() {
    game.onComponentHoverExit?.call();
  }

  /// 영웅 정보 → 툴팁 데이터 맵 생성
  Map<String, dynamic> _buildHeroTooltipInfo() {
    return {
      'type': 'hero',
      'name': data.name,
      'title': data.title,
      'emoji': _getHeroEmoji(data.id),
      'hp': _hp.toStringAsFixed(0),
      'maxHp': _maxHp.toStringAsFixed(0),
      'attack': effectiveAttack.toStringAsFixed(0),
      'range': effectiveRange.toStringAsFixed(0),
      'damageType': data.damageType.name,
      'backstory': data.backstory,
      'skillName': data.skill.name,
      'skillDesc': data.skill.description,
      'skillCooldown': data.skill.cooldown.toStringAsFixed(0),
      'tier': currentTier.name,
      'level': level,
      'maxLevel': maxLevel,
      'xp': _xp,
      'xpForNextLevel': xpForNextLevel,
      'isDead': _isDead,
      'color': _getHeroColor(data.id).value,
    };
  }

  @override
  void onTapDown(TapDownEvent event) {
    useSkill();
  }
}
