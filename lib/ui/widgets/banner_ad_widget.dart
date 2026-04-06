import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../common/responsive.dart';

/// AdMob 배너 광고 위젯 — 가로 모드 상단 전용
/// 웹/iOS는 빈 위젯 반환
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // 배너 광고 단위 ID
  static const String _adUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'   // 테스트 ID
      : 'ca-app-pub-8134930906845147/5647657542';   // 실제 ID

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner, // 320×50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 웹 / iOS / 광고 미로드 시 빈 위젯
    if (kIsWeb || _bannerAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    final s = Responsive.uiScale(context);
    return SizedBox(
      width: _bannerAd!.size.width.toDouble() * s,
      height: _bannerAd!.size.height.toDouble() * s,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
