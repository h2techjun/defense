import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/enums.dart';
import '../state/user_state.dart';
import '../data/models/relic_data.dart';
import '../data/models/skin_data.dart';

/// 세이브 매니저 — 싱글톤 패턴
class SaveManager {
  static SaveManager? _instance;
  static SaveManager get instance => _instance ??= SaveManager._();
  SaveManager._();

  static const String _keyUserData = 'haewon_user_data';
  static const String _keyStageStars = 'haewon_stage_stars';
  static const String _keySaveVersion = 'haewon_save_version';
  static const String _keySelectedHero = 'haewon_selected_hero';
  static const String _keyHeroLevels = 'haewon_hero_levels';
  static const String _keyRelicData = 'haewon_relic_data';
  static const String _keySkinData = 'haewon_skin_data';
  static const int _currentVersion = 1;

  /// 사용자 데이터 저장
  Future<void> saveUserState(UserState state) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'version': _currentVersion,
      'unlockedHeroes': state.unlockedHeroes.map((h) => h.name).toList(),
      'heroLevels': state.heroLevels.map((k, v) => MapEntry(k.name, v)),
      'highestChapter': state.highestChapter,
      'highestLevel': state.highestLevel,
      'totalStars': state.totalStars,
      'gems': state.gems,
      'isPremium': state.isPremium,
    };

    await prefs.setString(_keyUserData, jsonEncode(data));
    await prefs.setInt(_keySaveVersion, _currentVersion);
  }

  /// 사용자 데이터 로드
  Future<UserState?> loadUserState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUserData);
    if (jsonStr == null) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 영웅 해금 파싱
      final heroNames = (data['unlockedHeroes'] as List?)?.cast<String>() ?? ['kkaebi'];
      final unlockedHeroes = heroNames
          .map((name) {
            try {
              return HeroId.values.firstWhere((h) => h.name == name);
            } catch (_) {
              return null;
            }
          })
          .whereType<HeroId>()
          .toSet();

      // 영웅 레벨 파싱
      final rawLevels = (data['heroLevels'] as Map<String, dynamic>?) ?? {'kkaebi': 1};
      final heroLevels = <HeroId, int>{};
      for (final entry in rawLevels.entries) {
        try {
          final heroId = HeroId.values.firstWhere((h) => h.name == entry.key);
          heroLevels[heroId] = (entry.value as num).toInt();
        } catch (_) {
          // 알 수 없는 영웅 ID는 무시
        }
      }

      return UserState(
        unlockedHeroes: unlockedHeroes.isEmpty ? {HeroId.kkaebi} : unlockedHeroes,
        heroLevels: heroLevels.isEmpty ? {HeroId.kkaebi: 1} : heroLevels,
        highestChapter: (data['highestChapter'] as num?)?.toInt() ?? 1,
        highestLevel: (data['highestLevel'] as num?)?.toInt() ?? 1,
        totalStars: (data['totalStars'] as num?)?.toInt() ?? 0,
        gems: (data['gems'] as num?)?.toInt() ?? 100,
        isPremium: (data['isPremium'] as bool?) ?? false,
      );
    } catch (e) {
      print('[SAVE] 세이브 데이터 파싱 오류: $e');
      return null;
    }
  }

  /// 스테이지별 별 저장 (chapter:level -> stars)
  Future<void> saveStageStar(int chapter, int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyStageStars);
    final Map<String, dynamic> stageStars = jsonStr != null
        ? jsonDecode(jsonStr) as Map<String, dynamic>
        : {};

    final key = '$chapter:$level';
    final existing = (stageStars[key] as num?)?.toInt() ?? 0;
    // 최고 기록만 저장
    if (stars > existing) {
      stageStars[key] = stars;
      await prefs.setString(_keyStageStars, jsonEncode(stageStars));
    }
  }

  /// 스테이지별 별 로드
  Future<Map<String, int>> loadStageStars() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyStageStars);
    if (jsonStr == null) return {};

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      print('[SAVE] 스테이지 별 데이터 파싱 오류: $e');
      return {};
    }
  }

  /// 특정 스테이지 별 조회
  Future<int> getStageStars(int chapter, int level) async {
    final stars = await loadStageStars();
    return stars['$chapter:$level'] ?? 0;
  }

  /// 세이브 데이터 초기화
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyStageStars);
    await prefs.remove(_keySaveVersion);
    await prefs.remove(_keyHeroLevels);
    await prefs.remove(_keyRelicData);
    await prefs.remove(_keySkinData);
  }

  /// 세이브 데이터 존재 여부
  Future<bool> hasSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserData);
  }

  /// 영웅 레벨/경험치 저장
  Future<void> saveHeroLevels(Map<String, Map<String, int>> heroLevels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHeroLevels, jsonEncode(heroLevels));
  }

  /// 영웅 레벨/경험치 로드
  Future<Map<String, Map<String, int>>> loadHeroLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyHeroLevels);
    if (json == null) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(
      key,
      (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
    ));
  }

  /// 개별 영웅 레벨 저장
  Future<void> saveHeroLevel(HeroId heroId, int level, int xp) async {
    final levels = await loadHeroLevels();
    levels[heroId.name] = {'level': level, 'xp': xp};
    await saveHeroLevels(levels);
  }

  /// 개별 영웅 레벨 로드
  Future<Map<String, int>> loadHeroLevel(HeroId heroId) async {
    final levels = await loadHeroLevels();
    return levels[heroId.name] ?? {'level': 1, 'xp': 0};
  }

  /// 선택된 영웅 저장
  Future<void> saveSelectedHero(HeroId heroId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedHero, heroId.name);
  }

  /// 선택된 영웅 로드
  Future<HeroId?> loadSelectedHero() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keySelectedHero);
    if (name == null) return null;
    try {
      return HeroId.values.firstWhere((h) => h.name == name);
    } catch (_) {
      return null;
    }
  }

  // ── 타워 출전 & 외부 레벨 ──

  static const String _keyTowerLoadout = 'haewon_tower_loadout';
  static const String _keyTowerLevels = 'haewon_tower_levels';

  /// 출전 타워 목록 저장
  Future<void> saveTowerLoadout(List<String> loadout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTowerLoadout, jsonEncode(loadout));
  }

  /// 출전 타워 목록 로드
  Future<List<TowerType>> loadTowerLoadout() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyTowerLoadout);
    if (json == null) return [];
    try {
      final list = (jsonDecode(json) as List).cast<String>();
      return list
          .map((name) {
            try {
              return TowerType.values.firstWhere((t) => t.name == name);
            } catch (_) {
              return null;
            }
          })
          .whereType<TowerType>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 타워 외부 레벨/XP 저장
  Future<void> saveTowerLevels(Map<String, Map<String, int>> levels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTowerLevels, jsonEncode(levels));
  }

  /// 타워 외부 레벨/XP 로드
  Future<Map<String, Map<String, int>>> loadTowerLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyTowerLevels);
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(
        key,
        (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
      ));
    } catch (_) {
      return {};
    }
  }

  // ── 유물 시스템 ──

  /// 유물 상태 저장 (잠금해제 + 영웅별 장착)
  Future<void> saveRelics({
    required Set<RelicId> unlockedRelics,
    required Map<HeroId, RelicId?> equippedRelics,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'unlocked': unlockedRelics.map((r) => r.name).toList(),
      'equipped': equippedRelics.map(
        (heroId, relicId) => MapEntry(heroId.name, relicId?.name),
      ),
    };
    await prefs.setString(_keyRelicData, jsonEncode(data));
  }

  /// 유물 상태 로드
  Future<Map<String, dynamic>?> loadRelics() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyRelicData);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      // 잠금해제 유물 파싱
      final unlockedNames = (data['unlocked'] as List?)?.cast<String>() ?? [];
      final unlocked = unlockedNames
          .map((name) {
            try {
              return RelicId.values.firstWhere((r) => r.name == name);
            } catch (_) {
              return null;
            }
          })
          .whereType<RelicId>()
          .toSet();

      // 장착 유물 파싱
      final rawEquipped = (data['equipped'] as Map<String, dynamic>?) ?? {};
      final equipped = <HeroId, RelicId?>{};
      for (final entry in rawEquipped.entries) {
        try {
          final heroId = HeroId.values.firstWhere((h) => h.name == entry.key);
          final relicName = entry.value as String?;
          RelicId? relicId;
          if (relicName != null) {
            relicId = RelicId.values.firstWhere((r) => r.name == relicName);
          }
          equipped[heroId] = relicId;
        } catch (_) {
          // 알 수 없는 ID는 무시
        }
      }

      return {
        'unlocked': unlocked,
        'equipped': equipped,
      };
    } catch (e) {
      print('[SAVE] 유물 데이터 파싱 오류: $e');
      return null;
    }
  }

  /// 스킨 데이터 저장
  Future<void> saveSkins({
    required Set<SkinId> ownedSkins,
    required Map<HeroId, SkinId> equippedSkins,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'owned': ownedSkins.map((s) => s.name).toList(),
      'equipped': equippedSkins.map((k, v) => MapEntry(k.name, v.name)),
    };
    await prefs.setString(_keySkinData, jsonEncode(data));
  }

  /// 스킨 데이터 로드
  Future<Map<String, dynamic>?> loadSkins() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keySkinData);
    if (json == null) return null;

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final ownedList = (decoded['owned'] as List<dynamic>?) ?? [];
      final equippedMap = (decoded['equipped'] as Map<String, dynamic>?) ?? {};

      final owned = <SkinId>{};
      for (final name in ownedList) {
        try {
          owned.add(SkinId.values.byName(name as String));
        } catch (_) {}
      }

      final equipped = <HeroId, SkinId>{};
      equippedMap.forEach((key, value) {
        try {
          equipped[HeroId.values.byName(key)] = SkinId.values.byName(value as String);
        } catch (_) {}
      });

      return {'owned': owned, 'equipped': equipped};
    } catch (e) {
      print('[SAVE] 스킨 데이터 파싱 오류: $e');
      return null;
    }
  }

  // ── 무한의 탑 ──

  /// 무한의 탑 상태 저장
  Future<void> saveEndlessTower(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('endless_tower', jsonEncode(data));
    print('[SAVE] 무한의 탑 저장: floor=${data['currentFloor']}, highest=${data['highestFloor']}');
  }

  /// 무한의 탑 상태 로드
  Future<Map<String, dynamic>?> loadEndlessTower() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('endless_tower');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] 무한의 탑 로드 오류: $e');
      return null;
    }
  }

  // ── 일일 도전 ──

  /// 일일 도전 상태 저장
  Future<void> saveDailyChallenge(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_challenge', jsonEncode(data));
    print('[SAVE] 일일 도전 저장: completed=${data['lastCompletedDate']}, streak=${data['streak']}');
  }

  /// 일일 도전 상태 로드
  Future<Map<String, dynamic>?> loadDailyChallenge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('daily_challenge');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] 일일 도전 로드 오류: $e');
      return null;
    }
  }

  // ── 시즌 패스 ──

  /// 시즌 패스 상태 저장
  Future<void> saveSeasonPass(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('season_pass', jsonEncode(data));
  }

  /// 시즌 패스 상태 로드
  Future<Map<String, dynamic>?> loadSeasonPass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('season_pass');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] 시즌 패스 로드 오류: $e');
      return null;
    }
  }

  // ── VIP ──

  /// VIP 상태 저장
  Future<void> saveVip(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vip_data', jsonEncode(data));
  }

  /// VIP 상태 로드
  Future<Map<String, dynamic>?> loadVip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('vip_data');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] VIP 로드 오류: $e');
      return null;
    }
  }

  // ── 업적 ──

  /// 업적 상태 저장
  Future<void> saveAchievements(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('achievements', jsonEncode(data));
  }

  /// 업적 상태 로드
  Future<Map<String, dynamic>?> loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('achievements');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] 업적 로드 오류: $e');
      return null;
    }
  }

  // ── 랭킹 ──

  /// 랭킹 상태 저장
  Future<void> saveRankings(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rankings', jsonEncode(data));
  }

  /// 랭킹 상태 로드
  Future<Map<String, dynamic>?> loadRankings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('rankings');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] 랭킹 로드 오류: $e');
      return null;
    }
  }

  // ─── 일일 미션 ───

  /// 일일 미션 상태 저장
  Future<void> saveDailyQuest(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_quest', jsonEncode(data));
  }

  /// 일일 미션 상태 로드
  Future<Map<String, dynamic>?> loadDailyQuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('daily_quest');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] 일일 미션 로드 오류: $e');
      return null;
    }
  }

  // ─── 설화도감 ───

  /// 설화도감 상태 저장
  Future<void> saveLoreCollection(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lore_collection', jsonEncode(data));
  }

  /// 설화도감 상태 로드
  Future<Map<String, dynamic>?> loadLoreCollection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('lore_collection');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] 설화도감 로드 오류: $e');
      return null;
    }
  }

  // ─── 범용 커스텀 데이터 ───

  /// 커스텀 키로 데이터 저장
  Future<void> saveCustomData(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_$key', jsonEncode(data));
  }

  /// 커스텀 키로 데이터 로드
  Future<Map<String, dynamic>?> loadCustomData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('custom_$key');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[SAVE] 커스텀 데이터 로드 오류 ($key): $e');
      return null;
    }
  }
}

