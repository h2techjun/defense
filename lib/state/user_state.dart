// 해원의 문 - 사용자 데이터 상태 (Riverpod)
// 게임 세션 간 유지되는 데이터를 관리합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enums.dart';

/// 사용자 영구 데이터
class UserState {
  final Set<HeroId> unlockedHeroes;
  final Map<HeroId, int> heroLevels;
  final int highestChapter;
  final int highestLevel;
  final int totalStars;
  final bool isPremium;

  const UserState({
    this.unlockedHeroes = const {HeroId.kkaebi},
    this.heroLevels = const {HeroId.kkaebi: 1},
    this.highestChapter = 1,
    this.highestLevel = 1,
    this.totalStars = 0,
    this.isPremium = false,
  });

  UserState copyWith({
    Set<HeroId>? unlockedHeroes,
    Map<HeroId, int>? heroLevels,
    int? highestChapter,
    int? highestLevel,
    int? totalStars,
    bool? isPremium,
  }) {
    return UserState(
      unlockedHeroes: unlockedHeroes ?? this.unlockedHeroes,
      heroLevels: heroLevels ?? this.heroLevels,
      highestChapter: highestChapter ?? this.highestChapter,
      highestLevel: highestLevel ?? this.highestLevel,
      totalStars: totalStars ?? this.totalStars,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

/// 사용자 데이터 Notifier
class UserStateNotifier extends StateNotifier<UserState> {
  UserStateNotifier() : super(const UserState());

  void unlockHero(HeroId heroId) {
    state = state.copyWith(
      unlockedHeroes: {...state.unlockedHeroes, heroId},
      heroLevels: {...state.heroLevels, heroId: 1},
    );
  }

  void levelUpHero(HeroId heroId) {
    final current = state.heroLevels[heroId] ?? 1;
    state = state.copyWith(
      heroLevels: {...state.heroLevels, heroId: current + 1},
    );
  }

  void completeLevel(int chapter, int level, int stars) {
    state = state.copyWith(
      highestChapter: chapter > state.highestChapter ? chapter : state.highestChapter,
      highestLevel: level > state.highestLevel ? level : state.highestLevel,
      totalStars: state.totalStars + stars,
    );
  }
}

final userStateProvider = StateNotifierProvider<UserStateNotifier, UserState>(
  (ref) => UserStateNotifier(),
);
