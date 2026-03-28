// 해원의 문 -- 핵심 전투 로직 & 밸런스 데이터 유닛 테스트
// DamageCalculator 속성 상성, 영웅/적 데이터 검증, 밸런스 범위 테스트

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_of_regrets/common/constants.dart';
import 'package:gateway_of_regrets/common/enums.dart';

void main() {
  // ── DamageCalculator 속성 상성 테스트 ──
  group('DamageCalculator.calculate', () {
    const baseDamage = 100.0;

    test('physical vs spiritual -> 0.5x', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.physical,
        armorType: ArmorType.spiritual,
      );
      expect(result, closeTo(50.0, 0.01));
    });

    test('magical vs physical -> 0.7x', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.magical,
        armorType: ArmorType.physical,
      );
      expect(result, closeTo(70.0, 0.01));
    });

    test('purification vs spiritual -> 2.0x', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.purification,
        armorType: ArmorType.spiritual,
      );
      expect(result, closeTo(200.0, 0.01));
    });

    test('yokai armor -> 0.8x 추가 감소', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.physical,
        armorType: ArmorType.yokai,
      );
      // physical vs yokai: 1.0 * 0.8 = 0.8x
      expect(result, closeTo(80.0, 0.01));
    });

    test('magical vs flying -> 1.2x 보너스', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.magical,
        armorType: ArmorType.spiritual, // 중립 상성
        isFlying: true,
      );
      // magical vs spiritual(중립 1.0) * flying(1.2) = 1.2x
      expect(result, closeTo(120.0, 0.01));
    });

    test('physical at night -> 0.9x', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.physical,
        armorType: ArmorType.physical, // 중립 상성
        isNight: true,
      );
      // physical vs physical(1.0) * night(0.9) = 0.9x
      expect(result, closeTo(90.0, 0.01));
    });

    test('복합: physical vs yokai at night = 0.8 * 0.9 = 0.72x', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.physical,
        armorType: ArmorType.yokai,
        isNight: true,
      );
      // physical(1.0) * yokai(0.8) * night(0.9) = 0.72x
      expect(result, closeTo(72.0, 0.01));
    });

    test('hasPiercing = true -> raw damage (상성 무시)', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.physical,
        armorType: ArmorType.spiritual,
        isNight: true,
        hasPiercing: true,
      );
      // 관통은 모든 배율 무시, 순수 데미지
      expect(result, equals(baseDamage));
    });

    test('magical vs flying yokai at night (다중 조합)', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.magical,
        armorType: ArmorType.yokai,
        isFlying: true,
        isNight: true,
      );
      // magical vs yokai: 1.0 * flying(1.2) * yokai(0.8)
      // night은 physical만 적용 -> magical은 night 패널티 없음
      // = 1.0 * 1.2 * 0.8 = 0.96x
      expect(result, closeTo(96.0, 0.01));
    });

    test('purification vs yokai -> 0.8x (정화는 요괴에 보너스 없음)', () {
      final result = DamageCalculator.calculate(
        baseDamage: baseDamage,
        damageType: DamageType.purification,
        armorType: ArmorType.yokai,
      );
      // purification vs yokai: 1.0(중립) * 0.8(yokai) = 0.8x
      expect(result, closeTo(80.0, 0.01));
    });
  });

  // ── DamageCalculator.canTarget 테스트 ──
  group('DamageCalculator.canTarget', () {
    test('barracks는 비행 유닛 공격 불가', () {
      final result = DamageCalculator.canTarget(
        towerType: TowerType.barracks,
        isFlying: true,
      );
      expect(result, isFalse);
    });

    test('barracks는 지상 유닛 공격 가능', () {
      final result = DamageCalculator.canTarget(
        towerType: TowerType.barracks,
        isFlying: false,
      );
      expect(result, isTrue);
    });

    test('archer는 비행 유닛 공격 가능', () {
      final result = DamageCalculator.canTarget(
        towerType: TowerType.archer,
        isFlying: true,
      );
      expect(result, isTrue);
    });

    test('shaman은 비행 유닛 공격 가능', () {
      final result = DamageCalculator.canTarget(
        towerType: TowerType.shaman,
        isFlying: true,
      );
      expect(result, isTrue);
    });
  });

  // ── 영웅 데이터 검증 ──
  group('Hero 데이터 검증 (heroes.json)', () {
    late List<dynamic> heroes;

    setUpAll(() {
      final file = File('assets/data/heroes.json');
      final content = file.readAsStringSync();
      heroes = jsonDecode(content) as List<dynamic>;
    });

    test('heroes.json이 5명의 영웅을 포함해야 한다', () {
      expect(heroes.length, 5);
    });

    test('kkaebi baseAttack = 120', () {
      final hero = heroes.firstWhere(
        (h) => (h as Map<String, dynamic>)['id'] == 'kkaebi',
      ) as Map<String, dynamic>;
      expect(hero['baseAttack'], 120);
    });

    test('miho baseAttack = 160', () {
      final hero = heroes.firstWhere(
        (h) => (h as Map<String, dynamic>)['id'] == 'miho',
      ) as Map<String, dynamic>;
      expect(hero['baseAttack'], 160);
    });

    test('gangrim baseAttack = 150', () {
      final hero = heroes.firstWhere(
        (h) => (h as Map<String, dynamic>)['id'] == 'gangrim',
      ) as Map<String, dynamic>;
      expect(hero['baseAttack'], 150);
    });

    test('sua baseAttack = 130', () {
      final hero = heroes.firstWhere(
        (h) => (h as Map<String, dynamic>)['id'] == 'sua',
      ) as Map<String, dynamic>;
      expect(hero['baseAttack'], 130);
    });

    test('bari baseAttack = 80', () {
      final hero = heroes.firstWhere(
        (h) => (h as Map<String, dynamic>)['id'] == 'bari',
      ) as Map<String, dynamic>;
      expect(hero['baseAttack'], 80);
    });
  });

  // ── 적 데이터 검증 ──
  group('Enemy 데이터 검증 (enemies.json)', () {
    late List<dynamic> enemies;

    setUpAll(() {
      final file = File('assets/data/enemies.json');
      final content = file.readAsStringSync();
      enemies = jsonDecode(content) as List<dynamic>;
    });

    test('bossOgreLord HP = 8000', () {
      final enemy = enemies.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == 'bossOgreLord',
      ) as Map<String, dynamic>;
      expect(enemy['hp'], 8000);
    });

    test('bossMountainLord HP = 15000', () {
      final enemy = enemies.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == 'bossMountainLord',
      ) as Map<String, dynamic>;
      expect(enemy['hp'], 15000);
    });

    test('bossGreatEggGhost HP = 20000', () {
      final enemy = enemies.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == 'bossGreatEggGhost',
      ) as Map<String, dynamic>;
      expect(enemy['hp'], 20000);
    });

    test('bossTyrantKing HP = 28000', () {
      final enemy = enemies.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == 'bossTyrantKing',
      ) as Map<String, dynamic>;
      expect(enemy['hp'], 28000);
    });

    test('bossGatekeeper HP = 45000', () {
      final enemy = enemies.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == 'bossGatekeeper',
      ) as Map<String, dynamic>;
      expect(enemy['hp'], 45000);
    });

    test('failedDragon speed = 85', () {
      final enemy = enemies.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == 'failedDragon',
      ) as Map<String, dynamic>;
      expect(enemy['speed'], 85);
    });

    test('boneGolem shieldDamageReduction = 0.55', () {
      final enemy = enemies.firstWhere(
        (e) => (e as Map<String, dynamic>)['id'] == 'boneGolem',
      ) as Map<String, dynamic>;
      expect(enemy['shieldDamageReduction'], closeTo(0.55, 0.001));
    });
  });

  // ── 밸런스 범위 테스트 ──
  group('밸런스 범위 검증', () {
    late List<dynamic> heroes;
    late List<dynamic> enemies;

    setUpAll(() {
      heroes = jsonDecode(
        File('assets/data/heroes.json').readAsStringSync(),
      ) as List<dynamic>;
      enemies = jsonDecode(
        File('assets/data/enemies.json').readAsStringSync(),
      ) as List<dynamic>;
    });

    test('모든 영웅 baseAttack < 200 (과도한 DPS 방지)', () {
      for (final h in heroes) {
        final hero = h as Map<String, dynamic>;
        final attack = hero['baseAttack'] as int;
        expect(
          attack,
          lessThan(200),
          reason: '${hero['id']}의 baseAttack($attack)이 200 이상입니다',
        );
      }
    });

    test('모든 보스 HP > 5000', () {
      final bosses = enemies.where(
        (e) => (e as Map<String, dynamic>)['isBoss'] == true,
      );
      expect(bosses.isNotEmpty, isTrue, reason: '보스가 한 명도 없습니다');
      for (final b in bosses) {
        final boss = b as Map<String, dynamic>;
        final hp = boss['hp'] as int;
        expect(
          hp,
          greaterThan(5000),
          reason: '${boss['id']}의 HP($hp)가 5000 이하입니다',
        );
      }
    });

    test('모든 일반 적 speed < 100', () {
      final normalEnemies = enemies.where(
        (e) => (e as Map<String, dynamic>)['isBoss'] != true,
      );
      for (final e in normalEnemies) {
        final enemy = e as Map<String, dynamic>;
        final speed = enemy['speed'] as int;
        expect(
          speed,
          lessThan(100),
          reason: '${enemy['id']}의 speed($speed)가 100 이상입니다',
        );
      }
    });

    test('보스 체력은 챕터별로 증가해야 한다', () {
      final bossOrder = [
        'bossOgreLord',
        'bossMountainLord',
        'bossGreatEggGhost',
        'bossTyrantKing',
        'bossGatekeeper',
      ];
      int prevHp = 0;
      for (final bossId in bossOrder) {
        final boss = enemies.firstWhere(
          (e) => (e as Map<String, dynamic>)['id'] == bossId,
        ) as Map<String, dynamic>;
        final hp = boss['hp'] as int;
        expect(
          hp,
          greaterThan(prevHp),
          reason: '$bossId HP($hp)가 이전 보스($prevHp)보다 낮거나 같습니다',
        );
        prevHp = hp;
      }
    });

    test('모든 적의 HP가 양수여야 한다', () {
      for (final e in enemies) {
        final enemy = e as Map<String, dynamic>;
        final hp = enemy['hp'] as int;
        expect(
          hp,
          greaterThan(0),
          reason: '${enemy['id']}의 HP($hp)가 0 이하입니다',
        );
      }
    });

    test('모든 영웅의 baseHp가 양수여야 한다', () {
      for (final h in heroes) {
        final hero = h as Map<String, dynamic>;
        final hp = hero['baseHp'] as int;
        expect(
          hp,
          greaterThan(0),
          reason: '${hero['id']}의 baseHp($hp)가 0 이하입니다',
        );
      }
    });
  });

  // ── GameConstants 상수 검증 ──
  group('GameConstants 상수 일관성', () {
    test('속성 상성 배율이 올바른 범위에 있어야 한다', () {
      expect(
        GameConstants.physicalVsSpiritualMultiplier,
        closeTo(0.5, 0.01),
      );
      expect(
        GameConstants.magicalVsPhysicalMultiplier,
        closeTo(0.7, 0.01),
      );
      expect(
        GameConstants.purificationVsSpiritualMultiplier,
        closeTo(2.0, 0.01),
      );
      expect(
        GameConstants.yokaiDamageReduction,
        closeTo(0.8, 0.01),
      );
    });

    test('타워 판매 환불 비율이 0~1 사이여야 한다', () {
      expect(GameConstants.towerSellRefundRatio, greaterThan(0.0));
      expect(GameConstants.towerSellRefundRatio, lessThanOrEqualTo(1.0));
    });

    test('웨이브 쿨다운이 양수여야 한다', () {
      expect(GameConstants.waveCooldown, greaterThan(0.0));
    });

    test('솟대 수호결계 범위가 양수여야 한다', () {
      expect(GameConstants.sotdaeWardRange, greaterThan(0.0));
      expect(GameConstants.sotdaeBuffRange, greaterThan(0.0));
    });
  });
}
