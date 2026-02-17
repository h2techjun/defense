// 해원의 문 - 적 (BaseEnemy) 컴포넌트
// FSM 상태머신, 경로 이동, 사망 시 원혼 스폰 포함

import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../../common/enums.dart';
import '../../../common/constants.dart';
import '../../../data/models/enemy_data.dart';
import '../../../data/game_data_loader.dart';
import '../../defense_game.dart';
import '../items/spirit_component.dart';

/// 적 기본 컴포넌트
class BaseEnemy extends PositionComponent with HasGameReference<DefenseGame>, CollisionCallbacks {
  final EnemyData data;

  // 상태
  EnemyState _state = EnemyState.walking;
  double _hp = 0;
  double _maxHp = 0;
  double _speed = 0;
  bool _isBerserk = false;

  // 경로 이동
  List<Vector2> _waypoints = [];
  int _currentWaypointIndex = 0;

  // 시각 표현
  late RectangleComponent _body;
  late RectangleComponent _hpBar;
  late RectangleComponent _hpBarBg;
  static final Random _random = Random();

  EnemyState get state => _state;
  double get hp => _hp;
  double get maxHp => _maxHp;
  bool get isBerserk => _isBerserk;
  bool get isDead => _hp <= 0;

  BaseEnemy({
    required this.data,
    required List<Vector2> waypoints,
  }) : super(
    size: Vector2(data.isBoss ? 48 : 28, data.isBoss ? 48 : 28),
    anchor: Anchor.center,
  ) {
    _waypoints = waypoints;
    _hp = data.hp;
    _maxHp = data.hp;
    _speed = data.speed;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 시작 위치
    if (_waypoints.isNotEmpty) {
      position = _waypoints.first.clone();
      _currentWaypointIndex = 1;
    }

    // 본체 색상 (속성별)
    final bodyColor = _getColorForArmor(data.armorType);
    _body = RectangleComponent(
      size: size,
      paint: Paint()..color = bodyColor,
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

    // 보스 시각 표시
    if (data.isBoss) {
      add(RectangleComponent(
        size: Vector2(size.x + 4, size.y + 4),
        position: Vector2(-2, -2),
        paint: Paint()
          ..color = const Color(0xFFFF0000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ));
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

  @override
  void update(double dt) {
    super.update(dt);

    switch (_state) {
      case EnemyState.walking:
      case EnemyState.berserk:
        _moveAlongPath(dt);
        break;
      case EnemyState.stunned:
        // 기절 상태 - 이동 없음
        break;
      case EnemyState.dying:
        // 사망 애니메이션
        break;
      case EnemyState.idle:
        break;
    }

    // HP 바 업데이트
    final hpRatio = (_hp / _maxHp).clamp(0.0, 1.0);
    _hpBar.size = Vector2(size.x * hpRatio, 4);
    _hpBar.paint.color = hpRatio > 0.5
        ? const Color(0xFF44FF44)
        : hpRatio > 0.25
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF0000);
  }

  /// 경로를 따라 이동
  void _moveAlongPath(double dt) {
    if (_currentWaypointIndex >= _waypoints.length) {
      _reachGateway();
      return;
    }

    final target = _waypoints[_currentWaypointIndex];
    final direction = target - position;
    final distance = direction.length;

    final effectiveSpeed = _isBerserk
        ? _speed * GameConstants.berserkSpeedMultiplier
        : _speed;

    if (distance < effectiveSpeed * dt) {
      position = target.clone();
      _currentWaypointIndex++;
    } else {
      direction.normalize();
      position += direction * effectiveSpeed * dt;
    }
  }

  /// 게이트웨이 도달 (적이 끝까지 감)
  void _reachGateway() {
    game.onEnemyReachedGateway(1);
    removeFromParent();
  }

  /// 데미지 받기
  void takeDamage(double damage, DamageType damageType) {
    if (_state == EnemyState.dying) return;

    // 속성 상성 계산
    final finalDamage = DamageCalculator.calculate(
      baseDamage: damage,
      damageType: damageType,
      armorType: data.armorType,
      isNight: game.dayNightSystem.isNight,
    );

    // 회피 체크 (밤 보너스 포함)
    final totalEvasion = data.evasion +
        game.dayNightSystem.getEvasionBonus(data.armorType);
    if (_random.nextDouble() < totalEvasion) {
      // 회피 성공 - 이펙트 표시 가능
      return;
    }

    _hp -= finalDamage;

    if (_hp <= 0) {
      _die();
    }
  }

  /// 사망 처리
  void _die() {
    _state = EnemyState.dying;

    // 신명 보상
    game.onEnemyKilled(data.sinmyeongReward);

    // 원한의 순환: 원혼 스폰
    if (_random.nextDouble() < GameConstants.spiritSpawnChance) {
      final spirit = SpiritComponent(position: position.clone());
      parent?.add(spirit);
    }

    // 2페이즈 스폰 (ex: 무지기 → 아귀 3마리)
    if (data.deathSpawnId != null && data.deathSpawnCount > 0) {
      _spawnDeathMinions();
    }

    removeFromParent();
  }

  /// 사망 시 하위 적 스폰
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
    _body.paint.color = const Color(0xFFFF4500); // 주황빨강
    _hp += _maxHp * 0.3; // HP 30% 회복
    if (_hp > _maxHp) _hp = _maxHp;
  }

  /// 기절
  void stun(double duration) {
    _state = EnemyState.stunned;
    Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
      if (!isDead) {
        _state = _isBerserk ? EnemyState.berserk : EnemyState.walking;
      }
    });
  }

  /// ID로 적 데이터 검색
  EnemyData? _getEnemyDataById(EnemyId id) {
    return GameDataLoader.enemies[id];
  }
}
