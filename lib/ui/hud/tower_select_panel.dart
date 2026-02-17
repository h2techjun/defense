// 해원의 문 - 타워 선택 패널 (인게임 하단)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/enums.dart';
import '../../state/game_state.dart';

/// 타워 선택 콜백
typedef TowerSelectCallback = void Function(TowerType type);

/// 타워 선택 패널 - 화면 하단에 타워 아이콘 표시
class TowerSelectPanel extends ConsumerWidget {
  final TowerSelectCallback? onTowerSelected;
  final TowerType? selectedTower;

  const TowerSelectPanel({
    super.key,
    this.onTowerSelected,
    this.selectedTower,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Color(0x00000000)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TowerButton(
              type: TowerType.archer,
              name: '궁수\n산적초소',
              cost: 70,
              color: const Color(0xFF228B22),
              icon: '🏹',
              canAfford: state.sinmyeong >= 70,
              isSelected: selectedTower == TowerType.archer,
              onTap: () => onTowerSelected?.call(TowerType.archer),
            ),
            const SizedBox(width: 12),
            _TowerButton(
              type: TowerType.barracks,
              name: '병영\n씨름터',
              cost: 90,
              color: const Color(0xFF4169E1),
              icon: '🤼',
              canAfford: state.sinmyeong >= 90,
              isSelected: selectedTower == TowerType.barracks,
              onTap: () => onTowerSelected?.call(TowerType.barracks),
            ),
            const SizedBox(width: 12),
            _TowerButton(
              type: TowerType.shaman,
              name: '마법\n서당',
              cost: 100,
              color: const Color(0xFF9400D3),
              icon: '🔮',
              canAfford: state.sinmyeong >= 100,
              isSelected: selectedTower == TowerType.shaman,
              onTap: () => onTowerSelected?.call(TowerType.shaman),
            ),
          ],
        ),
      ),
    );
  }
}

class _TowerButton extends StatelessWidget {
  final TowerType type;
  final String name;
  final int cost;
  final Color color;
  final String icon;
  final bool canAfford;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TowerButton({
    required this.type,
    required this.name,
    required this.cost,
    required this.color,
    required this.icon,
    required this.canAfford,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(100) : const Color(0x44000000),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : canAfford
                    ? color.withAlpha(120)
                    : const Color(0x33FFFFFF),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: canAfford ? Colors.white : Colors.white38,
                fontSize: 9,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: canAfford
                    ? const Color(0x44FFD700)
                    : const Color(0x22FF0000),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '✨$cost',
                style: TextStyle(
                  color: canAfford
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFF6666),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
