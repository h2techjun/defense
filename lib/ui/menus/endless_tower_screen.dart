// ?¥Ïõê??Î¨?- Î¨¥Ìïú????+ ?ºÏùº ?ÑÏ†Ñ UI ?îÎ©¥
// ??ÏßÑÌñâ?? Ï∏?ÎØ∏Î¶¨Î≥¥Í∏∞, ?ºÏùº ?ÑÏ†Ñ ??

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../data/models/endless_tower_data.dart';
import '../../data/models/daily_challenge_data.dart';
import '../../data/models/wave_data.dart';
import '../../data/wave_builder.dart';
import '../../data/json_data_loader.dart';
import '../../state/endless_tower_provider.dart';
import '../theme/app_colors.dart';

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

  /// Î¨¥Ìïú?????úÏûë
  void _startTowerFloor(int floor) {
    final floorData = TowerFloorGenerator.generateFloor(floor);

    // ?¥Ïãù Ï∏µÏù¥Î©?Î≥¥ÏÉÅ ?†ÌÉù ?§Ïù¥?ºÎ°úÍ∑??úÏãú
    if (floorData.type == TowerFloorType.rest) {
      _showRestRewardDialog(floorData);
      return;
    }

    // ?ôÏ†Å LevelData ?ùÏÑ±
    final waves = WaveBuilder.buildEndlessTowerFloor(floorData);
    final levelData = _buildLevelData(floorData, waves);

    // ÏßÑÌñâ ?ÅÌÉú ?ÖÎç∞?¥Ìä∏
    if (ref.read(endlessTowerProvider).currentFloor == 0) {
      ref.read(endlessTowerProvider.notifier).startRun();
    }

    widget.onStartLevel(levelData, GameMode.endlessTower);
  }

  /// ?ºÏùº ?ÑÏ†Ñ ?úÏûë
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
      floorTitle: '?ìÖ ${challenge.title}',
      narrative: '"?§Îäò???úÎ†®???úÏûë?úÎã§..."',
    );

    final waves = WaveBuilder.buildEndlessTowerFloor(floorData);
    final levelData = _buildLevelData(floorData, waves);

    widget.onStartLevel(levelData, GameMode.dailyChallenge);
  }

  /// TowerFloorData ??LevelData Î≥Ä??
  LevelData _buildLevelData(TowerFloorData floorData, List<WaveData> waves) {
    // Í∏∞Ï°¥ ?àÎ≤®?êÏÑú Í≤ΩÎ°ú ?∞Ïù¥??Ï∞®Ïö© (Ï∏?Î≤àÌò∏???∞Îùº ?§Ïñë??Í≤ΩÎ°ú)
    final existingLevels = JsonDataLoader.allLevels;
    final pathIdx = (floorData.floor - 1) % existingLevels.length;
    final referencedLevel = existingLevels.isNotEmpty
        ? existingLevels[pathIdx]
        : null;

    final path = referencedLevel?.path ?? [
      [0, 300], [200, 300], [200, 150], [400, 150], [400, 300], [600, 300],
    ];

    // ?úÏù¥?ÑÏóê ?∞Î•∏ ?¥ÏõêÎ¨?HP ?§Ï??ºÎßÅ
    final baseHp = 20;
    final scaledHp = (baseHp * (1 + floorData.difficultyScale * 0.1)).round();

    return LevelData(
      levelNumber: 1000 + floorData.floor,
      chapter: Chapter.values[(floorData.floor - 1) % Chapter.values.length],
      name: floorData.floorTitle,
      briefing: floorData.narrative ?? 'Î¨¥Ìïú????${floorData.floor}Ï∏?,
      startingSinmyeong: (200 * floorData.difficultyScale).round(),
      gatewayHp: scaledHp,
      waves: waves,
      path: path,
    );
  }

  /// ?¥Ïãù Ï∏?Î≥¥ÏÉÅ ?†ÌÉù ?§Ïù¥?ºÎ°úÍ∑?
  void _showRestRewardDialog(TowerFloorData floorData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '?èïÔ∏?${floorData.floor}Ï∏????¥Ïãù',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Î≥¥ÏÉÅ???òÎÇò ?†ÌÉù?òÏÑ∏??,
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
          // Í≥µÌÜµ ???åÎßà Î∞∞Í≤Ω (?Ä?Ä?òÍ≤å ?¨Í≥º)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/towers/tower_sotdae_3.png',
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
                  '?óº Î¨¥Ìïú????,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ÏµúÍ≥† Í∏∞Î°ù: ${state.highestFloor}Ï∏?| Î≥¥ÏÑù: ${state.totalGemsEarned}?íé',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: Responsive.fontSize(context, 12),
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
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Text(
              '?îÔ∏è ${state.totalFloorsCleared}Ï∏??¥Î¶¨??,
              style: TextStyle(
                color: Colors.amber,
                fontSize: Responsive.fontSize(context, 12),
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
          Tab(text: '?óº Î¨¥Ìïú????),
          Tab(text: '?ìÖ ?ºÏùº ?ÑÏ†Ñ'),
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
            color: Colors.green.withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '?úÏÑ± Î≤ÑÌîÑ: ${state.activeBuffs.map((b) => b.name).join(', ')} (${state.buffRemainingFloors}Ï∏??®Ïùå)',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: Responsive.fontSize(context, 12),
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
                onTap: isCurrent
                    ? () => _startTowerFloor(floor.floor)
                    : null,
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
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                state.currentFloor > 0
                    ? '?îÔ∏è ${startFloor}Ï∏?Í≥ÑÏÜç?òÍ∏∞'
                    : '?óº ???ÑÏ†Ñ ?úÏûë',
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
                image: const AssetImage('assets/images/objects/obj_shrine.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(const Color(0xFF16213E).withAlpha(200), BlendMode.darken),
              ),
              gradient: const LinearGradient(
                colors: [AppColors.surfaceMid, AppColors.bgDeepPlum],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(color: Colors.purple.withAlpha(60), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '?ìÖ ?§Îäò???ÑÏ†Ñ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: Responsive.fontSize(context, 12),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 4)),
                Text(
                  challenge.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, 16)),

                Text(
                  '?πÏàò Í∑úÏπô',
                  style: TextStyle(
                    color: Colors.amber,
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
                              mod.displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.fontSize(context, 13),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              mod.description,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: Responsive.fontSize(context, 11),
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
                      _rewardItem(context, '?íé', '${challenge.reward.gems}', 'Î≥¥ÏÑù'),
                      _rewardItem(context, '‚≠?, '${challenge.reward.exp}', 'Í≤ΩÌóòÏπ?),
                      _rewardItem(context, '?èÜ', challenge.reward.title, 'Ïπ?ò∏'),
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
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(context, '?î•', '${state.streak}??, '?∞ÏÜç ?ÑÏ†Ñ'),
                _statItem(context, '?îÔ∏è', '${state.bestWavesSurvived}', 'ÏµúÍ≥† ?®Ïù¥Î∏?),
                _statItem(context, '?èÖ', '${state.totalChallengesCompleted}', 'Ï¥??ÑÎ£å'),
              ],
            ),
          ),

          SizedBox(height: Responsive.spacing(context, 20)),

          SizedBox(
            height: Responsive.spacing(context, 52),
            child: ElevatedButton(
              onPressed: isCompleted ? null : _startDailyChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.grey : Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isCompleted ? '???§Îäò???ÑÏ†Ñ ?ÑÎ£å!' : '?îÔ∏è ?ÑÏ†Ñ ?úÏûë',
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

  Widget _statItem(BuildContext context, String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: Responsive.fontSize(context, 20))),
        SizedBox(height: Responsive.spacing(context, 4)),
        Text(value, style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.fontSize(context, 16),
          fontWeight: FontWeight.bold,
        )),
        Text(label, style: TextStyle(
          color: Colors.white54,
          fontSize: Responsive.fontSize(context, 11),
        )),
      ],
    );
  }
}

// ?Ä?Ä ?òÏúÑ ?ÑÏ†Ø ?Ä?Ä

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
        ? Colors.amber
        : isCleared
            ? Colors.green.withValues(alpha: 0.5)
            : Colors.white12;

    final bgColor = isCurrent
        ? Colors.amber.withValues(alpha: 0.1)
        : isCleared
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.03);

    final typeColor = switch (floor.type) {
      TowerFloorType.normal => Colors.white70,
      TowerFloorType.elite  => Colors.orange,
      TowerFloorType.boss   => Colors.red,
      TowerFloorType.rest   => Colors.green,
    };

    return Padding(
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
                  ? LinearGradient(colors: [Colors.amber.withAlpha(40), Colors.black.withAlpha(150)])
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
              boxShadow: isCurrent
                  ? [BoxShadow(color: Colors.amber.withAlpha(60), blurRadius: 10, offset: const Offset(0, 2))]
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
                        floor.floorTitle,
                        style: TextStyle(
                          color: isCleared ? Colors.white54 : Colors.white,
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.bold,
                          decoration: isCleared ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, 2)),
                      Text(
                        floor.type == TowerFloorType.rest
                            ? 'Î≥¥ÏÉÅ ?†ÌÉù'
                            : '?®Ïù¥Î∏? ${floor.waveCount} | ?úÏù¥?? √ó${floor.difficultyScale.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: Responsive.fontSize(context, 11),
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
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '?íé${floor.bonusGems}',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: Responsive.fontSize(context, 11),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (isCleared)
                  Padding(
                    padding: EdgeInsets.only(left: Responsive.spacing(context, 8)),
                    child: Icon(Icons.check_circle,
                      color: Colors.green, size: Responsive.iconSize(context, 20)),
                  ),

                if (isCurrent)
                  Padding(
                    padding: EdgeInsets.only(left: Responsive.spacing(context, 8)),
                    child: Icon(Icons.play_circle_fill,
                      color: Colors.amber, size: Responsive.iconSize(context, 24)),
                  ),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(context, 13),
                      ),
                    ),
                    Text(
                      reward.description,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: Responsive.fontSize(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white38, size: Responsive.iconSize(context, 20)),
            ],
          ),
        ),
      ),
    );
  }
}

