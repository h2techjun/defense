/// 디버그 로그 유틸리티
/// 프로덕션 빌드에서는 모든 로그를 자동 제거합니다.
///
/// 사용법:
/// ```dart
/// import '../common/debug_log.dart';
/// dlog('[Wave] 웨이브 3 시작');
/// ```
library;

import 'package:flutter/foundation.dart';

/// kDebugMode 가드된 debugPrint — 릴리스 빌드에서 완전 제거
void dlog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// 조건부 디버그 로그 (특정 태그만 활성화할 때)
void dlogIf(bool condition, String message) {
  if (kDebugMode && condition) {
    debugPrint(message);
  }
}
