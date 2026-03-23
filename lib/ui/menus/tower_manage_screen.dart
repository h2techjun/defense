// 해원의 문 - 타워 관리 화면 (반응형)
// 타워 외부 레벨/XP 확인 + 출전 선택 + 인게임 레벨/분기별 스탯 조회

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

class TowerManageScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const TowerManageScreen({super.key, required this.onBack});

  // 타워 메타 (아이콘/색상)
  static const _meta = <TowerType, Map<String, dynamic>>{
    TowerType.archer: {'icon': '🛖', 'image': 'tower_archer_1', 'color': AppColors.towerArcher, 'descKey': 'tower_desc_archer'},
    TowerType.barracks: {'icon': '🤼', 'image': 'tower_barracks_1', 'color': AppColors.towerBarracks, 'descKey': 'tower_desc_barracks'},
    TowerType.shaman: {'icon': '🔮', 'image': 'tower_shaman_1', 'color': AppColors.towerShaman, 'descKey': 'tower_desc_shaman'},
    TowerType.artillery: {'icon': '💥', 'image': 'tower_artillery_1', 'color': AppColors.towerArtillery, 'descKey': 'tower_desc_artillery'},
    TowerType.sotdae: {'icon': '🪶', 'image': 'tower_sotdae_1', 'color': AppColors.towerSotdae, 'descKey': 'tower_desc_sotdae'},
  };

  @override
  ConsumerState<TowerManageScreen> createState() => _TowerManageScreenState();
}

class _TowerManageScreenState extends ConsumerState<TowerManageScreen> {
  // 각 타워별 표시할 인게임 레벨/분기 상태 (null = 기본 Lv.1)
  // 값: 0=Lv.1, 1=Lv.2, 2=Lv.3, 3=분기A, 4=분기B
  final Map<TowerType, int> _selectedPreviewLevel = {};

  @override
  Widget build(BuildContext context) {
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
                  onTap: widget.onBack,
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
                  'tower_deploy_title',
                  style: TextStyle(color: AppColors.lavender, fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6 * s),
                Row(
                  children: List.generate(TowerLoadoutNotifier.maxLoadoutSlots, (i) {
                    final hasSlot = i < loadoutState.loadout.length;
                    final type = hasSlot ? loadoutState.loadout[i] : null;
                    final meta = type != null ? TowerManageScreen._meta[type] : null;

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
                                    : const Color(0xCC1A1530),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isHovering
                                      ? const Color(0xFFCC88FF)
                                      : hasSlot
                                          ? (meta?['color'] as Color?)?.withAlpha(200) ?? const Color(0x66FFFFFF)
                                          : const Color(0x22FFFFFF),
                                  width: hasSlot ? 2 : 1,
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

          // 타워 카드 그리드 (반응형: 행별 동일 높이 + 스크롤)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth - 24 * s;
                final spacing = 6 * s;
                // 최소 카드 너비 (이 이하로는 줄어들지 않고 다음 줄로 넘어감)
                const minCardWidth = 140.0;
                final cols = ((availableWidth + spacing) / (minCardWidth + spacing)).floor().clamp(1, allTypes.length);
                final cardWidth = (availableWidth - spacing * (cols - 1)) / cols;

                // 카드들을 행 단위로 묶기
                final List<List<TowerType>> rows = [];
                for (int i = 0; i < allTypes.length; i += cols) {
                  rows.add(allTypes.sublist(i, (i + cols).clamp(0, allTypes.length)));
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12 * s),
                  child: Column(
                    children: rows.asMap().entries.map((rowEntry) {
                      final rowIdx = rowEntry.key;
                      final rowTypes = rowEntry.value;

                      return Padding(
                        padding: EdgeInsets.only(bottom: rowIdx < rows.length - 1 ? spacing : 0),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rowTypes.asMap().entries.map((entry) {
                              final colIdx = entry.key;
                              final type = entry.value;
                              final data = towers[type]!;
                              final meta = TowerManageScreen._meta[type] ?? {'icon': '❓', 'color': Colors.grey, 'desc': ''};
                              final color = meta['color'] as Color;
                              final level = loadoutState.getTowerLevel(type);
                              final xp = loadoutState.getTowerXp(type);
                              final maxLv = TowerLoadoutNotifier.maxExternalLevel;
                              final xpNeeded = level < maxLv ? TowerLoadoutNotifier.xpForLevel(level) : 0;
                              final isInLoadout = loadoutState.loadout.contains(type);
                              final previewIdx = _selectedPreviewLevel[type] ?? 0;

                              return SizedBox(
                                width: cardWidth,
                                child: Padding(
                                  padding: EdgeInsets.only(right: colIdx < rowTypes.length - 1 ? spacing : 0),
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
                                      child: _buildTowerCard(context, lang, s, cardWidth, type, data, meta, color, level, xp, maxLv, xpNeeded, isInLoadout, previewIdx),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (isInLoadout) {
                                          ref.read(towerLoadoutProvider.notifier).removeFromLoadout(type);
                                        } else if (loadoutState.loadout.length < TowerLoadoutNotifier.maxLoadoutSlots) {
                                          ref.read(towerLoadoutProvider.notifier).addToLoadout(type);
                                        }
                                      },
                                      child: _buildTowerCard(context, lang, s, cardWidth, type, data, meta, color, level, xp, maxLv, xpNeeded, isInLoadout, previewIdx),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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

  /// 드롭다운 선택지 빌드
  List<DropdownMenuItem<int>> _buildDropdownItems(TowerData data) {
    final items = <DropdownMenuItem<int>>[];
    for (int i = 0; i < data.upgrades.length; i++) {
      items.add(DropdownMenuItem(
        value: i,
        child: Text(
          'Lv.${data.upgrades[i].level}',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ));
    }
    if (data.branchA != null) {
      final bd = GameDataLoader.getBranches()[data.branchA];
      items.add(DropdownMenuItem(
        value: data.upgrades.length,
        child: Text(
          bd?.name ?? 'branch_a_fallback',
          style: const TextStyle(color: AppColors.sinmyeongGold, fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }
    if (data.branchB != null) {
      final bd = GameDataLoader.getBranches()[data.branchB];
      items.add(DropdownMenuItem(
        value: data.upgrades.length + 1,
        child: Text(
          bd?.name ?? 'branch_b_fallback',
          style: const TextStyle(color: AppColors.mintGreen, fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }
    return items;
  }

  /// 선택된 프리뷰 인덱스에 따른 스탯
  ({String name, double damage, double range, double fireRate, String? special, String? desc}) _getPreviewStats(TowerData data, int previewIdx) {
    if (previewIdx < data.upgrades.length) {
      final u = data.upgrades[previewIdx];
      return (
        name: u.name, damage: u.damage, range: u.range,
        fireRate: u.fireRate, special: u.specialAbility, desc: null,
      );
    }
    final branchOffset = previewIdx - data.upgrades.length;
    TowerBranch? branchKey;
    if (branchOffset == 0) branchKey = data.branchA;
    else if (branchOffset == 1) branchKey = data.branchB;
    if (branchKey != null) {
      final bd = GameDataLoader.getBranches()[branchKey];
      if (bd != null) {
        return (
          name: bd.name, damage: bd.damage, range: bd.range,
          fireRate: bd.fireRate, special: bd.specialAbility, desc: bd.description,
        );
      }
    }
    final u = data.upgrades.isNotEmpty ? data.upgrades[0] : null;
    return (
      name: data.name,
      damage: u?.damage ?? data.baseDamage,
      range: u?.range ?? data.baseRange,
      fireRate: u?.fireRate ?? data.baseFireRate,
      special: null, desc: null,
    );
  }

  /// 타워 카드 위젯 (반응형 — 모든 카드 동일 높이)
  Widget _buildTowerCard(
    BuildContext context, GameLanguage lang, double s, double cardWidth,
    TowerType type, TowerData data, Map<String, dynamic> meta, Color color,
    int level, int xp, int maxLv, int xpNeeded, bool isInLoadout,
    int previewIdx,
  ) {
    final stats = _getPreviewStats(data, previewIdx);
    final isBranch = previewIdx >= data.upgrades.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 아이콘 + 이름 + 체크
              Row(
                children: [
                  Container(
                    width: 36 * s, height: 36 * s,
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/towers/${meta['image'] as String}.png',
                        width: 36 * s, height: 36 * s, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(meta['icon'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, 16))),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 9), fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
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
                            style: TextStyle(color: color, fontSize: Responsive.fontSize(context, 7), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isInLoadout)
                    Icon(Icons.check_circle, color: color, size: 12 * s),
                ],
              ),
              SizedBox(height: 4 * s),

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

              // 레벨/분기 드롭다운
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4 * s),
                decoration: BoxDecoration(
                  color: isBranch ? AppColors.sinmyeongGold.withAlpha(20) : Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isBranch ? AppColors.sinmyeongGold.withAlpha(80) : Colors.white24),
                ),
                child: DropdownButton<int>(
                  value: previewIdx,
                  items: _buildDropdownItems(data),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPreviewLevel[type] = val);
                  },
                  isExpanded: true, isDense: true,
                  dropdownColor: const Color(0xEE1A1530),
                  underline: const SizedBox.shrink(),
                  iconSize: 14 * s,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white54, size: 14 * s),
                  style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 9)),
                ),
              ),
              SizedBox(height: 4 * s),

              // 스탯 표시
              _statRow(context, s, '⚔️', AppStrings.get(lang, 'stat_attack'), stats.damage.toStringAsFixed(1), color),
              SizedBox(height: 2 * s),
              _statRow(context, s, '🎯', AppStrings.get(lang, 'stat_range'), stats.range.toStringAsFixed(0), color),
              SizedBox(height: 2 * s),
              _statRow(context, s, '⚡', AppStrings.get(lang, 'stat_speed'), '${stats.fireRate.toStringAsFixed(2)}/s', color),
              if (stats.special != null) ...[
                SizedBox(height: 2 * s),
                Row(
                  children: [
                    Text('💎', style: TextStyle(fontSize: Responsive.fontSize(context, 8))),
                    SizedBox(width: 2 * s),
                    Expanded(
                      child: Text(
                        stats.special!,
                        style: TextStyle(color: AppColors.sinmyeongGold, fontSize: Responsive.fontSize(context, 7)),
                        maxLines: 3, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (stats.desc != null) ...[
                SizedBox(height: 2 * s),
                Text(
                  stats.desc!,
                  style: TextStyle(color: Colors.white38, fontSize: Responsive.fontSize(context, 6)),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 능력치 행 위젯
  Widget _statRow(BuildContext context, double s, String icon, String label, String value, Color color) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: Responsive.fontSize(context, 8))),
        SizedBox(width: 2 * s),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: Responsive.fontSize(context, 7))),
        const Spacer(),
        Text(value, style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 8), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
