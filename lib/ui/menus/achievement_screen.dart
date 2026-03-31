// 해원의 문 - 업적 + 랭킹 UI 화면
// 업적 목록, 진행도, 랭킹 보드

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/responsive.dart';
import '../../data/models/achievement_data.dart';
import '../../state/achievement_provider.dart';
import '../theme/app_colors.dart';
import '../../l10n/app_strings.dart';
import '../../common/asset_paths.dart';

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
                AssetPaths.asset('objects/obj_sacred_tree'),
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
          colors: [AppColors.bgDeepPlum, AppColors.bgNavy],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: Responsive.iconSize(context, 24)),
          ),
          SizedBox(width: Responsive.spacing(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(ref, 'ach_ranking_title'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.fontSize(context, 22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${tr(ref, "ach_completion")}: ${state.completed.length}/${allAchievements.length} (${(state.completionRate * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: Responsive.fontSize(context, 15),
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
                color: AppColors.berserkRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.unclaimedCount} ${tr(ref, "ach_unclaimed")}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fontSize(context, 14),
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
      color: AppColors.bgNavy,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.sinmyeongGold,
        labelColor: AppColors.sinmyeongGold,
        unselectedLabelColor: AppColors.textMid,
        labelStyle: TextStyle(
          fontSize: Responsive.fontSize(context, 14),
          fontWeight: FontWeight.bold,
        ),
        tabs: [
          Tab(text: '🏅 ${tr(ref, "ach_tab_achievements")}'),
          Tab(text: '🏆 ${tr(ref, "ach_tab_ranking")}'),
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
                    '${category.emoji} ${tr(ref, category.displayName)}',
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
                      color: AppColors.textFaint,
                      fontSize: Responsive.fontSize(context, 15),
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
                lang: ref.read(gameLanguageProvider),
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
                              content: Text('💎 ${achievement.rewardGems} ${tr(ref, "ach_gems_reward")}'),
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
                image: AssetImage(AssetPaths.asset('objects/obj_old_well')),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(AppColors.bgDeepPlum.withAlpha(200), BlendMode.darken),
              ),
              gradient: const LinearGradient(
                colors: [AppColors.surfaceMid, AppColors.bgDeepPlum],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sinmyeongGold.withAlpha(60), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.sinmyeongGold.withAlpha(30), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _rankStat(context, '🗼', '${state.personalBestTower}', 'Tower Best'),
                Container(
                  width: 1,
                  height: Responsive.spacing(context, 40),
                  color: AppColors.textGhost,
                ),
                _rankStat(context, '📅', '${state.personalBestDaily}', 'Best Wave'),
              ],
            ),
          ),

          SizedBox(height: Responsive.spacing(context, 20)),

          // ── 이번 시즌 기록 (매월 리셋) ──
          _sectionTitle(context, '📅 ${tr(ref, "ach_season")} (${state.seasonMonth.isNotEmpty ? state.seasonMonth : tr(ref, "ach_season_wait")})'),
          Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 12)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1040), AppColors.bgNavy],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sinmyeongGold.withAlpha(40)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _rankStat(context, '🗼', '${state.seasonBestTower}', 'Best Floor'),
                Container(width: 1, height: Responsive.spacing(context, 30), color: AppColors.textGhost),
                _rankStat(context, '📅', '${state.seasonBestDaily}', 'Best Wave'),
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
                      color: AppColors.sinmyeongGold.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.sinmyeongGold.withAlpha(60)),
                    ),
                    child: Text(
                      '$floor층 ✅',
                      style: TextStyle(
                        color: AppColors.sinmyeongGold,
                        fontSize: Responsive.fontSize(context, 15),
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
            _emptyRanking(context, 'No records yet. Try the tower!')
          else
            ...state.towerRankings.asMap().entries.map(
              (e) => _RankingRow(rank: e.key + 1, entry: e.value),
            ),

          SizedBox(height: Responsive.spacing(context, 20)),

          // 일일 도전 랭킹
          _sectionTitle(context, '📅 일일 도전 기록'),
          if (state.dailyRankings.isEmpty)
            _emptyRanking(context, 'No records yet. Start a daily challenge!')
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
          color: AppColors.textPrimary,
          fontSize: Responsive.fontSize(context, 22),
          fontWeight: FontWeight.bold,
        )),
        Text(label, style: TextStyle(
          color: AppColors.textMid,
          fontSize: Responsive.fontSize(context, 14),
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
          color: AppColors.textPrimary,
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
        color: AppColors.bgNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textFaint,
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
  final GameLanguage lang;
  final int progress;
  final bool isCompleted;
  final bool isClaimed;
  final bool isHidden;
  final VoidCallback? onClaim;

  const _AchievementCard({
    required this.achievement,
    required this.lang,
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
                    isHidden ? AppStrings.get(lang, 'ach_hidden') : AppStrings.get(lang, achievement.name),
                    style: TextStyle(
                      color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: Responsive.fontSize(context, 13),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isHidden ? '???' : AppStrings.get(lang, achievement.description),
                    style: TextStyle(
                      color: AppColors.textFaint,
                      fontSize: Responsive.fontSize(context, 13),
                    ),
                  ),
                  if (!isHidden && !isCompleted) ...[
                    SizedBox(height: Responsive.spacing(context, 4)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (progress / achievement.targetValue).clamp(0.0, 1.0),
                        backgroundColor: AppColors.textGhost,
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
                        color: AppColors.textFaint,
                        fontSize: Responsive.fontSize(context, 12),
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
                      color: Colors.black, // 금색 배경 위 텍스트
                      fontSize: Responsive.fontSize(context, 14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (isClaimed)
              Icon(Icons.check_circle, color: AppColors.success,
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
              ? AppColors.sinmyeongGold.withValues(alpha: 0.05 * (4 - rank))
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
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fontSize(context, 13),
                ),
              ),
            ),
            Text(
              '${entry.score}',
              style: TextStyle(
                color: AppColors.sinmyeongGold,
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
