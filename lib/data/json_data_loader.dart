// 해원의 문 - JSON 데이터 로더
// JSON 에셋 파일에서 게임 데이터를 로딩합니다.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../common/enums.dart';
import 'models/enemy_data.dart';
import 'models/hero_data.dart';
import 'models/tower_data.dart';
import 'models/wave_data.dart';
import 'wave_builder.dart';

/// JSON 파일에서 게임 데이터를 로드하는 유틸리티 클래스
class JsonDataLoader {
  JsonDataLoader._();

  /// JSON 로딩 완료 여부
  static bool _isLoaded = false;
  static bool get isLoaded => _isLoaded;

  /// 로드된 데이터 캐시
  static Map<HeroId, HeroData> _heroes = {};
  static Map<EnemyId, EnemyData> _enemies = {};
  static Map<TowerType, TowerData> _towers = {};
  static Map<TowerBranch, TowerBranchData> _branches = {};
  static List<LevelData> _chapter1Levels = [];
  static List<LevelData> _chapter2Levels = [];
  static List<LevelData> _chapter3Levels = [];
  static List<LevelData> _chapter4Levels = [];
  static List<LevelData> _chapter5Levels = [];

  // 외부 접근용 getters
  static Map<HeroId, HeroData> get heroes => _heroes;
  static Map<EnemyId, EnemyData> get enemies => _enemies;
  static Map<TowerType, TowerData> get towers => _towers;
  static Map<TowerBranch, TowerBranchData> get branches => _branches;
  static List<LevelData> get chapter1Levels => _chapter1Levels;
  static List<LevelData> get chapter2Levels => _chapter2Levels;
  static List<LevelData> get chapter3Levels => _chapter3Levels;
  static List<LevelData> get chapter4Levels => _chapter4Levels;
  static List<LevelData> get chapter5Levels => _chapter5Levels;
  static List<LevelData> get allLevels => [
    ..._chapter1Levels,
    ..._chapter2Levels,
    ..._chapter3Levels,
    ..._chapter4Levels,
    ..._chapter5Levels,
  ];

  /// 모든 JSON 데이터를 비동기로 로드합니다.
  static Future<void> loadAll() async {
    if (_isLoaded) return;

    try {
      await Future.wait([
        _loadHeroes(),
        _loadEnemies(),
        _loadTowers(),
        _loadLevels(),
      ]);
      _isLoaded = true;
      if (kDebugMode) {
        print('[JsonDataLoader] ✅ 모든 데이터 로드 완료');
        print('  영웅: ${_heroes.length}명');
        print('  적: ${_enemies.length}종');
        print('  타워: ${_towers.length}종, 분기: ${_branches.length}개');
        print('  레벨: ${allLevels.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[JsonDataLoader] ❌ 데이터 로드 실패: $e');
      }
      rethrow;
    }
  }

  /// 영웅 데이터 로드
  static Future<void> _loadHeroes() async {
    final jsonStr = await rootBundle.loadString('assets/data/heroes.json');
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    final heroMap = <HeroId, HeroData>{};
    for (final item in jsonList) {
      final hero = HeroData.fromJson(item as Map<String, dynamic>);
      heroMap[hero.id] = hero;
    }
    _heroes = heroMap;
  }

  /// 적 데이터 로드
  static Future<void> _loadEnemies() async {
    final jsonStr = await rootBundle.loadString('assets/data/enemies.json');
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    final enemyMap = <EnemyId, EnemyData>{};
    for (final item in jsonList) {
      final enemy = EnemyData.fromJson(item as Map<String, dynamic>);
      enemyMap[enemy.id] = enemy;
    }
    _enemies = enemyMap;
  }

  /// 타워 데이터 로드
  static Future<void> _loadTowers() async {
    final jsonStr = await rootBundle.loadString('assets/data/towers.json');
    final Map<String, dynamic> jsonData =
        json.decode(jsonStr) as Map<String, dynamic>;

    // 타워 기본 데이터
    final towerMap = <TowerType, TowerData>{};
    final towerList = jsonData['towers'] as List<dynamic>;
    for (final item in towerList) {
      final tower = TowerData.fromJson(item as Map<String, dynamic>);
      towerMap[tower.type] = tower;
    }
    _towers = towerMap;

    // Tier 4 분기 데이터
    final branchMap = <TowerBranch, TowerBranchData>{};
    final branchList = jsonData['branches'] as List<dynamic>;
    for (final item in branchList) {
      final branch = TowerBranchData.fromJson(item as Map<String, dynamic>);
      branchMap[branch.branch] = branch;
    }
    _branches = branchMap;
  }

  /// 레벨 데이터 로드 (3챕터)
  static Future<void> _loadLevels() async {
    final results = await Future.wait([
      _loadChapterLevels('assets/data/levels/chapter1.json'),
      _loadChapterLevels('assets/data/levels/chapter2.json'),
      _loadChapterLevels('assets/data/levels/chapter3.json'),
      _loadChapterLevels('assets/data/levels/chapter4.json'),
      _loadChapterLevels('assets/data/levels/chapter5.json'),
    ]);
    _chapter1Levels = results[0];
    _chapter2Levels = results[1];
    _chapter3Levels = results[2];
    _chapter4Levels = results[3];
    _chapter5Levels = results[4];
  }

  /// 개별 챕터 레벨 파일 로드
  static Future<List<LevelData>> _loadChapterLevels(String path) async {
    final jsonStr = await rootBundle.loadString(path);
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    final levels = <LevelData>[];

    for (final item in jsonList) {
      final map = item as Map<String, dynamic>;
      final levelData = LevelData.fromJson(map);

      // waveConfig에서 WaveBuilder로 웨이브 생성
      final waveConfig = map['waveConfig'] as Map<String, dynamic>?;
      if (waveConfig != null) {
        final waves = _buildWavesFromConfig(waveConfig);
        levels.add(LevelData(
          levelNumber: levelData.levelNumber,
          chapter: levelData.chapter,
          name: levelData.name,
          briefing: levelData.briefing,
          startingSinmyeong: levelData.startingSinmyeong,
          gatewayHp: levelData.gatewayHp,
          path: levelData.path,
          waves: waves,
        ));
      } else {
        levels.add(levelData);
      }
    }

    return levels;
  }

  /// waveConfig JSON에서 WaveBuilder로 웨이브 데이터 생성
  static List<WaveData> _buildWavesFromConfig(Map<String, dynamic> config) {
    final type = config['type'] as String;
    final stageNumber = config['stageNumber'] as int;
    final waveCount = config['waveCount'] as int;
    final availableEnemies = (config['availableEnemies'] as List<dynamic>)
        .map((e) => EnemyId.values.firstWhere((id) => id.name == e as String))
        .toList();
    final openingNarrative = config['openingNarrative'] as String?;

    if (type == 'boss') {
      final bossId = EnemyId.values.firstWhere(
        (e) => e.name == config['bossId'] as String,
      );
      final bossNarrative = config['bossNarrative'] as String?;
      return WaveBuilder.buildBoss(
        stageNumber: stageNumber,
        availableEnemies: availableEnemies,
        bossId: bossId,
        waveCount: waveCount,
        openingNarrative: openingNarrative,
        bossNarrative: bossNarrative,
      );
    } else {
      return WaveBuilder.buildNormal(
        stageNumber: stageNumber,
        availableEnemies: availableEnemies,
        waveCount: waveCount,
        openingNarrative: openingNarrative,
      );
    }
  }

  /// 챕터별 레벨 목록 반환
  static List<LevelData> getLevelsForChapter(Chapter chapter) {
    switch (chapter) {
      case Chapter.marketOfHunger:
        return _chapter1Levels;
      case Chapter.wailingWoods:
        return _chapter2Levels;
      case Chapter.facelessForest:
        return _chapter3Levels;
      case Chapter.shadowPalace:
        return _chapter4Levels;
      case Chapter.thresholdOfDeath:
        return _chapter5Levels;
    }
  }
}
