// 해원의 문 - 가로 모드 좌우 광고 배너 래퍼
// 가로 모드에서 좌우 여백이 있는 化면에 AdMob 배너를 배치할 수 있는 래퍼 위젯

import 'package:flutter/material.dart';
import '../../common/responsive.dart';
import '../../common/constants.dart';
import '../theme/app_colors.dart';

/// 가로 모드에서 좌우 여백에 광고를 표시하는 래퍼 위젯
/// [child] 를 중앙에 배치하고, 양쪽에 광고 슬롯을 표시
class AdSideBanners extends StatelessWidget {
  final Widget child;
  /// 광고 최소 너비 (이보다 여백이 좁으면 광고 숨김)
  final double minAdWidth;

  const AdSideBanners({
    super.key,
    required this.child,
    this.minAdWidth = 60,
  });

  @override
  Widget build(BuildContext context) {
    // 세로 모드이면 광고 없이 child만 반환
    if (!Responsive.isLandscape(context)) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // 실제 타일 영역 너비 계산 (카메라가 화면 전체를 채우므로)
        // 타일은 960px 게임 단위, 화면 높이 기준으로 스케일
        final visibleH = GameConstants.gameHeight + 120; // defense_game.dart와 동일
        final tileWidthOnScreen = screenHeight * (GameConstants.gameWidth / visibleH);
        final sideMargin = (screenWidth - tileWidthOnScreen) / 2;

        // 여백이 최소 광고 너비보다 작으면 광고 없이 표시
        if (sideMargin < minAdWidth) {
          return child;
        }

        // Stack으로 겹쳐서 게임 화면은 풀 너비, 광고는 좌우 여백 위에 오버레이
        return Stack(
          children: [
            // 중앙 콘텐츠 (풀 너비 — 화면이 좁아지지 않음)
            child,
            // 왼쪽 광고 슬롯 (여백 위에 오버레이 — 터치 투과)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: sideMargin,
              child: IgnorePointer(
                child: _AdSlot(width: sideMargin, height: screenHeight, side: 'left'),
              ),
            ),
            // 오른쪽 광고 슬롯 (여백 위에 오버레이 — 터치 투과)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: sideMargin,
              child: IgnorePointer(
                child: _AdSlot(width: sideMargin, height: screenHeight, side: 'right'),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 광고 슬롯 위젯 — 현재는 플레이스홀더, 추후 AdMob 배너로 교체
class _AdSlot extends StatelessWidget {
  final double width;
  final double height;
  final String side;

  const _AdSlot({
    required this.width,
    required this.height,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 AdMob 배너 광고로 교체
    // BannerAd(size: AdSize(width: width.toInt(), height: height.toInt()))
    
    return Container(
      width: width,
      height: height,
      color: Colors.black.withAlpha(150),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ad_units_outlined,
              color: AppColors.lavender.withAlpha(40),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'AD',
              style: TextStyle(
                color: AppColors.lavender.withAlpha(30),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
