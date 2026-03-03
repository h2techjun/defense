import 'dart:convert';
import 'dart:io';

// Mock enums
enum EnemyId {
  hungryGhost,
  strawShoeSpirit,
  burdenedLaborer,
}

void main() async {
  final f = File('e:/defense/assets/data/levels/chapter1.json');
  final txt = await f.readAsString();
  final list = json.decode(txt) as List;
  
  final level1 = list.firstWhere((e) => e['levelNumber'] == 1);
  final waveConfig = level1['waveConfig'];
  
  print('Level 1 waveConfig: $waveConfig');
  
  final enemiesRaw = waveConfig['availableEnemies'] as List;
  print('Raw available: $enemiesRaw');
  
  final available = enemiesRaw.map((e) => EnemyId.values.firstWhere((id) => id.name == e, orElse: () => EnemyId.hungryGhost)).toList();
  print('Parsed Enums: $available');
  
  final waveCount = waveConfig['waveCount'] as int;
  final stageNumber = waveConfig['stageNumber'] as int;
  final difficulty = stageNumber;
  
  for(int w=1; w<=waveCount; w++) {
    final baseCount = (3 + (difficulty * 0.15 + w * 0.5)).round().clamp(3, 12);
    final interval = (2.0 - 0 * 1.0).clamp(0.6, 2.5);
    final mainIdx = (w - 1) % available.length;
    final mainEnemy = available[mainIdx];
    print('Wave $w: Main Enemy: ${mainEnemy.name}, Count: $baseCount, Interval: $interval');
  }
}
