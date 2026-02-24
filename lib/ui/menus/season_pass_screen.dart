// 해원의 문 - 시즌 패스 UI 화면
// 무료/프리미엄 트랙, VIP 정보, 상점

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/responsive.dart';
import '../../data/models/season_pass_data.dart';
import '../../state/season_pass_provider.dart';
import '../theme/app_colors.dart';

class SeasonPassScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const SeasonPassScreen({super.key, required this.onBack});

  @override
  ConsumerState<SeasonPassScreen> createState() => _SeasonPassScreenState();
}

class _SeasonPassScreenState extends ConsumerState<SeasonPassScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passState = ref.watch(seasonPassProvider);
    final vipState = ref.watch(vipProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, passState),
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPassTab(context, passState),
                  _buildShopTab(context),
                  _buildVipTab(context, vipState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SeasonPassState state) {
    final season = season1;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(context, 16),
        vertical: Responsive.spacing(context, 12),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceMid, AppColors.bgDeepPlum],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(Icons.arrow_back,
                    color: Colors.white, size: Responsive.iconSize(context, 24)),
              ),
              SizedBox(width: Responsive.spacing(context, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌸 ${season.title}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'D-${season.daysRemaining} | Lv.${state.currentLevel}/${season.maxLevel}',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: Responsive.fontSize(context, 12),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isPremiumPass)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.spacing(context, 10),
                    vertical: Responsive.spacing(context, 4),
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.sinmyeongGold, Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✨ PREMIUM',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: Responsive.fontSize(context, 10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, 8)),
          // XP 진행 바
          _buildXpBar(context, state),
        ],
      ),
    );
  }

  Widget _buildXpBar(BuildContext context, SeasonPassState state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP: ${state.currentXp} / ${season1.xpForLevel(state.currentLevel)}',
              style: TextStyle(
                color: Colors.white54,
                fontSize: Responsive.fontSize(context, 11),
              ),
            ),
            Text(
              '다음 레벨까지 ${state.xpToNextLevel} XP',
              style: TextStyle(
                color: Colors.amber,
                fontSize: Responsive.fontSize(context, 11),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.spacing(context, 4)),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: state.isMaxLevel ? 1.0 : state.levelProgress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: Responsive.spacing(context, 8),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: const Color(0xFF16213E),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.amber,
        labelColor: Colors.amber,
        unselectedLabelColor: Colors.white54,
        labelStyle: TextStyle(
          fontSize: Responsive.fontSize(context, 13),
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: '🎫 시즌 패스'),
          Tab(text: '🛒 상점'),
          Tab(text: '👑 VIP'),
        ],
      ),
    );
  }

  // ── 시즌 패스 탭 ──

  Widget _buildPassTab(BuildContext context, SeasonPassState state) {
    final rewards = season1.rewards;
    // 레벨별로 그룹핑
    final levels = <int>{};
    for (final r in rewards) {
      levels.add(r.level);
    }
    final sortedLevels = levels.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.all(Responsive.spacing(context, 12)),
      itemCount: sortedLevels.length + 1, // +1 프리미엄 구매 버튼
      itemBuilder: (context, index) {
        if (index == sortedLevels.length) {
          // 마지막: 프리미엄 구매 버튼
          if (state.isPremiumPass) return const SizedBox.shrink();
          return _buildPremiumPurchaseButton(context);
        }

        final level = sortedLevels[index];
        final levelRewards = rewards.where((r) => r.level == level).toList();
        final isUnlocked = level <= state.currentLevel;

        return _PassLevelRow(
          level: level,
          rewards: levelRewards,
          isUnlocked: isUnlocked,
          isPremiumPass: state.isPremiumPass,
          claimedFree: state.claimedFree,
          claimedPremium: state.claimedPremium,
          onClaim: (reward) {
            final success = ref.read(seasonPassProvider.notifier)
                .claimReward(reward.level, reward.isPremium);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${reward.emoji} ${reward.name} 획득!'),
                  backgroundColor: Colors.green.shade700,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildPremiumPurchaseButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Responsive.spacing(context, 16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.surfaceMid, Color(0xFF4A148C)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
        ),
        padding: EdgeInsets.all(Responsive.spacing(context, 20)),
        child: Column(
          children: [
            Text(
              '✨ 프리미엄 패스',
              style: TextStyle(
                color: Colors.amber,
                fontSize: Responsive.fontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.spacing(context, 8)),
            Text(
              '프리미엄 보상 트랙 해금\n한정 스킨, 유물, 보석 2배 보상',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: Responsive.fontSize(context, 13),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, 16)),
            SizedBox(
              width: double.infinity,
              height: Responsive.spacing(context, 48),
              child: ElevatedButton(
                onPressed: () {
                  // [💰 Monetize] IAP 연동 예정
                  ref.read(seasonPassProvider.notifier).purchasePremium();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ 프리미엄 패스가 활성화되었습니다!'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '₩9,900 구매하기',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 상점 탭 ──

  Widget _buildShopTab(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(Responsive.spacing(context, 12)),
      children: [
        _sectionTitle(context, '🎁 스타터 패키지 (1회 한정)'),
        ...allShopPackages
            .where((p) => p.type == PackageType.starter)
            .map((p) => _ShopPackageCard(package: p)),

        SizedBox(height: Responsive.spacing(context, 16)),
        _sectionTitle(context, '📅 구독 패키지'),
        ...allShopPackages
            .where((p) => p.type == PackageType.weekly || p.type == PackageType.monthly)
            .map((p) => _ShopPackageCard(package: p)),

        SizedBox(height: Responsive.spacing(context, 16)),
        _sectionTitle(context, '💎 보석 충전'),
        ...allShopPackages
            .where((p) => p.type == PackageType.gems)
            .map((p) => _ShopPackageCard(package: p)),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, 8)),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.fontSize(context, 16),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── VIP 탭 ──

  Widget _buildVipTab(BuildContext context, VipState state) {
    final tier = state.tier;
    final nextTier = VipTier.values.indexOf(tier) < VipTier.values.length - 1
        ? VipTier.values[VipTier.values.indexOf(tier) + 1]
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 현재 VIP 등급
          Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 20)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tier.color.withValues(alpha: 0.3), AppColors.bgDeepPlum],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tier.color.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Text(
                  '${tier.emoji} ${tier.displayName}',
                  style: TextStyle(
                    color: tier.color,
                    fontSize: Responsive.fontSize(context, 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _vipStat(context, '💎', '${tier.dailyGemBonus}/일', '보석 보너스'),
                    _vipStat(context, '⭐', '×${tier.xpMultiplier}', 'XP 배율'),
                    _vipStat(context, '💰', '₩${state.totalSpendKRW}', '누적 결제'),
                  ],
                ),
              ],
            ),
          ),

          if (nextTier != null) ...[
            SizedBox(height: Responsive.spacing(context, 12)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, 12)),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '다음 등급 (${nextTier.displayName}): ₩${nextTier.requiredSpend - state.totalSpendKRW} 추가 결제 필요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: Responsive.fontSize(context, 12),
                ),
              ),
            ),
          ],

          SizedBox(height: Responsive.spacing(context, 24)),

          // VIP 혜택 표
          _sectionTitle(context, '👑 VIP 등급 혜택'),
          ...VipTier.values.where((t) => t != VipTier.none).map(
            (t) => _VipTierRow(
              tier: t,
              isCurrentOrHigher: t.index <= tier.index,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vipStat(BuildContext context, String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: Responsive.fontSize(context, 20))),
        SizedBox(height: Responsive.spacing(context, 4)),
        Text(value, style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.fontSize(context, 14),
          fontWeight: FontWeight.bold,
        )),
        Text(label, style: TextStyle(
          color: Colors.white54,
          fontSize: Responsive.fontSize(context, 10),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 하위 위젯
// ═══════════════════════════════════════════

class _PassLevelRow extends StatelessWidget {
  final int level;
  final List<PassReward> rewards;
  final bool isUnlocked;
  final bool isPremiumPass;
  final Set<int> claimedFree;
  final Set<int> claimedPremium;
  final void Function(PassReward) onClaim;

  const _PassLevelRow({
    required this.level,
    required this.rewards,
    required this.isUnlocked,
    required this.isPremiumPass,
    required this.claimedFree,
    required this.claimedPremium,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final freeRewards = rewards.where((r) => !r.isPremium).toList();
    final premiumRewards = rewards.where((r) => r.isPremium).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, 6)),
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(context, 10)),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black26,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUnlocked ? Colors.white12 : Colors.white.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          children: [
            // 레벨 번호
            Container(
              width: Responsive.spacing(context, 32),
              height: Responsive.spacing(context, 32),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.amber.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    color: isUnlocked ? Colors.amber : Colors.white38,
                    fontSize: Responsive.fontSize(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: Responsive.spacing(context, 8)),

            // 무료 보상
            Expanded(
              child: Wrap(
                spacing: 4,
                children: freeRewards.map((r) {
                  final claimed = claimedFree.contains(r.level);
                  return _RewardChip(
                    reward: r,
                    isUnlocked: isUnlocked,
                    isClaimed: claimed,
                    onTap: isUnlocked && !claimed
                        ? () => onClaim(r)
                        : null,
                  );
                }).toList(),
              ),
            ),

            // 구분선
            Container(
              width: 1,
              height: Responsive.spacing(context, 30),
              color: Colors.amber.withValues(alpha: 0.3),
            ),
            SizedBox(width: Responsive.spacing(context, 8)),

            // 프리미엄 보상
            Expanded(
              child: premiumRewards.isEmpty
                  ? const SizedBox.shrink()
                  : Wrap(
                      spacing: 4,
                      children: premiumRewards.map((r) {
                        final claimed = claimedPremium.contains(r.level);
                        final locked = !isPremiumPass;
                        return _RewardChip(
                          reward: r,
                          isUnlocked: isUnlocked && !locked,
                          isClaimed: claimed,
                          isPremiumLocked: locked,
                          onTap: isUnlocked && !locked && !claimed
                              ? () => onClaim(r)
                              : null,
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final PassReward reward;
  final bool isUnlocked;
  final bool isClaimed;
  final bool isPremiumLocked;
  final VoidCallback? onTap;

  const _RewardChip({
    required this.reward,
    required this.isUnlocked,
    this.isClaimed = false,
    this.isPremiumLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, 6),
          vertical: Responsive.spacing(context, 3),
        ),
        decoration: BoxDecoration(
          color: isClaimed
              ? Colors.green.withValues(alpha: 0.2)
              : isPremiumLocked
                  ? Colors.purple.withValues(alpha: 0.1)
                  : isUnlocked
                      ? Colors.amber.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isClaimed
                ? Colors.green.withValues(alpha: 0.5)
                : isPremiumLocked
                    ? Colors.purple.withValues(alpha: 0.3)
                    : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isClaimed ? '✅' : (isPremiumLocked ? '🔒' : reward.emoji),
              style: TextStyle(fontSize: Responsive.fontSize(context, 12)),
            ),
            SizedBox(width: Responsive.spacing(context, 3)),
            Flexible(
              child: Text(
                reward.name,
                style: TextStyle(
                  color: isClaimed
                      ? Colors.green
                      : isUnlocked
                          ? Colors.white
                          : Colors.white38,
                  fontSize: Responsive.fontSize(context, 10),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopPackageCard extends StatelessWidget {
  final ShopPackage package;

  const _ShopPackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, 8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
        padding: EdgeInsets.all(Responsive.spacing(context, 14)),
        decoration: BoxDecoration(
          color: const Color(0xCC16213E),
          borderRadius: BorderRadius.circular(12),
          border: package.isHighlight
              ? Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Text(package.emoji,
                style: TextStyle(fontSize: Responsive.fontSize(context, 28))),
            SizedBox(width: Responsive.spacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        package.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (package.isHighlight) ...[
                        SizedBox(width: Responsive.spacing(context, 6)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '추천',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.fontSize(context, 9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    package.description,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: Responsive.fontSize(context, 11),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.spacing(context, 12),
                vertical: Responsive.spacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '₩${package.priceKRW}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Responsive.fontSize(context, 13),
                  fontWeight: FontWeight.bold,
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
}

class _VipTierRow extends StatelessWidget {
  final VipTier tier;
  final bool isCurrentOrHigher;

  const _VipTierRow({required this.tier, required this.isCurrentOrHigher});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, 6)),
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(context, 12)),
        decoration: BoxDecoration(
          color: isCurrentOrHigher
              ? tier.color.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrentOrHigher
                ? tier.color.withValues(alpha: 0.4)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Text('${tier.emoji} ', style: TextStyle(fontSize: Responsive.fontSize(context, 18))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.displayName,
                    style: TextStyle(
                      color: isCurrentOrHigher ? tier.color : Colors.white54,
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₩${tier.requiredSpend}+ | 보석 ${tier.dailyGemBonus}/일 | XP ×${tier.xpMultiplier}',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: Responsive.fontSize(context, 10),
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrentOrHigher)
              Icon(Icons.check_circle, color: tier.color,
                  size: Responsive.iconSize(context, 18)),
          ],
        ),
      ),
    );
  }
}
