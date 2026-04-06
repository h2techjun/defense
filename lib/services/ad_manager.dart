// 해원의 문 - 광고 매니저
// 보상형 광고 + 배너 관리 (Android: AdMob 실제 연동 / Web: CrazyGames SDK)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'save_manager.dart';
import '../l10n/app_strings.dart';
import '../common/debug_log.dart';

/// 보상형 광고 목적
enum RewardedAdPurpose {
  freeGems,        // 무료 보석 획득 (30개)
  revive,          // 패배 시 부활 (HP 50% 회복)
  doubleReward,    // 승리 시 보상 2배
  freeSummon,      // 무료 소환
  bonusMission,    // 일일 미션 추가 보상
  seasonPremium,   // 시즌 패스 프리미엄 해금
}

/// 보상형 광고 결과
class AdReward {
  final int gems;
  final String description;
  final RewardedAdPurpose purpose;

  const AdReward({
    required this.gems,
    required this.description,
    this.purpose = RewardedAdPurpose.freeGems,
  });
}

/// 광고 매니저 — 싱글톤
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  bool _initialized = false;
  bool _isAdPlaying = false;
  RewardedAd? _rewardedAd;

  // 광고 단위 ID
  static const String _rewardedAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'   // 테스트 ID
      : 'ca-app-pub-8134930906845147/5511926170';   // 실제 ID

  // 보상형 광고 쿨다운 (과도한 광고 시청 방지)
  DateTime? _lastRewardedAdTime;
  static const _rewardedAdCooldown = Duration(minutes: 2);

  // 일일 보상형 광고 제한
  int _dailyRewardedCount = 0;
  static const _maxDailyRewarded = 15;
  DateTime _dailyResetDate = DateTime.now();

  // 무료 보석 — 점진적 쿨다운 (총 12시간에 걸쳐 5회)
  DateTime? _lastFreeGemsTime;
  static const List<Duration> _freeGemsCooldowns = [
    Duration.zero,
    Duration(minutes: 30),
    Duration(minutes: 90),
    Duration(hours: 3),
    Duration(hours: 7),
  ];
  static const _maxDailyFreeGems = 5;
  int _dailyFreeGemsCount = 0;

  bool get isInitialized => _initialized;
  bool get isAdPlaying => _isAdPlaying;

  /// 보상형 광고 시청 가능 여부
  bool get canShowRewardedAd {
    _checkDailyReset();
    if (_dailyRewardedCount >= _maxDailyRewarded) return false;
    if (_lastRewardedAdTime != null) {
      final elapsed = DateTime.now().difference(_lastRewardedAdTime!);
      if (elapsed < _rewardedAdCooldown) return false;
    }
    return true;
  }

  Duration get _currentFreeGemsCooldown {
    if (_dailyFreeGemsCount >= _freeGemsCooldowns.length) {
      return _freeGemsCooldowns.last;
    }
    return _freeGemsCooldowns[_dailyFreeGemsCount];
  }

  bool get canShowFreeGemsAd {
    _checkDailyReset();
    if (_dailyFreeGemsCount >= _maxDailyFreeGems) return false;
    if (_lastFreeGemsTime != null) {
      final elapsed = DateTime.now().difference(_lastFreeGemsTime!);
      if (elapsed < _currentFreeGemsCooldown) return false;
    }
    return canShowRewardedAd;
  }

  int get freeGemsCooldownSeconds {
    if (_lastFreeGemsTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastFreeGemsTime!);
    final remaining = _currentFreeGemsCooldown - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  String get freeGemsCooldownFormatted {
    final secs = freeGemsCooldownSeconds;
    if (secs <= 0) return AppStrings.trs('ad_cooldown_ready');
    final hours = secs ~/ 3600;
    final mins = (secs % 3600) ~/ 60;
    if (hours > 0) return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    return '${mins}m';
  }

  int get currentFreeGemsRound => _dailyFreeGemsCount;

  int get rewardedAdCooldownSeconds {
    if (_lastRewardedAdTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastRewardedAdTime!);
    final remaining = _rewardedAdCooldown - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  int get remainingDailyRewarded {
    _checkDailyReset();
    return _maxDailyRewarded - _dailyRewardedCount;
  }

  int get remainingDailyFreeGems {
    _checkDailyReset();
    return _maxDailyFreeGems - _dailyFreeGemsCount;
  }

  /// 초기화
  Future<void> init() async {
    if (_initialized) return;

    // 세이브 데이터 로드
    final adData = await SaveManager.instance.loadAdData();
    if (adData != null) {
      if (adData['lastRewardedAdTime'] != null) {
        _lastRewardedAdTime = DateTime.tryParse(adData['lastRewardedAdTime']);
      }
      _dailyRewardedCount = adData['dailyRewardedCount'] ?? 0;
      if (adData['lastFreeGemsTime'] != null) {
        _lastFreeGemsTime = DateTime.tryParse(adData['lastFreeGemsTime']);
      }
      _dailyFreeGemsCount = adData['dailyFreeGemsCount'] ?? 0;
      if (adData['dailyResetDate'] != null) {
        _dailyResetDate = DateTime.tryParse(adData['dailyResetDate']) ?? DateTime.now();
      }
    }

    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      _loadRewardedAd();
      if (kDebugMode) dlog('[AD] AdMob SDK 초기화 완료');
    } else {
      if (kDebugMode) dlog('[AD] 웹 환경 — AdMob 스킵 (CrazyGames SDK 사용)');
    }

    _initialized = true;
  }

  /// 보상형 광고 미리 로드
  void _loadRewardedAd() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          if (kDebugMode) dlog('[AD] 보상형 광고 로드 완료');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          if (kDebugMode) dlog('[AD] 보상형 광고 로드 실패: $error');
        },
      ),
    );
  }

  /// 보상형 광고 시청 (목적별)
  Future<AdReward?> showRewardedAd({
    RewardedAdPurpose purpose = RewardedAdPurpose.freeGems,
  }) async {
    if (!canShowRewardedAd) return null;
    if (_isAdPlaying) return null;

    _isAdPlaying = true;

    try {
      if (kIsWeb) {
        // 웹: 3초 시뮬레이션
        await Future.delayed(const Duration(seconds: 3));
        return _buildReward(purpose);
      }

      // Android: 실제 AdMob 보상형 광고
      if (_rewardedAd == null) {
        // 광고 미로드 시 재시도 후 시뮬레이션 fallback
        _loadRewardedAd();
        await Future.delayed(const Duration(seconds: 3));
        return _buildReward(purpose);
      }

      final completer = Completer<AdReward?>();

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd(); // 다음 광고 미리 로드
          if (!completer.isCompleted) completer.complete(null);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (_, __) {
          final reward = _buildReward(purpose);
          if (!completer.isCompleted) completer.complete(reward);
        },
      );

      final reward = await completer.future;
      if (reward == null) return null;

      _lastRewardedAdTime = DateTime.now();
      _dailyRewardedCount++;
      if (purpose == RewardedAdPurpose.freeGems) {
        _lastFreeGemsTime = DateTime.now();
        _dailyFreeGemsCount++;
      }
      await _saveData();

      if (kDebugMode) dlog('[AD] 보상형 완료: ${reward.description}');
      return reward;

    } on Exception catch (e) {
      if (kDebugMode) dlog('[AD] 보상형 광고 오류: $e');
      return null;
    } finally {
      _isAdPlaying = false;
    }
  }

  /// 목적별 보상 객체 생성 + 카운트 업데이트 (웹 시뮬레이션용)
  AdReward _buildReward(RewardedAdPurpose purpose) {
    _lastRewardedAdTime = DateTime.now();
    _dailyRewardedCount++;
    if (purpose == RewardedAdPurpose.freeGems) {
      _lastFreeGemsTime = DateTime.now();
      _dailyFreeGemsCount++;
    }
    _saveData();

    return switch (purpose) {
      RewardedAdPurpose.freeGems     => const AdReward(gems: 30,  description: '💎 30 Gems!',         purpose: RewardedAdPurpose.freeGems),
      RewardedAdPurpose.revive       => const AdReward(gems: 0,   description: '💚 Gateway HP +50%!',  purpose: RewardedAdPurpose.revive),
      RewardedAdPurpose.doubleReward => const AdReward(gems: 0,   description: '✨ Double Reward!',     purpose: RewardedAdPurpose.doubleReward),
      RewardedAdPurpose.freeSummon   => const AdReward(gems: 0,   description: '🎫 Free Summon x1!',   purpose: RewardedAdPurpose.freeSummon),
      RewardedAdPurpose.bonusMission => const AdReward(gems: 15,  description: '🎁 Bonus Reward!',     purpose: RewardedAdPurpose.bonusMission),
      RewardedAdPurpose.seasonPremium=> const AdReward(gems: 0,   description: '✨ Premium Pass!',      purpose: RewardedAdPurpose.seasonPremium),
    };
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _dailyResetDate.day ||
        now.month != _dailyResetDate.month ||
        now.year != _dailyResetDate.year) {
      _dailyRewardedCount = 0;
      _dailyFreeGemsCount = 0;
      _dailyResetDate = now;
      _saveData();
    }
  }

  Future<void> _saveData() async {
    await SaveManager.instance.saveAdData({
      'lastRewardedAdTime': _lastRewardedAdTime?.toIso8601String(),
      'dailyRewardedCount': _dailyRewardedCount,
      'lastFreeGemsTime': _lastFreeGemsTime?.toIso8601String(),
      'dailyFreeGemsCount': _dailyFreeGemsCount,
      'dailyResetDate': _dailyResetDate.toIso8601String(),
    });
  }
}
