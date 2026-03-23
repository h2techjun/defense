// 해원의 문 — UserState 데이터 모델 유닛 테스트
// toJson / fromJson 왕복 검증

import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_of_regrets/state/user_state.dart';
import 'package:gateway_of_regrets/common/enums.dart';

void main() {
  group('UserState — 기본 생성', () {
    test('기본 생성자 초기값이 정확해야 한다', () {
      const state = UserState();
      expect(state.unlockedHeroes, contains(HeroId.kkaebi));
      expect(state.heroLevels[HeroId.kkaebi], 1);
      expect(state.highestChapter, 1);
      expect(state.highestLevel, 1);
      expect(state.totalStars, 0);
      expect(state.gems, 200);
      expect(state.gold, 1000);
      expect(state.membershipPoints, 0);
      expect(state.isPremium, isFalse);
      expect(state.hasCompletedTutorial, isFalse);
    });

    test('hasSpeedPass는 만료 전이면 true', () {
      final futureDate = DateTime.now().add(const Duration(days: 7));
      final state = UserState(speedPassExpiresAt: futureDate);
      expect(state.hasSpeedPass, isTrue);
    });

    test('hasSpeedPass는 만료 후이면 false', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final state = UserState(speedPassExpiresAt: pastDate);
      expect(state.hasSpeedPass, isFalse);
    });

    test('hasSpeedPass는 null이면 false', () {
      const state = UserState();
      expect(state.hasSpeedPass, isFalse);
    });
  });

  group('UserState — 스테이지 별 조회', () {
    test('getStars는 존재하는 스테이지의 별 수를 반환', () {
      const state = UserState(stageStars: {'1:1': 3, '1:2': 2});
      expect(state.getStars(1, 1), 3);
      expect(state.getStars(1, 2), 2);
    });

    test('getStars는 미클리어 스테이지에 0을 반환', () {
      const state = UserState();
      expect(state.getStars(5, 5), 0);
    });

    test('isCleared는 클리어된 스테이지만 true', () {
      const state = UserState(stageStars: {'1:1': 1});
      expect(state.isCleared(1, 1), isTrue);
      expect(state.isCleared(1, 2), isFalse);
    });
  });

  group('UserState — JSON 직렬화', () {
    test('toJson이 올바른 형식이어야 한다', () {
      const state = UserState(
        gems: 500,
        gold: 2000,
        totalStars: 15,
        highestChapter: 3,
        highestLevel: 5,
        isPremium: true,
        membershipPoints: 100,
      );
      final json = state.toJson();
      expect(json['gems'], 500);
      expect(json['gold'], 2000);
      expect(json['totalStars'], 15);
      expect(json['highestChapter'], 3);
      expect(json['highestLevel'], 5);
      expect(json['isPremium'], isTrue);
      expect(json['membershipPoints'], 100);
      expect(json['unlockedHeroes'], isList);
    });

    test('fromJson이 올바르게 파싱되어야 한다', () {
      final json = {
        'unlockedHeroes': ['kkaebi'],
        'heroLevels': {'kkaebi': 5},
        'highestChapter': 2,
        'highestLevel': 3,
        'totalStars': 10,
        'gems': 300,
        'gold': 1500,
        'membershipPoints': 50,
        'isPremium': false,
        'hasCompletedTutorial': true,
      };
      final state = UserState.fromJson(json);
      expect(state.unlockedHeroes, contains(HeroId.kkaebi));
      expect(state.heroLevels[HeroId.kkaebi], 5);
      expect(state.highestChapter, 2);
      expect(state.gems, 300);
      expect(state.gold, 1500);
      expect(state.hasCompletedTutorial, isTrue);
    });

    test('toJson → fromJson 왕복 검증 (Round-trip)', () {
      const original = UserState(
        gems: 999,
        gold: 5000,
        totalStars: 42,
        highestChapter: 5,
        highestLevel: 8,
        isPremium: true,
        membershipPoints: 200,
        hasCompletedTutorial: true,
      );
      final json = original.toJson();
      final restored = UserState.fromJson(json);

      expect(restored.gems, original.gems);
      expect(restored.gold, original.gold);
      expect(restored.totalStars, original.totalStars);
      expect(restored.highestChapter, original.highestChapter);
      expect(restored.highestLevel, original.highestLevel);
      expect(restored.isPremium, original.isPremium);
      expect(restored.membershipPoints, original.membershipPoints);
      expect(restored.hasCompletedTutorial, original.hasCompletedTutorial);
    });

    test('fromJson은 누락된 키에 기본값을 사용해야 한다', () {
      final minimal = <String, dynamic>{};
      final state = UserState.fromJson(minimal);
      expect(state.gems, 200);
      expect(state.gold, 1000);
      expect(state.highestChapter, 1);
      expect(state.isPremium, isFalse);
    });

    test('speedPassExpiresAt 직렬화/역직렬화', () {
      final now = DateTime(2026, 3, 31, 23, 59, 59);
      final state = UserState(speedPassExpiresAt: now);
      final json = state.toJson();
      expect(json['speedPassExpiresAt'], isNotNull);
      
      final restored = UserState.fromJson(json);
      // DateTime 파싱 동작 확인 (null이 아닌지)
      expect(restored.speedPassExpiresAt, isNotNull);
    });
  });

  group('UserState — copyWith', () {
    test('copyWith은 지정된 필드만 변경해야 한다', () {
      const original = UserState(gems: 100, gold: 200);
      final copy = original.copyWith(gems: 500);
      expect(copy.gems, 500);
      expect(copy.gold, 200); // 변경 없음
    });
  });
}
