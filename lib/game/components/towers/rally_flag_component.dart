// 해원의 문 - 랠리 포인트 깃발 컴포넌트
// 병영 타워에서 병사 배치 위치를 지정하는 드래그 가능한 깃발

import 'dart:ui' hide TextStyle;
import 'package:flutter/painting.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../defense_game.dart';
import 'barracks_soldier.dart';

/// 병영 타워의 병사 배치 위치를 나타내는 깃발
/// 드래그하여 병사를 원하는 위치로 이동시킬 수 있음
class RallyFlagComponent extends PositionComponent
    with DragCallbacks, HasGameReference<DefenseGame> {
  /// 이 깃발이 속한 타워 위치
  final Vector2 towerPosition;

  /// 병사 활동 반경 (이 범위 밖으로 이동 불가)
  final double operationRange;

  /// 이 타워의 병사 리스트 참조
  final List<BarracksSoldier> soldiers;

  /// 드래그 중인지
  bool _isDragging = false;

  /// 범위 표시 서클 (드래그 시)
  late CircleComponent _rangeCircle;

  /// 깃발 본체
  late RectangleComponent _flagBody;
  late RectangleComponent _flagPole;

  RallyFlagComponent({
    required this.towerPosition,
    required this.operationRange,
    required this.soldiers,
    required Vector2 initialPosition,
  }) : super(
          size: Vector2(20, 28),
          anchor: Anchor.bottomCenter,
          position: initialPosition,
          priority: 15, // 병사 위에 표시
        );

  @override
  Future<void> onLoad() async {
    // 깃발 기둥
    _flagPole = RectangleComponent(
      size: Vector2(2, 24),
      position: Vector2(9, 4),
      paint: Paint()..color = const Color(0xFF8B4513),
    );
    add(_flagPole);

    // 깃발 천 (작은 삼각형 대신 사각형)
    _flagBody = RectangleComponent(
      size: Vector2(12, 10),
      position: Vector2(11, 4),
      paint: Paint()..color = const Color(0xFFFF4444),
    );
    add(_flagBody);

    // ⚑ 텍스트 라벨
    add(TextComponent(
      text: '⚑',
      position: Vector2(size.x / 2, 0),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 14),
      ),
    ));

    // 범위 표시 원 (기본 투명, 드래그 시 표시)
    _rangeCircle = CircleComponent(
      radius: operationRange,
      position: Vector2(size.x / 2, size.y),
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0x00000000) // 투명
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(_rangeCircle);

    // 탭 가능한 히트 영역 확대
    add(RectangleHitbox(
      size: Vector2(30, 36),
      position: Vector2(-5, -4),
    ));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    // 드래그 시작: 범위 원 표시
    _rangeCircle.paint.color = const Color(0x4444AAFF);
    // 깃발 색상 변경 (드래그 피드백)
    _flagBody.paint.color = const Color(0xFFFFAA00);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) return;

    // 새 위치 계산
    final newPos = position + event.localDelta;

    // 타워 범위 내로 제한
    final fromTower = newPos - towerPosition;
    if (fromTower.length > operationRange) {
      fromTower.normalize();
      position = towerPosition + fromTower * operationRange;
    } else {
      position = newPos;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;

    // 범위 원 숨기기
    _rangeCircle.paint.color = const Color(0x00000000);
    // 깃발 색상 복원
    _flagBody.paint.color = const Color(0xFFFF4444);

    // 모든 병사의 랠리 포인트 업데이트
    _updateSoldiersRallyPoint();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
    _rangeCircle.paint.color = const Color(0x00000000);
    _flagBody.paint.color = const Color(0xFFFF4444);
  }

  /// 모든 병사의 랠리 포인트를 깃발 위치로 업데이트
  void _updateSoldiersRallyPoint() {
    for (final soldier in soldiers) {
      if (soldier.isMounted && !soldier.isDead) {
        soldier.rallyPoint = position.clone();
      }
    }
  }

  /// 깃발 위치로 랠리 포인트 반환 (새 병사 소환 시 사용)
  Vector2 get currentRallyPoint => position.clone();

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 드래그 중일 때 추가 시각 효과 — 글로우
    if (_isDragging) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y),
        8,
        Paint()
          ..color = const Color(0x66FFAA00)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }
}
