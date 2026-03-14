// 해원의 문 - 반응형 레이아웃 유틸리티
// 핸드폰, 태블릿, PC 등 다양한 화면 크기에 대응

import 'package:flutter/material.dart';

/// 디바이스 유형
enum DeviceType { phone, tablet, desktop }

/// 반응형 유틸리티 — 화면 크기 기반 스케일링
class Responsive {
  Responsive._();

  // 기준 해상도 (디자인 기준)
  static const double _baseWidth = 960.0;
  static const double _baseHeight = 576.0;

  // ═══════════════════════════════════════════
  // 🔧 모바일 UI 부스트 — 이 값 하나로 전체 모바일 UI 크기 제어
  // 1.0 = 원본, 1.2 = 20% 확대, 1.4 = 40% 확대
  // ═══════════════════════════════════════════
  static const double _mobileUiBoost = 1.6;
  static const double _minMobileFontSize = 13.0;
  static const double _minMobileIconSize = 20.0;

  /// 현재 디바이스 유형 판별 (shortestSide 기준 — 가로/세로 모드 공통)
  static DeviceType deviceType(BuildContext context) {
    final shortSide = MediaQuery.of(context).size.shortestSide;
    if (shortSide < 600) return DeviceType.phone;
    if (shortSide < 900) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// 가로 기준 스케일 팩터
  static double scaleX(BuildContext context) {
    return MediaQuery.of(context).size.width / _baseWidth;
  }

  /// 세로 기준 스케일 팩터
  static double scaleY(BuildContext context) {
    return MediaQuery.of(context).size.height / _baseHeight;
  }

  /// 원본 스케일 (게임 엔진 Flame 전용 — 부스트 없음)
  static double rawScale(BuildContext context) {
    final sx = scaleX(context);
    final sy = scaleY(context);
    return (sx < sy ? sx : sy).clamp(0.5, 2.5);
  }

  /// UI 스케일 (모바일에서 _mobileUiBoost 자동 적용)
  /// ⚠️ 모든 UI 위젯 (메뉴/HUD/패널/다이얼로그)에서 사용
  static double scale(BuildContext context) {
    final raw = rawScale(context);
    return deviceType(context) == DeviceType.phone
        ? (raw * _mobileUiBoost).clamp(0.7, 2.5)
        : raw;
  }

  /// UI 위젯 전용 스케일 (scale과 동일 — 호환성 유지)
  static double uiScale(BuildContext context) => scale(context);

  /// 반응형 폰트 크기 (phone에서 _minMobileFontSize 보장)
  static double fontSize(BuildContext context, double baseFontSize) {
    final size = baseFontSize * scale(context);
    return deviceType(context) == DeviceType.phone
        ? size.clamp(_minMobileFontSize, double.infinity)
        : size;
  }

  /// 반응형 패딩/마진
  static double spacing(BuildContext context, double baseSpacing) {
    return baseSpacing * scale(context);
  }

  /// 반응형 아이콘 크기 (phone에서 _minMobileIconSize 보장)
  static double iconSize(BuildContext context, double baseIconSize) {
    final size = baseIconSize * scale(context);
    return deviceType(context) == DeviceType.phone
        ? size.clamp(_minMobileIconSize, double.infinity)
        : size;
  }

  /// 반응형 EdgeInsets
  static EdgeInsets padding(BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    final s = scale(context);
    return EdgeInsets.symmetric(
      horizontal: horizontal * s,
      vertical: vertical * s,
    );
  }

  /// 반응형 EdgeInsets.all
  static EdgeInsets paddingAll(BuildContext context, double base) {
    return EdgeInsets.all(base * scale(context));
  }

  /// 그리드 열 수 (화면 폭 기반)
  static int gridColumns(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.phone:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 4;
    }
  }

  /// 최대 컨텐츠 너비 (너무 넓어지지 않도록)
  static double maxContentWidth(BuildContext context) {
    switch (deviceType(context)) {
      case DeviceType.phone:
        return MediaQuery.of(context).size.width;
      case DeviceType.tablet:
        return MediaQuery.of(context).size.width * 0.9;
      case DeviceType.desktop:
        return 1200;
    }
  }

  /// 반응형 TextStyle
  static TextStyle textStyle(
    BuildContext context, {
    double baseFontSize = 14,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: fontSize(context, baseFontSize),
      color: color,
      fontWeight: fontWeight,
    );
  }

  /// 가로 모드 여부
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
  }

  /// 화면 비율 기반 너비 (fraction: 0~1)
  static double adaptiveWidth(BuildContext context, double fraction) {
    return MediaQuery.of(context).size.width * fraction;
  }

  /// 화면 비율 기반 높이
  static double adaptiveHeight(BuildContext context, double fraction) {
    return MediaQuery.of(context).size.height * fraction;
  }

  /// 디바이스별 다른 값 반환
  static T value<T>(BuildContext context, {
    required T phone,
    required T tablet,
    required T desktop,
  }) {
    switch (deviceType(context)) {
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// 화면 너비
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;

  /// 화면 높이
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
}

/// 반응형 래퍼 위젯 — 최대 너비 제한 + 가운데 정렬
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
