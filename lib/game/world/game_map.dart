// 해원의 문 - 게임 맵
// 경로 시각화, 타워 배치 가능 지점 관리
// 최적화: 배경+도로를 Picture→Image로 캐시 (600+개 Component → 2개 이미지)

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../common/constants.dart';

/// 게임 맵 컴포넌트 (경로, 배치 가능 지점 등)
class GameMap extends Component {
  /// 적 이동 경로 (월드 좌표)
  List<Vector2> waypoints = [];

  /// 타워 배치 가능 지점
  List<Vector2> towerSlots = [];

  /// 이미 타워가 배치된 슬롯 인덱스
  final Set<int> _occupiedSlots = {};

  /// 시각 요소가 이미 추가되었는지 추적
  bool _visualsAdded = false;

  /// setPath가 mount 전에 호출되었는지 추적
  bool _pendingVisuals = false;

  /// 슬롯 비주얼 컴포넌트 참조 (index → visual)
  final Map<int, _TowerSlotVisual> _slotVisuals = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (kDebugMode) debugPrint('GameMap.onLoad started');
  }

  @override
  void onMount() {
    super.onMount();
    if (kDebugMode) debugPrint('GameMap.onMount — isMounted: $isMounted');

    // 배경을 래스터 이미지로 캐시
    _renderBackgroundToImage();

    // 만약 mount 전에 setPath가 호출되었다면, 지금 시각 그리기
    if (_pendingVisuals) {
      if (kDebugMode) debugPrint('GameMap: Processing pending visuals in onMount');
      _pendingVisuals = false;
      _addVisuals();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Failsafe: waypoints가 있지만 시각 요소가 렌더링되지 않았다면 강제 렌더링
    if (waypoints.isNotEmpty && !_visualsAdded && isMounted) {
      if (kDebugMode) debugPrint('GameMap.update: Failsafe — forcing visual render');
      _addVisuals();
    }
  }

  // ──────────────────────────────────────────────
  // 배경 래스터 캐시 (기존 ~270개 Component → 1개 이미지)
  // ──────────────────────────────────────────────

  /// 배경 타일을 Canvas에 직접 그리고 Image로 래스터화
  void _renderBackgroundToImage() {
    final w = GameConstants.gameWidth;
    final h = GameConstants.gameHeight;
    final ts = GameConstants.tileSize;
    final rng = math.Random(42); // 고정 시드로 일관된 패턴

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // 1) 베이스 배경
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1E1538),
    );

    // 2) 타일별 색상 그리기
    int col = 0;
    for (double x = 0; x < w; x += ts) {
      int row = 0;
      for (double y = 0; y < h; y += ts) {
        final noise = rng.nextDouble();
        final yRatio = y / h;

        // 상단: 어두운 산 / 하단: 짙은 풀밭 느낌
        final baseR = (30 + yRatio * 15 + noise * 8).toInt().clamp(0, 255);
        final baseG = (20 + yRatio * 25 + noise * 12).toInt().clamp(0, 255);
        final baseB = (50 + (1 - yRatio) * 30 + noise * 10).toInt().clamp(0, 255);

        // 체크무늬 미세 변조
        final isDark = (col + row) % 2 == 0;
        final adjust = isDark ? 0 : 8;

        canvas.drawRect(
          Rect.fromLTWH(x, y, ts, ts),
          Paint()
            ..color = Color.fromARGB(
              255,
              (baseR + adjust).clamp(0, 255),
              (baseG + adjust).clamp(0, 255),
              (baseB + adjust).clamp(0, 255),
            ),
        );

        // 3) 미세 그리드 라인 (희미한 격자)
        if (isDark) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, ts, ts),
            Paint()
              ..color = const Color(0x08FFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.3,
          );
        }

        // 4) 랜덤 풀/점 장식 (일부 타일에만)
        if (noise > 0.85) {
          final dotSize = 1.5 + rng.nextDouble() * 2;
          final dotX = x + rng.nextDouble() * (ts - dotSize);
          final dotY = y + rng.nextDouble() * (ts - dotSize);
          canvas.drawCircle(
            Offset(dotX + dotSize, dotY + dotSize),
            dotSize,
            Paint()
              ..color = Color.fromARGB(
                (30 + noise * 30).toInt(),
                40 + rng.nextInt(30),
                80 + rng.nextInt(40),
                30 + rng.nextInt(20),
              ),
          );
        }

        row++;
      }
      col++;
    }

    // 5) 맵 가장자리 비네팅 효과
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 40),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h - 30, w, 30),
      Paint()..color = const Color(0x33000000),
    );

    final picture = recorder.endRecording();
    picture.toImage(w.toInt(), h.toInt()).then((image) {
      add(SpriteComponent(
        sprite: Sprite(image),
        position: Vector2.zero(),
        size: Vector2(w, h),
        priority: -1,
      ));
      if (kDebugMode) debugPrint('GameMap: Background rasterized to single image');
    });
  }

  // ──────────────────────────────────────────────
  // 경로/도로 래스터 캐시 (기존 ~100+개 Component → 1개 이미지)
  // ──────────────────────────────────────────────

  /// 도로+점선+입출구를 Canvas에 직접 그리고 Image로 래스터화
  void _renderPathToImage() {
    if (waypoints.isEmpty) return;

    final w = GameConstants.gameWidth;
    final h = GameConstants.gameHeight;
    final ts = GameConstants.tileSize;
    final pathTilesDrawn = <String>{};

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. 경로 도로 타일 (황토색 사각형 채우기)
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final dir = (end - start);
      final length = dir.length;
      final normalized = dir.normalized();
      const step = 8.0;

      for (double d = 0; d <= length; d += step) {
        final pos = start + normalized * d;
        final gx = (pos.x / ts).floor();
        final gy = (pos.y / ts).floor();
        final key = '$gx,$gy';
        if (pathTilesDrawn.contains(key)) continue;
        pathTilesDrawn.add(key);

        // 도로 타일
        canvas.drawRect(
          Rect.fromLTWH(gx * ts, gy * ts, ts, ts),
          Paint()..color = const Color(0xFF6B5B3A),
        );
        // 도로 테두리
        canvas.drawRect(
          Rect.fromLTWH(gx * ts, gy * ts, ts, ts),
          Paint()
            ..color = const Color(0x33000000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // 경로 중앙 점선 (방향 안내)
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final dir = (end - start);
      final length = dir.length;
      final normalized = dir.normalized();

      for (double d = 0; d < length; d += 24.0) {
        final pos = start + normalized * d;
        canvas.drawCircle(
          Offset(pos.x, pos.y),
          2.5,
          Paint()..color = const Color(0x55FFD700),
        );
      }
    }

    // 시작/끝 표시
    if (waypoints.isNotEmpty) {
      // 입구 (초록 마커)
      canvas.drawCircle(
        Offset(waypoints.first.x, waypoints.first.y),
        10,
        Paint()..color = const Color(0xAA00FF66),
      );
      // 출구 (빨간 마커)
      canvas.drawCircle(
        Offset(waypoints.last.x, waypoints.last.y),
        10,
        Paint()..color = const Color(0xAAFF4444),
      );
    }

    final picture = recorder.endRecording();
    picture.toImage(w.toInt(), h.toInt()).then((image) {
      add(SpriteComponent(
        sprite: Sprite(image),
        position: Vector2.zero(),
        size: Vector2(w, h),
        priority: 2,
      ));
      if (kDebugMode) debugPrint('GameMap: Path rasterized to single image');
    });
  }

  /// 경로 설정 (그리드 좌표 → 월드 좌표 변환)
  void setPath(List<List<int>> gridPath) {
    if (kDebugMode) debugPrint('GameMap.setPath called with ${gridPath.length} points');

    waypoints = gridPath.map((coord) {
      return Vector2(
        coord[0] * GameConstants.tileSize + GameConstants.tileSize / 2,
        coord[1] * GameConstants.tileSize + GameConstants.tileSize / 2,
      );
    }).toList();

    if (kDebugMode) {
      debugPrint('GameMap: Generated ${waypoints.length} waypoints');
      for (int i = 0; i < waypoints.length; i++) {
        debugPrint('  wp[$i]: (${waypoints[i].x}, ${waypoints[i].y})');
      }
    }

    // 경로 주변에 타워 배치 지점 자동 생성
    _generateTowerSlots();

    if (kDebugMode) debugPrint('GameMap: Generated ${towerSlots.length} tower slots');

    // 시각 요소 추가 — 마운트 상태에 따라 즉시 또는 지연
    _visualsAdded = false; // 리셋
    if (isMounted) {
      _clearPathVisuals();
      _addVisuals();
    } else {
      if (kDebugMode) debugPrint('GameMap: Not mounted yet, deferring visuals');
      _pendingVisuals = true;
    }
  }

  /// 경로/슬롯 시각 요소만 제거 (배경 캐시 이미지는 유지)
  void _clearPathVisuals() {
    // 도로 캐시 이미지 제거 (priority 2의 SpriteComponent)
    final sprites = children.whereType<SpriteComponent>()
        .where((s) => s.priority == 2)
        .toList();
    for (final s in sprites) {
      s.removeFromParent();
    }
    // 슬롯 비주얼 제거
    final slotVisuals = children.whereType<_TowerSlotVisual>().toList();
    for (final s in slotVisuals) {
      s.removeFromParent();
    }
    _slotVisuals.clear();

    if (kDebugMode) {
      debugPrint('GameMap._clearPathVisuals: removed ${sprites.length} path images, ${slotVisuals.length} slots');
    }
  }

  void _generateTowerSlots() {
    towerSlots.clear();
    _occupiedSlots.clear();
    final used = <String>{};
    final ts = GameConstants.tileSize;

    // 경로 위의 모든 타일을 기록 (웨이포인트 + 중간 타일 포함)
    final pathTiles = <String>{};
    for (final wp in waypoints) {
      final gx = (wp.x ~/ ts).toInt();
      final gy = (wp.y ~/ ts).toInt();
      pathTiles.add('${gx}_$gy');
    }

    // 웨이포인트 사이의 모든 중간 타일도 경로로 기록
    for (int i = 0; i < waypoints.length - 1; i++) {
      final startGx = (waypoints[i].x ~/ ts).toInt();
      final startGy = (waypoints[i].y ~/ ts).toInt();
      final endGx = (waypoints[i + 1].x ~/ ts).toInt();
      final endGy = (waypoints[i + 1].y ~/ ts).toInt();

      // 수평 이동
      if (startGy == endGy) {
        final minX = startGx < endGx ? startGx : endGx;
        final maxX = startGx > endGx ? startGx : endGx;
        for (int x = minX; x <= maxX; x++) {
          pathTiles.add('${x}_${startGy}');
        }
      }
      // 수직 이동
      else if (startGx == endGx) {
        final minY = startGy < endGy ? startGy : endGy;
        final maxY = startGy > endGy ? startGy : endGy;
        for (int y = minY; y <= maxY; y++) {
          pathTiles.add('${startGx}_$y');
        }
      }
    }

    if (kDebugMode) debugPrint('GameMap: ${pathTiles.length} path tiles identified');

    // 경로 인접 타일에만 배치 지점 생성 (경로 위 제외)
    final offsets = [
      [0, -1], [0, 1], [-1, 0], [1, 0],  // 상하좌우
    ];

    for (final pathKey in pathTiles) {
      final parts = pathKey.split('_');
      final px = int.parse(parts[0]);
      final py = int.parse(parts[1]);

      for (final offset in offsets) {
        final nx = px + offset[0];
        final ny = py + offset[1];
        final key = '${nx}_$ny';

        // 범위 체크, 중복 제거, 경로 위 제외
        // 상단 1행(HUD)과 하단 1행(타워 패널) 제외
        if (nx >= 0 &&
            nx < GameConstants.mapColumns &&
            ny >= 1 &&
            ny < GameConstants.mapRows - 1 &&
            !used.contains(key) &&
            !pathTiles.contains(key)) {
          towerSlots.add(Vector2(
            nx * ts + ts / 2,
            ny * ts + ts / 2,
          ));
          used.add(key);
        }
      }
    }
  }

  /// 시각 요소 추가 (경로 이미지 캐시 + 배치 지점)
  void _addVisuals() {
    if (_visualsAdded) return;
    _visualsAdded = true;

    if (kDebugMode) {
      debugPrint('GameMap._addVisuals: ${waypoints.length} waypoints, ${towerSlots.length} slots');
    }

    // 1. 도로/점선을 래스터 이미지로 캐시
    _renderPathToImage();

    // 2. 배치 가능 지점 (개별 컴포넌트 — 상호작용 필요)
    for (int i = 0; i < towerSlots.length; i++) {
      final visual = _TowerSlotVisual(
        slotPosition: towerSlots[i],
        slotIndex: i,
        gameMap: this,
      );
      _slotVisuals[i] = visual;
      add(visual);
    }

    if (kDebugMode) {
      debugPrint('GameMap._addVisuals COMPLETE — path cached + ${towerSlots.length} slot visuals');
    }
  }

  /// 가장 가까운 빈 배치 지점 찾기
  int? findNearestEmptySlot(Vector2 tapPosition) {
    int? bestIndex;
    double bestDist = double.infinity;

    // 슬롯 스냅 범위: 타일 2칸 거리 (128px)
    const double maxSnapDistance = GameConstants.tileSize * 2;

    for (int i = 0; i < towerSlots.length; i++) {
      if (_occupiedSlots.contains(i)) continue;

      final dist = tapPosition.distanceTo(towerSlots[i]);
      if (dist < maxSnapDistance && dist < bestDist) {
        bestDist = dist;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  /// 슬롯 점유 처리 — 비주얼도 즉시 숨김
  void occupySlot(int index) {
    _occupiedSlots.add(index);
    _slotVisuals[index]?.setOccupied(true);
  }

  /// 슬롯 점유 해제 (타워 판매 시) — 비주얼 복원
  void freeSlot(int index) {
    _occupiedSlots.remove(index);
    _slotVisuals[index]?.setOccupied(false);
  }

  /// 위치에 해당하는 슬롯 인덱스 찾기
  int? findSlotAt(Vector2 position) {
    for (int i = 0; i < towerSlots.length; i++) {
      if (towerSlots[i].distanceTo(position) < 5) {
        return i;
      }
    }
    return null;
  }

  /// 슬롯이 비어있는지 확인
  bool isSlotEmpty(int index) => !_occupiedSlots.contains(index);

  /// 맵 월드 경계 (영웅 드래그 범위 제한용)
  Rect get worldBounds => Rect.fromLTWH(
    0, 0,
    GameConstants.gameWidth,
    GameConstants.gameHeight,
  );
}

/// 배치 가능 지점 시각 컴포넌트 (최적화: update() 제거, 이벤트 기반)
class _TowerSlotVisual extends PositionComponent {
  final Vector2 slotPosition;
  final int slotIndex;
  final GameMap gameMap;

  late RectangleComponent _indicator;
  late RectangleComponent _border;

  // 점유 상태 캐시 — Paint 반복 생성 방지
  bool _isHidden = false;

  static const _visibleFill = Color(0x3300FF00);
  static const _visibleBorder = Color(0xAA00FF00);
  static const _hiddenColor = Color(0x00000000);

  _TowerSlotVisual({
    required this.slotPosition,
    required this.slotIndex,
    required this.gameMap,
  }) : super(
    position: slotPosition,
    size: Vector2.all(GameConstants.tileSize * 0.8),
    anchor: Anchor.center,
    priority: 3, // 격자 위, 경로 아래
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 평소에는 희미하게
    _indicator = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = _visibleFill
        ..style = PaintingStyle.fill,
    );
    add(_indicator);

    // 테두리는 선명하게
    _border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = _visibleBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(_border);
  }

  /// 점유 상태 변경 (이벤트 기반 — 매 프레임 체크 불필요)
  void setOccupied(bool occupied) {
    if (occupied && !_isHidden) {
      _isHidden = true;
      _indicator.paint.color = _hiddenColor;
      _border.paint.color = _hiddenColor;
    } else if (!occupied && _isHidden) {
      _isHidden = false;
      _indicator.paint.color = _visibleFill;
      _border.paint.color = _visibleBorder;
    }
  }

  // update() 제거 — 매 프레임 점유 체크 불필요
}
