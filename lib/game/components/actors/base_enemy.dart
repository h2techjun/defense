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
import '../items/spirit_component.dart';
import '../towers/base_tower.dart';
import '../towers/barracks_soldier.dart';

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

  // 디버프 오라 주기 제한
  double _debuffAuraTimer = 0;

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
    size: Vector2(data.isBoss ? 48 : 28, data.isBoss ? 48 : 28),
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
      enemyId: data.id,
      armorType: data.armorType,
      isBoss: data.isBoss,
      isFlying: data.isFlying,
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

  /// EnemyId별 고유 비주얼 빌드
  void _buildEnemyVisual(PositionComponent parent, Color color) {
    final s = size.x;
    final halfS = s / 2;

    switch (data.id) {
      case EnemyId.hungryGhost:   // 허기귀신 — 둥근 몸체 + 입
        parent.add(CircleComponent(
          radius: s * 0.4,
          position: Vector2(halfS, halfS),
          anchor: Anchor.center,
          paint: _bodyPaint,
        ));
        // 입 (반원 대용 — 작은 원)
        parent.add(CircleComponent(
          radius: s * 0.12,
          position: Vector2(halfS, s * 0.65),
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xCC000000),
        ));
        break;

      case EnemyId.strawShoeSpirit:     // 짚신귀 — 빠른 삼각형
        parent.add(PolygonComponent(
          [
            Vector2(halfS, s * 0.1),
            Vector2(s * 0.15, s * 0.85),
            Vector2(s * 0.85, s * 0.85),
          ],
          paint: _bodyPaint,
        ));
        break;

      case EnemyId.maidenGhost:      // 손각시 — 치마 형태
        parent.add(PolygonComponent(
          [
            Vector2(halfS, s * 0.05),
            Vector2(s * 0.05, s * 0.95),
            Vector2(s * 0.95, s * 0.95),
          ],
          paint: _bodyPaint,
        ));
        // 오라 링
        parent.add(CircleComponent(
          radius: s * 0.45,
          position: Vector2(halfS, halfS),
          anchor: Anchor.center,
          paint: Paint()
            ..color = Color.fromARGB(40, color.red, color.green, color.blue)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        ));
        break;

      case EnemyId.eggGhost: // 달걀귀신 — 타원형
        parent.add(CircleComponent(
          radius: s * 0.35,
          position: Vector2(halfS, halfS * 0.9),
          anchor: Anchor.center,
          paint: _bodyPaint,
        ));
        // 눈 (두 점)
        parent.add(CircleComponent(
          radius: 2,
          position: Vector2(s * 0.4, s * 0.38),
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF000000),
        ));
        parent.add(CircleComponent(
          radius: 2,
          position: Vector2(s * 0.6, s * 0.38),
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF000000),
        ));
        break;

      case EnemyId.burdenedLaborer:    // 짐꾼귀 — 큰 사각형 + 짐 표시
        parent.add(RectangleComponent(
          size: Vector2(s * 0.8, s * 0.7),
          position: Vector2(s * 0.1, s * 0.25),
          paint: _bodyPaint,
        ));
        // 짐 (작은 사각형 위에)
        parent.add(RectangleComponent(
          size: Vector2(s * 0.5, s * 0.3),
          position: Vector2(s * 0.25, s * 0.02),
          paint: Paint()..color = Color.fromARGB(200, (color.red * 0.6).toInt(), (color.green * 0.6).toInt(), (color.blue * 0.6).toInt()),
        ));
        break;

      case EnemyId.bossOgreLord:     // 두억시니 — 큰 원 + 뿔
        parent.add(CircleComponent(
          radius: s * 0.38,
          position: Vector2(halfS, halfS * 1.1),
          anchor: Anchor.center,
          paint: _bodyPaint,
        ));
        // 왼쪽 뿔
        parent.add(PolygonComponent(
          [
            Vector2(s * 0.3, s * 0.25),
            Vector2(s * 0.2, s * 0.0),
            Vector2(s * 0.35, s * 0.2),
          ],
          paint: Paint()..color = const Color(0xFFFF6600),
        ));
        // 오른쪽 뿔
        parent.add(PolygonComponent(
          [
            Vector2(s * 0.7, s * 0.25),
            Vector2(s * 0.8, s * 0.0),
            Vector2(s * 0.65, s * 0.2),
          ],
          paint: Paint()..color = const Color(0xFFFF6600),
        ));
        break;

      default:
        // 기타 적 — 기본 원형
        parent.add(CircleComponent(
          radius: s * 0.38,
          position: Vector2(halfS, halfS),
          anchor: Anchor.center,
          paint: _bodyPaint,
        ));
        break;
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

  // ── 디버깅용 타이머 ──
  double _debugTimer = 0;
  static int _debugSlotCounter = 0;
  late final int _debugSlot;
  bool _debugInitialized = false;

  @override
  void update(double dt) {
    super.update(dt);

    // 디버깅: 최초 3개 적만 3초 주기로 상태 보고
    if (!_debugInitialized) {
      _debugSlot = _debugSlotCounter++;
      _debugInitialized = true;
    }
    if (_debugSlot < 3 && !isDead) {
      _debugTimer += dt;
      if (_debugTimer >= 3.0) {
        _debugTimer = 0;
        debugPrint('[ENEMY#$_debugSlot] id=${data.id.name} '
          'state=$_state pos=(${position.x.toInt()},${position.y.toInt()}) '
          'wpIdx=$_currentWaypointIndex/${_waypoints.length} '
          'speed=${_getEffectiveSpeed().toStringAsFixed(1)} '
          'dt=${dt.toStringAsFixed(4)} '
          'blocked=${_blockedBy != null} '
          'berserk=$_isBerserk stun=${_stunTimer.toStringAsFixed(1)} '
          'mounted=$isMounted');
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
            _blockedBy!.takeDamage(data.attack);
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

    // 디버프 오라 적용 (0.5초 주기 — 매 프레임 타워 순회 방지)
    if (data.debuffSlowAura > 0) {
      _debuffAuraTimer += dt;
      if (_debuffAuraTimer >= 0.5) {
        _debuffAuraTimer = 0;
        _applyDebuffAura();
      }
    }

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

  /// 디버프 오라: 범위 내 타워 공격속도 감소
  void _applyDebuffAura() {
    final towers = game.cachedTowers;
    for (final tower in towers) {
      final dist = position.distanceTo(tower.position);
      if (dist <= data.debuffRange) {
        tower.applySlowDebuff(data.debuffSlowAura);
      }
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
  void takeDamage(double damage, DamageType damageType) {
    if (_state == EnemyState.dying) return;

    // 물리 면역 체크 (그슨대 등 — abilities에 '물리 면역' 포함)
    if (damageType == DamageType.physical &&
        data.abilities.any((a) => a.name == '물리 면역')) {
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

    // 방패 활성 시 데미지 감소
    if (_shieldActive) {
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
    // 두억시니: 지진 — 모든 타워 2초 침묵 + 화면 흔들림
    if (data.abilities.any((a) => a.name == '지진')) {
      final towers = game.cachedTowers;
      for (final tower in towers) {
        tower.silence(2.0);
      }
      // 지진 시각 이펙트 — 강한 화면 흔들림 + 빨간 플래시
      game.shakeScreen(8.0, duration: 0.6);
      game.triggerRedFlash(duration: 0.5);
      return;
    }

    // 산군: 포효 — 모든 타워 사거리 감소 (silence로 대체)
    if (data.abilities.any((a) => a.name == '포효')) {
      final towers = game.cachedTowers;
      for (final tower in towers) {
        tower.silence(3.0);
      }
      // 포효 시각 이펙트 — 중간 화면 흔들림 + 빨간 플래시
      game.shakeScreen(5.0, duration: 0.4);
      game.triggerRedFlash(duration: 0.4);
      return;
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
    game.onEnemyKilled(data.sinmyeongReward, isBoss: data.isBoss);

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
  DamageType _dotDamageType = DamageType.physical;

  /// DoT 적용 (持continuation — tick damage)
  void applyDot(double damagePerSecond, double duration, DamageType type) {
    // 더 강한 DoT만 덮어씀
    if (damagePerSecond > _dotDamage) {
      _dotDamage = damagePerSecond;
      _dotTimer = duration;
      _dotDamageType = type;
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
    if (data.isFlying) abilities.add('비행');
    if (data.isStealth) abilities.add('은신');
    if (data.isBoss) abilities.add('보스');
    if (data.shieldHpRatio > 0) abilities.add('방패');
    if (data.debuffSlowAura > 0) abilities.add('감속 오라');

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
