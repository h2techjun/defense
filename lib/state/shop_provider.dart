// 해원의 문 - 상점 상태 관리 (Riverpod)
// 패키지 구매 및 보상 지급 시스템

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/season_pass_data.dart';
import '../services/save_manager.dart';
import 'user_state.dart';
import 'season_pass_provider.dart';
import 'summon_provider.dart';

class ShopState {
  final Map<String, int> purchaseCounts; // id -> count
  final Set<String> activeSubscriptions; // id (e.g., 'weekly_gems')
  final Map<String, DateTime> firstSeenTimes; // 한정 패키지 첫 노출 시각

  const ShopState({
    this.purchaseCounts = const {},
    this.activeSubscriptions = const {},
    this.firstSeenTimes = const {},
  });

  ShopState copyWith({
    Map<String, int>? purchaseCounts,
    Set<String>? activeSubscriptions,
    Map<String, DateTime>? firstSeenTimes,
  }) {
    return ShopState(
      purchaseCounts: purchaseCounts ?? this.purchaseCounts,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
      firstSeenTimes: firstSeenTimes ?? this.firstSeenTimes,
    );
  }

  Map<String, dynamic> toJson() => {
    'purchaseCounts': purchaseCounts.map((k, v) => MapEntry(k, v)),
    'activeSubscriptions': activeSubscriptions.toList(),
    'firstSeenTimes': firstSeenTimes.map(
        (k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
  };

  factory ShopState.fromJson(Map<String, dynamic> json) {
    return ShopState(
      purchaseCounts: (json['purchaseCounts'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
      activeSubscriptions: (json['activeSubscriptions'] as List<dynamic>?)
          ?.map((e) => e as String).toSet() ?? {},
      firstSeenTimes: (json['firstSeenTimes'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k,
              DateTime.fromMillisecondsSinceEpoch((v as num).toInt()))) ?? {},
    );
  }
}

class ShopNotifier extends StateNotifier<ShopState> {
  final Ref _ref;
  ShopNotifier(this._ref) : super(const ShopState());

  /// 데이터 로드
  Future<void> load() async {
    final data = await SaveManager.instance.loadCustomData('shop_state');
    if (data != null) {
      state = ShopState.fromJson(data);
    }
  }

  /// 자동 저장
  Future<void> _save() async {
    await SaveManager.instance.saveCustomData('shop_state', state.toJson());
  }

  /// 패키지 구매 실행
  bool purchasePackage(ShopPackage package) {
    // 1. 구매 제한 체크
    final currentCount = state.purchaseCounts[package.id] ?? 0;
    if (package.limitCount != null && currentCount >= package.limitCount!) {
      return false;
    }

    // 2. 시간 제한 체크
    if (isExpired(package)) return false;

    // 3. 가상 결제 프로세스 (Always Run: 성공 가정)
    // 실제 환경에서는 플랫폼 인앱 결제 API 호출
    
    // 4. 결제액 VIP 반영 (할인 적용 가격)
    _ref.read(vipProvider.notifier).addPurchase(package.discountedPrice);

    // 5. 멤버십 포인트 적립 (10% 적립)
    final points = (package.discountedPrice * 0.1).toInt();
    _ref.read(userStateProvider.notifier).addMembershipPoints(points);

    // 6. 첫 구매 보너스 적용 여부
    final isFirstPurchase = currentCount == 0;
    final effectiveContents = package.getEffectiveContents(isFirstPurchase);

    // 7. 패키지 내용물 지급
    final userNotifier = _ref.read(userStateProvider.notifier);
    effectiveContents.forEach((key, value) {
      switch (key) {
        case 'gems':
          userNotifier.addGems(value);
          break;
        case 'gold':
          userNotifier.addGold(value);
          break;
        case 'premiumPass':
          _ref.read(seasonPassProvider.notifier).purchasePremium();
          state = state.copyWith(
            activeSubscriptions: {...state.activeSubscriptions, package.id},
          );
          break;
        case 'dailyGems':
          // 구독 활성화만 (일별 지급은 별도 로직)
          state = state.copyWith(
            activeSubscriptions: {...state.activeSubscriptions, package.id},
          );
          break;
        case 'summonTicket':
        case 'towerUpgrade':
          _ref.read(summonProvider.notifier).addTickets(key, value);
          break;
        default:
          print('[Shop] 미구현 보상 타입: $key');
      }
    });

    // 8. 구매 횟수 갱신
    state = state.copyWith(
      purchaseCounts: {...state.purchaseCounts, package.id: currentCount + 1},
    );

    _save();
    return true;
  }

  /// 구매 가능 여부 확인
  bool canPurchase(ShopPackage package) {
    final currentCount = state.purchaseCounts[package.id] ?? 0;
    if (package.limitCount != null && currentCount >= package.limitCount!) {
      return false;
    }
    if (isExpired(package)) return false;
    return true;
  }

  /// 첫 구매 여부
  bool isFirstPurchase(ShopPackage package) {
    return (state.purchaseCounts[package.id] ?? 0) == 0;
  }

  /// 한정 패키지 만료 여부
  bool isExpired(ShopPackage package) {
    if (package.expiresAfter == null) return false;
    final firstSeen = state.firstSeenTimes[package.id];
    if (firstSeen == null) return false;
    return DateTime.now().isAfter(firstSeen.add(package.expiresAfter!));
  }

  /// 한정 패키지 남은 시간
  Duration? getRemainingTime(ShopPackage package) {
    if (package.expiresAfter == null) return null;
    final firstSeen = state.firstSeenTimes[package.id];
    if (firstSeen == null) return package.expiresAfter;
    final deadline = firstSeen.add(package.expiresAfter!);
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 한정 패키지 첫 노출 기록
  void markFirstSeen(String packageId) {
    if (!state.firstSeenTimes.containsKey(packageId)) {
      state = state.copyWith(
        firstSeenTimes: {...state.firstSeenTimes, packageId: DateTime.now()},
      );
      _save();
    }
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  return ShopNotifier(ref);
});
