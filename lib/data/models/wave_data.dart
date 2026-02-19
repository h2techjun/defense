// 해원의 문 - 웨이브 데이터 모델

import '../../common/enums.dart';
import 'map_object_data.dart';

/// 웨이브 내 적 스폰 그룹
class SpawnGroup {
  final EnemyId enemyId;
  final int count;
  final double spawnInterval; // 적 사이 간격 (초)
  final double startDelay; // 그룹 시작 지연 (초)

  const SpawnGroup({
    required this.enemyId,
    required this.count,
    this.spawnInterval = 1.2,
    this.startDelay = 0,
  });

  /// JSON → SpawnGroup
  factory SpawnGroup.fromJson(Map<String, dynamic> json) {
    return SpawnGroup(
      enemyId: EnemyId.values.firstWhere((e) => e.name == json['enemyId']),
      count: json['count'] as int,
      spawnInterval: (json['spawnInterval'] as num?)?.toDouble() ?? 1.2,
      startDelay: (json['startDelay'] as num?)?.toDouble() ?? 0,
    );
  }

  /// SpawnGroup → JSON
  Map<String, dynamic> toJson() => {
    'enemyId': enemyId.name,
    'count': count,
    if (spawnInterval != 1.2) 'spawnInterval': spawnInterval,
    if (startDelay != 0) 'startDelay': startDelay,
  };
}

/// 웨이브 데이터
class WaveData {
  final int waveNumber;
  final DayCycle dayCycle;
  final List<SpawnGroup> spawnGroups;
  final String? narrative; // 웨이브 시작 시 표시할 텍스트

  const WaveData({
    required this.waveNumber,
    required this.dayCycle,
    required this.spawnGroups,
    this.narrative,
  });

  /// JSON → WaveData
  factory WaveData.fromJson(Map<String, dynamic> json) {
    return WaveData(
      waveNumber: json['waveNumber'] as int,
      dayCycle: DayCycle.values.firstWhere((e) => e.name == json['dayCycle']),
      spawnGroups: (json['spawnGroups'] as List<dynamic>)
          .map((g) => SpawnGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
      narrative: json['narrative'] as String?,
    );
  }

  /// WaveData → JSON
  Map<String, dynamic> toJson() => {
    'waveNumber': waveNumber,
    'dayCycle': dayCycle.name,
    'spawnGroups': spawnGroups.map((g) => g.toJson()).toList(),
    if (narrative != null) 'narrative': narrative,
  };
}

/// 레벨(스테이지) 데이터
class LevelData {
  final int levelNumber;
  final Chapter chapter;
  final String name;
  final String briefing;
  final int startingSinmyeong;
  final int gatewayHp;
  final List<WaveData> waves;
  final List<List<int>> path; // 적 이동 경로 [[x,y], [x,y], ...]
  final List<MapObjectData> mapObjects; // 인터랙티브 맵 오브젝트

  const LevelData({
    required this.levelNumber,
    required this.chapter,
    required this.name,
    required this.briefing,
    required this.startingSinmyeong,
    required this.gatewayHp,
    required this.waves,
    required this.path,
    this.mapObjects = const [],
  });

  /// JSON → LevelData (WaveBuilder 파라미터 기반)
  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      levelNumber: json['levelNumber'] as int,
      chapter: Chapter.values.firstWhere((e) => e.name == json['chapter']),
      name: json['name'] as String,
      briefing: json['briefing'] as String,
      startingSinmyeong: json['startingSinmyeong'] as int,
      gatewayHp: json['gatewayHp'] as int,
      waves: const [], // 런타임에 WaveBuilder가 채움
      path: (json['path'] as List<dynamic>)
          .map((p) => (p as List<dynamic>).map((v) => v as int).toList())
          .toList(),
      mapObjects: (json['mapObjects'] as List<dynamic>?)
          ?.map((m) => MapObjectData.fromJson(m as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  /// LevelData → JSON (메타정보만 — 웨이브는 WaveBuilder 파라미터로 저장)
  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'chapter': chapter.name,
    'name': name,
    'briefing': briefing,
    'startingSinmyeong': startingSinmyeong,
    'gatewayHp': gatewayHp,
    'path': path,
    if (mapObjects.isNotEmpty)
      'mapObjects': mapObjects.map((m) => m.toJson()).toList(),
  };
}
