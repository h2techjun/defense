// 해원의 문 - 타워 관리 화면
// 타워 외부 레벨/XP 확인 + 출전 선택

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/enums.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/tower_data.dart';
import '../../state/tower_loadout_provider.dart';
import '../../l10n/app_strings.dart';

class TowerManageScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const TowerManageScreen({super.key, required this.onBack});

  // 타워 메타 (아이콘/색상)
  static const _meta = <TowerType, Map<String, dynamic>>{
    TowerType.archer: {'icon': '🏹', 'color': Color(0xFF228B22), 'desc': '빠른 공격, 단일 타격'},
    TowerType.barracks: {'icon': '🤼', 'color': Color(0xFF4169E1), 'desc': '근접 차단, 적 묶기'},
    TowerType.shaman: {'icon': '🔮', 'color': Color(0xFF9400D3), 'desc': '마법 데미지 + 감속'},
    TowerType.artillery: {'icon': '💥', 'color': Color(0xFFB22222), 'desc': '범위 폭발 데미지'},
    TowerType.sotdae: {'icon': '🪶', 'color': Color(0xFFFFD700), 'desc': '아군 버프 + 정화'},
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(gameLanguageProvider);
    final loadoutState = ref.watch(towerLoadoutProvider);
    final towers = GameDataLoader.getTowers();
    final allTypes = towers.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1A),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0x44FFFFFF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.get(lang, 'back'),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppStrings.get(lang, 'menu_towers'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 출전 슬롯 표시 (DragTarget 지원)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x44CC88FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚔️ 출전 편성 (최대 5)',
                    style: TextStyle(color: Color(0xFFCC88FF), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                height: 56,
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
                                            Text(meta?['icon'] as String? ?? '?', style: const TextStyle(fontSize: 20)),
                                            Text(
                                              'Lv.${loadoutState.getTowerLevel(type!)}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 9),
                                            ),
                                          ],
                                        )
                                      : const Text('+', style: TextStyle(color: Colors.white24, fontSize: 20)),
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

            const SizedBox(height: 16),

            // 타워 카드 그리드
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: allTypes.map((type) {
                    final data = towers[type]!;
                    final meta = _meta[type] ?? {'icon': '❓', 'color': Colors.grey, 'desc': ''};
                    final color = meta['color'] as Color;
                    final level = loadoutState.getTowerLevel(type);
                    final xp = loadoutState.getTowerXp(type);
                    final maxLv = TowerLoadoutNotifier.maxExternalLevel;
                    final xpNeeded = level < maxLv ? TowerLoadoutNotifier.xpForLevel(level) : 0;
                    final isInLoadout = loadoutState.loadout.contains(type);

                    // 현재 레벨 스탯 배율
                    final curDmg = TowerLoadoutNotifier.damageMultiplier(level);
                    final curRange = TowerLoadoutNotifier.rangeMultiplier(level);
                    final curSpeed = TowerLoadoutNotifier.fireRateMultiplier(level);

                    // 다음 레벨 스탯 배율
                    final nxtLv = (level < maxLv) ? level + 1 : level;
                    final nxtDmg = TowerLoadoutNotifier.damageMultiplier(nxtLv);
                    final nxtRange = TowerLoadoutNotifier.rangeMultiplier(nxtLv);
                    final nxtSpeed = TowerLoadoutNotifier.fireRateMultiplier(nxtLv);

                    // 실제 스탯 값
                    final baseDmg = data.baseDamage;
                    final baseRange = data.baseRange;
                    final baseSpeed = data.baseFireRate;

                    return Draggable<TowerType>(
                      data: type,
                      dragAnchorStrategy: (_, __, ___) => const Offset(30, 30),
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: color.withAlpha(180),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 12)],
                          ),
                          child: Center(
                            child: Text(meta['icon'] as String, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildTowerCard(data, meta, color, level, xp, maxLv, xpNeeded, isInLoadout,
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
                        child: _buildTowerCard(data, meta, color, level, xp, maxLv, xpNeeded, isInLoadout,
                            baseDmg, baseRange, baseSpeed, curDmg, curRange, curSpeed, nxtDmg, nxtRange, nxtSpeed),
                      ),
                    );
                    
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 타워 카드 위젯 (Draggable의 child/childWhenDragging에서 재사용)
  Widget _buildTowerCard(
    TowerData data, Map<String, dynamic> meta, Color color,
    int level, int xp, int maxLv, int xpNeeded, bool isInLoadout,
    double baseDmg, double baseRange, double baseSpeed,
    double curDmg, double curRange, double curSpeed,
    double nxtDmg, double nxtRange, double nxtSpeed,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1530),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(meta['icon'] as String, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withAlpha(50),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        level >= maxLv ? 'MAX' : 'Lv.$level',
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              if (isInLoadout)
                Icon(Icons.check_circle, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),

          // XP 바
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: level >= maxLv ? 1.0 : (xpNeeded > 0 ? xp / xpNeeded : 0),
              backgroundColor: const Color(0x22FFFFFF),
              color: level >= maxLv ? const Color(0xFFFFD700) : color.withAlpha(180),
              minHeight: 3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              level >= maxLv ? '✨ MAX' : '$xp / $xpNeeded XP',
              style: const TextStyle(color: Colors.white38, fontSize: 8),
            ),
          ),
          const SizedBox(height: 4),

          // 능력치 표시
          _statRow('⚔️', '공격', (baseDmg * curDmg).toStringAsFixed(1),
              level < maxLv ? '+${((nxtDmg - curDmg) * baseDmg).toStringAsFixed(1)}' : null, color),
          const SizedBox(height: 2),
          _statRow('🎯', '사거리', (baseRange * curRange).toStringAsFixed(0),
              level < maxLv ? '+${((nxtRange - curRange) * baseRange).toStringAsFixed(1)}' : null, color),
          const SizedBox(height: 2),
          _statRow('⚡', '공속', '${(baseSpeed * curSpeed).toStringAsFixed(2)}s',
              level < maxLv ? '+${((nxtSpeed - curSpeed) * baseSpeed).toStringAsFixed(2)}' : null, color),
        ],
      ),
    );
  }

  /// 능력치 행 위젯
  Widget _statRow(String icon, String label, String value, String? nextBonus, Color color) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 9)),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        if (nextBonus != null) ...[
          const SizedBox(width: 3),
          Text(
            nextBonus,
            style: TextStyle(color: color.withAlpha(200), fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}
