// 해원의 문 — GameState 유닛 테스트
// GameStateNotifier의 핵심 로직 검증

import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_of_regrets/state/game_state.dart';
import 'package:gateway_of_regrets/common/enums.dart';

void main() {
  group('GameState — 기본 상태', () {
    test('기본 생성자 초기값이 정확해야 한다', () {
      const state = GameState();
      expect(state.sinmyeong, 200);
      expect(state.wailing, 0);
      expect(state.gatewayHp, 20);
      expect(state.maxGatewayHp, 20);
      expect(state.currentWave, 0);
      expect(state.totalWaves, 10);
      expect(state.phase, GamePhase.mainMenu);
      expect(state.starRating, 0);
      expect(state.dayCycle, DayCycle.day);
      expect(state.enemiesKilled, 0);
      expect(state.gameSpeed, 1.0);
    });

    test('copyWith은 지정된 필드만 변경해야 한다', () {
      const state = GameState();
      final modified = state.copyWith(sinmyeong: 500, currentWave: 3);
      expect(modified.sinmyeong, 500);
      expect(modified.currentWave, 3);
      // 나머지는 원본 유지
      expect(modified.gatewayHp, 20);
      expect(modified.phase, GamePhase.mainMenu);
    });

    test('isWailingMax는 100 이상일 때 true', () {
      final state = const GameState(wailing: 100);
      expect(state.isWailingMax, isTrue);
      final low = const GameState(wailing: 50);
      expect(low.isWailingMax, isFalse);
    });
  });

  group('GameStateNotifier — 레벨 초기화', () {
    test('initLevel이 상태를 올바르게 설정해야 한다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(
        startingSinmyeong: 300,
        gatewayHp: 50,
        totalWaves: 15,
      );

      expect(notifier.state.sinmyeong, 300);
      expect(notifier.state.gatewayHp, 50);
      expect(notifier.state.maxGatewayHp, 50);
      expect(notifier.state.totalWaves, 15);
      expect(notifier.state.phase, GamePhase.playing);
      expect(notifier.state.currentWave, 0);
    });
  });

  group('GameStateNotifier — 자원 관리', () {
    test('addSinmyeong이 정확히 증가해야 한다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 20, totalWaves: 5);
      notifier.addSinmyeong(50);
      expect(notifier.state.sinmyeong, 150);
    });

    test('addSinmyeong은 99999를 초과할 수 없다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 99990, gatewayHp: 20, totalWaves: 5);
      notifier.addSinmyeong(20);
      expect(notifier.state.sinmyeong, 99999);
    });

    test('spendSinmyeong은 잔액 부족 시 false를 반환해야 한다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 50, gatewayHp: 20, totalWaves: 5);
      
      final result = notifier.spendSinmyeong(100);
      expect(result, isFalse);
      expect(notifier.state.sinmyeong, 50); // 변경 없음
    });

    test('spendSinmyeong은 잔액 충분 시 true를 반환하고 차감해야 한다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 20, totalWaves: 5);
      
      final result = notifier.spendSinmyeong(60);
      expect(result, isTrue);
      expect(notifier.state.sinmyeong, 40);
    });
  });

  group('GameStateNotifier — 게이트웨이', () {
    test('damageGateway가 HP를 정확히 감소시켜야 한다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 20, totalWaves: 5);
      notifier.damageGateway(5);
      expect(notifier.state.gatewayHp, 15);
    });

    test('damageGateway로 HP 0 이하 시 defeat 페이즈로 전환', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 3, totalWaves: 5);
      notifier.damageGateway(5);
      expect(notifier.state.gatewayHp, 0);
      expect(notifier.state.phase, GamePhase.defeat);
    });

    test('reviveGateway가 HP를 회복하고 playing 페이즈로 전환', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 10, totalWaves: 5);
      notifier.damageGateway(10); // HP 0 → defeat
      notifier.reviveGateway(5);
      expect(notifier.state.gatewayHp, 5);
      expect(notifier.state.phase, GamePhase.playing);
    });
  });

  group('GameStateNotifier — 한 게이지', () {
    test('addWailing이 한 게이지를 증가시켜야 한다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 20, totalWaves: 5);
      notifier.addWailing(30);
      expect(notifier.state.wailing, 30);
    });

    test('한 게이지는 100을 초과할 수 없다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 20, totalWaves: 5);
      notifier.addWailing(120);
      expect(notifier.state.wailing, 100);
    });

    test('솟대 억제 적용 시 한 게이지 증가량이 감소해야 한다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 20, totalWaves: 5);
      notifier.setSotdaeWailingReduction(0.5); // 50% 억제
      notifier.addWailing(20);
      expect(notifier.state.wailing, closeTo(10, 0.01)); // 20 * 0.5 = 10
    });
  });

  group('GameStateNotifier — 별 평가', () {
    test('HP 90%+ → 별 3개', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 100, totalWaves: 5);
      notifier.damageGateway(5); // HP 95/100
      notifier.calculateStarRating();
      expect(notifier.state.starRating, 3);
    });

    test('HP 50%+ → 별 2개', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 100, totalWaves: 5);
      notifier.damageGateway(40); // HP 60/100
      notifier.calculateStarRating();
      expect(notifier.state.starRating, 2);
    });

    test('HP 50% 미만 → 별 1개', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 100, totalWaves: 5);
      notifier.damageGateway(80); // HP 20/100
      notifier.calculateStarRating();
      expect(notifier.state.starRating, 1);
    });
  });

  group('GameStateNotifier — batchUpdate', () {
    test('batchUpdate가 모든 필드를 한 번에 업데이트해야 한다', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 20, totalWaves: 5);
      
      notifier.batchUpdate(
        addSinmyeongAmount: 50,
        addKillCount: 3,
        damageGatewayAmount: 2,
      );

      expect(notifier.state.sinmyeong, 150);
      expect(notifier.state.enemiesKilled, 3);
      expect(notifier.state.gatewayHp, 18);
      expect(notifier.state.score, 30); // 3 * 10
    });

    test('batchUpdate로 게이트웨이 파괴 시 defeat 페이즈 전환', () {
      final notifier = GameStateNotifier();
      notifier.initLevel(startingSinmyeong: 100, gatewayHp: 5, totalWaves: 5);
      
      notifier.batchUpdate(damageGatewayAmount: 10);
      expect(notifier.state.gatewayHp, 0);
      expect(notifier.state.phase, GamePhase.defeat);
    });
  });
}
