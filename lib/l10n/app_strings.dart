// 해원의 문 - 다중언어 지원 시스템
// 4개 언어 지원: 한국어, English, 日本語, 简体中文

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/debug_log.dart';

/// 지원 언어 목록
enum GameLanguage {
  ko('한국어', '🇰🇷'),
  en('English', '🇺🇸'),
  ja('日本語', '🇯🇵'),
  zhCn('简体中文', '🇨🇳');

  final String displayName;
  final String flag;
  const GameLanguage(this.displayName, this.flag);
}

/// 언어 상태 Provider
final gameLanguageProvider = StateProvider<GameLanguage>((ref) => GameLanguage.ko);

/// 번역 문자열 접근 헬퍼
String tr(WidgetRef ref, String key) {
  final lang = ref.watch(gameLanguageProvider);
  return AppStrings.get(lang, key);
}


/// 앱 문자열 레지스트리
class AppStrings {
  static final Map<GameLanguage, Map<String, String>> _cache = {};

  /// 초기 구동 시 기본(혹은 저장된) 언어 프리로드
  static Future<void> init([GameLanguage defaultLang = GameLanguage.ko]) async {
    await loadLanguage(defaultLang);
    // 폴백용 한국어도 로드해두는 것이 안전
    if (defaultLang != GameLanguage.ko) {
      await loadLanguage(GameLanguage.ko);
    }
  }

  /// 특정 언어 JSON 파일을 비동기 로드하여 캐시에 저장
  static Future<void> loadLanguage(GameLanguage lang) async {
    if (_cache.containsKey(lang)) return; // 이미 로드됨

    try {
      final jsonString = await rootBundle.loadString('assets/i18n/${lang.name}.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
      final Map<String, String> strings = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      
      _cache[lang] = strings;
      dlog('🌐 [i18n] Loaded ${lang.name}.json');
    } catch (e) {
      dlog('🚨 [i18n] Failed to load ${lang.name}.json: $e');
      _cache[lang] = {};
    }
  }

  /// 번역 문자열 반환 (캐시에서 조회)
  static String get(GameLanguage lang, String key) {
    final currentLangMap = _cache[lang];
    final fallbackLangMap = _cache[GameLanguage.ko];

    if (currentLangMap != null && currentLangMap.containsKey(key)) {
      return currentLangMap[key]!;
    }
    if (fallbackLangMap != null && fallbackLangMap.containsKey(key)) {
      return fallbackLangMap[key]!;
    }
    return '[$key]';
  }
}

