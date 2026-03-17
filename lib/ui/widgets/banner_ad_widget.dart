import 'package:flutter/material.dart';
import '../../common/responsive.dart';
import '../theme/app_colors.dart';

/// 배너 광고 플레이스홀더 위젯
/// 
/// 웹/데스크톱 등 테스트 환경용 시뮬레이터이며,
/// 추후 모바일 연동 시 AdManager/AdMob으로 대체될 영역입니다.
class BannerAdWidget extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  const BannerAdWidget({
    super.key,
    this.width = 320,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final isLand = Responsive.isLandscape(context);
    
    // 가로 모드일 때는 배너가 UI를 가리지 않도록 보수적으로 설정
    if (isLand) {
      return SizedBox(
        width: 1, 
        height: 1,
      );
    }
    
    return Padding(
      padding: padding,
      child: SafeArea(
        top: false,
        child: Container(
          width: width * s,
          height: height * s,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(150),
            border: Border.all(color: AppColors.cherryBlossom.withAlpha(100)),
            borderRadius: BorderRadius.circular(4 * s),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ad_units, color: Colors.white54, size: 16 * s),
              SizedBox(width: 8 * s),
              Text(
                'Test Banner Ad ($width x $height)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: Responsive.fontSize(context, 12),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1 * s,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
