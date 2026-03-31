// 해원의 문 - 무한의 탑 + 일일 도전 UI 화면
// 탑 진행도, 층 미리보기, 일일 도전 탭

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/debug_log.dart';
import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../data/models/endless_tower_data.dart';
import '../../data/models/daily_challenge_data.dart';
import '../../data/models/wave_data.dart';
import '../../data/wave_builder.dart';
import '../../data/json_data_loader.dart';
import '../../state/endless_tower_provider.dart';
import '../theme/app_colors.dart';
import '../../l10n/app_strings.dart';
import '../../common/asset_paths.dart';

class EndlessTowerScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final void Function(LevelData level, GameMode mode) onStartLevel;

  const EndlessTowerScreen({
    super.key,
    required this.onBack,
    required this.onStartLevel,
  });

  @override
  ConsumerState<EndlessTowerScreen> createState() => _EndlessTowerScreenState();
}

class _EndlessTowerScreenState extends ConsumerState<EndlessTowerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTowerFloor(int floor) {
    try {
      final floorData = TowerFloorGenerator.generateFloor(floor);

      // 휴식 층이면 보상 선택 다이얼로그 표시
      if (floorData.type == TowerFloorType.rest) {
        _showRestRewardDialog(floorData);
        return;
      }

      // 동적 LevelData 생성
      final waves = WaveBuilder.buildEndlessTowerFloor(floorData);
      final levelData = _buildLevelData(floorData, waves);

      // 진행 상태 업데이트
      if (ref.read(endlessTowerProvider).currentFloor == 0) {
        ref.read(endlessTowerProvider.notifier).startRun();
      }

      widget.onStartLevel(levelData, GameMode.endlessTower);
    } on Exception catch (e, st) {
      dlog('Endless Tower Error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr(ref, 'error_generic')}: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 일일 도전 시작
  void _startDailyChallenge() {
    final challenge = DailyChallengeGenerator.today;
    final floorData = TowerFloorData(
      floor: 1,
      type: challenge.bossId != null ? TowerFloorType.boss : TowerFloorType.normal,
      difficultyScale: challenge.difficultyScale,
      availableEnemies: challenge.availableEnemies,
      bossId: challenge.bossId,
      bonusGems: challenge.reward.gems,
      bonusExp: challenge.reward.exp,
      waveCount: challenge.targetWaves,
      floorTitle: '📅 ${challenge.title}',
      typeKey: challenge.bossId != null ? 'et_type_boss' : 'et_type_normal',
      narrative: 'et_narr_start',
    );

    final waves = WaveBuilder.buildEndlessTowerFloor(floorData);
    final levelData = _buildLevelData(floorData, waves);

    widget.onStartLevel(levelData, GameMode.dailyChallenge);
  }

  /// TowerFloorData → LevelData 변환
  LevelData _buildLevelData(TowerFloorData floorData, List<WaveData> waves) {
    // 기존 레벨에서 경로 데이터 차용 (층 번호에 따라 다양한 경로)
    final existingLevels = JsonDataLoader.allLevels;
    final pathIdx = existingLevels.isNotEmpty ? (floorData.floor - 1) % existingLevels.length : 0;
    final referencedLevel = existingLevels.isNotEmpty
        ? existingLevels[pathIdx]
        : null;

    final path = referencedLevel?.path ?? [
      [0, 300], [200, 300], [200, 150], [400, 150], [400, 300], [600, 300],
    ];

    // 난이도에 따른 해원문 HP 스케일링
    final baseHp = 15;
    final scaledHp = (baseHp * (1 + floorData.difficultyScale * 0.1)).round();

    return LevelData(
      levelNumber: 1000 + floorData.floor,
      chapter: Chapter.values[(floorData.floor - 1) % Chapter.values.length],
      name: floorData.floorTitle,
      briefing: floorData.narrative ?? AppStrings.trs('et_fallback_briefing').replaceAll('{floor}', '${floorData.floor}'),
      startingSinmyeong: (200 * floorData.difficultyScale).round(),
      gatewayHp: scaledHp,
      waves: waves,
      path: path,
    );
  }

  /// 휴식 층 보상 선택 다이얼로그
  void _showRestRewardDialog(TowerFloorData floorData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '🏕️ ${floorData.floor}층 — 휴식',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a reward',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...allRestRewards.map((reward) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RestRewardButton(
                  reward: reward,
                  onSelect: () {
                    Navigator.of(ctx).pop();
                    ref.read(endlessTowerProvider.notifier)
                        .selectRestReward(reward.type);
                    setState(() {});
                  },
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final towerState = ref.watch(endlessTowerProvider);
    final challengeState = ref.watch(dailyChallengeProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          // 공통 탑 테마 배경 (은은하게 투과)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                AssetPaths.asset('objects/obj_sotdae'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, towerState),
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTowerTab(context, towerState),
                      _buildDailyTab(context, challengeState),
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

  Widget _buildHeader(BuildContext context, EndlessTowerState state) {
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
            tooltip: AppStrings.trs('back'),
            icon: Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: Responsive.iconSize(context, 24)),
          ),
          SizedBox(width: Responsive.spacing(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(ref, 'et_title'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.fontSize(context, 22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppStrings.trs('et_record_summary').replaceAll('{floor}', '${state.highestFloor}').replaceAll('{gems}', '${state.totalGemsEarned}'),
                  style: TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: Responsive.fontSize(context, 15),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(context, 12),
              vertical: Responsive.spacing(context, 6),
            ),
            decoration: BoxDecoration(
              color: AppColors.sinmyeongGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.sinmyeongGold.withValues(alpha: 0.5)),
            ),
            child: Text(
              '⚔️ ${state.totalFloorsCleared}층 클리어',
              style: TextStyle(
                color: AppColors.sinmyeongGold,
                fontSize: Responsive.fontSize(context, 15),
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
          Tab(text: AppStrings.trs('et_tab_tower')),
          Tab(text: AppStrings.trs('et_tab_daily')),
        ],
      ),
    );
  }

  Widget _buildTowerTab(BuildContext context, EndlessTowerState state) {
    final startFloor = state.currentFloor > 0 ? state.currentFloor : 1;
    final displayFloors = TowerFloorGenerator.generateFloorRange(
      (startFloor - 2).clamp(1, 999),
      startFloor + 8,
    );

    return Column(
      children: [
        if (state.activeBuffs.isNotEmpty)
          Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 8)),
            color: AppColors.success.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.trs('et_active_buffs').replaceAll('{buffs}', state.activeBuffs.map((b) => b.name).join(', ')).replaceAll('{floors}', '${state.buffRemainingFloors}'),
                  style: TextStyle(
                    color: AppColors.mintGreen,
                    fontSize: Responsive.fontSize(context, 15),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(Responsive.spacing(context, 12)),
            itemCount: displayFloors.length,
            itemBuilder: (context, index) {
              final floor = displayFloors[displayFloors.length - 1 - index];
              final isCurrent = floor.floor == startFloor;
              final isCleared = floor.floor < startFloor;

              return _TowerFloorCard(
                floor: floor,
                isCurrent: isCurrent,
                isCleared: isCleared,
                onTap: () => _startTowerFloor(state.currentFloor > 0 ? state.currentFloor : 1),
              );
            },
          ),
        ),

        Padding(
          padding: EdgeInsets.all(Responsive.spacing(context, 16)),
          child: SizedBox(
            width: double.infinity,
            height: Responsive.spacing(context, 52),
            child: ElevatedButton(
              onPressed: () => _startTowerFloor(startFloor),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sinmyeongGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                state.currentFloor > 0
                    ? '⚔️ ${startFloor}층 계속하기'
                    : '🗼 탑 도전 시작',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTab(BuildContext context, DailyChallengeState state) {
    final challenge = DailyChallengeGenerator.today;
    final isCompleted = state.isCompletedToday;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 20)),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AssetPaths.asset('objects/obj_grave_mound')),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(AppColors.bgNavy.withAlpha(200), BlendMode.darken),
              ),
              gradient: const LinearGradient(
                colors: [AppColors.surfaceMid, AppColors.bgDeepPlum],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.lavender.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(color: AppColors.lavender.withAlpha(60), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📅 오늘의 도전',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: Responsive.fontSize(context, 15),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 4)),
                Text(
                  challenge.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.fontSize(context, 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 16)),

                Text(
                  tr(ref, 'et_special_rules'),
                  style: TextStyle(
                    color: AppColors.sinmyeongGold,
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 8)),
                ...challenge.modifiers.map((mod) => Padding(
                  padding: EdgeInsets.only(bottom: Responsive.spacing(context, 6)),
                  child: Row(
                    children: [
                      Text(mod.emoji, style: TextStyle(fontSize: Responsive.fontSize(context, 18))),
                      SizedBox(width: Responsive.spacing(context, 8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(ref, mod.displayName),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: Responsive.fontSize(context, 13),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              mod.description,
                              style: TextStyle(
                                color: AppColors.textMid,
                                fontSize: Responsive.fontSize(context, 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

                SizedBox(height: Responsive.spacing(context, 16)),

                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, 12)),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _rewardItem(context, '💎', '${challenge.reward.gems}', 'Gems'),
                      _rewardItem(context, '⭐', '${challenge.reward.exp}', 'EXP'),
                      _rewardItem(context, '🏆', challenge.reward.title, 'Title'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.spacing(context, 16)),

          Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 16)),
            decoration: BoxDecoration(
              color: AppColors.bgNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(context, '🔥', '${state.streak}', AppStrings.trs('et_streak_label')),
                _statItem(context, '⚔️', '${state.bestWavesSurvived}', 'Best Wave'),
                _statItem(context, '🏅', '${state.totalChallengesCompleted}', 'Total'),
              ],
            ),
          ),

          SizedBox(height: Responsive.spacing(context, 20)),

          SizedBox(
            height: Responsive.spacing(context, 52),
            child: ElevatedButton(
              onPressed: isCompleted ? null : _startDailyChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? AppColors.rarityCommon : AppColors.lavender,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isCompleted ? '✅ 오늘의 도전 완료!' : '⚔️ 도전 시작',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardItem(BuildContext context, String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: Responsive.fontSize(context, 20))),
        SizedBox(height: Responsive.spacing(context, 4)),
        Text(value, style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: Responsive.fontSize(context, 14),
          fontWeight: FontWeight.bold,
        )),
        Text(label, style: TextStyle(
          color: AppColors.textMid,
          fontSize: Responsive.fontSize(context, 13),
        )),
      ],
    );
  }

  Widget _statItem(BuildContext context, String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: Responsive.fontSize(context, 20))),
        SizedBox(height: Responsive.spacing(context, 4)),
        Text(value, style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: Responsive.fontSize(context, 16),
          fontWeight: FontWeight.bold,
        )),
        Text(label, style: TextStyle(
          color: AppColors.textMid,
          fontSize: Responsive.fontSize(context, 14),
        )),
      ],
    );
  }
}

// ── 하위 위젯 ──

class _TowerFloorCard extends StatelessWidget {
  final TowerFloorData floor;
  final bool isCurrent;
  final bool isCleared;
  final VoidCallback? onTap;

  const _TowerFloorCard({
    required this.floor,
    required this.isCurrent,
    required this.isCleared,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? AppColors.sinmyeongGold
        : isCleared
            ? AppColors.success.withValues(alpha: 0.5)
            : AppColors.textGhost;

    final bgColor = isCurrent
        ? AppColors.sinmyeongGold.withValues(alpha: 0.1)
        : isCleared
            ? AppColors.success.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.03);

    final typeColor = switch (floor.type) {
      TowerFloorType.normal => AppColors.textSecondary,
      TowerFloorType.elite  => AppColors.peachCoral,
      TowerFloorType.boss   => AppColors.berserkRed,
      TowerFloorType.rest   => AppColors.success,
    };

    final floorStatus = isCleared
        ? 'Cleared'
        : isCurrent
            ? 'Current'
            : '';
    final floorLabel = '${floor.floorTitle}, ${floor.type.name}${floorStatus.isNotEmpty ? ', $floorStatus' : ''}';

    return Semantics(
      button: isCurrent,
      label: floorLabel,
      child: Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(context, 8)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
            padding: EdgeInsets.all(Responsive.spacing(context, 12)),
            decoration: BoxDecoration(
              color: isCurrent ? null : bgColor,
              gradient: isCurrent
                  ? LinearGradient(colors: [AppColors.sinmyeongGold.withAlpha(40), Colors.black.withAlpha(150)])
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
              boxShadow: isCurrent
                  ? [BoxShadow(color: AppColors.sinmyeongGold.withAlpha(60), blurRadius: 10, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: Responsive.spacing(context, 44),
                  height: Responsive.spacing(context, 44),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      '${floor.floor}',
                      style: TextStyle(
                        color: typeColor,
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.spacing(context, 12)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${floor.floorTitle} — ${AppStrings.trs(floor.typeKey)}',
                        style: TextStyle(
                          color: isCleared ? AppColors.textMid : AppColors.textPrimary,
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.bold,
                          decoration: isCleared ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, 2)),
                      Text(
                        floor.type == TowerFloorType.rest
                            ? AppStrings.trs('et_reward_select')
                            : '${AppStrings.trs('wave')}: ${floor.waveCount} | ${AppStrings.trs('et_difficulty')}: ×${floor.difficultyScale.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: Responsive.fontSize(context, 14),
                        ),
                      ),
                    ],
                  ),
                ),

                if (floor.bonusGems > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(context, 8),
                      vertical: Responsive.spacing(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sinmyeongGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💎${floor.bonusGems}',
                      style: TextStyle(
                        color: AppColors.sinmyeongGold,
                        fontSize: Responsive.fontSize(context, 14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (isCleared)
                  Padding(
                    padding: EdgeInsets.only(left: Responsive.spacing(context, 8)),
                    child: Icon(Icons.check_circle,
                      color: AppColors.success, size: Responsive.iconSize(context, 20)),
                  ),

                if (isCurrent)
                  Padding(
                    padding: EdgeInsets.only(left: Responsive.spacing(context, 8)),
                    child: Icon(Icons.play_circle_fill,
                      color: AppColors.sinmyeongGold, size: Responsive.iconSize(context, 24)),
                  ),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    ));
  }
}

class _RestRewardButton extends StatelessWidget {
  final RestReward reward;
  final VoidCallback onSelect;

  const _RestRewardButton({required this.reward, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(Responsive.spacing(context, 12)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Text(reward.emoji, style: TextStyle(fontSize: Responsive.fontSize(context, 22))),
              SizedBox(width: Responsive.spacing(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(context, 13),
                      ),
                    ),
                    Text(
                      reward.description,
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: Responsive.fontSize(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textFaint, size: Responsive.iconSize(context, 20)),
            ],
          ),
        ),
      ),
    );
  }
}
