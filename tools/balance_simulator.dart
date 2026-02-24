// tools/balance_simulator.dart
// 타워 DPS vs 적 HP 밸런스를 자동 검증하는 도구

import 'dart:convert';
import 'dart:io';
import 'dart:math';

// 에뮬레이션할 기본 데이터 구조들
class MockTower {
  final String id;
  final String name;
  final int cost;
  final double damage;
  final double fireRate;
  final String damageType;

  MockTower({
    required this.id,
    required this.name,
    required this.cost,
    required this.damage,
    required this.fireRate,
    required this.damageType,
  });

  double get dps => damage * fireRate;
}

class MockEnemy {
  final String id;
  final String name;
  final double hp;
  final double speed;
  final String armorType;
  final bool isFlying;

  MockEnemy({
    required this.id,
    required this.name,
    required this.hp,
    required this.speed,
    required this.armorType,
    this.isFlying = false,
  });
}

class SpawnGroup {
  final String enemyId;
  final int count;
  final double spawnInterval;
  final double startDelay;

  SpawnGroup({
    required this.enemyId,
    required this.count,
    this.spawnInterval = 1.2,
    this.startDelay = 0,
  });
}

void main() async {
  print('=== 🏯 Gateway of Regrets: Balance Simulator ===\n');

  // 1. 데이터 로드
  final towersFile = File('assets/data/towers.json');
  final enemiesFile = File('assets/data/enemies.json');

  if (!towersFile.existsSync() || !enemiesFile.existsSync()) {
    print('Error: Data files not found at assets/data/');
    return;
  }

  final towersData = jsonDecode(await towersFile.readAsString());
  final List enemiesData = jsonDecode(await enemiesFile.readAsString());

  final Map<String, MockTower> towerMap = {};
  for (var t in towersData['towers']) {
    towerMap[t['type']] = MockTower(
      id: t['type'],
      name: t['name'],
      cost: t['baseCost'],
      damage: (t['baseDamage'] as num).toDouble(),
      fireRate: (t['baseFireRate'] as num).toDouble(),
      damageType: t['damageType'],
    );
  }

  final Map<String, MockEnemy> enemyMap = {};
  for (var e in enemiesData) {
    enemyMap[e['id']] = MockEnemy(
      id: e['id'],
      name: e['name'],
      hp: (e['hp'] as num).toDouble(),
      speed: (e['speed'] as num).toDouble(),
      armorType: e['armorType'],
      isFlying: e['isFlying'] ?? false,
    );
  }

  // 2. 스테이지 폴더 순회
  final levelDir = Directory('assets/data/levels');
  if (!levelDir.existsSync()) {
    print('Error: Levels directory not found');
    return;
  }

  final levelFiles = levelDir.listSync().where((f) => f.path.endsWith('.json')).toList();
  levelFiles.sort((a, b) => a.path.compareTo(b.path));

  print('${"Stage".padRight(20)} | ${"Wave".padRight(5)} | ${"Total HP".padRight(10)} | ${"Req. DPS".padRight(10)} | ${"Avail DPS".padRight(10)} | Status');
  print('-' * 85);

  for (var file in levelFiles) {
    if (file is File) {
      final List levels = jsonDecode(await file.readAsString());
      for (var lvl in levels) {
        final int stageNum = lvl['levelNumber'];
        final String stageName = lvl['name'];
        final int startSinmyeong = lvl['startingSinmyeong'];
        final List path = lvl['path'];
        final waveConfig = lvl['waveConfig'];

        if (waveConfig == null) continue;

        // 경로 길이 계산 (그리드 -> 픽셀)
        double gridLength = 0;
        for (int i = 0; i < path.length - 1; i++) {
          final p1 = path[i];
          final p2 = path[i + 1];
          gridLength += sqrt(pow(p2[0] - p1[0], 2) + pow(p2[1] - p1[1], 2));
        }
        final pixelLength = gridLength * 64.0;

        // 웨이브 생성 (WaveBuilder 로직 모사)
        final int waveCount = waveConfig['waveCount'] ?? 10;
        final List availableEnemiesStr = (waveConfig['availableEnemies'] as List).cast<String>();
        final String? bossId = waveConfig['bossId'];

        for (int w = 1; w <= waveCount; w++) {
          final isBossWave = (waveConfig['type'] == 'boss' && w == waveCount);
          final phase = w / waveCount;
          final hpScale = 1.0 + phase * 0.5 + stageNum * 0.08;
          final userScaling = 1.3; // 평균적인 상향 보정값 (Lv 10 타워/영웅 등)

          double totalHp = 0;
          double avgSpeed = 0;
          int enemyCount = 0;

          List<SpawnGroup> groups = [];
          if (isBossWave && bossId != null) {
            groups.add(SpawnGroup(enemyId: bossId, count: 1));
            final escortCount = (3 + stageNum * 0.15).round().clamp(3, 8);
            groups.add(SpawnGroup(enemyId: availableEnemiesStr[0], count: escortCount));
          } else {
            final mainIdx = (w - 1) % availableEnemiesStr.length;
            final count = (3 + (stageNum * 0.15 + w * 0.5)).round().clamp(3, 12);
            groups.add(SpawnGroup(enemyId: availableEnemiesStr[mainIdx], count: count));
          }

          for (var g in groups) {
            final e = enemyMap[g.enemyId];
            if (e != null) {
              totalHp += e.hp * g.count * hpScale * userScaling;
              avgSpeed += e.speed * g.count;
              enemyCount += g.count;
            }
          }

          if (enemyCount > 0) avgSpeed /= enemyCount;

          // 경로 통과 시간 (초)
          final timeOnPath = pixelLength / (avgSpeed > 0 ? avgSpeed : 1);
          final requiredDps = totalHp / timeOnPath;

          // 가용 DPS 계산 (가장 기본인 궁수탑 스팸 기준으로 판정)
          final archer = towerMap['archer']!;
          final towerCount = (startSinmyeong / archer.cost).floor();
          final availableDps = towerCount * archer.dps;

          // 보수적으로 가용 DPS의 1.5배(영웅 스킬, 타워 업그레이드 등 고려)가 요구 DPS보다 높으면 합격
          final status = (availableDps * 1.5 >= requiredDps) ? '✅ PASS' : '🔴 HARD';

          // 일부 웨이브만 출력 (첫 웨이브, 중간 웨이브, 마지막/보스 웨이브)
          if (isBossWave || w == 1 || w == waveCount ~/ 2) {
            final stageDisp = "$stageNum. $stageName";
            final stageCrop = stageDisp.length > 20 ? stageDisp.substring(0, 17) + "..." : stageDisp;
            print('${stageCrop.padRight(20)} | ${w.toString().padRight(5)} | ${totalHp.toInt().toString().padRight(10)} | ${requiredDps.toStringAsFixed(1).padRight(10)} | ${availableDps.toStringAsFixed(1).padRight(10)} | $status');
          }
        }
      }
    }
  }
}
