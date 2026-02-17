// 해원의 문 - 게임 맵

import 'package:flame/components.dart';
import 'dart:ui';
import '../../common/constants.dart';

/// 게임 맵 컴포넌트 (경로, 배치 가능 지점 등)
class GameMap extends Component {
  /// 적 이동 경로 (월드 좌표)
  List<Vector2> waypoints = [];

  /// 타워 배치 가능 지점
  List<Vector2> towerSlots = [];

  /// 경로 설정 (그리드 좌표 → 월드 좌표 변환)
  void setPath(List<List<int>> gridPath) {
    waypoints = gridPath.map((coord) {
      return Vector2(
        coord[0] * GameConstants.tileSize + GameConstants.tileSize / 2,
        coord[1] * GameConstants.tileSize + GameConstants.tileSize / 2,
      );
    }).toList();

    // 경로 주변에 타워 배치 지점 자동 생성
    _generateTowerSlots();
  }

  void _generateTowerSlots() {
    towerSlots.clear();
    final used = <String>{};

    for (final wp in waypoints) {
      // 경로 양쪽에 배치 지점 생성
      final offsets = [
        Vector2(0, -GameConstants.tileSize),
        Vector2(0, GameConstants.tileSize),
        Vector2(-GameConstants.tileSize, 0),
        Vector2(GameConstants.tileSize, 0),
      ];

      for (final offset in offsets) {
        final slot = wp + offset;
        final key = '${slot.x.toInt()}_${slot.y.toInt()}';

        // 범위 체크 및 중복 제거
        if (slot.x > 0 &&
            slot.x < GameConstants.gameWidth &&
            slot.y > 0 &&
            slot.y < GameConstants.gameHeight &&
            !used.contains(key) &&
            !_isOnPath(slot)) {
          towerSlots.add(slot);
          used.add(key);
        }
      }
    }
  }

  bool _isOnPath(Vector2 pos) {
    for (final wp in waypoints) {
      if (pos.distanceTo(wp) < GameConstants.tileSize * 0.5) return true;
    }
    return false;
  }
}
