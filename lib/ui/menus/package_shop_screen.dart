// 해원의 문 - 패키지 상점 화면
// 보석, 골드, 시즌 패스 등 유료 상품 판매
// 72시간 한정 특가 / 첫 구매 3배 / 할인 뱃지 지원

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/season_pass_data.dart';
import '../../state/shop_provider.dart';
import '../../state/user_state.dart';
import '../../state/season_pass_provider.dart';
import '../../state/summon_provider.dart';
import '../../common/responsive.dart';
import '../theme/app_colors.dart';
import '../dialogs/ad_simulator_dialog.dart';

class PackageShopScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const PackageShopScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userStateProvider);
    final vipState = ref.watch(vipProvider);
    final summonState = ref.watch(summonProvider);
    final shopState = ref.watch(shopProvider);
    final shopNotifier = ref.read(shopProvider.notifier);
    final s = Responsive.scale(context);

    // 한정 패키지 firstSeen 자동 기록 방어 코드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final pkg in timeLimitedPackages) {
        shopNotifier.markFirstSeen(pkg.id);
      }
    });

    // 패키지 분류
    final limitedActive = timeLimitedPackages
        .where((p) => !shopNotifier.isExpired(p))
        .toList();
    final firstPurchase = firstPurchaseBonusPackages
        .where((p) => shopNotifier.isFirstPurchase(p))
        .toList();
    final recommended = allShopPackages.where((p) => p.isHighlight).toList();
    final gemPacks = allShopPackages.where((p) => p.type == PackageType.gems).toList();
    final specialPacks = allShopPackages
        .where((p) => p.type == PackageType.starter ||
            p.type == PackageType.weekly ||
            p.type == PackageType.monthly)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          // 배경 에셋 투과
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/objects/obj_shrine.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── 헤더 ──
                _buildHeader(context, userState, vipState, summonState, s),

            // ── 상품 목록 ──
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16 * s),
                children: [
                  // ── 광고 보상 ──
                  _buildAdRewardBanner(context, ref, s),
                  SizedBox(height: 24 * s),

                  // ── 한정 특가 (72시간) ──
                  if (limitedActive.isNotEmpty) ...[
                    _buildSectionTitle(context, '🔥 한정 특가', s, accent: AppColors.berserkRed),
                    _buildPackageGrid(context, ref, limitedActive, s),
                    SizedBox(height: 24 * s),
                  ],

                  // ── 첫 구매 3배 ──
                  if (firstPurchase.isNotEmpty) ...[
                    _buildSectionTitle(context, '🌟 첫 구매 3배 보너스', s, accent: AppColors.sinmyeongGold),
                    _buildPackageGrid(context, ref, firstPurchase, s),
                    SizedBox(height: 24 * s),
                  ],

                  // ── 추천 상품 ──
                  _buildSectionTitle(context, '✨ 추천 상품', s),
                  _buildPackageGrid(context, ref, recommended, s),

                  SizedBox(height: 24 * s),
                  _buildSectionTitle(context, '💎 보석 충전', s),
                  _buildPackageGrid(context, ref, gemPacks, s),

                  SizedBox(height: 24 * s),
                  _buildSectionTitle(context, '📦 특별 제안', s),
                  _buildPackageGrid(context, ref, specialPacks, s),

                  SizedBox(height: 40 * s),
                ],
              ),
            ),
          ],
        ),
      ),
      ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserState user, VipState vip, SummonState summon, double s) {
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: AppColors.bgDeepPlum.withAlpha(204),
        border: const Border(bottom: BorderSide(color: AppColors.lavender, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              Text(
                '💰 상점',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, 24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildResourceBadge(Icons.diamond, '${user.gems}', AppColors.skyBlue, s),
              SizedBox(width: 8 * s),
              _buildResourceBadge(Icons.stars, '${user.membershipPoints}', AppColors.sinmyeongGold, s),
              SizedBox(width: 8 * s),
              _buildResourceBadge(Icons.confirmation_num, '${summon.heroSummonTickets}', const Color(0xFFE91E63), s),
            ],
          ),
          SizedBox(height: 12 * s),
          _buildVipProgress(context, vip, s),
        ],
      ),
    );
  }

  Widget _buildResourceBadge(IconData icon, String value, Color color, double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15 * s),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16 * s),
          SizedBox(width: 4 * s),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdRewardBanner(BuildContext context, WidgetRef ref, double s) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AdSimulatorDialog(
            onRewardEarned: () {
              ref.read(userStateProvider.notifier).addGems(10);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('광고 시청 완료! 보석 10개가 지급되었습니다.')),
              );
            },
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: AppColors.bgDeepPlum.withAlpha(230),
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: AppColors.sinmyeongGold),
          boxShadow: [
            BoxShadow(color: AppColors.sinmyeongGold.withAlpha(40), blurRadius: 10 * s),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12 * s),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lavender),
              ),
              child: Icon(Icons.play_circle_fill, color: AppColors.sinmyeongGold, size: 32 * s),
            ),
            SizedBox(width: 16 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '무료 보석 받기!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4 * s),
                  Text(
                    '광고 시청하고 보석 10개를 획득하세요',
                    style: TextStyle(color: Colors.white70, fontSize: 13 * s),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
              decoration: BoxDecoration(
                color: AppColors.sinmyeongGold,
                borderRadius: BorderRadius.circular(8 * s),
              ),
              child: const Text('시청하기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVipProgress(BuildContext context, VipState vip, double s) {
    final currentTier = vip.tier;
    final nextTierSpend = currentTier.nextTierSpend(vip.totalSpendKRW);
    final progress = currentTier == VipTier.diamond
        ? 1.0
        : vip.totalSpendKRW / VipTier.values[VipTier.values.indexOf(currentTier) + 1].requiredSpend;

    return Container(
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: currentTier.color.withAlpha(100)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentTier.emoji} ${currentTier.displayName}',
                style: TextStyle(color: currentTier.color, fontWeight: FontWeight.bold),
              ),
              if (currentTier != VipTier.diamond)
                Text(
                  '다음 등급까지: ₩${_formatNumber(nextTierSpend)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
            ],
          ),
          SizedBox(height: 8 * s),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black45,
              valueColor: AlwaysStoppedAnimation<Color>(currentTier.color),
              minHeight: 6 * s,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, double s, {Color? accent}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * s),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent ?? AppColors.lavender,
              fontSize: Responsive.fontSize(context, 18),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (accent != null) ...[
            SizedBox(width: 8 * s),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
              decoration: BoxDecoration(
                color: accent.withAlpha(40),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withAlpha(100)),
              ),
              child: Text(
                'EVENT',
                style: TextStyle(
                  color: accent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageGrid(BuildContext context, WidgetRef ref, List<ShopPackage> packages, double s) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isLandscape(context) ? 5 : 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12 * s,
        mainAxisSpacing: 12 * s,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        return _PackageCard(package: packages[index]);
      },
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

// ═══════════════════════════════════════════
// 패키지 카드 위젯 (한정/첫구매/할인 뱃지 포함)
// ═══════════════════════════════════════════

class _PackageCard extends ConsumerStatefulWidget {
  final ShopPackage package;

  const _PackageCard({required this.package});

  @override
  ConsumerState<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends ConsumerState<_PackageCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 한정 패키지 → 1초마다 카운트다운 갱신
    if (widget.package.expiresAfter != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final package = widget.package;
    final shopNotifier = ref.read(shopProvider.notifier);
    final shopState = ref.watch(shopProvider);
    final currentCount = shopState.purchaseCounts[package.id] ?? 0;
    final isSoldOut = package.limitCount != null && currentCount >= package.limitCount!;
    final isExpired = shopNotifier.isExpired(package);
    final isFirst = shopNotifier.isFirstPurchase(package);
    final hasDiscount = package.discountPercent > 0;
    final hasFirstBonus = package.firstPurchaseMultiplier > 1 && isFirst;
    final remaining = shopNotifier.getRemainingTime(package);
    // 패키지 타입별 그라데이션 색상
    List<Color> getGradientColors() {
      switch (package.type) {
        case PackageType.seasonPass:
          return [const Color(0xFF4A148C), const Color(0xFF1A237E)];
        case PackageType.starter:
          return [const Color(0xFFC62828), const Color(0xFF4A148C)];
        case PackageType.weekly:
        case PackageType.monthly:
          return [const Color(0xFF00695C), const Color(0xFF004D40)];
        case PackageType.gems:
          return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
        default:
          return [AppColors.bgDeepPlum, AppColors.bgDeepPlum.withAlpha(200)];
      }
    }

    return GestureDetector(
      onTap: (isSoldOut || isExpired) ? null : () => _showPurchaseConfirm(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16 * s),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: getGradientColors().map((c) => c.withOpacity(0.8)).toList(),
          ),
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(
            color: _borderColor(package, hasFirstBonus, hasDiscount),
            width: (package.isHighlight || hasFirstBonus || hasDiscount) ? 2 : 1,
          ),
          boxShadow: (package.isHighlight || hasFirstBonus)
              ? [BoxShadow(color: _borderColor(package, hasFirstBonus, hasDiscount).withOpacity(0.4), blurRadius: 10 * s)]
              : null,
        ),
        child: Stack(
          children: [
            // ── 메인 콘텐츠 ──
            Center(
              child: Padding(
                padding: EdgeInsets.all(8 * s),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  // 아이콘 (고품질 이미지 또는 이모지)
                  if (package.imagePath != null)
                    Image.asset(
                      package.imagePath!,
                      height: 52 * s,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(package.emoji, style: TextStyle(fontSize: 36 * s)),
                    )
                  else
                    Text(package.emoji, style: TextStyle(fontSize: 36 * s)),
                  SizedBox(height: 6 * s),

                  // 이름
                  Text(
                    package.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 13),
                    ),
                  ),
                  SizedBox(height: 4 * s),

                  // 가격 표시
                  _buildPriceRow(package, hasDiscount, s),

                  // 첫 구매 보너스 표시
                  if (hasFirstBonus) ...[
                    SizedBox(height: 6 * s),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.sinmyeongGold, const Color(0xFFFF8800)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '첫 구매 ${package.firstPurchaseMultiplier}배!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10 * s,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  // 카운트다운 타이머
                  if (remaining != null && !isExpired) ...[
                    SizedBox(height: 6 * s),
                    _buildCountdown(remaining, s),
                  ],

                  // 추천 라벨
                  if (package.isHighlight && !hasFirstBonus && !hasDiscount) ...[
                    SizedBox(height: 6 * s),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sinmyeongGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '강력 추천',
                        style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── 마일리지 적립 ──
            Positioned(
              top: 6 * s,
              right: 6 * s,
              child: Container(
                padding: EdgeInsets.all(3 * s),
                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: Text(
                  '+${(package.discountedPrice * 0.1).toInt()}P',
                  style: const TextStyle(color: AppColors.sinmyeongGold, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ── 할인 뱃지 ──
            if (hasDiscount)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16 * s),
                      bottomRight: Radius.circular(12 * s),
                    ),
                  ),
                  child: Text(
                    '-${package.discountPercent}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11 * s,
                    ),
                  ),
                ),
              ),

            // ── 품절/만료 오버레이 ──
            if (isSoldOut || isExpired)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(180),
                  borderRadius: BorderRadius.circular(16 * s),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpired ? Icons.timer_off : Icons.check_circle,
                        color: Colors.white54,
                        size: 32 * s,
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        isExpired ? '기간 만료' : '구매 완료',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  /// 가격 행: 할인 시 원가 취소선 + 할인가 + 가치 문구 표시
  Widget _buildPriceRow(ShopPackage package, bool hasDiscount, double s) {
    if (hasDiscount) {
      // 내용물의 보석 환산 가치 계산 (보석 1개 = ₩20 기준)
      final gemValue = (package.contents['gems'] ?? 0) * 20;
      final goldValue = ((package.contents['gold'] ?? 0) / 100).round() * 20; // 골드 100 = 보석1
      final ticketValue = (package.contents['summonTicket'] ?? 0) * 500; // 소환권 1장 = ₩500
      final totalValue = gemValue + goldValue + ticketValue;
      final showValue = totalValue > package.discountedPrice;

      return Column(
        children: [
          Text(
            '₩${_formatNum(package.priceKRW)}',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11 * s,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white38,
            ),
          ),
          Text(
            '₩${_formatNum(package.discountedPrice)}',
            style: TextStyle(
              color: AppColors.berserkRed,
              fontSize: 14 * s,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showValue)
            Text(
              '₩${_formatNum(package.discountedPrice)}으로 ₩${_formatNum(totalValue)} 가치!',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 9 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      );
    }
    return Text(
      '₩${_formatNum(package.priceKRW)}',
      style: TextStyle(
        color: AppColors.lavender,
        fontSize: 13 * s,
      ),
    );
  }

  /// 카운트다운 타이머
  Widget _buildCountdown(Duration remaining, double s) {
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final sec = remaining.inSeconds % 60;
    final isUrgent = remaining.inHours < 6;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0x44FF1744) : const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFF1744) : const Color(0x44FFFFFF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 12 * s,
            color: isUrgent ? const Color(0xFFFF4444) : Colors.white54,
          ),
          SizedBox(width: 4 * s),
          Text(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isUrgent ? const Color(0xFFFF4444) : Colors.white70,
              fontSize: 11 * s,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Color _borderColor(ShopPackage pkg, bool hasFirstBonus, bool hasDiscount) {
    if (hasDiscount) return AppColors.berserkRed;
    if (hasFirstBonus) return AppColors.sinmyeongGold;
    if (pkg.isHighlight) return AppColors.sinmyeongGold;
    return const Color(0xFF333366);
  }

  void _showPurchaseConfirm(BuildContext context, WidgetRef ref) {
    final package = widget.package;
    final isFirst = ref.read(shopProvider.notifier).isFirstPurchase(package);
    final hasBonus = package.firstPurchaseMultiplier > 1 && isFirst;
    final hasDiscount = package.discountPercent > 0;

    // 실제 지급 내용물 계산
    final effectiveContents = package.getEffectiveContents(isFirst);
    final contentsText = effectiveContents.entries
        .map((e) => '${_contentName(e.key)}: ${e.value}')
        .join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDeepPlum,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(package.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(package.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.description,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // 지급 내역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333366)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📦 지급 내역', style: TextStyle(color: AppColors.lavender, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(contentsText, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  if (hasBonus) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🌟 첫 구매 ${package.firstPurchaseMultiplier}배 적용!',
                      style: const TextStyle(color: AppColors.sinmyeongGold, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 가격
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('결제 금액', style: TextStyle(color: Colors.white70)),
                hasDiscount
                    ? Row(
                        children: [
                          Text(
                            '₩${_formatNum(package.priceKRW)}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₩${_formatNum(package.discountedPrice)}',
                            style: const TextStyle(color: AppColors.berserkRed, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      )
                    : Text(
                        '₩${_formatNum(package.priceKRW)}',
                        style: const TextStyle(color: AppColors.lavender, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '(테스트 환경: 즉시 구매 완료 처리)',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6633AA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final success = ref.read(shopProvider.notifier).purchasePackage(package);
              if (success && package.type == PackageType.monthly) {
                ref.read(vipProvider.notifier).purchaseMonthlySubscription();
              }
              Navigator.pop(ctx);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceMid,
                    content: Row(
                      children: [
                        Text('${package.emoji} '),
                        Expanded(child: Text('${package.name} 구매 완료!')),
                      ],
                    ),
                  ),
                );
              }
            },
            child: const Text('구매'),
          ),
        ],
      ),
    );
  }

  String _contentName(String key) {
    switch (key) {
      case 'gems': return '💎 보석';
      case 'gold': return '🪙 골드';
      case 'premiumPass': return '🌸 프리미엄 패스';
      case 'dailyGems': return '💎 일일 보석';
      case 'summonTicket': return '🎟️ 소환권';
      case 'towerUpgrade': return '🗼 타워 강화';
      default: return key;
    }
  }

  String _formatNum(int n) {
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
