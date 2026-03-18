import 'dart:ui';
import 'package:flame/components.dart';
import '../components/actors/base_enemy.dart';

/// 단순 격자(Grid) 기반 공간 분할 시스템 (Spatial Hashing)
/// 타워 투사체(Projectile)의 관통/스플래시 연산 최적화를 위해 사용됩니다.
class GridSystem {
  final double cellSize;
  // 각 격자 셀(Key: "X_Y")에 들어있는 적 목록
  final Map<String, List<BaseEnemy>> _cells = {};

  GridSystem({this.cellSize = 80.0});

  /// 매 프레임 살아있는 적 목록을 기반으로 격자를 업데이트합니다.
  void updateGrid(List<BaseEnemy> aliveEnemies) {
    // 모든 셀 비우기
    _cells.clear();

    for (final enemy in aliveEnemies) {
      if (enemy.isDead || !enemy.isMounted) continue;

      final key = _getCellKey(enemy.position);
      if (!_cells.containsKey(key)) {
        _cells[key] = [];
      }
      _cells[key]!.add(enemy);
    }
  }

  /// 특정 좌표 주변의 적 목록을 반환합니다. 
  /// (주어진 위치의 셀 + 인접 8개 바운더리를 포함해 최대 9개 셀의 적 리스트)
  List<BaseEnemy> getEnemiesNear(Vector2 position, double range) {
    final List<BaseEnemy> nearbyEnemies = [];
    
    // 만약 탐색 범위가 cell 사이즈를 넘어서면 더 많은 셀을 봐야 하지만,
    // 일반적으로 Projectile 관통범위는 30~50 정도이므로 인접 1칸(9셀)으로 충분합니다.
    final int cellRangePattern = (range / cellSize).ceil().clamp(1, 3);

    final int cx = (position.x / cellSize).floor();
    final int cy = (position.y / cellSize).floor();

    for (int x = cx - cellRangePattern; x <= cx + cellRangePattern; x++) {
      for (int y = cy - cellRangePattern; y <= cy + cellRangePattern; y++) {
        final key = '${x}_$y';
        final cellEnemies = _cells[key];
        if (cellEnemies != null) {
          nearbyEnemies.addAll(cellEnemies);
        }
      }
    }

    return nearbyEnemies;
  }

  /// 좌표를 격자 키 문자열("X_Y")로 변환
  String _getCellKey(Vector2 pos) {
    final x = (pos.x / cellSize).floor();
    final y = (pos.y / cellSize).floor();
    return '${x}_$y';
  }
}
