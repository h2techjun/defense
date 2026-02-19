// 해원의 문 - 광고 매니저
// 보상형 광고 + 배너 광고 관리
// 웹 환경에서는 시뮬레이션 모드, 모바일에서는 AdMob 연동 예정

import 'dart:async';
import 'package:flutter/foundation.dart';

/// 광고 유형
enum AdType {
  rewarded,   // 보상형 (보석 획득)
  interstitial, // 전면 (스테이지 사이)
  banner,     // 배너 (하단)
}

/// 보상형 광고 결과
class AdReward {
  final int gems;
  final String description;

  const AdReward({required this.gems, required this.description});
}

/// 광고 매니저 — 싱글톤
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  bool _initialized = false;
  bool _isAdPlaying = false;

  // 광고 쿨다운 (과도한 광고 시청 방지)
  DateTime? _lastRewardedAdTime;
  static const _rewardedAdCooldown = Duration(minutes: 3);

  // 일일 보상형 광고 제한
  int _dailyRewardedCount = 0;
  static const _maxDailyRewarded = 10;
  DateTime _dailyResetDate = DateTime.now();

  bool get isInitialized => _initialized;
  bool get isAdPlaying => _isAdPlaying;

  /// 보상형 광고 시청 가능 여부
  bool get canShowRewardedAd {
    _checkDailyReset();

    // 일일 제한 확인
    if (_dailyRewardedCount >= _maxDailyRewarded) return false;

    // 쿨다운 확인
    if (_lastRewardedAdTime != null) {
      final elapsed = DateTime.now().difference(_lastRewardedAdTime!);
      if (elapsed < _rewardedAdCooldown) return false;
    }

    return true;
  }

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

  /// 초기화
  Future<void> init() async {
    if (_initialized) return;

    // 웹 환경: 시뮬레이션 모드
    // 모바일 환경: AdMob SDK 초기화 (추후 구현)
    if (kIsWeb) {
      if (kDebugMode) debugPrint('📺 AdManager 초기화 (웹 시뮬레이션)');
    } else {
      if (kDebugMode) debugPrint('📺 AdManager 초기화 (모바일)');
      // TODO: MobileAds.instance.initialize();
    }

    _initialized = true;
  }

  /// 보상형 광고 시청 — 완료 시 AdReward 반환, 취소/실패 시 null
  Future<AdReward?> showRewardedAd() async {
    if (!canShowRewardedAd) return null;
    if (_isAdPlaying) return null;

    _isAdPlaying = true;

    try {
      if (kIsWeb) {
        // 웹 시뮬레이션: 3초 대기 후 보상
        await Future.delayed(const Duration(seconds: 3));
      } else {
        // 모바일: 실제 광고 로드 + 표시
        // TODO: 실제 AdMob 보상형 광고 연동
        await Future.delayed(const Duration(seconds: 3));
      }

      _lastRewardedAdTime = DateTime.now();
      _dailyRewardedCount++;

      const reward = AdReward(gems: 30, description: '광고 시청 보상');

      if (kDebugMode) {
        debugPrint('💎 보상형 광고 완료: +${reward.gems} 보석 (오늘 $_dailyRewardedCount/$_maxDailyRewarded)');
      }

      return reward;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 광고 오류: $e');
      return null;
    } finally {
      _isAdPlaying = false;
    }
  }

  /// 일일 리셋 확인
  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _dailyResetDate.day ||
        now.month != _dailyResetDate.month ||
        now.year != _dailyResetDate.year) {
      _dailyRewardedCount = 0;
      _dailyResetDate = now;
    }
  }
}
