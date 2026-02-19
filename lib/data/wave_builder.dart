// 해원의 문 — 웨이브 자동 생성기
// 스테이지 난이도에 따라 10~15 웨이브를 자동 빌드

import '../common/enums.dart';
import 'models/wave_data.dart';
import 'models/endless_tower_data.dart';

/// 웨이브 빌더 — 스테이지 파라미터 기반 자동 생성
class WaveBuilder {
  WaveBuilder._();

  /// 일반 스테이지용 (10~12 웨이브)
  static List<WaveData> buildNormal({
    required int stageNumber,
    required List<EnemyId> availableEnemies,
    int waveCount = 10,
    String? openingNarrative,
  }) {
    final waves = <WaveData>[];
    final difficulty = stageNumber; // 1~20

    for (int w = 1; w <= waveCount; w++) {
      final isNight = w % 3 == 0 || w > waveCount - 2;
      final cycle = isNight ? DayCycle.night : DayCycle.day;
      final phase = w / waveCount; // 0.0 ~ 1.0 진행률

      String? narrative;
      if (w == 1 && openingNarrative != null) narrative = openingNarrative;
      if (w == waveCount) narrative = '"마지막 파도가 다가온다..."';

      // 기본 스폰 수 = 웹 성능 안전 범위 (3~12마리, 동시 30마리 이하)
      final baseCount = (3 + (difficulty * 0.15 + w * 0.5)).round().clamp(3, 12);
      final interval = (2.0 - phase * 1.0).clamp(0.6, 2.5);
      // HP 보정 (난이도 유지 — 완화된 곡선)
      final hpScale = 1.0 + phase * 0.5 + difficulty * 0.08;

      final groups = <SpawnGroup>[];

      // 메인 적 (항상)
      final mainIdx = (w - 1) % availableEnemies.length;
      groups.add(SpawnGroup(
        enemyId: availableEnemies[mainIdx],
        count: baseCount,
        spawnInterval: interval,
      ));

      // 서브 적 (3웨이브부터, 메인의 40% — 합계 캡 적용)
      if (w >= 3 && availableEnemies.length > 1) {
        final subIdx = (w) % availableEnemies.length;
        if (subIdx != mainIdx) {
          groups.add(SpawnGroup(
            enemyId: availableEnemies[subIdx],
            count: (baseCount * 0.4).round().clamp(2, 6),
            spawnInterval: interval + 0.5,
            startDelay: 5,
          ));
        }
      }

      // 3번째 적 (후반부부터, 소수)
      if (w >= waveCount * 0.7 && availableEnemies.length > 2) {
        final thirdIdx = (w + 2) % availableEnemies.length;
        groups.add(SpawnGroup(
          enemyId: availableEnemies[thirdIdx],
          count: (baseCount * 0.25).round().clamp(2, 4),
          spawnInterval: interval + 0.8,
          startDelay: 8,
        ));
      }

      waves.add(WaveData(
        waveNumber: w,
        dayCycle: cycle,
        narrative: narrative,
        spawnGroups: groups,
      ));
    }
    return waves;
  }

  /// 보스 스테이지용 (10 웨이브 — 마지막에 보스)
  static List<WaveData> buildBoss({
    required int stageNumber,
    required List<EnemyId> availableEnemies,
    required EnemyId bossId,
    int waveCount = 12,
    String? openingNarrative,
    String? bossNarrative,
  }) {
    // 보스 전 일반 웨이브 (waveCount - 1개)
    final waves = buildNormal(
      stageNumber: stageNumber,
      availableEnemies: availableEnemies,
      waveCount: waveCount - 1,
      openingNarrative: openingNarrative,
    );

    // 마지막 웨이브의 내러티브 수정
    if (waves.isNotEmpty) {
      final lastNormal = waves.last;
      waves[waves.length - 1] = WaveData(
        waveNumber: lastNormal.waveNumber,
        dayCycle: DayCycle.night,
        narrative: '"무언가 거대한 것이 다가온다..."',
        spawnGroups: lastNormal.spawnGroups,
      );
    }

    // 보스 웨이브 — 호위 강화 (영웅 추가 후 밸런스)
    final escortCount = (3 + stageNumber * 0.15).round().clamp(3, 8);
    final bossGroups = <SpawnGroup>[
      SpawnGroup(enemyId: bossId, count: 1, spawnInterval: 1),
      // 1차 호위 — 즉시
      SpawnGroup(
        enemyId: availableEnemies[0],
        count: (escortCount * 0.5).round().clamp(3, 6),
        spawnInterval: 2.0,
        startDelay: 3,
      ),
      // 2차 호위 — 15초 후
      SpawnGroup(
        enemyId: availableEnemies[availableEnemies.length > 1 ? 1 : 0],
        count: (escortCount * 0.4).round().clamp(2, 5),
        spawnInterval: 1.8,
        startDelay: 15,
      ),
      // 3차 호위 — 30초 후
      if (availableEnemies.length > 2)
        SpawnGroup(
          enemyId: availableEnemies[2],
          count: (escortCount * 0.3).round().clamp(2, 4),
          spawnInterval: 2.0,
          startDelay: 30,
        ),
    ];

    waves.add(WaveData(
      waveNumber: waveCount,
      dayCycle: DayCycle.night,
      narrative: bossNarrative ?? '"보스가 나타났다!"',
      spawnGroups: bossGroups,
    ));

    return waves;
  }

  /// 무한의 탑 — 층 데이터 기반 웨이브 생성
  static List<WaveData> buildEndlessTowerFloor(TowerFloorData floor) {
    if (floor.type == TowerFloorType.rest) return [];

    // 난이도 배율을 가상 스테이지 번호로 변환
    final virtualStage = (floor.difficultyScale * 5).round().clamp(1, 50);

    if (floor.type == TowerFloorType.boss && floor.bossId != null) {
      return buildBoss(
        stageNumber: virtualStage,
        availableEnemies: floor.availableEnemies,
        bossId: floor.bossId!,
        waveCount: floor.waveCount,
        openingNarrative: '"${floor.floor}층 — 탑의 주인이 기다린다"',
        bossNarrative: floor.narrative,
      );
    }

    // 일반/엘리트 — buildNormal 사용
    final waves = buildNormal(
      stageNumber: virtualStage,
      availableEnemies: floor.availableEnemies,
      waveCount: floor.waveCount,
      openingNarrative: floor.narrative ?? '"${floor.floor}층에 도달했다."',
    );

    // 엘리트: 적 수 +30%, 인터벌 -20%
    if (floor.type == TowerFloorType.elite) {
      return waves.map((w) => WaveData(
        waveNumber: w.waveNumber,
        dayCycle: w.dayCycle,
        narrative: w.narrative,
        spawnGroups: w.spawnGroups.map((g) => SpawnGroup(
          enemyId: g.enemyId,
          count: (g.count * 1.3).round(),
          spawnInterval: g.spawnInterval * 0.8,
          startDelay: g.startDelay,
        )).toList(),
      )).toList();
    }

    return waves;
  }
}

