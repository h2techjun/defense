// 해원의 문 - 가로 모드 좌우 광고 배너 래퍼
// Row 기반 자동 레이아웃: 좌배너 | 게임(Expanded) | 우배너

import 'package:flutter/material.dart';
import '../../common/responsive.dart';
import '../theme/app_colors.dart';

/// 가로 모드에서 좌우 여백에 광고를 표시하는 래퍼 위젯
/// [child] 를 중앙에 배치하고, 양쪽에 광고 슬롯을 자동 크기 조절
class AdSideBanners extends StatelessWidget {
  final Widget child;

  /// 배너 1개의 기본 너비 (화면에 여유가 있을 때)
  final double bannerWidth;

  /// 배너를 표시할 최소 화면 여유 너비 (이보다 좁으면 배너 숨김)
  final double minExtraWidth;

  const AdSideBanners({
    super.key,
    required this.child,
    this.bannerWidth = 60,
    this.minExtraWidth = 100,
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

        // 게임 비율 (카메라 visibleGameSize 기준)
        const gameAspect = 16 / 9; // 대략적 게임 비율
        final idealGameWidth = screenHeight * gameAspect;
        final extraWidth = screenWidth - idealGameWidth;

        // 여유 너비가 최소 기준보다 작으면 배너 없이 표시
        if (extraWidth < minExtraWidth) {
          return child;
        }

        // 배너 너비: 여유 너비의 절반, 최대 bannerWidth까지
        final actualBannerWidth = (extraWidth / 2).clamp(0.0, bannerWidth);

        return Row(
          children: [
            // 좌측 배너
            SizedBox(
              width: actualBannerWidth,
              child: _AdSlot(side: 'left'),
            ),
            // 중앙 게임 영역 (자동 크기 맞춤)
            Expanded(child: child),
            // 우측 배너
            SizedBox(
              width: actualBannerWidth,
              child: _AdSlot(side: 'right'),
            ),
          ],
        );
      },
    );
  }
}

/// 광고 슬롯 위젯 — 현재는 플레이스홀더, 추후 AdMob 배너로 교체
class _AdSlot extends StatelessWidget {
  final String side;

  const _AdSlot({required this.side});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ad_units_outlined,
              color: AppColors.lavender.withAlpha(40),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              'AD',
              style: TextStyle(
                color: AppColors.lavender.withAlpha(30),
                fontSize: 9,
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
