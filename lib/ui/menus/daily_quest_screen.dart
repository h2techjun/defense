// 해원의 문 - 일일 미션 UI
// 프리미엄 디자인: 출석 캘린더 + 미션 카드 + 올클리어 보물상자

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/responsive.dart';
import '../../data/models/daily_quest_data.dart';
import '../../state/daily_quest_provider.dart';
import '../../audio/sound_manager.dart';
import '../theme/app_colors.dart';

class DailyQuestScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DailyQuestScreen({super.key, required this.onBack});

  @override
  ConsumerState<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends ConsumerState<DailyQuestScreen> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getRemainingTime() {
    final tomorrow = DateTime(_now.year, _now.month, _now.day + 1);
    final diff = tomorrow.difference(_now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final questState = ref.watch(dailyQuestProvider);
    final s = Responsive.scale(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          // 공통 배경 에셋 투과
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/objects/obj_shrine.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, questState, s),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16 * s),
                    children: [
                      // ── 연속 출석 캘린더 ──
                      _buildStreakCalendar(context, ref, questState, s),
                      SizedBox(height: 20 * s),

                      // ── 일일 미션 카드 ──
                      _buildSectionTitle('📋 오늘의 미션', s),
                      SizedBox(height: 8 * s),
                      ...questState.mainQuests.map(
                        (q) => _buildQuestCard(context, ref, questState, q, false, s),
                      ),

                      SizedBox(height: 16 * s),

                      // ── 보너스 미션 ──
                      if (questState.bonusQuest != null) ...[
                        _buildSectionTitle('⭐ 보너스 미션', s),
                        SizedBox(height: 8 * s),
                        _buildQuestCard(context, ref, questState, questState.bonusQuest!, true, s),
                        SizedBox(height: 16 * s),
                      ],

                      // ── 올클리어 보너스 ──
                      _buildAllClearBonus(context, ref, questState, s),
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

  Widget _buildHeader(BuildContext context, DailyQuestState state, double s) {
    final completed = state.quests.where((q) => state.isCompleted(q.id)).length;
    final total = state.quests.length;

    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceMid, AppColors.bgDeepPlum],
        ),
        border: Border(bottom: BorderSide(color: AppColors.lavender, width: 1)),
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
                  '📋 일일 미션',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.fontSize(context, 22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '완료: $completed / $total | 🔥 연속 ${state.loginStreak}일차',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: Responsive.fontSize(context, 12),
                  ),
                ),
                SizedBox(height: 4 * s),
                // 리셋 카운트다운 타이머
                Row(
                  children: [
                    Icon(Icons.timer, color: Colors.amber, size: 14 * s),
                    SizedBox(width: 4 * s),
                    Text(
                      '초기화까지 ${_getRemainingTime()}',
                      style: TextStyle(
                        color: _now.hour >= 23 ? Colors.redAccent : Colors.amber,
                        fontSize: Responsive.fontSize(context, 11),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 출석 연속일 뱃지
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔥', style: TextStyle(fontSize: 16 * s)),
                SizedBox(width: 4 * s),
                Text(
                  '${state.loginStreak}일',
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar(BuildContext context, WidgetRef ref, DailyQuestState state, double s) {
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: AppColors.bgDeepPlum.withAlpha(200),
        image: DecorationImage(
          image: const AssetImage('assets/images/objects/obj_old_well.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(AppColors.bgDeepPlum.withAlpha(180), BlendMode.darken),
        ),
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: AppColors.lavender.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.bgDeepPlum.withAlpha(100), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 연속 출석 보상',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.fontSize(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: loginStreakRewards.map((reward) {
              final isReached = state.loginStreak >= reward.day;
              final isClaimed = state.streakRewardsClaimed.contains(reward.day);
              final isClaimable = state.loginStreak == reward.day && !isClaimed;
              final isToday = state.loginStreak == reward.day;

              return GestureDetector(
                onTap: isClaimable
                    ? () {
                        final success = ref.read(dailyQuestProvider.notifier)
                            .claimStreakReward(reward.day);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${reward.emoji} ${reward.displayName} 획득!'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        }
                      }
                    : null,
                child: Column(
                  children: [
                    // 날짜 원형
                    Container(
                      width: 36 * s,
                      height: 36 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isClaimed
                            ? Colors.green.withAlpha(50)
                            : isClaimable
                                ? Colors.amber.withAlpha(80)
                                : isReached
                                    ? Colors.white.withAlpha(15)
                                    : Colors.white.withAlpha(5),
                        border: Border.all(
                          color: isClaimed
                              ? Colors.green
                              : isClaimable
                                  ? Colors.amber
                                  : isToday
                                      ? Colors.white54
                                      : Colors.white12,
                          width: isClaimable ? 2 : 1,
                        ),
                        boxShadow: isClaimable
                            ? [BoxShadow(color: Colors.amber.withAlpha(60), blurRadius: 8)]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          isClaimed ? '✅' : reward.emoji,
                          style: TextStyle(fontSize: 14 * s),
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * s),
                    // 일차
                    Text(
                      '${reward.day}일',
                      style: TextStyle(
                        color: isReached ? Colors.white : Colors.white38,
                        fontSize: 10 * s,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, double s) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.lavender,
        fontSize: 16 * s,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context, WidgetRef ref, DailyQuestState state,
    DailyQuest quest, bool isBonus, double s,
  ) {
    final progress = state.progress[quest.id] ?? 0;
    final isCompleted = progress >= quest.targetValue;
    final isClaimed = state.claimed.contains(quest.id);
    final progressRatio = (progress / quest.targetValue).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14 * s),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
      margin: EdgeInsets.only(bottom: 8 * s),
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        color: isClaimed
            ? Colors.green.withAlpha(25)
            : isBonus
                ? const Color(0xFF1F1040).withAlpha(180)
                : const Color(0xFF16213E).withAlpha(180),
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(
          color: isClaimed
              ? Colors.green.withAlpha(100)
              : isBonus
                  ? Colors.amber.withAlpha(80)
                  : isCompleted
                      ? Colors.cyan.withAlpha(80)
                      : Colors.white.withAlpha(15),
          width: isBonus ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 아이콘
              Text(quest.type.emoji, style: TextStyle(fontSize: 22 * s)),
              SizedBox(width: 10 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isBonus)
                          Container(
                            margin: EdgeInsets.only(right: 6 * s),
                            padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '보너스',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9 * s,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            quest.description,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14 * s,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2 * s),
                    // 보상 표시
                    Row(
                      children: [
                        if (quest.rewardPassXp > 0)
                          _rewardTag('🌟${quest.rewardPassXp}XP', AppColors.sinmyeongGold, s),
                        if (quest.rewardGold > 0)
                          _rewardTag('🪙${quest.rewardGold}', AppColors.sinmyeongGold, s),
                        if (quest.rewardGems > 0)
                          _rewardTag('💎${quest.rewardGems}', AppColors.skyBlue, s),
                      ],
                    ),
                  ],
                ),
              ),
              // 수령 및 바로가기 프레임
              if (isClaimed)
                // CLEAR 스탬프 연출
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 3.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Transform.rotate(
                        angle: -0.2, // 살짝 삐딱하게 스탬프 연출
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CLEAR',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w900,
                              fontSize: 16 * s,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              else if (isCompleted)
                ElevatedButton(
                  onPressed: () {
                    final success = ref.read(dailyQuestProvider.notifier).claimReward(quest.id);
                    if (success) {
                      SoundManager.instance.playSfx(SfxType.uiUpgrade);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${quest.type.emoji} 보상 획득!'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('수령', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 * s)),
                )
              else if (quest.type.routePath != null)
                // 바로가기 버튼 추가
                OutlinedButton.icon(
                  onPressed: () {
                    widget.onBack();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('해당 메뉴 탭을 선택해주세요! 🚀'),
                        backgroundColor: Colors.cyan.shade700,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.flight_takeoff, size: 14 * s, color: Colors.cyan),
                  label: Text('이동', style: TextStyle(color: Colors.cyan, fontSize: 11 * s, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.cyan.withAlpha(100)),
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                Text(
                  '$progress/${quest.targetValue}',
                  style: TextStyle(color: Colors.white54, fontSize: 12 * s),
                ),
            ],
          ),
          SizedBox(height: 8 * s),
          // 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: Colors.white.withAlpha(15),
              valueColor: AlwaysStoppedAnimation<Color>(
                isClaimed
                    ? Colors.green
                    : isCompleted
                        ? Colors.cyan
                        : Colors.amber,
              ),
              minHeight: 5 * s,
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _rewardTag(String text, Color color, double s) {
    return Container(
      margin: EdgeInsets.only(right: 6 * s),
      padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10 * s, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAllClearBonus(BuildContext context, WidgetRef ref, DailyQuestState state, double s) {
    final isReady = state.isAllMainCompleted;
    final isClaimed = state.allClearClaimed;

    return GestureDetector(
      onTap: isReady && !isClaimed
          ? () {
              final success = ref.read(dailyQuestProvider.notifier).claimAllClearBonus();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎁 올클리어 보너스 획득!'),
                    backgroundColor: Colors.purple,
                  ),
                );
              }
            }
          : null,
      child: Container(
        padding: EdgeInsets.all(20 * s),
        decoration: BoxDecoration(
          color: isReady ? null : const Color(0xFF16213E).withAlpha(200),
          image: isReady && !isClaimed
              ? DecorationImage(
                  image: const AssetImage('assets/images/objects/obj_shrine.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(const Color(0xFF4A148C).withAlpha(150), BlendMode.srcATop),
                )
              : null,
          gradient: isReady && !isClaimed
              ? const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)])
              : null,
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(
            color: isClaimed
                ? Colors.green.withAlpha(100)
                : isReady
                    ? Colors.amber.withAlpha(150)
                    : Colors.white.withAlpha(10),
            width: isReady ? 2 : 1,
          ),
          boxShadow: isReady && !isClaimed
              ? [BoxShadow(color: Colors.purple.withAlpha(80), blurRadius: 15, spreadRadius: 3)]
              : null,
        ),
        child: Column(
          children: [
            Text(
              isClaimed ? '✅' : (isReady ? '🎁' : '🔒'),
              style: TextStyle(fontSize: 36 * s),
            ),
            SizedBox(height: 8 * s),
            Text(
              '올클리어 보너스',
              style: TextStyle(
                color: isClaimed ? Colors.green : Colors.white,
                fontSize: 16 * s,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4 * s),
            Text(
              isClaimed
                  ? '수령 완료!'
                  : isReady
                      ? '탭하여 수령하세요!'
                      : '일일 미션 3개를 모두 완료하세요',
              style: TextStyle(
                color: isClaimed ? Colors.green.shade300 : Colors.white60,
                fontSize: 12 * s,
              ),
            ),
            SizedBox(height: 8 * s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rewardTag('💎$allClearBonusGems', AppColors.skyBlue, s),
                _rewardTag('🪙$allClearBonusGold', AppColors.sinmyeongGold, s),
                _rewardTag('🌟${allClearBonusPassXp}XP', AppColors.sinmyeongGold, s),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
