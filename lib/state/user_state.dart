// 해원의 문 - 사용자 데이터 상태 (Riverpod)
// 게임 세션 간 유지되는 데이터를 관리합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enums.dart';
import '../services/save_manager.dart';

/// 사용자 영구 데이터
class UserState {
  final Set<HeroId> unlockedHeroes;
  final Map<HeroId, int> heroLevels;
  final int highestChapter;
  final int highestLevel;
  final int totalStars;
  final int gems;           // 보석 화폐
  final int gold;           // 골드(신명) 화폐
  final int membershipPoints; // 멤버십 포인트 (마일리지)
  final bool isPremium;
  final Map<String, int> stageStars; // "chapter:level" -> stars

  const UserState({
    this.unlockedHeroes = const {HeroId.kkaebi},
    this.heroLevels = const {HeroId.kkaebi: 1},
    this.highestChapter = 1,
    this.highestLevel = 1,
    this.totalStars = 0,
    this.gems = 100,         // 초기 보석 100개
    this.gold = 1000,        // 초기 골드 1000개
    this.membershipPoints = 0, // 초기 멤버십 포인트
    this.isPremium = false,
    this.stageStars = const {},
  });

  UserState copyWith({
    Set<HeroId>? unlockedHeroes,
    Map<HeroId, int>? heroLevels,
    int? highestChapter,
    int? highestLevel,
    int? totalStars,
    int? gems,
    int? gold,
    int? membershipPoints,
    bool? isPremium,
    Map<String, int>? stageStars,
  }) {
    return UserState(
      unlockedHeroes: unlockedHeroes ?? this.unlockedHeroes,
      heroLevels: heroLevels ?? this.heroLevels,
      highestChapter: highestChapter ?? this.highestChapter,
      highestLevel: highestLevel ?? this.highestLevel,
      totalStars: totalStars ?? this.totalStars,
      gems: gems ?? this.gems,
      gold: gold ?? this.gold,
      membershipPoints: membershipPoints ?? this.membershipPoints,
      isPremium: isPremium ?? this.isPremium,
      stageStars: stageStars ?? this.stageStars,
    );
  }

  /// 특정 스테이지의 별 수 조회
  int getStars(int chapter, int level) => stageStars['$chapter:$level'] ?? 0;

  /// 특정 스테이지 클리어 여부
  bool isCleared(int chapter, int level) => stageStars.containsKey('$chapter:$level');

  Map<String, dynamic> toJson() => {
    'unlockedHeroes': unlockedHeroes.map((e) => e.name).toList(),
    'heroLevels': heroLevels.map((key, value) => MapEntry(key.name, value)),
    'highestChapter': highestChapter,
    'highestLevel': highestLevel,
    'totalStars': totalStars,
    'gems': gems,
    'gold': gold,
    'membershipPoints': membershipPoints,
    'isPremium': isPremium,
  };

  factory UserState.fromJson(Map<String, dynamic> json) {
    return UserState(
      unlockedHeroes: ((json['unlockedHeroes'] as List?) ?? [])
          .map((e) => HeroId.values.firstWhere((h) => h.name == e))
          .toSet(),
      heroLevels: (json['heroLevels'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          HeroId.values.firstWhere((h) => h.name == key),
          (value as num).toInt(),
        ),
      ) ?? {HeroId.kkaebi: 1},
      highestChapter: (json['highestChapter'] as num?)?.toInt() ?? 1,
      highestLevel: (json['highestLevel'] as num?)?.toInt() ?? 1,
      totalStars: (json['totalStars'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 100,
      gold: (json['gold'] as num?)?.toInt() ?? 1000,
      membershipPoints: (json['membershipPoints'] as num?)?.toInt() ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
}

/// 사용자 데이터 Notifier
class UserStateNotifier extends StateNotifier<UserState> {
  UserStateNotifier() : super(const UserState());

  /// 앱 시작 시 세이브 데이터 로드
  Future<void> loadFromSave() async {
    final savedState = await SaveManager.instance.loadUserState();
    final stageStars = await SaveManager.instance.loadStageStars();
    if (savedState != null) {
      state = savedState.copyWith(stageStars: stageStars);
      print('[SAVE] 세이브 데이터 로드 완료: level ${state.highestLevel}, stars ${state.totalStars}');
    } else {
      state = UserState(stageStars: stageStars);
      print('[SAVE] 신규 게임 시작');
    }
  }

  /// 자동 저장
  Future<void> _autoSave() async {
    await SaveManager.instance.saveUserState(state);
  }

  void unlockHero(HeroId heroId) {
    state = state.copyWith(
      unlockedHeroes: {...state.unlockedHeroes, heroId},
      heroLevels: {...state.heroLevels, heroId: 1},
    );
    _autoSave();
  }

  void levelUpHero(HeroId heroId) {
    final current = state.heroLevels[heroId] ?? 1;
    state = state.copyWith(
      heroLevels: {...state.heroLevels, heroId: current + 1},
    );
    _autoSave();
  }

  void completeLevel(int chapter, int level, int stars) {
    final key = '$chapter:$level';
    final existingStars = state.stageStars[key] ?? 0;
    final bestStars = stars > existingStars ? stars : existingStars;
    final starDiff = bestStars - existingStars;

    state = state.copyWith(
      highestChapter: chapter > state.highestChapter ? chapter : state.highestChapter,
      highestLevel: level > state.highestLevel ? level : state.highestLevel,
      totalStars: state.totalStars + starDiff,
      gems: state.gems + (starDiff * 5),  // 별 1개당 5보석 보상
      stageStars: {...state.stageStars, key: bestStars},
    );

    // 스테이지별 별 저장
    SaveManager.instance.saveStageStar(chapter, level, bestStars);
    _autoSave();
  }

  /// 보석 추가 (광고 보상, 스테이지 클리어 등)
  void addGems(int amount) {
    state = state.copyWith(gems: state.gems + amount);
    _autoSave();
  }

  /// 보석 소비 (스킨 구매 등) — 부족 시 false 반환
  bool spendGems(int amount) {
    if (state.gems < amount) return false;
    state = state.copyWith(gems: state.gems - amount);
    _autoSave();
    return true;
  }

  /// 골드 추가
  void addGold(int amount) {
    state = state.copyWith(gold: state.gold + amount);
    _autoSave();
  }

  /// 골드 소비 — 부족 시 false 반환
  bool spendGold(int amount) {
    if (state.gold < amount) return false;
    state = state.copyWith(gold: state.gold - amount);
    _autoSave();
    return true;
  }

  /// 멤버십 포인트 추가
  void addMembershipPoints(int amount) {
    state = state.copyWith(membershipPoints: state.membershipPoints + amount);
    _autoSave();
  }
}

final userStateProvider = StateNotifierProvider<UserStateNotifier, UserState>(
  (ref) => UserStateNotifier(),
);

