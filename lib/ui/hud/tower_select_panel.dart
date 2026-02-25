// 해원의 문 - 타워 선택 패널 (인게임 하단)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/sound_manager.dart';

import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../state/game_state.dart';
import '../../state/tower_loadout_provider.dart';
import '../../data/game_data_loader.dart';
import '../theme/app_colors.dart';

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
    final loadout = ref.watch(towerLoadoutProvider).loadout;
    final towers = GameDataLoader.getTowers();

    // 타워 타입별 메타데이터
    const towerMeta = <TowerType, Map<String, dynamic>>{
      TowerType.archer: {'icon': '🛖', 'image': 'tower_archer_t1', 'color': AppColors.towerArcher, 'tooltip': '빠른 공격속도로 원거리 단일 적을 공격'},
      TowerType.barracks: {'icon': '🤼', 'image': 'tower_barracks_t1', 'color': AppColors.towerBarracks, 'tooltip': '적을 발이 묶어 경로 진행을 차단'},
      TowerType.shaman: {'icon': '🔮', 'image': 'tower_shaman_t1', 'color': AppColors.towerShaman, 'tooltip': '마법 공격으로 방어 무시 + 감속'},
      TowerType.artillery: {'icon': '💥', 'image': 'tower_artillery_t1', 'color': AppColors.towerArtillery, 'tooltip': '느리지만 범위 폭발 데미지'},
      TowerType.sotdae: {'icon': '🪶', 'image': 'tower_sotdae_t1', 'color': AppColors.towerSotdae, 'tooltip': '주변 타워 공격력/공속 버프'},
    };

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8 * Responsive.scale(context), vertical: 8 * Responsive.scale(context)),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xCC000000), Color(0x00000000)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: loadout.map((type) {
              final data = towers[type];
              if (data == null) return const SizedBox.shrink();
              final meta = towerMeta[type] ?? {'icon': '❓', 'color': Colors.grey, 'tooltip': ''};
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 3 * Responsive.scale(context)),
                child: _TowerButton(
                  type: type,
                  name: data.name,
                  cost: data.baseCost,
                  color: meta['color'] as Color,
                  icon: meta['icon'] as String,
                  imageName: meta['image'] as String,
                  tooltip: meta['tooltip'] as String,
                  canAfford: state.sinmyeong >= data.baseCost,
                  isSelected: selectedTower == type,
                  onTap: () {
                    if (state.sinmyeong >= data.baseCost) {
                      SoundManager.instance.playSfx(SfxType.uiClick);
                      onTowerSelected?.call(type);
                    } else {
                      SoundManager.instance.playSfx(SfxType.uiError);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TowerButton extends StatefulWidget {
  final TowerType type;
  final String name;
  final int cost;
  final Color color;
  final String icon;
  final String imageName;
  final String? tooltip;
  final bool canAfford;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TowerButton({
    required this.type,
    required this.name,
    required this.cost,
    required this.color,
    required this.icon,
    required this.imageName,
    this.tooltip,
    required this.canAfford,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_TowerButton> createState() => _TowerButtonState();
}

class _TowerButtonState extends State<_TowerButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64 * Responsive.scale(context),
          padding: EdgeInsets.all(4 * Responsive.scale(context)),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withAlpha(100)
                : _isHovered
                    ? widget.color.withAlpha(40)
                    : Colors.black.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : widget.canAfford
                      ? widget.color.withAlpha(100)
                      : AppColors.borderDefault,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.color.withAlpha(80),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32 * Responsive.scale(context),
            height: 32 * Responsive.scale(context),
            child: Image.asset(
              'assets/images/towers/${widget.imageName}.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(widget.icon, style: TextStyle(fontSize: Responsive.fontSize(context, 20))),
            ),
          ),
          SizedBox(height: 2 * Responsive.scale(context)),
          Text(
            widget.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              color: widget.canAfford ? Colors.white : Colors.white38,
              fontSize: Responsive.fontSize(context, 8),
              height: 1.2,
            ),
          ),
          SizedBox(height: 2 * Responsive.scale(context)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * Responsive.scale(context), vertical: 1 * Responsive.scale(context)),
            decoration: BoxDecoration(
              color: widget.canAfford
                  ? AppColors.sinmyeongGold.withAlpha(68)
                  : AppColors.berserkRed.withAlpha(34),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '✨${widget.cost}',
              style: TextStyle(
                color: widget.canAfford
                    ? AppColors.sinmyeongGold
                    : AppColors.berserkRed.withAlpha(170),
                fontSize: Responsive.fontSize(context, 10),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.isSelected) ...[
            SizedBox(height: 4 * Responsive.scale(context)),
            Container(
              width: 20 * Responsive.scale(context),
              height: 3 * Responsive.scale(context),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
      ),
      ),
    );

    if (!widget.canAfford) {
      return _wrapWithTooltip(
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: content,
          ),
        ),
      );
    }

    return _wrapWithTooltip(
      Draggable<TowerType>(
        data: widget.type,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Transform.translate(
          offset: const Offset(-32, -32),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 64 * Responsive.scale(context),
              height: 64 * Responsive.scale(context),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Image.asset(
                'assets/images/towers/${widget.imageName}.png',
                width: 48 * Responsive.scale(context),
                height: 48 * Responsive.scale(context),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(widget.icon, style: TextStyle(fontSize: Responsive.fontSize(context, 32), decoration: TextDecoration.none)),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: content),
        onDragStarted: () => widget.onTap?.call(),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _wrapWithTooltip(Widget child) {
    if (widget.tooltip == null) return child;
    return Tooltip(
      message: '${widget.name.replaceAll('\n', ' ')} (✨${widget.cost})\n${widget.tooltip!}',
      textStyle: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 11)),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withAlpha(240),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0x44FFFFFF)),
      ),
      waitDuration: const Duration(milliseconds: 400),
      child: child,
    );
  }
}
