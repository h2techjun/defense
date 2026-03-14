// 해원의 문 - 타워 관리 화면 (반응형)
// 타워 외부 레벨/XP 확인 + 출전 선택

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/tower_data.dart';
import '../../state/tower_loadout_provider.dart';
import '../../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/themed_scaffold.dart';
import '../widgets/touch_button.dart';

class TowerManageScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const TowerManageScreen({super.key, required this.onBack});

  // 타워 메타 (아이콘/색상)
  static const _meta = <TowerType, Map<String, dynamic>>{
    TowerType.archer: {'icon': '🛖', 'image': 'tower_archer_1', 'color': AppColors.towerArcher, 'desc': '빠른 공격, 단일 타격'},
    TowerType.barracks: {'icon': '🤼', 'image': 'tower_barracks_1', 'color': AppColors.towerBarracks, 'desc': '유닛 소환, 경로 차단'},
    TowerType.shaman: {'icon': '🔮', 'image': 'tower_shaman_1', 'color': AppColors.towerShaman, 'desc': '마법 공격, 방어 무시'},
    TowerType.artillery: {'icon': '💥', 'image': 'tower_artillery_1', 'color': AppColors.towerArtillery, 'desc': '느린 공격, 광역 피해'},
    TowerType.sotdae: {'icon': '🪶', 'image': 'tower_sotdae_1', 'color': AppColors.towerSotdae, 'desc': '아군 버프 + 정화'},
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(gameLanguageProvider);
    final loadoutState = ref.watch(towerLoadoutProvider);
    final towers = GameDataLoader.getTowers();
    final allTypes = towers.keys.toList();
    final s = Responsive.scale(context);

    return ThemedScaffold(
      backgroundColor: AppColors.scaffoldBg,
      backgroundAsset: 'assets/images/bg/bg_tower_manage.png',
      body: Column(
        children: [
          // 헤더
          Padding(
              padding: EdgeInsets.all(12 * s),
              child: Row(
                children: [
                  TouchButton(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x44FFFFFF)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
                    child: Text(
                      AppStrings.get(lang, 'back'),
                      style: TextStyle(color: Colors.white70, fontSize: Responsive.fontSize(context, 13)),
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  Text(
                    AppStrings.get(lang, 'menu_towers'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 출전 슬롯 표시 (DragTarget 지원)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12 * s),
              padding: EdgeInsets.all(10 * s),
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x44CC88FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚔️ 출전 편성 (최대 5)',
                    style: TextStyle(color: AppColors.lavender, fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6 * s),
                  Row(
                    children: List.generate(TowerLoadoutNotifier.maxLoadoutSlots, (i) {
                      final hasSlot = i < loadoutState.loadout.length;
                      final type = hasSlot ? loadoutState.loadout[i] : null;
                      final meta = type != null ? _meta[type] : null;

                      return Expanded(
                        child: DragTarget<TowerType>(
                          onWillAcceptWithDetails: (_) => true,
                          onAcceptWithDetails: (details) {
                            final draggedType = details.data;
                            ref.read(towerLoadoutProvider.notifier)
                                .insertAtSlot(i, draggedType);
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isHovering = candidateData.isNotEmpty;
                            return GestureDetector(
                              onTap: hasSlot ? () {
                                ref.read(towerLoadoutProvider.notifier).removeFromLoadout(type!);
                              } : null,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 2 * s),
                                height: 120 * s,
                                decoration: BoxDecoration(
                                  color: isHovering
                                      ? const Color(0x44CC88FF)
                                      : hasSlot
                                          ? (meta?['color'] as Color?)?.withAlpha(60) ?? const Color(0x33FFFFFF)
                                          : const Color(0x11FFFFFF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isHovering
                                        ? const Color(0xFFCC88FF)
                                        : hasSlot ? const Color(0x66FFFFFF) : const Color(0x22FFFFFF),
                                    width: isHovering ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: hasSlot
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/images/towers/${meta?['image'] as String? ?? 'tower_archer_t1'}.png',
                                              width: 80 * s, height: 80 * s, fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Text(meta?['icon'] as String? ?? '?', style: TextStyle(fontSize: Responsive.fontSize(context, 18))),
                                            ),
                                            Text(
                                              'Lv.${loadoutState.getTowerLevel(type!)}',
                                              style: TextStyle(color: Colors.white54, fontSize: Responsive.fontSize(context, 8)),
                                            ),
                                          ],
                                        )
                                      : Text('+', style: TextStyle(color: Colors.white24, fontSize: Responsive.fontSize(context, 18))),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12 * s),

            // 타워 카드 그리드
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth - 24 * s;
                  final spacing = 6 * s;
                  final cardWidth = (availableWidth - spacing * (allTypes.length - 1)) / allTypes.length;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12 * s),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: allTypes.asMap().entries.map((entry) {
                        final i = entry.key;
                        final type = entry.value;
                        final data = towers[type]!;
                        final meta = _meta[type] ?? {'icon': '❓', 'color': Colors.grey, 'desc': ''};
                        final color = meta['color'] as Color;
                        final level = loadoutState.getTowerLevel(type);
                        final xp = loadoutState.getTowerXp(type);
                        final maxLv = TowerLoadoutNotifier.maxExternalLevel;
                        final xpNeeded = level < maxLv ? TowerLoadoutNotifier.xpForLevel(level) : 0;
                        final isInLoadout = loadoutState.loadout.contains(type);
                        final curDmg = TowerLoadoutNotifier.damageMultiplier(level);
                        final curRange = TowerLoadoutNotifier.rangeMultiplier(level);
                        final curSpeed = TowerLoadoutNotifier.fireRateMultiplier(level);
                        final nxtLv = (level < maxLv) ? level + 1 : level;
                        final nxtDmg = TowerLoadoutNotifier.damageMultiplier(nxtLv);
                        final nxtRange = TowerLoadoutNotifier.rangeMultiplier(nxtLv);
                        final nxtSpeed = TowerLoadoutNotifier.fireRateMultiplier(nxtLv);
                        final baseDmg = data.baseDamage;
                        final baseRange = data.baseRange;
                        final baseSpeed = data.baseFireRate;

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < allTypes.length - 1 ? spacing : 0),
                            child: Draggable<TowerType>(
                              data: type,
                              dragAnchorStrategy: (_, __, ___) => Offset(30 * s, 30 * s),
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width: 60 * s, height: 60 * s,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(180),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 12)],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/towers/${meta['image'] as String}.png',
                                      width: 40 * s, height: 40 * s, fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Text(meta['icon'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, 24))),
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _buildTowerCard(context, s, cardWidth, data, meta, color, level, xp, maxLv, xpNeeded, isInLoadout,
                                    baseDmg, baseRange, baseSpeed, curDmg, curRange, curSpeed, nxtDmg, nxtRange, nxtSpeed),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  if (isInLoadout) {
                                    ref.read(towerLoadoutProvider.notifier).removeFromLoadout(type);
                                  } else if (loadoutState.loadout.length < TowerLoadoutNotifier.maxLoadoutSlots) {
                                    ref.read(towerLoadoutProvider.notifier).addToLoadout(type);
                                  }
                                },
                                child: _buildTowerCard(context, s, cardWidth, data, meta, color, level, xp, maxLv, xpNeeded, isInLoadout,
                                    baseDmg, baseRange, baseSpeed, curDmg, curRange, curSpeed, nxtDmg, nxtRange, nxtSpeed),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  /// 타워 카드 위젯 (반응형)
  Widget _buildTowerCard(
    BuildContext context, double s, double cardWidth,
    TowerData data, Map<String, dynamic> meta, Color color,
    int level, int xp, int maxLv, int xpNeeded, bool isInLoadout,
    double baseDmg, double baseRange, double baseSpeed,
    double curDmg, double curRange, double curSpeed,
    double nxtDmg, double nxtRange, double nxtSpeed,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
      width: cardWidth,
      padding: EdgeInsets.all(8 * s),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1530),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isInLoadout ? color.withAlpha(160) : const Color(0x33FFFFFF),
          width: isInLoadout ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 아이콘 + 이름 + 체크
          Row(
            children: [
              Container(
                width: 56 * s,
                height: 56 * s,
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/towers/${meta['image'] as String}.png',
                    width: 56 * s, height: 56 * s, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(meta['icon'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, 16))),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 10), fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 2 * s),
                      padding: EdgeInsets.symmetric(horizontal: 4 * s, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withAlpha(50),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        level >= maxLv ? 'MAX' : 'Lv.$level',
                        style: TextStyle(color: color, fontSize: Responsive.fontSize(context, 8), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              if (isInLoadout)
                Icon(Icons.check_circle, color: color, size: 14 * s),
            ],
          ),
          SizedBox(height: 6 * s),

          // XP 바
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: level >= maxLv ? 1.0 : (xpNeeded > 0 ? xp / xpNeeded : 0),
              backgroundColor: const Color(0x22FFFFFF),
               color: level >= maxLv ? AppColors.sinmyeongGold : color.withAlpha(180),
              minHeight: 3 * s,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 2 * s),
            child: Text(
              level >= maxLv ? '✨ MAX' : '$xp / $xpNeeded XP',
              style: TextStyle(color: Colors.white38, fontSize: Responsive.fontSize(context, 7)),
            ),
          ),
          SizedBox(height: 4 * s),

          // 능력치 표시
          _statRow(context, s, '⚔️', '공격', (baseDmg * curDmg).toStringAsFixed(1),
              level < maxLv ? '+${((nxtDmg - curDmg) * baseDmg).toStringAsFixed(1)}' : null, color),
          SizedBox(height: 2 * s),
          _statRow(context, s, '🎯', '사거리', (baseRange * curRange).toStringAsFixed(0),
              level < maxLv ? '+${((nxtRange - curRange) * baseRange).toStringAsFixed(1)}' : null, color),
          SizedBox(height: 2 * s),
          _statRow(context, s, '⚡', '공속', '${(baseSpeed * curSpeed).toStringAsFixed(2)}s',
              level < maxLv ? '+${((nxtSpeed - curSpeed) * baseSpeed).toStringAsFixed(2)}' : null, color),
        ],
      ),
    ),
      ),
    );
  }

  /// 능력치 행 위젯 (반응형)
  Widget _statRow(BuildContext context, double s, String icon, String label, String value, String? nextBonus, Color color) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: Responsive.fontSize(context, 8))),
        SizedBox(width: 2 * s),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: Responsive.fontSize(context, 7))),
        const Spacer(),
        Text(value, style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 8), fontWeight: FontWeight.bold)),
        if (nextBonus != null) ...[
          SizedBox(width: 3 * s),
          Text(
            nextBonus,
            style: TextStyle(color: color.withAlpha(200), fontSize: Responsive.fontSize(context, 7), fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}
