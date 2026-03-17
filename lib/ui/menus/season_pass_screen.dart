// 해원의 문 - 시즌 패스 UI 화면
// 무료/프리미엄 트랙 (광고 기반 해금)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/responsive.dart';
import '../../data/models/season_pass_data.dart';
import '../../state/season_pass_provider.dart';
import '../../state/season_pass_provider.dart';
import '../../state/user_state.dart';
import '../../services/ad_manager.dart';
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
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passState = ref.watch(seasonPassProvider);


    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          // 공통 프리미엄 테마 배경 (은은하게 투과)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/objects/obj_sacred_tree.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, passState),
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPassTab(context, passState),
                    ],
                  ),),
              ],
            ),
          ),
        ],
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
                        color: season.daysRemaining <= 7 ? Colors.redAccent : Colors.white60,
                        fontSize: Responsive.fontSize(context, 15),
                        fontWeight: season.daysRemaining <= 7 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, 4)),
                    // 시즌 진행률 프로그레스 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: Responsive.spacing(context, 6),
                        child: LinearProgressIndicator(
                          value: (() {
                            final totalDays = season.endDate.difference(season.startDate).inDays;
                            final elapsed = DateTime.now().difference(season.startDate).inDays;
                            return (elapsed / totalDays).clamp(0.0, 1.0);
                          })(),
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            season.daysRemaining <= 7 ? Colors.redAccent : Colors.amber,
                          ),
                        ),
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
                      fontSize: Responsive.fontSize(context, 13),
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
                fontSize: Responsive.fontSize(context, 14),
              ),
            ),
            Text(
              '다음 레벨까지 ${state.xpToNextLevel} XP',
              style: TextStyle(
                color: Colors.amber,
                fontSize: Responsive.fontSize(context, 14),
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
        SizedBox(height: Responsive.spacing(context, 8)),
        // XP 부스트 구매 버튼
        if (!state.isMaxLevel)
          GestureDetector(
            onTap: () {
              final userState = ref.read(userStateProvider);
              if (userState.gems >= 10) {
                ref.read(userStateProvider.notifier).spendGems(10);
                ref.read(seasonPassProvider.notifier).addXp(50);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('⚡ XP +50! (💎10 사용)'),
                    backgroundColor: const Color(0xFF6633AA),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('💎 보석이 부족합니다 (필요: 10개)'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.spacing(context, 12),
                vertical: Responsive.spacing(context, 6),
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6633AA), Color(0xFF4488CC)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⚡', style: TextStyle(fontSize: Responsive.fontSize(context, 14))),
                  SizedBox(width: Responsive.spacing(context, 4)),
                  Text(
                    'XP 부스트 (💎10 → +50XP)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withAlpha(220),
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(20), width: 1)),
      ),
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
                onPressed: () async {
                  // 광고 시청으로 프리미엄 패스 해금
                  final reward = await AdManager.instance.showRewardedAd(
                    purpose: RewardedAdPurpose.seasonPremium,
                  );
                  if (reward != null && context.mounted) {
                    ref.read(seasonPassProvider.notifier).purchasePremium();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✨ 프리미엄 패스가 활성화되었습니다!'),
                        backgroundColor: Colors.purple,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '📺 광고 시청으로 해금',
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 10)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUnlocked
                    ? [const Color(0xFF3B1E54).withAlpha(180), AppColors.bgDeepPlum.withAlpha(220)]
                    : [Colors.black.withAlpha(150), Colors.black.withAlpha(200)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnlocked ? Colors.amber.withAlpha(60) : Colors.white.withAlpha(10),
                width: isUnlocked ? 1.5 : 1.0,
              ),
              boxShadow: isUnlocked
                  ? [BoxShadow(color: Colors.amber.withAlpha(20), blurRadius: 8, spreadRadius: 1)]
                  : null,
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
                    fontSize: Responsive.fontSize(context, 15),
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
    )));
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
              style: TextStyle(fontSize: Responsive.fontSize(context, 15)),
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
                  fontSize: Responsive.fontSize(context, 13),
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


