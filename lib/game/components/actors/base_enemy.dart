// 해원의 문 - 적 (BaseEnemy) 컴포넌트
// FSM 상태머신, 경로 이동, 사망 시 원혼 스폰 포함
// 비행, 은신, 디버프 오라, 방패, 분열, 광폭화, 블로킹, 보스 능력

import 'dart:math';
import '../effects/particle_effect.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../../common/enums.dart';
import '../../../common/constants.dart';
import '../renderers/enemy_renderer.dart';
import '../../../data/models/enemy_data.dart';
import '../../../data/game_data_loader.dart';
import '../../../state/game_state.dart';
import '../../defense_game.dart';
import '../actors/base_hero.dart';
import '../items/spirit_component.dart';
import '../towers/base_tower.dart';
import '../towers/barracks_soldier.dart';
import '../../../common/debug_log.dart';

/// 적 기본 컴포넌트
class BaseEnemy extends PositionComponent
    with HasGameReference<DefenseGame>, HoverCallbacks {
  final EnemyData data;

  // 상태
  EnemyState _state = EnemyState.walking;
  double _hp = 0;
  double _maxHp = 0;
  double _speed = 0;
  bool _isBerserk = false;
  double _stunTimer = 0;

  // 병사에 의한 블로킹
  BarracksSoldier? _blockedBy;
  double _counterAttackTimer = 0;
  double _blockDuration = 0; // 블로킹 지속 시간 (타임아웃용)

  // ── 디버그용 public getter ──
  EnemyState get debugState => _state;
  BarracksSoldier? get debugBlockedBy => _blockedBy;
  int get debugWaypointIndex => _currentWaypointIndex;
  double get debugSpeed => _getEffectiveSpeed();
  double get debugStunTimer => _stunTimer;
  bool get debugIsBerserk => _isBerserk;

  // 보스 특수 능력 타이머
  double _bossAbilityTimer = 0;
  static const double _bossAbilityCooldown = 10.0; // 10초마다 발동

  // 은신 상태
  bool _isRevealed = false; // 영웅에 의해 감지됨

  // 방패 활성화 상태
  bool _shieldActive = false;

  // 경로 이동
  List<Vector2> _waypoints = [];
  int _currentWaypointIndex = 0;

  // 시각 표현
  late PositionComponent _body;
  late Paint _bodyPaint; // 광폭화 색상 변경용
  late RectangleComponent _hpBar;
  late RectangleComponent _hpBarBg;
  double _hitFlashTimer = 0; // 피격 플래시
  static final Random _random = Random();

  EnemyState get state => _state;
  double get hp => _hp;
  double get maxHp => _maxHp;
  bool get isBerserk => _isBerserk;
  bool _reachedGateway = false;
  bool get isDead => _hp <= 0 || _reachedGateway;

  /// 은신 상태인가? (타워가 타겟팅 불가)
  bool get isStealth => data.isStealth && !_isRevealed;

  /// 병사에 의해 블로킹 중인가?
  BarracksSoldier? get isBlockedBy => _blockedBy;

  /// 병사가 이 적을 블로킹
  void setBlockedBy(BarracksSoldier soldier) {
    _blockedBy = soldier;
  }

  /// 블로킹 해제
  void clearBlockedBy() {
    _blockedBy = null;
  }

  /// 진행도 (타워 타겟팅 우선순위용)
  double get progress {
    if (_currentWaypointIndex >= _waypoints.length) return double.infinity;
    final nextWp = _waypoints[_currentWaypointIndex];
    return (_currentWaypointIndex * 10000) - position.distanceTo(nextWp);
  }

  BaseEnemy({
    required this.data,
    required List<Vector2> waypoints,
    double hpMultiplier = 1.0,
    double speedMultiplier = 1.0,
  }) : super(
    size: Vector2(data.isBoss ? 160 : 100, data.isBoss ? 160 : 100), // 2.5배 확대
    anchor: Anchor.center,
  ) {
    _waypoints = waypoints;
    _hp = data.hp * hpMultiplier;
    _maxHp = data.hp * hpMultiplier;
    _speed = data.speed * speedMultiplier;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 시작 위치
    if (_waypoints.isNotEmpty) {
      position = _waypoints.first.clone();
      _currentWaypointIndex = 1;
    }

    // 본체 — Canvas 기반 고품질 렌더링
    final bodyColor = _getColorForArmor(data.armorType);
    _bodyPaint = Paint()..color = bodyColor;
    _body = EnemyRenderer(
      data: data,
      size: size.clone(),
    );
    add(_body);

    // HP 바 배경
    _hpBarBg = RectangleComponent(
      size: Vector2(size.x, 4),
      position: Vector2(0, -8),
      paint: Paint()..color = const Color(0xFF333333),
    );
    add(_hpBarBg);

    // HP 바
    _hpBar = RectangleComponent(
      size: Vector2(size.x, 4),
      position: Vector2(0, -8),
      paint: Paint()..color = const Color(0xFF44FF44),
    );
    add(_hpBar);

    // 충돌 감지
    add(RectangleHitbox());

    // 은신 유닛 — 반투명
    if (data.isStealth) {
      _bodyPaint.color = bodyColor.withAlpha(100);
    }

    // 보스 등장 시 GameState에 보스 정보 등록 + 등장 연출
    if (data.isBoss) {
      game.ref.read(gameStateProvider.notifier).setBoss(data.name, _maxHp);
      // 보스 등장 화면 흔들림 + 빨간 플래시
      game.shakeScreen(10.0, duration: 0.8);
      game.triggerRedFlash(duration: 0.6);
    }
  }

  Color _getColorForArmor(ArmorType armor) {
    switch (armor) {
      case ArmorType.physical:
        return const Color(0xFF8B4513); // 갈색
      case ArmorType.spiritual:
        return const Color(0xFF6A0DAD); // 보라색
      case ArmorType.yokai:
        return const Color(0xFFDC143C); // 진홍색
    }
  }

  // ── 디버깅용 타이머 (디버그 빌드 전용) ──
  double _debugTimer = 0;
  static int _debugSlotCounter = 0;
  int _debugSlot = -1;

  @override
  void update(double dt) {
    super.update(dt);

    // 디버깅: 최초 3개 적만 3초 주기로 상태 보고 (릴리즈 빌드에서는 완전 스킵)
    if (kDebugMode) {
      if (_debugSlot < 0) {
        _debugSlot = _debugSlotCounter++;
      }
      if (_debugSlot < 3 && !isDead) {
        _debugTimer += dt;
        if (_debugTimer >= 3.0) {
          _debugTimer = 0;
          dlog('[ENEMY#$_debugSlot] id=${data.id.name} '
            'state=$_state pos=(${position.x.toInt()},${position.y.toInt()}) '
            'wpIdx=$_currentWaypointIndex/${_waypoints.length} '
            'speed=${_getEffectiveSpeed().toStringAsFixed(1)} '
            'dt=${dt.toStringAsFixed(4)} '
            'blocked=${_blockedBy != null} '
            'berserk=$_isBerserk stun=${_stunTimer.toStringAsFixed(1)} '
            'mounted=$isMounted');
        }
      }
    }

    switch (_state) {
      case EnemyState.walking:
      case EnemyState.berserk:
        // 블로킹 유효성 검증 — 여러 조건으로 해제
        if (_blockedBy != null) {
          final soldier = _blockedBy!;
          final soldierDead = soldier.isDead;
          final soldierUnmounted = !soldier.isMounted;
          // 거리 체크: 병사가 100px 이상 떨어지면 블로킹 해제
          final dist = position.distanceTo(soldier.position);
          final tooFar = dist > 100.0;
          // 블로킹 지속 시간 누적
          _blockDuration += dt;
          // 타임아웃: 10초 이상 블로킹되면 강제 해제 (프리즈 방지)
          final timeout = _blockDuration > 10.0;
          
          if (soldierDead || soldierUnmounted || tooFar || timeout) {
            _blockedBy = null;
            _counterAttackTimer = 0;
            _blockDuration = 0;
          }
        }
        
        // 블로킹 중이면 이동 중지 + 반격
        if (_blockedBy != null) {
          _counterAttackTimer += dt;
          if (_counterAttackTimer >= 1.5 && data.attack > 0) {
            _counterAttackTimer = 0; // 반격 후 리셋 (1.5초 주기)
            final attackDmg = _isBerserk
                ? data.attack * GameConstants.berserkAttackMultiplier
                : data.attack;
            _blockedBy!.takeDamage(attackDmg);
          }
        } else {
          // 비행 유닛은 직선 이동 (경로 무시), 지상 유닛은 경로 이동
          if (data.isFlying) {
            _moveFlyingStraight(dt);
          } else {
            _moveAlongPath(dt);
          }
        }
        break;
      case EnemyState.stunned:
        _stunTimer -= dt;
        if (_stunTimer <= 0) {
          _state = _isBerserk ? EnemyState.berserk : EnemyState.walking;
        }
        break;
      case EnemyState.dying:
        break;
      case EnemyState.idle:
        break;
    }

    // 보스 특수 능력 (지진 등)
    if (data.isBoss && !isDead && _state != EnemyState.dying) {
      _bossAbilityTimer += dt;
      if (_bossAbilityTimer >= _bossAbilityCooldown) {
        _bossAbilityTimer = 0;
        _executeBossAbility();
      }
    }

    // 방패 상태 체크
    _updateShield();


    // HP 바 업데이트
    _updateHpBar();

    // DoT 틱 데미지 (화차 분기 등)
    _updateDot(dt);

    // 감속 디버프 타이머
    if (_speedDebuffTimer > 0) {
      _speedDebuffTimer -= dt;
      if (_speedDebuffTimer <= 0) {
        _speedDebuff = 0;
        _speedDebuffTimer = 0;
      }
    }

    // 피격 플래시 — 흰색 반동 + 스케일
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
      _body.scale = Vector2.all(1.1);
    } else {
      _body.scale = Vector2.all(1.0);
    }
  }

  /// 경로를 따라 이동 (지상 유닛)
  void _moveAlongPath(double dt) {
    if (_currentWaypointIndex >= _waypoints.length) {
      _reachGateway();
      return;
    }

    final target = _waypoints[_currentWaypointIndex];
    final direction = target - position;
    final distance = direction.length;

    final effectiveSpeed = _getEffectiveSpeed();

    // distance가 0이거나 매우 작으면 바로 다음 waypoint로 이동 (NaN 방지)
    if (distance < 0.5) {
      position = target.clone();
      _currentWaypointIndex++;
      return;
    }

    if (distance < effectiveSpeed * dt) {
      position = target.clone();
      _currentWaypointIndex++;
    } else {
      direction.normalize();
      position += direction * effectiveSpeed * dt;
    }
  }

  /// 직선 이동 (비행 유닛) — 경로 무시, 마지막 웨이포인트로 직진
  void _moveFlyingStraight(double dt) {
    if (_waypoints.isEmpty) {
      _reachGateway();
      return;
    }

    final destination = _waypoints.last;
    final direction = destination - position;
    final distance = direction.length;
    final effectiveSpeed = _getEffectiveSpeed();

    if (distance < effectiveSpeed * dt) {
      _reachGateway();
    } else {
      direction.normalize();
      position += direction * effectiveSpeed * dt;
    }
  }

  // 감속 디버프 (만신전, 지신 제단 분기용)
  double _speedDebuff = 0;  // 0~1 감속 비율
  double _speedDebuffTimer = 0;

  /// 이동 속도 감속 디버프 적용
  void applySpeedDebuff(double ratio, double duration) {
    // 더 강한 감속만 덮어씀
    if (ratio > _speedDebuff) {
      _speedDebuff = ratio.clamp(0, 0.8);
      _speedDebuffTimer = duration;
    }
  }

  /// 실효 이동 속도 계산
  double _getEffectiveSpeed() {
    double speed = _speed;
    if (_isBerserk) {
      speed *= GameConstants.berserkSpeedMultiplier;
    }
    // 비행 유닛: 경로를 따라가되 30% 더 빠르게
    if (data.isFlying) {
      speed *= 1.3;
    }
    // 감속 디버프 적용
    if (_speedDebuff > 0) {
      speed *= (1.0 - _speedDebuff);
    }
    // 최소 속도 보장 (디버프로 인한 완전 정지 방지)
    return speed.clamp(5.0, double.infinity);
  }

  /// 게이트웨이 도달 (적이 끝까지 감)
  void _reachGateway() {
    _reachedGateway = true;
    _state = EnemyState.dying;
    game.onEnemyReachedGateway(1);
    game.waveManager.onEnemyDied();
    removeFromParent();
  }

  /// 방패 상태 업데이트
  void _updateShield() {
    if (data.shieldHpRatio <= 0) return;

    final hpRatio = _hp / _maxHp;
    if (hpRatio <= data.shieldHpRatio && !_shieldActive) {
      _shieldActive = true;
      // 방패 활성화 시각 표시 (파란 테두리)
      add(RectangleComponent(
        size: Vector2(size.x + 2, size.y + 2),
        position: Vector2(-1, -1),
        paint: Paint()
          ..color = const Color(0xFF4488FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      ));
    }
  }


  /// HP 바 업데이트
  void _updateHpBar() {
    final hpRatio = (_hp / _maxHp).clamp(0.0, 1.0);
    _hpBar.size = Vector2(size.x * hpRatio, 4);
    _hpBar.paint.color = hpRatio > 0.5
        ? const Color(0xFF44FF44)
        : hpRatio > 0.25
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF0000);
  }

  /// 영웅에 의해 은신 해제
  void reveal() {
    _isRevealed = true;
    if (data.isStealth) {
      _bodyPaint.color = _getColorForArmor(data.armorType);
    }
  }

  /// 데미지 받기
  /// [ignoreShield] — true이면 방패 데미지 감소를 무시하고 직접 HP에 적용 (저승사자 등)
  void takeDamage(double damage, DamageType damageType, {bool ignoreShield = false}) {
    if (_state == EnemyState.dying) return;

    // 물리 면역 체크 (그슨대 등 — abilities에 'Phys Immune' 포함)
    if (damageType == DamageType.physical &&
        data.abilities.any((a) => a.name == 'Phys Immune')) {
      return; // 물리 공격 무효
    }

    // 속성 상성 계산
    var finalDamage = DamageCalculator.calculate(
      baseDamage: damage,
      damageType: damageType,
      armorType: data.armorType,
      isNight: game.dayNightSystem.isNight,
      isFlying: data.isFlying,
    );

    // 방패 활성 시 데미지 감소 (ignoreShield면 방패 무시)
    if (_shieldActive && !ignoreShield) {
      finalDamage *= (1.0 - data.shieldDamageReduction);
    }

    // 회피 체크 (밤 보너스 포함)
    final totalEvasion = data.evasion +
        game.dayNightSystem.getEvasionBonus(data.armorType);
    if (_random.nextDouble() < totalEvasion) {
      return; // 회피 성공
    }

    _hp -= finalDamage;

    // 피격 플래시
    _hitFlashTimer = 0.08;

    // 보스 HP 동기화
    if (data.isBoss) {
      game.ref.read(gameStateProvider.notifier).updateBossHp(_hp);
    }

    if (_hp <= 0) {
      _die();
    }
  }

  /// 보스 특수 능력 발동
  void _executeBossAbility() {
    // 챕터 1: 두억시니 — 지진
    if (data.abilities.any((a) => a.name == 'Earthquake')) {
      final towers = game.cachedTowers;
      for (final tower in towers) {
        tower.silence(2.0);
      }
      game.shakeScreen(8.0, duration: 0.6);
      game.triggerRedFlash(duration: 0.5);
      return;
    }

    // 챕터 2: 산군 — 포효 & 창귀 소환
    if (data.abilities.any((a) => a.name == 'Roar')) {
      final towers = game.cachedTowers;
      for (final tower in towers) {
        tower.silence(3.0);
      }
      game.shakeScreen(5.0, duration: 0.4);
      game.triggerRedFlash(duration: 0.4);
      
      // 창귀 소환 (능력 목록에 있으면 발동)
      if (data.abilities.any((a) => a.name == 'Summon')) {
        final ability = data.abilities.firstWhere((a) => a.name == 'Summon');
        _spawnBossMinions(EnemyId.tigerSlave, ability.value.toInt());
      }
      return;
    }

    // 챕터 3: 대왕 달걀귀신 — 스킬 반사 & 흡수
    if (data.abilities.any((a) => a.name == 'Reflect')) {
      game.triggerRedFlash(duration: 0.3);

      // 반사 탄환: 가장 가까운 영웅에게 보스 공격력 50% 즉시 데미지
      if (game.activeHeroes.isNotEmpty) {
        BaseHero? nearest;
        double minDist = double.infinity;
        for (final hero in game.activeHeroes) {
          if (hero.isDead) continue;
          final dist = position.distanceTo(hero.position);
          if (dist < minDist) {
            minDist = dist;
            nearest = hero;
          }
        }
        if (nearest != null) {
          nearest.takeDamage(data.attack * 0.5);
          // 반사 이펙트
          if (ParticleEffect.canCreate) {
            parent?.add(ParticleEffect.magic(
              position: nearest.position.clone(),
              color: const Color(0xFFFF4488),
            ));
          }
        }
      }

      if (data.abilities.any((a) => a.name == 'Absorb')) {
        // 주변 병사 제거 (병영 방어 무력화)
        final soldiers = parent?.children.whereType<BarracksSoldier>().toList() ?? [];
        for (final soldier in soldiers) {
          final dist = position.distanceTo(soldier.position);
          if (dist <= 150) {
            soldier.removeFromParent();
          }
        }
      }
      return;
    }

    // 챕터 4: 폭군왕 — 칙령 & 궁녀 소환
    if (data.abilities.any((a) => a.name == 'Decree')) {
      final ability = data.abilities.firstWhere((a) => a.name == 'Decree');
      final towers = List<BaseTower>.from(game.cachedTowers)..shuffle();
      // 랜덤 타워 3개 (또는 value만큼) 침묵
      final count = ability.value.toInt().clamp(0, towers.length);
      for (int i = 0; i < count; i++) {
        towers[i].silence(ability.duration);
      }
      game.triggerRedFlash(duration: 0.8);

      if (data.abilities.any((a) => a.name == 'Summon')) {
        _spawnBossMinions(EnemyId.courtAssassin, 4);
      }
      return;
    }

    // 챕터 5: 귀문관 수문장 — 귀문개방 & 저승의 선고
    if (data.abilities.any((a) => a.name == 'Ghost Gate')) {
      // 랜덤 적 소환 (창귀, 아귀, 자객 중 랜덤)
      final pool = [EnemyId.hungryGhost, EnemyId.tigerSlave, EnemyId.courtAssassin];
      final targetId = pool[_random.nextInt(pool.length)];
      _spawnBossMinions(targetId, 3);
      game.shakeScreen(5.0, duration: 0.5);
    }

    if (data.abilities.any((a) => a.name == 'Judgment')) {
      // 가장 비싼(강한) 타워 1개 파괴 (또는 장시간 무력화)
      final towers = List<BaseTower>.from(game.cachedTowers);
      if (towers.isNotEmpty) {
        towers.sort((a, b) => b.totalInvestedCost.compareTo(a.totalInvestedCost));
        final target = towers.first;
        target.silence(15.0); // 15초간 정지

        // 파괴 이펙트: 빨간 폭발 + 연기
        if (ParticleEffect.canCreate) {
          parent?.add(ParticleEffect.explosion(
            position: target.position.clone(),
            radius: 60,
          ));
          parent?.add(ParticleEffect.death(
            position: target.position.clone(),
            color: const Color(0xFFFF1744),
          ));
        }

        game.triggerRedFlash(duration: 1.0);
      }
    }
  }

  /// 보스 주위로 졸개 소환
  void _spawnBossMinions(EnemyId minionId, int count) {
    final spawnData = _getEnemyDataById(minionId);
    if (spawnData == null) return;

    for (int i = 0; i < count; i++) {
      final offset = Vector2(
        (_random.nextDouble() - 0.5) * 60,
        (_random.nextDouble() - 0.5) * 60,
      );

      final miniWaypoints = _waypoints.sublist(
        (_currentWaypointIndex - 1).clamp(0, _waypoints.length - 1),
      );

      final minion = BaseEnemy(
        data: spawnData,
        waypoints: miniWaypoints,
      );
      minion.position = position + offset;
      parent?.add(minion);
    }
  }

  /// 사망 처리
  void _die() {
    _state = EnemyState.dying;

    // 보스 사망 시 GameState 해제
    if (data.isBoss) {
      game.ref.read(gameStateProvider.notifier).clearBoss();
    }

    // 사망 파티클 이펙트 (통합 시스템)
    if (ParticleEffect.canCreate) {
      final color = _getColorForArmor(data.armorType);
      parent?.add(ParticleEffect.death(
        position: position.clone(),
        color: color,
      ));
    }

    // 신명 보상
    game.onEnemyKilled(data.sinmyeongReward, isBoss: data.isBoss, enemyId: data.id);

    // 원한의 순환: 원혼 스폰
    if (_random.nextDouble() < GameConstants.spiritSpawnChance) {
      final spirit = SpiritComponent(position: position.clone());
      parent?.add(spirit);
    }

    // 2페이즈 스폰 (분열: 무지기 → 아귀 3마리 등)
    if (data.deathSpawnId != null && data.deathSpawnCount > 0) {
      _spawnDeathMinions();
    }

    game.waveManager.onEnemyDied();
    removeFromParent();
  }

  /// 사망 시 하위 적 스폰 (분열)
  void _spawnDeathMinions() {
    final spawnData = _getEnemyDataById(data.deathSpawnId!);
    if (spawnData == null) return;

    for (int i = 0; i < data.deathSpawnCount; i++) {
      final offset = Vector2(
        (_random.nextDouble() - 0.5) * 30,
        (_random.nextDouble() - 0.5) * 30,
      );

      final miniWaypoints = _waypoints.sublist(
        (_currentWaypointIndex - 1).clamp(0, _waypoints.length - 1),
      );

      final minion = BaseEnemy(
        data: spawnData,
        waypoints: miniWaypoints,
      );
      minion.position = position + offset;

      parent?.add(minion);
    }
  }

  /// 광폭화 (원혼 흡수)
  void buffBerserk() {
    _isBerserk = true;
    _state = EnemyState.berserk;
    _bodyPaint.color = const Color(0xFFFF4500); // 주황빨강
    _hp += _maxHp * 0.3; // HP 30% 회복
    if (_hp > _maxHp) _hp = _maxHp;
  }

  /// 기절
  void stun(double duration) {
    // 보스는 기절 저항: 기절 시간 80% 감소
    final effectiveDuration = data.isBoss ? duration * 0.2 : duration;
    if (effectiveDuration < 0.1) return; // 너무 짧으면 무시
    _state = EnemyState.stunned;
    _stunTimer = effectiveDuration;
  }

  // DoT (화상, 독 등) — 화차 분기용
  double _dotDamage = 0;
  double _dotTimer = 0;

  /// DoT 적용 (持continuation — tick damage)
  void applyDot(double damagePerSecond, double duration, DamageType type) {
    // 더 강한 DoT만 덮어씀
    if (damagePerSecond > _dotDamage) {
      _dotDamage = damagePerSecond;
      _dotTimer = duration;
    }
  }

  /// DoT 업데이트 (update에서 호출)
  void _updateDot(double dt) {
    if (_dotTimer <= 0 || _dotDamage <= 0) return;
    _dotTimer -= dt;
    // 초당 데미지 적용
    _hp -= _dotDamage * dt;
    if (_hp <= 0) {
      _die();
    }
    if (_dotTimer <= 0) {
      _dotDamage = 0;
      _dotTimer = 0;
    }
  }

  /// ID로 적 데이터 검색
  EnemyData? _getEnemyDataById(EnemyId id) {
    return GameDataLoader.getEnemies()[id];
  }

  // ── 호버 툴팁 ──

  @override
  void onHoverEnter() {
    game.onComponentHover?.call(_buildTooltipInfo());
  }

  @override
  void onHoverExit() {
    game.onComponentHoverExit?.call();
  }

  Map<String, dynamic> _buildTooltipInfo() {
    final abilities = <String>[];
    if (data.isFlying) abilities.add('Flying');
    if (data.isStealth) abilities.add('Stealth');
    if (data.isBoss) abilities.add('Boss');
    if (data.shieldHpRatio > 0) abilities.add('Shield');
    if (data.debuffSlowAura > 0) abilities.add('Slow Aura');

    return {
      'type': 'enemy',
      'name': data.name,
      'hp': '${_hp.toStringAsFixed(0)} / ${_maxHp.toStringAsFixed(0)}',
      'speed': _speed.toStringAsFixed(0),
      'reward': data.sinmyeongReward.toString(),
      'description': data.description,
      'abilities': abilities.join(', '),
      'isBerserk': _isBerserk,
      'position': Vector2(position.x, position.y),
    };
  }
}

// _DeathParticle 제거 — ParticleEffect.death()로 통합됨
