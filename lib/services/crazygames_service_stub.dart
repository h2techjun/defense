/// CrazyGames stub — 비웹 플랫폼(Android/Windows)에서 사용.
/// 모든 메서드가 no-op.
class CrazyGamesService {
  CrazyGamesService._();

  static Future<void> init() async {}
  static void loadingStart() {}
  static void loadingStop() {}
  static void gameplayStart() {}
  static void gameplayStop() {}
  static void happytime() {}

  static void requestMidgameAd({
    void Function()? onStarted,
    void Function()? onFinished,
    void Function(String error)? onError,
  }) {}

  static void requestRewardedAd({
    void Function()? onStarted,
    void Function()? onFinished,
    void Function(String error)? onError,
  }) {}
}
