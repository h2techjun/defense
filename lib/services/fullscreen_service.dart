// 해원의 문 - 전체화면 서비스 (크로스 플랫폼)
// 웹: JavaScript Fullscreen API (조건부 import)
// 모바일/태블릿: SystemChrome immersiveSticky
// 전체화면 토글 버튼 + 모바일 자동 전체화면

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'fullscreen_stub.dart'
    if (dart.library.html) 'fullscreen_web.dart';

/// 전체화면 관리 서비스
class FullscreenService {
  FullscreenService._();
  static final instance = FullscreenService._();

  bool _isFullscreen = false;
  bool get isFullscreen => _isFullscreen;

  /// 전체화면 토글
  Future<void> toggle() async {
    if (_isFullscreen) {
      await exitFullscreen();
    } else {
      await enterFullscreen();
    }
  }

  /// 전체화면 진입
  Future<void> enterFullscreen() async {
    if (kIsWeb) {
      webEnterFullscreen();
    } else {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    }
    _isFullscreen = true;
  }

  /// 전체화면 해제
  Future<void> exitFullscreen() async {
    if (kIsWeb) {
      webExitFullscreen();
    } else {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }
    _isFullscreen = false;
  }

  /// 현재 전체화면 상태 새로고침 (웹에서 ESC로 나간 경우 동기화)
  void syncState() {
    if (kIsWeb) {
      _isFullscreen = isWebFullscreen();
    }
  }

  /// 모바일/태블릿 자동 전체화면 (앱 시작 시 호출)
  Future<void> autoFullscreenOnMobile() async {
    if (!kIsWeb) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
      _isFullscreen = true;
    }
    // 웹은 사용자 제스처 없이 전체화면 불가 → 버튼으로 처리
  }
}
