// 접근성 설정 상태 관리

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/debug_log.dart';
import '../common/responsive.dart';

/// 색맹 모드
enum ColorBlindMode {
  off,        // 기본
  protanopia, // 적색맹 (L-cone 결핍)
  deuteranopia, // 녹색맹 (M-cone 결핍)
  tritanopia, // 청색맹 (S-cone 결핍)
}

/// 접근성 설정
class AccessibilityPrefs {
  final double fontSizeMultiplier; // 0.8 ~ 1.5
  final ColorBlindMode colorBlindMode;
  final bool highContrast;
  final bool reduceMotion;

  const AccessibilityPrefs({
    this.fontSizeMultiplier = 1.0,
    this.colorBlindMode = ColorBlindMode.off,
    this.highContrast = false,
    this.reduceMotion = false,
  });

  AccessibilityPrefs copyWith({
    double? fontSizeMultiplier,
    ColorBlindMode? colorBlindMode,
    bool? highContrast,
    bool? reduceMotion,
  }) {
    return AccessibilityPrefs(
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontSizeMultiplier': fontSizeMultiplier,
    'colorBlindMode': colorBlindMode.index,
    'highContrast': highContrast,
    'reduceMotion': reduceMotion,
  };

  factory AccessibilityPrefs.fromJson(Map<String, dynamic> json) {
    return AccessibilityPrefs(
      fontSizeMultiplier: (json['fontSizeMultiplier'] as num?)?.toDouble() ?? 1.0,
      colorBlindMode: ColorBlindMode.values.elementAtOrNull(
        json['colorBlindMode'] as int? ?? 0,
      ) ?? ColorBlindMode.off,
      highContrast: json['highContrast'] as bool? ?? false,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
    );
  }
}

/// 접근성 설정 Notifier
class AccessibilityNotifier extends StateNotifier<AccessibilityPrefs> {
  static const String _storageKey = 'haewon_accessibility';

  AccessibilityNotifier() : super(const AccessibilityPrefs()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        state = AccessibilityPrefs.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        Responsive.accessibilityFontMultiplier = state.fontSizeMultiplier;
        dlog('✅ [Accessibility] 설정 로드 완료');
      }
    } on Exception catch (e) {
      dlog('⚠️ [Accessibility] 설정 로드 실패: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } on Exception catch (e) {
      dlog('⚠️ [Accessibility] 설정 저장 실패: $e');
    }
  }

  void setFontSizeMultiplier(double value) {
    state = state.copyWith(fontSizeMultiplier: value.clamp(0.8, 1.5));
    Responsive.accessibilityFontMultiplier = state.fontSizeMultiplier;
    _save();
  }

  void setColorBlindMode(ColorBlindMode mode) {
    state = state.copyWith(colorBlindMode: mode);
    _save();
  }

  void setHighContrast(bool value) {
    state = state.copyWith(highContrast: value);
    _save();
  }

  void setReduceMotion(bool value) {
    state = state.copyWith(reduceMotion: value);
    _save();
  }
}

/// 접근성 설정 프로바이더
final accessibilityProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilityPrefs>(
  (ref) => AccessibilityNotifier(),
);
