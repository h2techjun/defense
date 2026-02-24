// 해원의 문 - 설화도감 UI
// 카테고리 탭, 3단계 해금 시각화, 수집률 프로그레스

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/responsive.dart';
import '../../data/models/lore_collection_data.dart';
import '../../state/lore_collection_provider.dart';
import '../theme/app_colors.dart';

class LoreCollectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const LoreCollectionScreen({super.key, required this.onBack});

  @override
  ConsumerState<LoreCollectionScreen> createState() => _LoreCollectionScreenState();
}

class _LoreCollectionScreenState extends ConsumerState<LoreCollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = LoreCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loreState = ref.watch(loreCollectionProvider);
    final s = Responsive.scale(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, loreState, s),
            _buildMilestones(context, ref, loreState, s),
            _buildTabBar(s),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((cat) {
                  final entries = allLoreEntries
                      .where((e) => e.category == cat)
                      .toList();
                  return _buildEntryList(context, ref, loreState, entries, s);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LoreCollectionState state, double s) {
    final rate = state.collectionRate;
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bgDeepPlum, AppColors.surfaceMid],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBack,
          ),
          SizedBox(width: 8 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📜 설화도감',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4 * s),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rate,
                          backgroundColor: Colors.white.withAlpha(20),
                          valueColor: AlwaysStoppedAnimation(AppColors.sinmyeongGold),
                          minHeight: 6 * s,
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    Text(
                      '${(rate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppColors.sinmyeongGold,
                        fontSize: 12 * s,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(BuildContext context, WidgetRef ref, LoreCollectionState state, double s) {
    return Container(
      height: 56 * s,
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      color: const Color(0xFF16213E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: collectionMilestones.map((ms) {
          final reached = state.collectionRate >= ms.percentage;
          final claimed = state.claimedMilestones.contains(ms.percentage);
          final claimable = reached && !claimed;

          return GestureDetector(
            onTap: claimable
                ? () {
                    final success = ref.read(loreCollectionProvider.notifier)
                        .claimMilestone(ms.percentage);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${ms.emoji} "${ms.rewardTitle}" 칭호 획득! 💎${ms.rewardGems}'),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    }
                  }
                : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
              decoration: BoxDecoration(
                color: claimed
                    ? Colors.green.withAlpha(30)
                    : claimable
                        ? Colors.amber.withAlpha(40)
                        : Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: claimable ? Colors.amber : Colors.white.withAlpha(10),
                  width: claimable ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(claimed ? '✅' : ms.emoji, style: TextStyle(fontSize: 14 * s)),
                  Text(
                    '${(ms.percentage * 100).toInt()}%',
                    style: TextStyle(
                      color: reached ? Colors.amber : Colors.white38,
                      fontSize: 10 * s,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar(double s) {
    return Container(
      color: AppColors.bgDeepPlum,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: AppColors.lavender,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: TextStyle(fontSize: 13 * s, fontWeight: FontWeight.bold),
        tabs: _categories.map((cat) => Tab(text: '${cat.emoji} ${cat.label}')).toList(),
      ),
    );
  }

  Widget _buildEntryList(BuildContext context, WidgetRef ref,
      LoreCollectionState state, List<LoreEntry> entries, double s) {
    if (entries.isEmpty) {
      return const Center(child: Text('아직 항목이 없습니다', style: TextStyle(color: Colors.white38)));
    }

    return ListView.builder(
      padding: EdgeInsets.all(12 * s),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final tier = state.getTier(entry);
        final kills = state.getKills(entry.id);

        return _buildLoreCard(context, ref, state, entry, tier, kills, s);
      },
    );
  }

  Widget _buildLoreCard(BuildContext context, WidgetRef ref,
      LoreCollectionState state, LoreEntry entry,
      LoreUnlockTier tier, int kills, double s) {
    final isLocked = tier == LoreUnlockTier.locked;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12 * s),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
      margin: EdgeInsets.only(bottom: 10 * s),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xCC0F0F20) : const Color(0xCC16213E),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(
          color: isLocked ? Colors.white.withAlpha(5) : _tierColor(tier).withAlpha(60),
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
        childrenPadding: EdgeInsets.fromLTRB(14 * s, 0, 14 * s, 14 * s),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white24,
        title: Row(
          children: [
            // 아이콘
            Text(
              isLocked ? '❓' : entry.emoji,
              style: TextStyle(fontSize: 24 * s),
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLocked ? '???' : entry.name,
                    style: TextStyle(
                      color: isLocked ? Colors.white24 : Colors.white,
                      fontSize: 15 * s,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2 * s),
                  // 해금 단계 뱃지
                  Row(
                    children: [
                      _tierBadge(tier, s),
                      if (!isLocked) ...[
                        SizedBox(width: 6 * s),
                        Text(
                          '처치: $kills',
                          style: TextStyle(color: Colors.white38, fontSize: 10 * s),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        children: isLocked
            ? [
                Text(
                  '이 존재를 처음 만나면 해금됩니다...',
                  style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic, fontSize: 12 * s),
                ),
              ]
            : _buildLoreContent(context, ref, state, entry, tier, kills, s),
      ),
    ),
      ),
    );
  }

  List<Widget> _buildLoreContent(BuildContext context, WidgetRef ref,
      LoreCollectionState state, LoreEntry entry,
      LoreUnlockTier tier, int kills, double s) {
    final widgets = <Widget>[];

    // 기본 설명 (encountered 이상)
    widgets.add(_loreSection(
      '📋 기본 정보',
      tier.index >= LoreUnlockTier.basic.index
          ? entry.basicDescription
          : '${entry.basicKills}마리 처치 시 해금 (${kills}/${entry.basicKills})',
      tier.index >= LoreUnlockTier.basic.index,
      entry, LoreUnlockTier.basic, state, ref, s,
    ));

    // 비밀 설화 (100킬)
    widgets.add(SizedBox(height: 8 * s));
    widgets.add(_loreSection(
      '🔮 비밀 설화',
      tier.index >= LoreUnlockTier.secretLore.index
          ? entry.secretDescription
          : '${entry.secretKills}마리 처치 시 해금 (${kills}/${entry.secretKills})',
      tier.index >= LoreUnlockTier.secretLore.index,
      entry, LoreUnlockTier.secretLore, state, ref, s,
    ));

    // 숨겨진 이야기 (1000킬)
    widgets.add(SizedBox(height: 8 * s));
    widgets.add(_loreSection(
      '👑 숨겨진 이야기',
      tier.index >= LoreUnlockTier.hiddenStory.index
          ? entry.hiddenDescription
          : '${entry.hiddenKills}마리 처치 시 해금 (${kills}/${entry.hiddenKills})',
      tier.index >= LoreUnlockTier.hiddenStory.index,
      entry, LoreUnlockTier.hiddenStory, state, ref, s,
    ));

    // 다음 단계 진행도 바
    if (tier != LoreUnlockTier.hiddenStory) {
      widgets.add(SizedBox(height: 10 * s));
      final remaining = entry.killsToNextTier(kills);
      final nextTarget = switch (tier) {
        LoreUnlockTier.encountered => entry.basicKills,
        LoreUnlockTier.basic       => entry.secretKills,
        LoreUnlockTier.secretLore  => entry.hiddenKills,
        _ => 1,
      };
      final progress = kills / nextTarget;
      widgets.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다음 단계까지 ${remaining}마리 남음',
            style: TextStyle(color: Colors.white38, fontSize: 11 * s),
          ),
          SizedBox(height: 4 * s),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withAlpha(10),
              valueColor: AlwaysStoppedAnimation(_tierColor(tier)),
              minHeight: 4 * s,
            ),
          ),
        ],
      ));
    }

    return widgets;
  }

  Widget _loreSection(String title, String text, bool unlocked,
      LoreEntry entry, LoreUnlockTier rewardTier,
      LoreCollectionState state, WidgetRef ref, double s) {
    final claimed = state.claimedTiers[entry.id]?.contains(rewardTier) ?? false;
    final claimable = unlocked && !claimed;
    final gems = entry.gemsForTier(rewardTier);

    return Container(
      padding: EdgeInsets.all(10 * s),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white.withAlpha(5) : Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: claimable ? Colors.amber.withAlpha(80) : Colors.white.withAlpha(5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(
                color: unlocked ? _tierColor(rewardTier) : Colors.white24,
                fontSize: 12 * s,
                fontWeight: FontWeight.bold,
              )),
              const Spacer(),
              if (claimable && gems > 0)
                GestureDetector(
                  onTap: () {
                    ref.read(loreCollectionProvider.notifier)
                        .claimTierReward(entry.id, rewardTier);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('💎 보석 $gems개 획득!'),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '💎$gems 수령',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10 * s,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (claimed)
                Text('✅', style: TextStyle(fontSize: 12 * s)),
            ],
          ),
          SizedBox(height: 6 * s),
          Text(
            text,
            style: TextStyle(
              color: unlocked ? Colors.white70 : Colors.white24,
              fontSize: 13 * s,
              height: 1.5,
              fontStyle: unlocked ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierBadge(LoreUnlockTier tier, double s) {
    final (label, color) = switch (tier) {
      LoreUnlockTier.locked      => ('미발견', Colors.grey),
      LoreUnlockTier.encountered => ('조우',   Colors.blue),
      LoreUnlockTier.basic       => ('기본',   Colors.green),
      LoreUnlockTier.secretLore  => ('비밀',   Colors.purple),
      LoreUnlockTier.hiddenStory => ('전설',   Colors.amber),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9 * s, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _tierColor(LoreUnlockTier tier) => switch (tier) {
    LoreUnlockTier.locked      => Colors.grey,
    LoreUnlockTier.encountered => Colors.blue,
    LoreUnlockTier.basic       => Colors.green,
    LoreUnlockTier.secretLore  => Colors.purple,
    LoreUnlockTier.hiddenStory => Colors.amber,
  };
}
