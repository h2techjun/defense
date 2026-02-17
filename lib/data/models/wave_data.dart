// 해원의 문 - 웨이브 데이터 모델

import '../../common/enums.dart';

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

  const LevelData({
    required this.levelNumber,
    required this.chapter,
    required this.name,
    required this.briefing,
    required this.startingSinmyeong,
    required this.gatewayHp,
    required this.waves,
    required this.path,
  });
}
