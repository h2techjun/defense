// 해원의 문 - 타워 (BaseTower) 컴포넌트

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/scheduler.dart';

import '../../../common/enums.dart';
import '../renderers/tower_renderer.dart';
import '../../../common/constants.dart';
import '../../../data/models/tower_data.dart';
import '../../../data/game_data_loader.dart';
import '../../../state/game_state.dart';
import '../../../state/tower_loadout_provider.dart';
import '../../defense_game.dart';
import '../actors/base_enemy.dart';

import 'projectile.dart';
import 'barracks_soldier.dart';
import 'rally_flag_component.dart';
import '../effects/particle_effect.dart';
import '../../../audio/sound_manager.dart';

/// 타워 기본 컴포넌트
class BaseTower extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasGameReference<DefenseGame> {
  static final math.Random _random = math.Random();
  final TowerData data;
  int upgradeLevel = 0;
  TowerBranch? selectedBranch;

  /// 외부 레벨 (로비에서 XP로 성장, 기초 스탯 보너스)
  final int externalLevel;

  // 전투 변수
  double _fireTimer = 0;
  BaseEnemy? _currentTarget;
  bool _isSilenced = false;
  double _silenceTimer = 0;
  bool _rangeVisible = false;

  // 적 디버프 오라
  double _slowDebuff = 0; // 0~1, 매 프레임 리셋

  // 런타임 스탯
  /// 분기 데이터 캐시
  TowerBranchData? get branchData =>
      selectedBranch != null ? GameDataLoader.getBranches()[selectedBranch!] : null;

  double get currentDamage {
    double base;
    // 분기 선택 시 분기 데이터 우선
    if (selectedBranch != null && branchData != null) {
      base = branchData!.damage;
    } else if (upgradeLevel > 0 && upgradeLevel <= data.upgrades.length) {
      base = data.upgrades[upgradeLevel - 1].damage;
    } else {
      base = data.baseDamage;
    }
    // 외부 레벨 보너스 적용
    return base * TowerLoadoutNotifier.damageMultiplier(externalLevel);
  }

  double get currentRange {
    double base;
    if (selectedBranch != null && branchData != null) {
      base = branchData!.range;
    } else if (upgradeLevel > 0 && upgradeLevel <= data.upgrades.length) {
      base = data.upgrades[upgradeLevel - 1].range;
    } else {
      base = data.baseRange;
    }
    // 외부 레벨 보너스 + 밤 패널티
    return base * TowerLoadoutNotifier.rangeMultiplier(externalLevel)
        * game.dayNightSystem.getTowerRangeMultiplier();
  }

  double get currentFireRate {
    double rate;
    if (selectedBranch != null && branchData != null) {
      rate = branchData!.fireRate;
    } else if (upgradeLevel > 0 && upgradeLevel <= data.upgrades.length) {
      rate = data.upgrades[upgradeLevel - 1].fireRate;
    } else {
      rate = data.baseFireRate;
    }
    // 한(恨) 게이지 단계적 패널티
    final gameState = game.ref.read(gameStateProvider);
    final wailingRatio = gameState.wailing / GameConstants.maxWailing;
    if (wailingRatio >= 1.0) {
      rate *= 0.60;
    } else if (wailingRatio >= 0.8) {
      rate *= 0.70;
    } else if (wailingRatio >= 0.5) {
      rate *= 0.85;
    }
    // 적 디버프 오라 (공속 감소)
    if (_slowDebuff > 0) {
      rate *= (1.0 - _slowDebuff);
    }
    // 솟대 버프 (공속 증가)
    if (_sotdaeBuffed) {
      rate *= GameConstants.sotdaeAttackSpeedBuff;
    }
    return rate;
  }

  late TowerRenderer _body;
  late CircleComponent _rangeIndicator;
  late CircleComponent _rangeFill;
  double _recoilTimer = 0; // 공격 반동 애니메이션
  bool _sotdaeBuffed = false; // 솟대 버프 상태 (forward declare)
  CircleComponent? _wardAura; // 솟대 수호결계 오라
  double _wardPulseTimer = 0; // 오라 맥동 타이머

  // 병영 전용 변수
  final List<BarracksSoldier> _soldiers = [];
  static const int _maxSoldiers = 3;
  double _soldierRespawnTimer = 0;
  static const double _soldierRespawnDelay = 8.0; // 병사 부활 대기 시간
  RallyFlagComponent? _rallyFlag; // 병사 배치 깃발

  BaseTower({
    required this.data,
    required Vector2 position,
    this.externalLevel = 1,
  }) : super(
    // 타일 크기보다 약간 작게
    size: Vector2.all(GameConstants.tileSize * 0.8),
    position: position,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final color = _getColorForType(data.type);

    // 타워 본체 — 스프라이트 이미지 기반 렌더링 (폴백: Canvas)
    _body = TowerRenderer(
      type: data.type,
      upgradeLevel: upgradeLevel,
      branch: selectedBranch,
      size: size.clone(),
    );
    _body.anchor = Anchor.center;
    _body.position = size / 2;
    add(_body);

    // 업그레이드 글로우 링
    if (upgradeLevel > 0) {
      _addUpgradeGlow(color);
    }

    // 범위 인디케이터 (병영은 병사 작전 범위, 나머지는 사거리)
    final displayRange = data.type == TowerType.barracks
        ? _soldierOperationRange
        : currentRange;
    // 반투명 채우기 원 (선택 시에만 보임)
    final rangeColor = _getRangeColorForType(data.type);
    _rangeFill = CircleComponent(
      radius: displayRange,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = rangeColor.withAlpha(0)
        ..style = PaintingStyle.fill,
    );
    add(_rangeFill);
    // 테두리 원 (기본: 얇은 반투명 선으로 항상 표시)
    _rangeIndicator = CircleComponent(
      radius: displayRange,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = rangeColor.withAlpha(0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    add(_rangeIndicator);

    // 히트박스 (터치/클릭 감지용)
    add(RectangleHitbox());

    // 병영 타워: 병사 소환
    if (data.type == TowerType.barracks) {
      _spawnSoldiers();
    }

    // 솟대 타워: 수호결계 오라
    if (data.type == TowerType.sotdae) {
      _initWardAura();
    }
  }

  /// 타워 타입별 고유 비주얼 빌드
  void _buildTowerVisual(PositionComponent parent, TowerType type, Color color) {
    final s = size.x;
    final halfS = s / 2;

    switch (type) {
      case TowerType.archer:
        // 궁수탑: 삼각형 지붕 + 세로 몸체 + 활 선
        // 몸체 (아래쪽 사각형)
        parent.add(RectangleComponent(
          size: Vector2(s * 0.5, s * 0.55),
          position: Vector2(s * 0.25, s * 0.45),
          paint: Paint()..color = color,
        ));
        // 지붕 (삼각형 — PolygonComponent)
        parent.add(PolygonComponent(
          [
            Vector2(halfS, 0),          // 꼭대기
            Vector2(s * 0.1, s * 0.5),  // 좌하
            Vector2(s * 0.9, s * 0.5),  // 우하
          ],
          paint: Paint()..color = Color.fromARGB(255, (color.red * 0.7).toInt(), (color.green * 0.7).toInt(), (color.blue * 0.7).toInt()),
        ));
        // 활 (원호 대용 — 작은 원)
        parent.add(CircleComponent(
          radius: s * 0.12,
          position: Vector2(halfS, halfS),
          anchor: Anchor.center,
          paint: Paint()
            ..color = const Color(0xCCFFD700)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        ));
        break;

      case TowerType.barracks:
        // 병영: 방패 모양 (둥근 사각형 + 십자)
        parent.add(RectangleComponent(
          size: Vector2(s * 0.7, s * 0.8),
          position: Vector2(s * 0.15, s * 0.1),
          paint: Paint()..color = color,
        ));
        // 십자 가로선
        parent.add(RectangleComponent(
          size: Vector2(s * 0.5, s * 0.08),
          position: Vector2(s * 0.25, s * 0.46),
          paint: Paint()..color = const Color(0xCCFFFFFF),
        ));
        // 십자 세로선
        parent.add(RectangleComponent(
          size: Vector2(s * 0.08, s * 0.5),
          position: Vector2(s * 0.46, s * 0.25),
          paint: Paint()..color = const Color(0xCCFFFFFF),
        ));
        break;

      case TowerType.shaman:
        // 무당: 보라 원형 오브 + 작은 위성
        parent.add(CircleComponent(
          radius: s * 0.3,
          position: Vector2(halfS, halfS),
          anchor: Anchor.center,
          paint: Paint()..color = color,
        ));
        // 내부 빛
        parent.add(CircleComponent(
          radius: s * 0.15,
          position: Vector2(halfS, halfS),
          anchor: Anchor.center,
          paint: Paint()..color = Color.fromARGB(180, 200, 150, 255),
        ));
        // 궤도 링
        parent.add(CircleComponent(
          radius: s * 0.38,
          position: Vector2(halfS, halfS),
          anchor: Anchor.center,
          paint: Paint()
            ..color = Color.fromARGB(80, color.red, color.green, color.blue)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        ));
        break;

      case TowerType.artillery:
        // 화포: 포탑(사각형 베이스) + 포신(직사각형)
        // 베이스
        parent.add(RectangleComponent(
          size: Vector2(s * 0.7, s * 0.5),
          position: Vector2(s * 0.15, s * 0.4),
          paint: Paint()..color = color,
        ));
        // 포신 (위쪽 돌출)
        parent.add(RectangleComponent(
          size: Vector2(s * 0.15, s * 0.5),
          position: Vector2(s * 0.42, s * 0.05),
          paint: Paint()..color = Color.fromARGB(255, (color.red * 0.8).toInt(), (color.green * 0.8).toInt(), (color.blue * 0.8).toInt()),
        ));
        // 포구 (원형)
        parent.add(CircleComponent(
          radius: s * 0.1,
          position: Vector2(halfS, s * 0.05),
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFFFF4444),
        ));
        break;

      case TowerType.sotdae:
        // 솟대: 세로 기둥 + 새 모양(삼각형) + 빛 원
        // 기둥
        parent.add(RectangleComponent(
          size: Vector2(s * 0.12, s * 0.7),
          position: Vector2(s * 0.44, s * 0.3),
          paint: Paint()..color = Color.fromARGB(255, 139, 101, 8),
        ));
        // 새 (삼각형)
        parent.add(PolygonComponent(
          [
            Vector2(halfS, s * 0.05),   // 머리
            Vector2(s * 0.2, s * 0.3),  // 좌날개
            Vector2(s * 0.8, s * 0.3),  // 우날개
          ],
          paint: Paint()..color = color,
        ));
        // 발광 원
        parent.add(CircleComponent(
          radius: s * 0.2,
          position: Vector2(halfS, s * 0.18),
          anchor: Anchor.center,
          paint: Paint()..color = Color.fromARGB(60, 255, 215, 0),
        ));
        break;
    }
  }

  /// 업그레이드 글로우 추가
  void _addUpgradeGlow(Color color) {
    final glowAlpha = (40 + upgradeLevel * 20).clamp(0, 120);
    add(CircleComponent(
      radius: size.x * 0.55,
      position: size / 2,
      anchor: Anchor.center,
      priority: -1,
      paint: Paint()..color = Color.fromARGB(glowAlpha, color.red, color.green, color.blue),
    ));
  }

  /// 솟대 수호결계 오라 초기화
  void _initWardAura() {
    final wardRange = GameConstants.sotdaeWardRange;

    // 분기별 오라 색상 결정
    Color auraColor;
    final bd = branchData;
    if (bd != null && bd.branch == TowerBranch.phoenixTotem) {
      auraColor = const Color(0x22FFD700); // 수호신단 — 금색
    } else if (bd != null && bd.branch == TowerBranch.earthSpiritAltar) {
      auraColor = const Color(0x2288CC44); // 지신제단 — 녹색
    } else {
      auraColor = const Color(0x18FFD700); // 기본 — 연한 금색
    }

    _wardAura = CircleComponent(
      radius: wardRange,
      position: size / 2,
      anchor: Anchor.center,
      priority: -2,
      paint: Paint()
        ..color = auraColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    add(_wardAura!);

    // 내부 희미한 원형 채우기
    add(CircleComponent(
      radius: wardRange * 0.7,
      position: size / 2,
      anchor: Anchor.center,
      priority: -2,
      paint: Paint()..color = auraColor.withValues(alpha: 0.06),
    ));
  }

  /// 수호결계 오라 맥동 애니메이션 (호흡 효과)
  void _updateWardAuraPulse(double dt) {
    if (_wardAura == null) return;

    _wardPulseTimer += dt;
    // 2초 주기 호흡 맥동
    final pulse = (math.sin(_wardPulseTimer * math.pi) * 0.5 + 0.5);
    final baseAlpha = 0x18;
    final maxAlpha = 0x40;
    final alpha = (baseAlpha + (maxAlpha - baseAlpha) * pulse).toInt();

    // 분기별 색상
    final bd = branchData;
    if (bd != null && bd.branch == TowerBranch.phoenixTotem) {
      _wardAura!.paint.color = Color.fromARGB(alpha, 0xFF, 0xD7, 0x00);
    } else if (bd != null && bd.branch == TowerBranch.earthSpiritAltar) {
      _wardAura!.paint.color = Color.fromARGB(alpha, 0x88, 0xCC, 0x44);
    } else {
      _wardAura!.paint.color = Color.fromARGB(alpha, 0xFF, 0xD7, 0x00);
    }

    // 맥동에 따른 미세 크기 변화
    final baseRadius = GameConstants.sotdaeWardRange;
    _wardAura!.radius = baseRadius * (0.95 + 0.05 * pulse);
  }

  /// 타워 제거 시 (판매 등) 병영 병사 + 깃발도 함께 제거
  @override
  void onRemove() {
    // 병영 병사 모두 제거
    for (final soldier in _soldiers) {
      if (soldier.isMounted) {
        soldier.removeFromParent();
      }
    }
    _soldiers.clear();
    // 랠리 깃발 제거
    if (_rallyFlag != null && _rallyFlag!.isMounted) {
      _rallyFlag!.removeFromParent();
      _rallyFlag = null;
    }
    super.onRemove();
  }

  /// 타워 클릭 → 판매/업그레이드 다이얼로그
  @override
  void onTapDown(TapDownEvent event) {
    showRange();
    game.onTowerTapped(this);
  }

  /// 범위 강조 표시
  void showRange() {
    _rangeVisible = true;
    final color = _getRangeColorForType(data.type);
    _rangeFill.paint.color = color.withAlpha(25);
    _rangeIndicator.paint
      ..color = color.withAlpha(180)
      ..strokeWidth = 2.5;
  }

  /// 범위 강조 해제 (기본 얇은 원으로 복귀)
  void hideRange() {
    _rangeVisible = false;
    _rangeFill.paint.color = const Color(0x00000000);
    final color = _getRangeColorForType(data.type);
    _rangeIndicator.paint
      ..color = color.withAlpha(0)
      ..strokeWidth = 1.5;
  }

  @override
  void onHoverEnter() {
    game.onComponentHover?.call(_buildTooltipInfo());
  }

  @override
  void onHoverExit() {
    game.onComponentHoverExit?.call();
  }

  /// 툴팁용 정보 생성
  Map<String, dynamic> _buildTooltipInfo() {
    final currentUpgradeData = upgradeLevel > 0 && upgradeLevel <= data.upgrades.length
        ? data.upgrades[upgradeLevel - 1]
        : data.upgrades.isNotEmpty ? data.upgrades[0] : null;
    return {
      'type': 'tower',
      'name': currentUpgradeData?.name ?? data.type.name,
      'towerType': data.type,
      'level': upgradeLevel,
      'damage': currentDamage,
      'range': currentRange,
      'fireRate': currentFireRate,
      'description': data.description,
      'specialAbility': currentUpgradeData?.specialAbility,
      'position': Vector2(position.x, position.y),
    };
  }

  Color _getColorForType(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return const Color(0xFF228B22); // 녹색
      case TowerType.barracks:
        return const Color(0xFF4169E1); // 파란색
      case TowerType.shaman:
        return const Color(0xFF9400D3); // 보라색
      case TowerType.artillery:
        return const Color(0xFFB22222); // 진홍색
      case TowerType.sotdae:
        return const Color(0xFFFFD700); // 금색
    }
  }

  /// 분기별 고유 색상 — Tier 4 분기 시각적 차별화
  Color _getColorForBranch(TowerBranch branch) {
    switch (branch) {
      // 궁수
      case TowerBranch.rocketBattery:
        return const Color(0xFFFF6600); // 주황색 (폭발)
      case TowerBranch.spiritHunter:
        return const Color(0xFF00CCFF); // 청록색 (신궁)
      // 병영
      case TowerBranch.generalTotem:
        return const Color(0xFF4488FF); // 청색 (장승)
      case TowerBranch.goblinRing:
        return const Color(0xFFFF4444); // 붉은색 (도깨비)
      // 마법
      case TowerBranch.shamanTemple:
        return const Color(0xFFAA44FF); // 보라색 (만신전)
      case TowerBranch.grimReaperOffice:
        return const Color(0xFF220044); // 암흑색 (저승사자)
      // 화포
      case TowerBranch.fireDragon:
        return const Color(0xFFFF2200); // 화염색 (화차)
      case TowerBranch.heavenlyThunder:
        return const Color(0xFFFFFF00); // 노란색 (천볌뢰)
      // 솟대
      case TowerBranch.phoenixTotem:
        return const Color(0xFFFF8800); // 봉황 주황색
      case TowerBranch.earthSpiritAltar:
        return const Color(0xFF88CC44); // 대지 녹색
    }
  }

  // ── 솟대 전용 변수 (수호결계) ──
  double _wardTimer = 0;
  double _buffTimer = 0;
  double _debuffResistance = 0; // 현재 디버프 내성 (0~1)

  @override
  void update(double dt) {
    super.update(dt);

    // 매 프레임 디버프/버프 리셋 (매 프레임 다시 적용)
    _slowDebuff = 0;
    _sotdaeBuffed = false;
    _debuffResistance = 0;
    if (_isSilenced) {
      _silenceTimer -= dt;
      if (_silenceTimer <= 0) {
        _isSilenced = false;
      }
      return;
    }

    // 솟대는 공격 대신 수호결계+버프
    if (data.type == TowerType.sotdae) {
      _updateSotdae(dt);
      _rangeIndicator.radius = currentRange;
      _rangeFill.radius = currentRange;
      return;
    }

    // 병영은 투사체 대신 병사 관리
    if (data.type == TowerType.barracks) {
      _updateBarracks(dt);
      _rangeIndicator.radius = _soldierOperationRange;
      _rangeFill.radius = _soldierOperationRange;
      return;
    }

    // 타겟 갱신
    _updateTarget();

    // 발사 로직
    if (_currentTarget != null) {
      _fireTimer += dt;
      final interval = 1.0 / currentFireRate;
      if (_fireTimer >= interval) {
        _fireTimer = 0;
        _fire();
        _recoilTimer = 0.1; // 반동 시작
      }
    } else {
      _fireTimer = interval * 0.9;
    }

    _rangeIndicator.radius = currentRange;
    _rangeFill.radius = currentRange;

    // 공격 반동 애니메이션
    if (_recoilTimer > 0) {
      _recoilTimer -= dt;
      final recoilScale = 1.0 + (_recoilTimer / 0.1) * 0.15;
      _body.scale = Vector2.all(recoilScale);
    } else {
      _body.scale = Vector2.all(1.0);
    }
  }
  
  double get interval => 1.0 / currentFireRate;

  /// 범위 내 가장 진행도가 높은(위협적인) 적 탐색
  void _updateTarget() {
    // 매 프레임 범위 내 가장 진행도 높은 적(게이트웨이에 가장 가까운) 선택
    double maxProgress = -double.infinity;
    BaseEnemy? bestEnemy;

    final enemies = game.cachedAliveEnemies;

    for (final enemy in enemies) {
      if (enemy.isDead) continue;

      // 비행 면역: 병영은 비행 유닛 타겟 불가
      if (!DamageCalculator.canTarget(
        towerType: data.type,
        isFlying: enemy.data.isFlying,
      )) continue;

      // 은신: 타워는 은신 적 타겟 불가 (영웅만 감지)
      // 예외: 신궁 분기는 은신 감지 가능
      if (enemy.isStealth && !(branchData?.canDetectStealth ?? false)) continue;

      final dist = position.distanceTo(enemy.position);
      if (dist <= currentRange) {
        // 진행도가 높은 적 우선 (게이트웨이에 가장 가까운)
        final prog = enemy.progress;
        if (prog > maxProgress) {
          maxProgress = prog;
          bestEnemy = enemy;
        }
      }
    }
    
    _currentTarget = bestEnemy;
  }

  /// 투사체 발사
  void _fire() {
    if (_currentTarget == null) return;

    final bd = branchData;

    // 화포탑: 스플래시 데미지 (범위 내 모든 적에게)
    if (data.type == TowerType.artillery) {
      _fireArtillery();
      return;
    }

    // 서당(무당): 광역 마법 공격 (범위 내 모든 적에게 직접 데미지)
    if (data.type == TowerType.shaman) {
      _fireShaman();
      return;
    }

    // ── 분기별 특수 발사 ──

    // 신기전 분기: 스플래시 로켓
    if (selectedBranch == TowerBranch.rocketBattery && bd != null) {
      final projectile = Projectile(
        target: _currentTarget!,
        damage: currentDamage,
        damageType: data.damageType,
        speed: 300,
        startPosition: position.clone(),
        onHit: () {
          // 스플래시 데미지
          final enemies = game.cachedAliveEnemies;
          for (final enemy in enemies) {
            if (enemy.isDead || enemy == _currentTarget) continue;
            final dist = _currentTarget!.position.distanceTo(enemy.position);
            if (dist <= bd.splashRadius) {
              enemy.takeDamage(currentDamage * 0.6, data.damageType);
            }
          }
          if (ParticleEffect.canCreate) {
            game.world.add(ParticleEffect.explosion(
              position: _currentTarget!.position,
              radius: bd.splashRadius,
            ));
          }
        },
      );
      SoundManager.instance.playSfx(SfxType.towerArtillery);
      game.world.add(projectile);
      return;
    }

    // 저승사자 출장소: 즉사 판정
    if (selectedBranch == TowerBranch.grimReaperOffice && bd != null) {
      final target = _currentTarget!;
      final hpRatio = target.hp / target.maxHp;
      if (hpRatio <= bd.instantKillThreshold && !target.data.isBoss) {
        // 즉사!
        target.takeDamage(target.hp + 1, bd.overrideDamageType ?? DamageType.purification);
        SoundManager.instance.playSfx(SfxType.towerMagic);
        if (ParticleEffect.canCreate) {
          game.world.add(ParticleEffect.magic(
            position: target.position,
            color: const Color(0xFF4B0082),
          ));
        }
        return;
      }
    }

    // 만신전 분기: 광역 + 감속 오라
    if (selectedBranch == TowerBranch.shamanTemple && bd != null) {
      _fireShaman();
      // 추가: 범위 내 적 감속
      if (bd.slowAuraRatio > 0) {
        final enemies = game.cachedAliveEnemies;
        for (final enemy in enemies) {
          if (enemy.isDead) continue;
          final dist = position.distanceTo(enemy.position);
          if (dist <= currentRange) {
            enemy.applySpeedDebuff(bd.slowAuraRatio, 2.0);
          }
        }
      }
      return;
    }

    // 일반 타워 / 기타 분기: 단일 투사체
    final dmgType = bd?.overrideDamageType ?? data.damageType;
    final projectile = Projectile(
      target: _currentTarget!,
      damage: currentDamage,
      damageType: dmgType,
      speed: 400,
      startPosition: position.clone(),
    );

    // 타워 타입별 발사 SFX
    switch (data.type) {
      case TowerType.archer:
        SoundManager.instance.playSfx(SfxType.towerShoot);
        break;
      case TowerType.shaman:
        SoundManager.instance.playSfx(SfxType.towerMagic);
        break;
      default:
        SoundManager.instance.playSfx(SfxType.towerShoot);
    }

    game.world.add(projectile);
  }

  /// 화포탑 스플래시 발사
  void _fireArtillery() {
    if (_currentTarget == null) return;

    final bd = branchData;
    // 분기 선택 시 분기 스플래시 반경 우선, 없으면 기본값
    final splashRadius = bd != null && bd.splashRadius > 0
        ? bd.splashRadius
        : GameConstants.artillerySplashRadius;
    final splashRatio = GameConstants.artillerySplashDamageRatio;
    final centerDamage = currentDamage;
    final dmgType = bd?.overrideDamageType ?? data.damageType;

    // 중심 타겟에게 투사체 발사
    final projectile = Projectile(
      target: _currentTarget!,
      damage: centerDamage,
      damageType: dmgType,
      speed: 250,
      startPosition: position.clone(),
      onHit: () {
        // 착탄 시 스플래시 데미지
        final enemies = game.cachedAliveEnemies;
        for (final enemy in enemies) {
          if (enemy.isDead || enemy == _currentTarget) continue;
          final dist = _currentTarget!.position.distanceTo(enemy.position);
          if (dist <= splashRadius) {
            enemy.takeDamage(centerDamage * splashRatio, dmgType);
          }
        }
        // 화차 분기: DoT 화상
        if (bd != null && bd.dotDamage > 0) {
          for (final enemy in enemies) {
            if (enemy.isDead) continue;
            final dist = _currentTarget!.position.distanceTo(enemy.position);
            if (dist <= splashRadius) {
              enemy.applyDot(bd.dotDamage, bd.dotDuration, dmgType);
            }
          }
        }
        // 천벌뢰 분기: 스턴
        if (bd != null && bd.stunDuration > 0) {
          _currentTarget!.stun(bd.stunDuration);
          // 스플래시 범위 적도 스턴 (절반 지속)
          for (final enemy in enemies) {
            if (enemy.isDead || enemy == _currentTarget) continue;
            final dist = _currentTarget!.position.distanceTo(enemy.position);
            if (dist <= splashRadius) {
              enemy.stun(bd.stunDuration * 0.5);
            }
          }
        }
        // 폭발 파티클 이펙트
        if (ParticleEffect.canCreate) {
          game.world.add(ParticleEffect.explosion(
            position: _currentTarget!.position,
            radius: splashRadius,
          ));
        }
      },
    );

    // 분기별 공격 사운드
    if (bd != null && bd.stunDuration > 0) {
      SoundManager.instance.playSfx(SfxType.branchThunder);
    } else if (bd != null && bd.dotDamage > 0) {
      SoundManager.instance.playSfx(SfxType.branchFire);
    } else {
      SoundManager.instance.playSfx(SfxType.towerArtillery);
    }
    game.world.add(projectile);
  }

  /// 솟대 업데이트 (수호결계 + 버프 + 오라 맥동)
  void _updateSotdae(double dt) {
    // 수호결계 갱신 주기
    _wardTimer += dt;
    if (_wardTimer >= GameConstants.sotdaeWardInterval) {
      _wardTimer = 0;
      _applyGuardianWard();
    }

    // 1초마다 아군 버프 적용
    _buffTimer += dt;
    if (_buffTimer >= 1.0) {
      _buffTimer = 0;
      _applySotdaeBuff();
    }

    // 수호결계 오라 맥동 애니메이션
    _updateWardAuraPulse(dt);
  }

  /// 수호결계 — 범위 내 한(恨) 억제 + 디버프 내성
  void _applyGuardianWard() {
    final wardRange = GameConstants.sotdaeWardRange *
        (upgradeLevel >= 3 ? 1.3 : 1.0); // 3레벨 시 결계 범위 +30%

    // 레벨별 디버프 내성
    final resistLevel = upgradeLevel.clamp(0, GameConstants.sotdaeDebuffResist.length - 1);
    _debuffResistance = GameConstants.sotdaeDebuffResist[resistLevel];

    // 범위 내 아군 타워에 디버프 내성 적용
    final towers = game.cachedTowers;
    for (final tower in towers) {
      if (tower == this) continue;
      if (tower.data.type == TowerType.sotdae) continue;

      final dist = position.distanceTo(tower.position);
      if (dist <= wardRange) {
        tower._debuffResistance = _debuffResistance;
      }
    }

    // 한(恨) 억제 — 범위 내 한 게이지 증가량 감소
    double wailingReduction = GameConstants.sotdaeWailingReduction;

    // 수호신단 분기: 한 억제 강화
    final bd = branchData;
    if (bd != null && bd.branch == TowerBranch.phoenixTotem) {
      wailingReduction = 0.5; // 50% 억제
    }

    // 지신 제단 분기: 적 공격력 감소 오라
    if (bd != null && bd.slowAuraRatio > 0) {
      final enemies = game.cachedAliveEnemies;
      for (final enemy in enemies) {
        if (enemy.isDead) continue;
        final dist = position.distanceTo(enemy.position);
        if (dist <= wardRange) {
          enemy.applySpeedDebuff(bd.slowAuraRatio, 1.5);
        }
      }
    }

    // 한 억제 효과 적용 — 배치 큐로 전환
    game.setSotdaeReduction(wailingReduction);
  }

  /// 솟대 버프: 범위 내 아군 타워 공격속도 증가
  void _applySotdaeBuff() {
    final buffRange = GameConstants.sotdaeBuffRange *
        (upgradeLevel >= 3 ? 1.5 : 1.0); // 3레벨 시 버프 범위 +50%

    final towers = game.cachedTowers;
    for (final tower in towers) {
      if (tower == this) continue;
      if (tower.data.type == TowerType.sotdae) continue; // 솟대끼리 중복 불가

      final dist = position.distanceTo(tower.position);
      if (dist <= buffRange) {
        tower._sotdaeBuffed = true;
      }
    }
  }

  /// 타워 업그레이드 (비용 처리는 호출자가 담당)
  bool upgrade() {
    if (upgradeLevel >= data.upgrades.length) return false;

    upgradeLevel++;
    
    // 업그레이드 비주얼 — 글로우 링 추가
    final color = _getColorForType(data.type);
    _addUpgradeGlow(color);

    // 스프라이트 이미지 갱신
    _body.updateVisual(newLevel: upgradeLevel);
    return true;
  }

  /// 분기 선택 (Tier 4) — 레벨 4 설정 + 분기 능력 활성화
  void selectBranch(TowerBranch branch) {
    selectedBranch = branch;
    upgradeLevel = 4; // Tier 4

    // 스프라이트 이미지를 분기 이미지로 갱신
    _body.updateVisual(newLevel: upgradeLevel, newBranch: branch);

    // 분기 비주얼 업데이트 — 분기 고유 색상 글로우
    final color = _getColorForBranch(branch);
    _addUpgradeGlow(color);
    // Tier 4 특별 외곽 링 추가
    add(CircleComponent(
      radius: size.x * 0.65,
      position: size / 2,
      anchor: Anchor.center,
      priority: -2,
      paint: Paint()
        ..color = Color.fromARGB(35, color.red, color.green, color.blue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    ));

    // 분기 선택 SFX
    SoundManager.instance.playSfx(SfxType.branchSelect);

    // 분기 선택 파티클 이펙트
    if (ParticleEffect.canCreate) {
      game.world.add(ParticleEffect.magic(
        position: position.clone(),
        color: color,
      ));
    }

    // 병영 분기: 추가 병사 소환
    final bd = branchData;
    if (data.type == TowerType.barracks && bd != null && bd.extraSoldierCount > 0) {
      for (int i = 0; i < bd.extraSoldierCount; i++) {
        final rallyPos = _rallyFlag?.currentRallyPoint
            ?? (position.clone() + Vector2(0, 50));
        final soldier = BarracksSoldier(
          rallyPoint: rallyPos,
          hp: (25 + (upgradeLevel * 10)) * bd.soldierHpMultiplier,
          attackDamage: bd.damage,
          operationRange: _soldierOperationRange,
          attackCooldown: 1.0 / bd.fireRate.clamp(0.5, 5.0),
          moveSpeed: 100,
          isGrappler: selectedBranch == TowerBranch.goblinRing,
          goldBonusRatio: bd.goldBonusRatio,
        );
        _soldiers.add(soldier);
        game.world.add(soldier);
      }
    }
  }

  /// 침묵 (적 능력에 의해)
  void silence(double duration) {
    _isSilenced = true;
    _silenceTimer = duration;
  }

  /// 적 디버프 오라 수신 (매 프레임 적용, 다음 프레임에 자동 리셋)
  void applySlowDebuff(double ratio) {
    // 솟대 수호결계 내성 적용
    final effectiveRatio = ratio * (1.0 - _debuffResistance);
    // 가장 강한 디버프만 적용 (중첩 불가)
    if (effectiveRatio > _slowDebuff) {
      _slowDebuff = effectiveRatio;
    }
  }

  // ── 솟대 버프 상태 ──
  /// 솟대 버프가 적용된 상태인지 (매 프레임 리셋, 솟대가 다시 설정)
  bool get isSotdaeBuffed => _sotdaeBuffed;

  /// 총 투자 비용 (판매 시 환불 계산용)
  int get totalInvestedCost {
    int total = data.baseCost;
    for (int i = 0; i < upgradeLevel && i < data.upgrades.length; i++) {
      total += data.upgrades[i].cost;
    }
    return total;
  }

  /// 판매 환불 금액
  int get sellRefund => (totalInvestedCost * GameConstants.towerSellRefundRatio).round();

  // ══════════════════════════════
  // 병영 전용 메서드
  // ══════════════════════════════

  /// 병사 활동 반경 — 넓은 범위로 설정
  static const double _soldierOperationRange = 160.0;

  /// 병사 초기 소환
  void _spawnSoldiers() {
    // 랠리 깃발 생성 (타워 아래쪽에 기본 배치)
    final flagPos = position.clone() + Vector2(0, 50);
    _rallyFlag = RallyFlagComponent(
      towerPosition: position.clone(),
      operationRange: _soldierOperationRange * 0.75,
      soldiers: _soldiers,
      initialPosition: flagPos,
    );
    game.world.add(_rallyFlag!);

    for (int i = 0; i < _maxSoldiers; i++) {
      final bd = branchData;
      final soldier = BarracksSoldier(
        rallyPoint: flagPos.clone(),
        hp: 25 + (upgradeLevel * 10),
        attackDamage: currentDamage,
        operationRange: _soldierOperationRange,
        attackCooldown: 1.0 / currentFireRate.clamp(0.5, 5.0),
        moveSpeed: 100,
        isGrappler: selectedBranch == TowerBranch.goblinRing,
        goldBonusRatio: bd?.goldBonusRatio ?? 0,
      );
      _soldiers.add(soldier);
      game.world.add(soldier);
    }
  }

  /// 병영 업데이트 — 사망한 병사 재소환 관리
  void _updateBarracks(double dt) {
    // 사망/제거된 병사 정리
    _soldiers.removeWhere((s) => !s.isMounted || s.isDead);

    // 병사 부족 시 재소환 타이머
    if (_soldiers.length < _maxSoldiers) {
      _soldierRespawnTimer += dt;
      if (_soldierRespawnTimer >= _soldierRespawnDelay) {
        _soldierRespawnTimer = 0;
        // 깃발 위치를 랠리 포인트로 사용
        final rallyPos = _rallyFlag?.currentRallyPoint
            ?? (position.clone() + Vector2(0, 50));
        final bd = branchData;
        final soldier = BarracksSoldier(
          rallyPoint: rallyPos,
          hp: 25 + (upgradeLevel * 10),
          attackDamage: currentDamage,
          operationRange: _soldierOperationRange,
          attackCooldown: 1.0 / currentFireRate.clamp(0.5, 5.0),
          moveSpeed: 100,
          isGrappler: selectedBranch == TowerBranch.goblinRing,
          goldBonusRatio: bd?.goldBonusRatio ?? 0,
        );
        _soldiers.add(soldier);
        game.world.add(soldier);
      }
    } else {
      _soldierRespawnTimer = 0;
    }
  }

  // ══════════════════════════════
  // 서당(무당) 전용 메서드
  // ══════════════════════════════

  /// 서당 광역 공격 — 범위 내 모든 적에게 동시 데미지
void _fireShaman() {
  final enemies = game.cachedAliveEnemies;
  final hitEnemies = <BaseEnemy>[];

  for (final enemy in enemies) {
    if (enemy.isDead) continue;
    if (enemy.isStealth) continue;

    final dist = position.distanceTo(enemy.position);
    if (dist <= currentRange) {
      enemy.takeDamage(currentDamage, data.damageType);
      hitEnemies.add(enemy);
    }
  }

  // ── 시각 이펙트 ──

  // 1) 범위 원 펄스 — 전체 공격 범위 표시 (보라색 원)
  final rangePulse = CircleComponent(
    radius: currentRange,
    position: size / 2,
    anchor: Anchor.center,
    paint: Paint()
      ..color = const Color(0x339944FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );
  add(rangePulse);

  // 2) 내부 충격파 (채워진 원, 작은 크기)
  final innerPulse = CircleComponent(
    radius: currentRange * 0.15,
    position: size / 2,
    anchor: Anchor.center,
    paint: Paint()
      ..color = const Color(0x228844FF)
      ..style = PaintingStyle.fill,
  );
  add(innerPulse);

  // 3) 각 타격된 적에게 보라색 광선 + 타격 이펙트
  for (final enemy in hitEnemies) {
    // 타워→적 방향 광선 (Canvas drawLine 기반)
    final beamStart = size / 2;
    final beamEnd = enemy.position - position + size / 2;
    final beam = _ShamanBeam(start: beamStart, end: beamEnd);
    add(beam);

    // 적 위치에 타격 플래시 (밝은 보라색 원)
    final hitFlash = CircleComponent(
      radius: 12,
      position: enemy.position - position + size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0x66CC77FF)
        ..style = PaintingStyle.fill,
    );
    add(hitFlash);

    // 0.25초 후 광선/플래시 제거
    Future.delayed(const Duration(milliseconds: 250), () {
      if (beam.isMounted) beam.removeFromParent();
      if (hitFlash.isMounted) hitFlash.removeFromParent();
    });
  }

  // 마법 파티클 이펙트
  if (hitEnemies.isNotEmpty && ParticleEffect.canCreate) {
    game.world.add(ParticleEffect.magic(
      position: position,
      color: const Color(0xFF9944FF),
    ));
  }

  if (hitEnemies.isNotEmpty) {
    SoundManager.instance.playSfx(SfxType.towerMagic);
  }

  // 0.4초 후 범위 원 제거
  Future.delayed(const Duration(milliseconds: 400), () {
    if (rangePulse.isMounted) rangePulse.removeFromParent();
    if (innerPulse.isMounted) innerPulse.removeFromParent();
  });
}
  // ══════════════════════════════
  // 범위 색상
  // ══════════════════════════════

  /// 타워 타입별 범위 표시 색상
  Color _getRangeColorForType(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return const Color(0x2244CC44); // 초록
      case TowerType.barracks:
        return const Color(0x224488FF); // 파랑
      case TowerType.shaman:
        return const Color(0x229944FF); // 보라
      case TowerType.artillery:
        return const Color(0x22FF4444); // 빨강
      case TowerType.sotdae:
        return const Color(0x22FFD700); // 금색
    }
  }
}

/// 마법서탑 공격 빔 — Canvas drawLine 기반
class _ShamanBeam extends PositionComponent {
  final Vector2 start;
  final Vector2 end;
  final Paint _beamPaint;

  _ShamanBeam({required this.start, required this.end})
      : _beamPaint = Paint()
          ..color = const Color(0xAA9955FF)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
        super(priority: 100);

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      Offset(start.x, start.y),
      Offset(end.x, end.y),
      _beamPaint,
    );
  }
}
