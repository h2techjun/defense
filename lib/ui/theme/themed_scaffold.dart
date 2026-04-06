// 해원의 문 - 배경 이미지가 있는 Scaffold 래퍼
// 에셋이 있으면 배경 이미지를, 없으면 기존 그라디언트를 사용

import 'package:flutter/material.dart';
import '../../common/debug_log.dart';
import '../../common/responsive.dart';
import '../widgets/banner_ad_widget.dart';
import 'app_colors.dart';

/// 배경 이미지를 지원하는 Scaffold 래퍼 위젯
/// [backgroundAsset]이 존재하면 이미지를 배경으로 사용, 없으면 기본 그라디언트
class ThemedScaffold extends StatelessWidget {
  final String? backgroundAsset;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;

  const ThemedScaffold({
    super.key,
    this.backgroundAsset,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
  });

  /// 가로 모드일 때만 상단에 배너 추가
  Widget _withBannerTop(BuildContext context, Widget child) {
    if (!Responsive.isLandscape(context)) return child;
    return Column(
      children: [
        const BannerAdWidget(),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: backgroundAsset != null,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor ?? AppColors.scaffoldBg,
      body: backgroundAsset != null
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                image: DecorationImage(
                  image: AssetImage(backgroundAsset!),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(
                    Colors.black45,
                    BlendMode.darken,
                  ),
                  onError: (e, st) { dlog('[ThemedScaffold] bg image load failed: $e'); },
                ),
              ),
              child: SafeArea(child: _withBannerTop(context, body)),
            )
          : SafeArea(child: _withBannerTop(context, body)),
    );
  }
}
