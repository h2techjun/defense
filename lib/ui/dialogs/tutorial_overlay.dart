import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 튜토리얼 단계 정의
class TutorialStep {
  final String title;
  final String content;
  final Rect? highlightRect;
  final Offset? tooltipOffset;

  const TutorialStep({
    required this.title,
    required this.content,
    this.highlightRect,
    this.tooltipOffset,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onFinish;

  const TutorialOverlay({
    Key? key,
    required this.steps,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentIndex = 0;

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      setState(() => _currentIndex++);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    final step = widget.steps[_currentIndex];

    // 페이드 인 전환을 위해 AnimatedSwitcher 사용
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. 하이라이트 영역만 투명하게 뚫린 Dim 배경 (터치 이벤트 스틸용 애니메이션 처리)
          AnimatedBuilder(
            animation: AlwaysStoppedAnimation(1.0), // 정적 애니메이션 대신 Tween 처리 가능
            builder: (ctx, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _HighlightPainter(
                  highlightRect: step.highlightRect,
                  backgroundColor: Colors.black.withAlpha(180),
                ),
              );
            },
          ),

          // 2. 전체 화면 제스처 영역 (아무데나 누르면 다음으로 넘어가도록)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _nextStep,
            child: Container(color: Colors.transparent),
          ),

          // 3. 툴팁 UI
          if (step.tooltipOffset != null)
            Positioned(
              left: step.tooltipOffset!.dx,
              top: step.tooltipOffset!.dy,
              child: _buildTooltipBox(step),
            )
          else
            // 중앙 배치 폴백
            Align(
              alignment: Alignment.center,
              child: _buildTooltipBox(step),
            ),
        ],
      ),
    );
  }

  Widget _buildTooltipBox(TutorialStep step) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sinmyeongGold),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('🦉', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    color: AppColors.sinmyeongGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '화면을 터치하여 계속 (${_currentIndex + 1}/${widget.steps.length})',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }
}

/// 지정된 Rect 영역을 제외한 나머지를 색칠하는 CustomPainter
class _HighlightPainter extends CustomPainter {
  final Rect? highlightRect;
  final Color backgroundColor;

  _HighlightPainter({
    required this.highlightRect,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = backgroundColor;
    
    // 전체 화면 경로
    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    Path finalPath = bgPath;

    // 하이라이트 영역 빼기 (구멍 뚫기)
    if (highlightRect != null) {
      final holePath = Path()
        ..addRRect(RRect.fromRectAndRadius(highlightRect!, const Radius.circular(8)));
      finalPath = Path.combine(PathOperation.difference, bgPath, holePath);
    }

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
