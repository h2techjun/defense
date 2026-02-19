// 해원의 문 - 게임 데이터 로더
// JSON 에셋 기반 데이터 로딩 (v2.0 — 하드코딩 제거)

import 'package:flutter/foundation.dart';

import '../common/enums.dart';
import 'models/hero_data.dart';
import 'models/enemy_data.dart';
import 'models/tower_data.dart';
import 'models/wave_data.dart';
import 'json_data_loader.dart';

/// 게임 데이터 레지스트리 — JSON 전용
///
/// 앱 시작 시 반드시 [initFromJson]을 호출해야 합니다.
/// 모든 데이터는 `assets/data/` JSON 에셋에서 로드됩니다.
class GameDataLoader {
  GameDataLoader._();

  /// 초기화 여부
  static bool _initialized = false;

  /// 앱 시작 시 호출하여 JSON 데이터 로드 (필수)
  static Future<void> initFromJson() async {
    try {
      await JsonDataLoader.loadAll();
      _initialized = true;
      if (kDebugMode) {
        print('[GameDataLoader] ✅ JSON 데이터 로드 완료');
      }
    } catch (e) {
      _initialized = false;
      if (kDebugMode) {
        print('[GameDataLoader] ❌ JSON 로드 실패: $e');
      }
      rethrow; // 앱 시작 시 반드시 성공해야 함
    }
  }

  /// 초기화 확인 가드
  static void _ensureInitialized() {
    assert(_initialized, 'GameDataLoader.initFromJson()을 먼저 호출하세요');
  }

  // ──────────────────────────────
  // 데이터 접근자 (JSON 전용)
  // ──────────────────────────────

  /// 영웅 데이터
  static Map<HeroId, HeroData> getHeroes() {
    _ensureInitialized();
    return JsonDataLoader.heroes;
  }

  /// 적 데이터
  static Map<EnemyId, EnemyData> getEnemies() {
    _ensureInitialized();
    return JsonDataLoader.enemies;
  }

  /// 타워 데이터
  static Map<TowerType, TowerData> getTowers() {
    _ensureInitialized();
    return JsonDataLoader.towers;
  }

  /// 분기 데이터
  static Map<TowerBranch, TowerBranchData> getBranches() {
    _ensureInitialized();
    return JsonDataLoader.branches;
  }

  /// 전체 레벨 데이터
  static List<LevelData> getAllLevels() {
    _ensureInitialized();
    return JsonDataLoader.allLevels;
  }

  /// 챕터별 레벨 접근
  static List<LevelData> getLevelsForChapterSafe(Chapter chapter) {
    _ensureInitialized();
    return JsonDataLoader.getLevelsForChapter(chapter);
  }
}
