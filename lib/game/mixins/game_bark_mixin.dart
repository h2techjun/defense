// 해원의 문 - 대사(Bark) 시스템 Mixin
// DefenseGame에서 분리된 영웅 대사 트리거 로직

import 'dart:math' as math;

import 'package:flame/game.dart';

import '../../common/enums.dart';
import '../../data/models/bark_data.dart';
import '../../data/bark_database.dart';
import '../components/actors/base_hero.dart';
import '../components/ui/bark_bubble.dart';
import '../world/day_night_system.dart';

/// 대사(Bark) 시스템 — 트리거 기반 영웅 대사 관리
///
/// [DefenseGame]에서 `activeHeroes`, `dayNightSystem`을 제공해야 함.
mixin GameBarkMixin on FlameGame {
  double _barkCooldown = 0;
  DayCycle? _previousDayCycle;

  /// 하위 클래스에서 구현해야 하는 접근자
  List<BaseHero> get activeHeroes;
  DayNightSystem get dayNightSystem;

  /// 대사 쿨다운 감소 (update에서 매 프레임 호출)
  void updateBarkCooldown(double dt) {
    if (_barkCooldown > 0) {
      _barkCooldown -= dt;
    }
  }

  /// 낮/밤 전환 대사 체크 (update에서 호출)
  /// 반환값: 전환된 DayCycle (null이면 전환 없음)
  DayCycle? checkDayCycleTransition() {
    final currentCycle = dayNightSystem.currentCycle;
    DayCycle? transitioned;
    if (_previousDayCycle != null && _previousDayCycle != currentCycle) {
      transitioned = currentCycle;
      if (currentCycle == DayCycle.night) {
        _triggerBark(BarkTrigger.nightTransition);
      }
    }
    _previousDayCycle = currentCycle;
    return transitioned;
  }

  /// 아군 위기 대사 (게이트웨이 HP 30% 이하)
  void checkAllyDangerBark(int gatewayHp, int maxGatewayHp) {
    if (maxGatewayHp <= 0) return;
    final hpRatio = gatewayHp / maxGatewayHp;
    if (gatewayHp > 0 && hpRatio <= 0.3) {
      _triggerBark(BarkTrigger.allyDanger);
    }
  }

  /// 보스 등장 시 호출 (WaveManager에서)
  void onBossAppear() {
    _triggerBark(BarkTrigger.bossAppear);
  }

  /// 전투 시작 시 호출
  void onBattleStart() {
    _triggerBark(BarkTrigger.battleStart);
  }

  /// 보스 처치 대사
  void onBossKilled() {
    _triggerBark(BarkTrigger.bossKill);
  }

  /// 영웅 궁극기 사용 시 호출
  void onHeroUltimate(HeroId heroId) {
    _triggerBarkForHero(heroId, BarkTrigger.ultimateUsed);
  }

  /// 특정 트리거에 대해 랜덤 영웅이 대사를 말함
  void _triggerBark(BarkTrigger trigger) {
    if (_barkCooldown > 0 || activeHeroes.isEmpty) return;

    final aliveHeroes = activeHeroes.where((h) => !h.isDead).toList();
    if (aliveHeroes.isEmpty) return;

    final rng = math.Random();
    final hero = aliveHeroes[rng.nextInt(aliveHeroes.length)];
    _triggerBarkForHero(hero.data.id, trigger);
  }

  /// 특정 영웅이 대사를 말함
  void _triggerBarkForHero(HeroId heroId, BarkTrigger trigger) {
    if (_barkCooldown > 0) return;

    final lines = getBarkLines(heroId, trigger);
    if (lines.isEmpty) return;

    final rng = math.Random();
    final line = lines[rng.nextInt(lines.length)];

    final heroComp = activeHeroes
        .where((h) => h.data.id == heroId && !h.isDead)
        .firstOrNull;
    if (heroComp == null) return;

    final bubble = BarkBubble(
      text: line,
      heroPosition: heroComp.position,
    );
    world.add(bubble);

    _barkCooldown = 8.0; // 8초 쿨다운
  }
}
