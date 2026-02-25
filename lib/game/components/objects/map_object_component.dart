// 해원의 문 - 인터랙티브 맵 오브젝트 컴포넌트
// GDD 7.2 — 환경 상호작용 오브젝트 (성황당, 우물, 횃불 등)

import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../../common/enums.dart';
import '../../../data/models/map_object_data.dart';
import '../../../state/game_state.dart';
import '../../defense_game.dart';

/// 맵 오브젝트 상태
enum MapObjectState {
  inactive,  // 비활성 (아직 활성화 안 됨)
  active,    // 활성화됨 (효과 발동 중)
  depleted,  // 소모됨 (1회용인 경우)
}

/// 인터랙티브 맵 오브젝트 — Flame 컴포넌트
class MapObjectComponent extends PositionComponent with TapCallbacks, HasGameRef<DefenseGame> {
  final MapObjectData data;
  MapObjectState state = MapObjectState.inactive;

  /// 효과 지속 시간 추적 (초)
  double _effectTimer = 0;
  double _effectDuration = 0; // 0 = 영구

  /// 시각 효과 타이머
  double _pulseTimer = 0;
  double _glowIntensity = 0;

  /// 인터랙션 쿨다운
  bool _canInteract = true;

  /// 스프라이트 에셋
  Sprite? _sprite;
  bool _spriteLoaded = false;

  MapObjectComponent({
    required this.data,
    required Vector2 position,
  }) : super(
    position: position,
    size: Vector2.all(40), // 1타일 크기
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSprite();
  }

  /// 오브젝트 타입별 스프라이트 로딩
  Future<void> _loadSprite() async {
    try {
      final imagePath = _getSpritePath();
      if (imagePath != null) {
        final image = await gameRef.images.load(imagePath);
        _sprite = Sprite(image);
        _spriteLoaded = true;
      }
    } catch (e) {
      // 이미지 로드 실패 → Canvas 폴백 사용
      _spriteLoaded = false;
    }
  }

  /// MapObjectType → 스프라이트 경로
  String? _getSpritePath() {
    switch (data.type) {
      case MapObjectType.sacredTree:
        return 'objects/obj_sacred_tree.png';
      case MapObjectType.shrine:
        return 'objects/obj_shrine.png';
      case MapObjectType.torch:
        return 'objects/obj_torch.png';
      case MapObjectType.oldWell:
        return 'objects/obj_old_well.png';
      case MapObjectType.mapSotdae:
        return 'objects/obj_sotdae.png';
      case MapObjectType.tomb:
        return 'objects/obj_grave_mound.png';
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 비활성 상태 — 깜빡이는 아이콘
    if (state == MapObjectState.inactive) {
      _pulseTimer += dt;
      _glowIntensity = 0.3 + 0.3 * math.sin(_pulseTimer * 2.5);
    }

    // 활성 상태 — 효과 지속 시간 체크
    if (state == MapObjectState.active && _effectDuration > 0) {
      _effectTimer += dt;
      if (_effectTimer >= _effectDuration) {
        state = MapObjectState.depleted;
        _onEffectExpired();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 스프라이트가 있으면 스프라이트 기반 렌더링
    if (_spriteLoaded && _sprite != null) {
      _renderSprite(canvas);
      return;
    }

    // 스프라이트 없으면 기존 Canvas 폴백
    switch (state) {
      case MapObjectState.inactive:
        _renderInactive(canvas);
        break;
      case MapObjectState.active:
        _renderActive(canvas);
        break;
      case MapObjectState.depleted:
        _renderDepleted(canvas);
        break;
    }
  }

  /// 스프라이트 기반 렌더링 (상태별 오버레이 차별화)
  void _renderSprite(Canvas canvas) {
    final center = size / 2;

    switch (state) {
      case MapObjectState.inactive:
        // 글로우 링
        final glowPaint = Paint()
          ..color = _getTypeColor().withValues(alpha: _glowIntensity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center.toOffset(), 22, glowPaint);
        // 반투명 스프라이트
        canvas.saveLayer(Rect.fromLTWH(0, 0, size.x, size.y),
          Paint()..color = Color.fromARGB((180 + (_glowIntensity * 75).toInt()).clamp(0, 255), 255, 255, 255));
        _sprite!.render(canvas, size: size);
        canvas.restore();
        // 비용 표시
        if (data.cost > 0) {
          final costPainter = TextPainter(
            text: TextSpan(
              text: '${data.cost}✦',
              style: TextStyle(
                color: Colors.amber.shade200,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          costPainter.layout();
          costPainter.paint(canvas, Offset(center.x - costPainter.width / 2, center.y + 18));
        }
        break;

      case MapObjectState.active:
        // 효과 범위
        if (data.effectRadius > 0) {
          final radiusPx = data.effectRadius * 40;
          canvas.drawCircle(center.toOffset(), radiusPx,
            Paint()..color = _getTypeColor().withValues(alpha: 0.12)..style = PaintingStyle.fill);
          canvas.drawCircle(center.toOffset(), radiusPx,
            Paint()..color = _getTypeColor().withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1);
        }
        // 밝은 스프라이트
        _sprite!.render(canvas, size: size);
        // 활성 테두리
        canvas.drawCircle(center.toOffset(), 20,
          Paint()..color = _getTypeColor()..style = PaintingStyle.stroke..strokeWidth = 2);
        break;

      case MapObjectState.depleted:
        // 흐릿한 스프라이트
        canvas.saveLayer(Rect.fromLTWH(0, 0, size.x, size.y),
          Paint()..color = const Color.fromARGB(80, 255, 255, 255));
        _sprite!.render(canvas, size: size);
        canvas.restore();
        break;
    }
  }

  /// 비활성 상태 렌더링 — 빛나는 아이콘 + 비용 표시
  void _renderInactive(Canvas canvas) {
    final center = size / 2;

    // 글로우 링
    final glowPaint = Paint()
      ..color = _getTypeColor().withValues(alpha: _glowIntensity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center.toOffset(), 22, glowPaint);

    // 배경 원
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.toOffset(), 16, bgPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = _getTypeColor().withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center.toOffset(), 16, borderPaint);

    // 아이콘 이모지
    _drawEmoji(canvas, center.toOffset(), _getTypeEmoji(), 14);

    // 비용 표시
    if (data.cost > 0) {
      final costPainter = TextPainter(
        text: TextSpan(
          text: '${data.cost}✦',
          style: TextStyle(
            color: Colors.amber.shade200,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      costPainter.layout();
      costPainter.paint(
        canvas,
        Offset(center.x - costPainter.width / 2, center.y + 18),
      );
    }
  }

  /// 활성 상태 렌더링 — 효과 범위 표시 + 활성 아이콘
  void _renderActive(Canvas canvas) {
    final center = size / 2;

    // 효과 범위 원 (반경이 있는 경우)
    if (data.effectRadius > 0) {
      final radiusPx = data.effectRadius * 40; // 타일 → 픽셀
      final rangePaint = Paint()
        ..color = _getTypeColor().withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center.toOffset(), radiusPx, rangePaint);

      final rangeBorderPaint = Paint()
        ..color = _getTypeColor().withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center.toOffset(), radiusPx, rangeBorderPaint);
    }

    // 활성 아이콘 (밝게)
    final bgPaint = Paint()
      ..color = _getTypeColor().withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.toOffset(), 16, bgPaint);

    final borderPaint = Paint()
      ..color = _getTypeColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center.toOffset(), 16, borderPaint);

    _drawEmoji(canvas, center.toOffset(), _getTypeEmoji(), 14);

    // 남은 시간 표시 (한정 효과인 경우)
    if (_effectDuration > 0) {
      final remaining = (_effectDuration - _effectTimer).clamp(0, _effectDuration);
      final pct = remaining / _effectDuration;
      final arcPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center.toOffset(), radius: 18),
        -math.pi / 2,
        2 * math.pi * pct,
        false,
        arcPaint,
      );
    }
  }

  /// 소모 상태 렌더링 — 흐릿하게
  void _renderDepleted(Canvas canvas) {
    final center = size / 2;
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.toOffset(), 14, bgPaint);
    _drawEmoji(canvas, center.toOffset(), _getTypeEmoji(), 12, alpha: 0.3);
  }

  /// 이모지 텍스트 그리기
  void _drawEmoji(Canvas canvas, Offset center, String emoji, double fontSize, {double alpha = 1.0}) {
    final painter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  /// 탭 이벤트 — 활성화 시도
  @override
  void onTapUp(TapUpEvent event) {
    if (state != MapObjectState.inactive || !_canInteract) return;

    final game = gameRef;
    final gameState = game.ref.read(gameStateProvider);

    // 비용 확인
    if (gameState.sinmyeong < data.cost) {
      // 신명 부족 — SFX + 시각 피드백
      // SoundManager.instance.playSfx(SfxType.uiError);
      _showInsufficientFeedback();
      return;
    }

    // 신명 차감 & 활성화
    game.ref.read(gameStateProvider.notifier).spendSinmyeong(data.cost);
    _activate();
  }

  /// 활성화 실행
  void _activate() {
    state = MapObjectState.active;
    _effectTimer = 0;

    // 타입별 효과 설정
    switch (data.type) {
      case MapObjectType.shrine:
        _effectDuration = 30; // 30초간 범위 내 이속 -30%
        _applySlowAura();
        break;

      case MapObjectType.oldWell:
        _effectDuration = 0; // 영구 — 물귀신 비등장
        _purifyWell();
        break;

      case MapObjectType.torch:
        _effectDuration = 0; // 영구 — 안개 해제 + 은신 감지
        _lightTorch();
        break;

      case MapObjectType.mapSotdae:
        _effectDuration = 0; // 영구 — 범위 내 원혼 자동 정화
        _activateSotdae();
        break;

      case MapObjectType.tomb:
        _effectDuration = 20; // 20초간 아군 유령 소환
        _summonGhostAlly();
        break;

      case MapObjectType.sacredTree:
        _effectDuration = 0;
        _forceNightToDay();
        state = MapObjectState.depleted; // 1회용
        break;
    }
  }

  // ── 타입별 효과 구현 ──

  /// 성황당: 범위 내 적 이속 -30%
  void _applySlowAura() {
    // 게임 루프에서 update 시 범위 내 적에게 슬로우 적용
    // DefenseGame에서 이 컴포넌트의 활성 상태와 범위를 체크
  }

  /// 오래된 우물: 물귀신 미등장
  void _purifyWell() {
    gameRef.setMapObjectFlag('wellPurified', true);
  }

  /// 횃불: 안개 해제, 은신 감지
  void _lightTorch() {
    gameRef.setMapObjectFlag('torchLit', true);
  }

  /// 솟대 (맵 고정): 범위 내 원혼 자동 정화
  void _activateSotdae() {
    // DefenseGame 루프에서 범위 내 SpiritComponent 자동 수집
  }

  /// 봉분: 아군 유령 소환 20초
  void _summonGhostAlly() {
    // 아군 유령 컴포넌트 생성 (추후 구현)
  }

  /// 당산나무: 밤→낮 강제 전환
  void _forceNightToDay() {
    gameRef.forceDayCycle(DayCycle.day);
  }

  /// 효과 만료 시 처리
  void _onEffectExpired() {
    switch (data.type) {
      case MapObjectType.shrine:
        // 슬로우 해제 — 적들의 이속이 복구됨
        break;
      case MapObjectType.tomb:
        // 아군 유령 소멸
        break;
      default:
        break;
    }
  }

  /// 신명 부족 시각 피드백
  void _showInsufficientFeedback() {
    _canInteract = false;
    Future.delayed(const Duration(milliseconds: 500), () {
      _canInteract = true;
    });
  }

  // ── 유틸리티 ──

  /// 타입별 색상
  Color _getTypeColor() {
    switch (data.type) {
      case MapObjectType.shrine:
        return Colors.cyan.shade300;
      case MapObjectType.oldWell:
        return Colors.blue.shade300;
      case MapObjectType.torch:
        return Colors.orange.shade300;
      case MapObjectType.mapSotdae:
        return Colors.green.shade300;
      case MapObjectType.tomb:
        return Colors.purple.shade300;
      case MapObjectType.sacredTree:
        return Colors.lime.shade300;
    }
  }

  /// 타입별 이모지
  String _getTypeEmoji() {
    switch (data.type) {
      case MapObjectType.shrine:
        return '⛩️';
      case MapObjectType.oldWell:
        return '🪣';
      case MapObjectType.torch:
        return '🔥';
      case MapObjectType.mapSotdae:
        return '🪶';
      case MapObjectType.tomb:
        return '⚰️';
      case MapObjectType.sacredTree:
        return '🌳';
    }
  }

  /// 이 오브젝트의 월드 좌표 범위 (DefenseGame에서 적 슬로우 등에 사용)
  bool isInEffectRange(Vector2 targetPos) {
    if (state != MapObjectState.active || data.effectRadius <= 0) return false;
    final radiusPx = data.effectRadius * 40;
    return position.distanceTo(targetPos) <= radiusPx;
  }
}
