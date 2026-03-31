/// CrazyGames SDK — 조건부 import.
/// 웹: dart:js_interop 기반 실제 구현 사용.
/// 비웹(Android/Windows): no-op stub 사용.
export 'crazygames_service_stub.dart'
    if (dart.library.js_interop) 'crazygames_service.dart';
