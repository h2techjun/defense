/// 해원의 문 — CrazyGames SDK v3 서비스
///
/// dart:js_interop 기반 웹 전용 래퍼.
/// 모든 메서드는 kIsWeb 가드로 보호되어 Windows/Android 빌드에서 에러 없음.
library;

import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;

// ─── JS Interop Extension Types ────────────────────────────────────────────

extension type CrazySDKAdCallbacks._(JSObject _) implements JSObject {
  external factory CrazySDKAdCallbacks({
    JSFunction? adStarted,
    JSFunction? adFinished,
    JSFunction? adError,
  });
}

extension type CrazySDKAdModule._(JSObject _) implements JSObject {
  external void requestAd(JSString type, CrazySDKAdCallbacks callbacks);
}

extension type CrazySDKGameModule._(JSObject _) implements JSObject {
  external void gameplayStart();
  external void gameplayStop();
  external void loadingStart();
  external void loadingStop();
  external void happytime();
}

extension type CrazySDKRoot._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> init();
  external CrazySDKAdModule get ad;
  external CrazySDKGameModule get game;
  external JSString get environment;
}

extension type CrazyGamesNamespace._(JSObject _) implements JSObject {
  external CrazySDKRoot get SDK;
}

@JS('CrazyGames')
external CrazyGamesNamespace get _crazyGamesNamespace;

// ─── CrazyGamesService ─────────────────────────────────────────────────────

class CrazyGamesService {
  CrazyGamesService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (!kIsWeb) return;
    if (_initialized) return;
    try {
      await _crazyGamesNamespace.SDK.init().toDart;
      _initialized = true;
    } catch (e) {
      _log('init failed (non-CrazyGames env?): $e');
    }
  }

  static void loadingStart() {
    if (!kIsWeb) return;
    try { _crazyGamesNamespace.SDK.game.loadingStart(); }
    catch (e) { _log('loadingStart error: $e'); }
  }

  static void loadingStop() {
    if (!kIsWeb) return;
    try { _crazyGamesNamespace.SDK.game.loadingStop(); }
    catch (e) { _log('loadingStop error: $e'); }
  }

  static void gameplayStart() {
    if (!kIsWeb) return;
    try { _crazyGamesNamespace.SDK.game.gameplayStart(); }
    catch (e) { _log('gameplayStart error: $e'); }
  }

  static void gameplayStop() {
    if (!kIsWeb) return;
    try { _crazyGamesNamespace.SDK.game.gameplayStop(); }
    catch (e) { _log('gameplayStop error: $e'); }
  }

  static void happytime() {
    if (!kIsWeb) return;
    try { _crazyGamesNamespace.SDK.game.happytime(); }
    catch (e) { _log('happytime error: $e'); }
  }

  static void requestMidgameAd({
    void Function()? onStarted,
    void Function()? onFinished,
    void Function(String error)? onError,
  }) {
    if (!kIsWeb) return;
    try {
      final callbacks = CrazySDKAdCallbacks(
        adStarted: onStarted != null ? (() => onStarted()).toJS : null,
        adFinished: onFinished != null ? (() => onFinished()).toJS : null,
        adError: onError != null
            ? ((JSAny? err) => onError(err?.toString() ?? 'unknown')).toJS
            : null,
      );
      _crazyGamesNamespace.SDK.ad.requestAd('midgame'.toJS, callbacks);
    } catch (e) {
      _log('requestMidgameAd error: $e');
      onError?.call(e.toString());
    }
  }

  static void requestRewardedAd({
    void Function()? onStarted,
    void Function()? onFinished,
    void Function(String error)? onError,
  }) {
    if (!kIsWeb) return;
    try {
      final callbacks = CrazySDKAdCallbacks(
        adStarted: onStarted != null ? (() => onStarted()).toJS : null,
        adFinished: onFinished != null ? (() => onFinished()).toJS : null,
        adError: onError != null
            ? ((JSAny? err) => onError(err?.toString() ?? 'unknown')).toJS
            : null,
      );
      _crazyGamesNamespace.SDK.ad.requestAd('rewarded'.toJS, callbacks);
    } catch (e) {
      _log('requestRewardedAd error: $e');
      onError?.call(e.toString());
    }
  }

  static void _log(String message) {
    // ignore: avoid_print
    print('[CrazyGames] $message');
  }
}
