// 해원의 문 - 업적 + 랭킹 UI 화면
// 업적 목록, 진행도, 랭킹 보드

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/responsive.dart';
import '../../data/models/achievement_data.dart';
import '../../state/achievement_provider.dart';
import '../theme/app_colors.dart';

class AchievementScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const AchievementScreen({super.key, required this.onBack});

  @override
  ConsumerState<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends ConsumerState<AchievementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achieveState = ref.watch(achievementProvider);
    final rankState = ref.watch(rankingProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          // 공통 성소 테마 배경 (은은하게 투과)
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
                _buildHeader(context, achieveState),
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAchievementsTab(context, achieveState),
                      _buildRankingsTab(context, rankState),
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

  Widget _buildHeader(BuildContext context, AchievementState state) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(context, 16),
        vertical: Responsive.spacing(context, 12),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bgDeepPlum, Color(0xFF16213E)],
        ),
      ),
      child: Row(
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
                  '🏆 업적 & 랭킹',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '달성: ${state.completed.length}/${allAchievements.length} (${(state.completionRate * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: Responsive.fontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
          if (state.unclaimedCount > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.spacing(context, 10),
                vertical: Responsive.spacing(context, 4),
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.unclaimedCount} 미수령',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, 11),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
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
          fontSize: Responsive.fontSize(context, 14),
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: '🏅 업적'),
          Tab(text: '🏆 랭킹'),
        ],
      ),
    );
  }

  // ── 업적 탭 ──

  Widget _buildAchievementsTab(BuildContext context, AchievementState state) {
    // 카테고리별 그룹핑
    return ListView(
      padding: EdgeInsets.all(Responsive.spacing(context, 12)),
      children: AchievementCategory.values.map((category) {
        final categoryAchievements = allAchievements
            .where((a) => a.category == category)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.spacing(context, 8),
              ),
              child: Row(
                children: [
                  Text(
                    '${category.emoji} ${category.displayName}',
                    style: TextStyle(
                      color: category.color,
                      fontSize: Responsive.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${categoryAchievements.where((a) => state.completed.contains(a.id)).length}/${categoryAchievements.length}',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: Responsive.fontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ),
            ...categoryAchievements.map((achievement) {
              final progress = state.progress[achievement.id] ?? 0;
              final isCompleted = state.completed.contains(achievement.id);
              final isClaimed = state.claimed.contains(achievement.id);
              final isHidden = achievement.isHidden && !isCompleted;

              return _AchievementCard(
                achievement: achievement,
                progress: progress,
                isCompleted: isCompleted,
                isClaimed: isClaimed,
                isHidden: isHidden,
                onClaim: isCompleted && !isClaimed
                    ? () {
                        final success = ref.read(achievementProvider.notifier)
                            .claimReward(achievement.id);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('💎 ${achievement.rewardGems} 보석 획득!'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        }
                      }
                    : null,
              );
            }),
            SizedBox(height: Responsive.spacing(context, 8)),
          ],
        );
      }).toList(),
    );
  }

  // ── 랭킹 탭 ──

  Widget _buildRankingsTab(BuildContext context, RankingState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 개인 최고 기록
          Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 16)),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/objects/obj_old_well.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(AppColors.bgDeepPlum.withAlpha(200), BlendMode.darken),
              ),
              gradient: const LinearGradient(
                colors: [AppColors.surfaceMid, AppColors.bgDeepPlum],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withAlpha(60), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.amber.withAlpha(30), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _rankStat(context, '🗼', '${state.personalBestTower}', '탑 최고층'),
                Container(
                  width: 1,
                  height: Responsive.spacing(context, 40),
                  color: Colors.white12,
                ),
                _rankStat(context, '📅', '${state.personalBestDaily}', '도전 최고웨이브'),
              ],
            ),
          ),

          SizedBox(height: Responsive.spacing(context, 20)),

          // ── 이번 시즌 기록 (매월 리셋) ──
          _sectionTitle(context, '📅 이번 시즌 (${state.seasonMonth.isNotEmpty ? state.seasonMonth : "시즌 대기"})'),
          Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 12)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1040), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withAlpha(40)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _rankStat(context, '🗼', '${state.seasonBestTower}', '탑 최고'),
                Container(width: 1, height: Responsive.spacing(context, 30), color: Colors.white12),
                _rankStat(context, '📅', '${state.seasonBestDaily}', '도전 최고'),
              ],
            ),
          ),

          SizedBox(height: Responsive.spacing(context, 20)),

          // ── 층별 마일스톤 ──
          if (state.floorMilestones.isNotEmpty) ...[
            _sectionTitle(context, '🏅 층별 마일스톤'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (state.floorMilestones.keys.toList()..sort()).map((floor) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, 10),
                      vertical: Responsive.spacing(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withAlpha(60)),
                    ),
                    child: Text(
                      '$floor층 ✅',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: Responsive.fontSize(context, 12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
            ),
            SizedBox(height: Responsive.spacing(context, 20)),
          ],

          // 무한의 탑 랭킹
          _sectionTitle(context, '🗼 무한의 탑 기록'),
          if (state.towerRankings.isEmpty)
            _emptyRanking(context, '아직 기록이 없습니다. 탑에 도전해보세요!')
          else
            ...state.towerRankings.asMap().entries.map(
              (e) => _RankingRow(rank: e.key + 1, entry: e.value),
            ),

          SizedBox(height: Responsive.spacing(context, 20)),

          // 일일 도전 랭킹
          _sectionTitle(context, '📅 일일 도전 기록'),
          if (state.dailyRankings.isEmpty)
            _emptyRanking(context, '아직 기록이 없습니다. 일일 도전을 시작하세요!')
          else
            ...state.dailyRankings.asMap().entries.map(
              (e) => _RankingRow(rank: e.key + 1, entry: e.value),
            ),
        ],
      ),
    );
  }

  Widget _rankStat(BuildContext context, String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: Responsive.fontSize(context, 24))),
        SizedBox(height: Responsive.spacing(context, 4)),
        Text(value, style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.fontSize(context, 22),
          fontWeight: FontWeight.bold,
        )),
        Text(label, style: TextStyle(
          color: Colors.white54,
          fontSize: Responsive.fontSize(context, 11),
        )),
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

  Widget _emptyRanking(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, 20)),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white38,
            fontSize: Responsive.fontSize(context, 13),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 하위 위젯
// ═══════════════════════════════════════════

class _AchievementCard extends StatelessWidget {
  final AchievementData achievement;
  final int progress;
  final bool isCompleted;
  final bool isClaimed;
  final bool isHidden;
  final VoidCallback? onClaim;

  const _AchievementCard({
    required this.achievement,
    required this.progress,
    required this.isCompleted,
    required this.isClaimed,
    required this.isHidden,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, 6)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
        padding: EdgeInsets.all(Responsive.spacing(context, 10)),
        decoration: BoxDecoration(
          color: isCompleted ? null : Colors.white.withValues(alpha: 0.03),
          gradient: isCompleted
              ? LinearGradient(
                  colors: isClaimed
                      ? [Colors.green.withAlpha(20), Colors.black.withAlpha(150)]
                      : [Colors.amber.withAlpha(40), Colors.black.withAlpha(150)],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted && !isClaimed
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.white10,
          ),
          boxShadow: isCompleted && !isClaimed
              ? [BoxShadow(color: Colors.amber.withAlpha(60), blurRadius: 10, spreadRadius: 1)]
              : null,
        ),
        child: Row(
          children: [
            Text(
              isHidden ? '❓' : achievement.emoji,
              style: TextStyle(fontSize: Responsive.fontSize(context, 22)),
            ),
            SizedBox(width: Responsive.spacing(context, 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHidden ? '히든 업적' : achievement.name,
                    style: TextStyle(
                      color: isCompleted ? Colors.white : Colors.white70,
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isHidden ? '???' : achievement.description,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: Responsive.fontSize(context, 10),
                    ),
                  ),
                  if (!isHidden && !isCompleted) ...[
                    SizedBox(height: Responsive.spacing(context, 4)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (progress / achievement.targetValue).clamp(0.0, 1.0),
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.category.color.withValues(alpha: 0.7),
                        ),
                        minHeight: Responsive.spacing(context, 4),
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, 2)),
                    Text(
                      '$progress / ${achievement.targetValue}',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: Responsive.fontSize(context, 9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isCompleted && !isClaimed)
              GestureDetector(
                onTap: onClaim,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.spacing(context, 10),
                    vertical: Responsive.spacing(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💎${achievement.rewardGems}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: Responsive.fontSize(context, 11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (isClaimed)
              Icon(Icons.check_circle, color: Colors.green,
                  size: Responsive.iconSize(context, 18)),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int rank;
  final RankingEntry entry;

  const _RankingRow({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final medalEmoji = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, 4)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(context, 12),
          vertical: Responsive.spacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: rank <= 3
              ? Colors.amber.withValues(alpha: 0.05 * (4 - rank))
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: Responsive.spacing(context, 32),
              child: Text(
                medalEmoji,
                style: TextStyle(fontSize: Responsive.fontSize(context, 16)),
              ),
            ),
            Expanded(
              child: Text(
                entry.playerName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, 13),
                ),
              ),
            ),
            Text(
              '${entry.score}',
              style: TextStyle(
                color: Colors.amber,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
