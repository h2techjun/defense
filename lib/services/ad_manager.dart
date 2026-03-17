// 해원의 문 - 광고 매니저
// 보상형 광고 + 전면(Interstitial) + 배너 관리
// 웹 환경에서는 시뮬레이션 모드, 모바일에서는 AdMob 연동 예정

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'save_manager.dart';

/// 광고 유형
enum AdType {
  rewarded,      // 보상형 (보석/부활/2배 등)
  interstitial,  // 전면 (스테이지 사이)
  banner,        // 배너 (하단)
}

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

  // 보상형 광고 쿨다운 (과도한 광고 시청 방지)
  DateTime? _lastRewardedAdTime;
  static const _rewardedAdCooldown = Duration(minutes: 2);

  // 일일 보상형 광고 제한
  int _dailyRewardedCount = 0;
  static const _maxDailyRewarded = 15;
  DateTime _dailyResetDate = DateTime.now();

  // 전면 광고 — 3판마다 1회
  int _stagesSinceLastInterstitial = 0;
  static const _interstitialInterval = 3;

  // 무료 보석 — 점진적 쿨다운 (총 12시간에 걸쳐 5회)
  // 1회차: 즉시, 2회차: 30분, 3회차: 90분, 4회차: 3시간, 5회차: 7시간
  DateTime? _lastFreeGemsTime;
  static const List<Duration> _freeGemsCooldowns = [
    Duration.zero,              // 1회차: 즉시
    Duration(minutes: 30),      // 2회차: 30분 후
    Duration(minutes: 90),      // 3회차: 1시간 30분 후
    Duration(hours: 3),         // 4회차: 3시간 후
    Duration(hours: 7),         // 5회차: 7시간 후
  ];
  static const _freeGemsAmount = 30;
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

  /// 현재 회차의 쿨다운
  Duration get _currentFreeGemsCooldown {
    if (_dailyFreeGemsCount >= _freeGemsCooldowns.length) {
      return _freeGemsCooldowns.last;
    }
    return _freeGemsCooldowns[_dailyFreeGemsCount];
  }

  /// 무료 보석 광고 시청 가능 여부
  bool get canShowFreeGemsAd {
    _checkDailyReset();
    if (_dailyFreeGemsCount >= _maxDailyFreeGems) return false;
    if (_lastFreeGemsTime != null) {
      final elapsed = DateTime.now().difference(_lastFreeGemsTime!);
      if (elapsed < _currentFreeGemsCooldown) return false;
    }
    return canShowRewardedAd;
  }

  /// 다음 무료 보석까지 남은 시간 (초)
  int get freeGemsCooldownSeconds {
    if (_lastFreeGemsTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastFreeGemsTime!);
    final remaining = _currentFreeGemsCooldown - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  /// 남은 시간 포맷 ("2시간 30분" / "45분" / "즉시 가능")
  String get freeGemsCooldownFormatted {
    final secs = freeGemsCooldownSeconds;
    if (secs <= 0) return '즉시 가능';
    final hours = secs ~/ 3600;
    final mins = (secs % 3600) ~/ 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}시간 ${mins}분' : '${hours}시간';
    }
    return '${mins}분';
  }

  /// 현재 회차 번호 (1~5)
  int get currentFreeGemsRound => _dailyFreeGemsCount + 1;

  /// 다음 보상형 광고까지 남은 시간 (초)
  int get rewardedAdCooldownSeconds {
    if (_lastRewardedAdTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastRewardedAdTime!);
    final remaining = _rewardedAdCooldown - elapsed;
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  /// 일일 남은 보상형 광고 횟수
  int get remainingDailyRewarded {
    _checkDailyReset();
    return _maxDailyRewarded - _dailyRewardedCount;
  }

  /// 일일 남은 무료 보석 횟수
  int get remainingDailyFreeGems {
    _checkDailyReset();
    return _maxDailyFreeGems - _dailyFreeGemsCount;
  }

  /// 전면 광고 표시 필요 여부 (3판마다)
  bool get shouldShowInterstitial {
    return _stagesSinceLastInterstitial >= _interstitialInterval;
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
      if (kDebugMode) debugPrint('[AD] 광고 시청 데이터 로드 완료');
    }

    if (kIsWeb) {
      if (kDebugMode) debugPrint('📺 AdManager 초기화 (웹 시뮬레이션)');
    } else {
      if (kDebugMode) debugPrint('📺 AdManager 초기화 (모바일)');
      // TODO: MobileAds.instance.initialize();
    }
    _initialized = true;
  }

  /// 보상형 광고 시청 (목적별)
  Future<AdReward?> showRewardedAd({
    RewardedAdPurpose purpose = RewardedAdPurpose.freeGems,
  }) async {
    if (!canShowRewardedAd) return null;
    if (_isAdPlaying) return null;

    _isAdPlaying = true;

    try {
      // 시뮬레이션: 3초 대기
      await Future.delayed(const Duration(seconds: 3));

      _lastRewardedAdTime = DateTime.now();
      _dailyRewardedCount++;

      // 목적별 보상 설정
      final reward = switch (purpose) {
        RewardedAdPurpose.freeGems => const AdReward(
          gems: 30,
          description: '💎 보석 30개 획득!',
          purpose: RewardedAdPurpose.freeGems,
        ),
        RewardedAdPurpose.revive => const AdReward(
          gems: 0,
          description: '💚 게이트웨이 HP 50% 회복!',
          purpose: RewardedAdPurpose.revive,
        ),
        RewardedAdPurpose.doubleReward => const AdReward(
          gems: 0,
          description: '✨ 보상 2배 적용!',
          purpose: RewardedAdPurpose.doubleReward,
        ),
        RewardedAdPurpose.freeSummon => const AdReward(
          gems: 0,
          description: '🎫 무료 소환 1회!',
          purpose: RewardedAdPurpose.freeSummon,
        ),
        RewardedAdPurpose.bonusMission => const AdReward(
          gems: 15,
          description: '🎁 추가 보상 획득!',
          purpose: RewardedAdPurpose.bonusMission,
        ),
        RewardedAdPurpose.seasonPremium => const AdReward(
          gems: 0,
          description: '✨ 프리미엄 패스 해금!',
          purpose: RewardedAdPurpose.seasonPremium,
        ),
      };

      // 무료 보석인 경우 카운트 업데이트
      if (purpose == RewardedAdPurpose.freeGems) {
        _lastFreeGemsTime = DateTime.now();
        _dailyFreeGemsCount++;
      }

      await _saveData();

      if (kDebugMode) {
        debugPrint('📺 보상형 광고 완료: ${reward.description} (오늘 $_dailyRewardedCount/$_maxDailyRewarded)');
      }

      return reward;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 광고 오류: $e');
      return null;
    } finally {
      _isAdPlaying = false;
    }
  }

  /// 전면 광고 표시 (스테이지 끝)
  Future<void> showInterstitialAd() async {
    if (_isAdPlaying) return;
    _isAdPlaying = true;

    try {
      // 시뮬레이션: 3초 대기
      await Future.delayed(const Duration(seconds: 3));
      _stagesSinceLastInterstitial = 0;

      if (kDebugMode) debugPrint('📺 전면 광고 표시 완료');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 전면 광고 오류: $e');
    } finally {
      _isAdPlaying = false;
    }
  }

  /// 스테이지 완료 기록 (전면 광고 카운터)
  void recordStageComplete() {
    _stagesSinceLastInterstitial++;
  }

  /// 일일 리셋 확인
  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _dailyResetDate.day ||
        now.month != _dailyResetDate.month ||
        now.year != _dailyResetDate.year) {
      _dailyRewardedCount = 0;
      _dailyFreeGemsCount = 0;
      _dailyResetDate = now;
      _saveData(); // 초기화 시 바로 자동 저장 방시
    }
  }

  /// 내부 데이터 저장 훅
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
