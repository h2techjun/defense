import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../common/constants.dart';

/// 튜토리얼 단계 정의
class TutorialStep {
  final String title;
  final String content;
  final String emoji;
  final Rect? highlightRect;

  const TutorialStep({
    required this.title,
    required this.content,
    this.emoji = '🦉',
    this.highlightRect,
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

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      _animController.reset();
      setState(() => _currentIndex++);
      _animController.forward();
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    final step = widget.steps[_currentIndex];
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    // 게임 영역 위치 계산 (AdSideBanners와 동일 공식)
    final visibleH = GameConstants.gameHeight + 120;
    final tileWidthOnScreen = screenH * (GameConstants.gameWidth / visibleH);
    final sideMargin = ((screenW - tileWidthOnScreen) / 2).clamp(0.0, 300.0);

    // 툴팁 너비: 게임 영역의 50% 이하, 최소 220, 최대 340
    final gameAreaW = screenW - sideMargin * 2;
    final tooltipW = (gameAreaW * 0.55).clamp(220.0, 340.0);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Dim 배경 + 하이라이트
          CustomPaint(
            size: Size.infinite,
            painter: _HighlightPainter(
              highlightRect: step.highlightRect,
              backgroundColor: Colors.black.withAlpha(180),
            ),
          ),

          // 2. 툴팁 — 게임 영역 중앙에 배치
          Positioned(
            left: sideMargin + (gameAreaW - tooltipW) / 2,
            top: screenH * 0.2,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildTooltipBox(step, tooltipW),
            ),
          ),

          // 3. 하단 진행 표시 바
          Positioned(
            bottom: 20,
            left: sideMargin + 16,
            right: sideMargin + 16,
            child: _buildProgressBar(),
          ),

          // 4. 전체 화면 제스처 영역 (가장 위에 배치하여 모든 터치 감지)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _nextStep,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipBox(TutorialStep step, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xF01A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sinmyeongGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.sinmyeongGold.withAlpha(60),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 행
          Row(
            children: [
              Text(step.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    color: AppColors.sinmyeongGold,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 본문
          Text(
            step.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          // 하단 안내 + 페이지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentIndex + 1} / ${widget.steps.length}',
                style: const TextStyle(
                  color: AppColors.sinmyeongGold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentIndex < widget.steps.length - 1
                        ? '터치하여 다음 →'
                        : '터치하여 시작! 🎮',
                    style: TextStyle(
                      color: _currentIndex < widget.steps.length - 1
                          ? Colors.white54
                          : AppColors.sinmyeongGold,
                      fontSize: 12,
                      fontWeight: _currentIndex < widget.steps.length - 1
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.steps.length, (i) {
        final isActive = i == _currentIndex;
        final isDone = i < _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 10,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? AppColors.sinmyeongGold
                : isDone
                    ? AppColors.sinmyeongGold.withAlpha(120)
                    : Colors.white24,
          ),
        );
      }),
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

    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    Path finalPath = bgPath;

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
