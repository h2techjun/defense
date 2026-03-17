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
      TowerType.archer: {'icon': '🛖', 'image': 'tower_archer_1', 'color': AppColors.towerArcher, 'tooltip': '빠른 공격속도로 원거리 단일 적을 공격'},
      TowerType.barracks: {'icon': '🤼', 'image': 'tower_barracks_1', 'color': AppColors.towerBarracks, 'tooltip': '적을 발이 묶어 경로 진행을 차단'},
      TowerType.shaman: {'icon': '🔮', 'image': 'tower_shaman_1', 'color': AppColors.towerShaman, 'tooltip': '마법 공격으로 방어 무시 + 감속'},
      TowerType.artillery: {'icon': '💥', 'image': 'tower_artillery_1', 'color': AppColors.towerArtillery, 'tooltip': '느리지만 범위 폭발 데미지'},
      TowerType.sotdae: {'icon': '🪶', 'image': 'tower_sotdae_1', 'color': AppColors.towerSotdae, 'tooltip': '주변 타워 공격력/공속 버프'},
    };

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 그라데이션 배경 (터치 투과 — 타일 터치 허용)
          IgnorePointer(
            ignoring: true,
            child: Container(
              height: 20 * Responsive.scale(context),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x88000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          // 타워 아이콘 Row (터치 흡수)
          Container(
            color: const Color(0xCC000000),
            padding: EdgeInsets.symmetric(
              horizontal: 8 * Responsive.scale(context),
              vertical: 8 * Responsive.scale(context),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: loadout.map((type) {
                final data = towers[type];
                if (data == null) return const SizedBox.shrink();
                final meta = towerMeta[type] ?? {'icon': '❓', 'color': Colors.grey, 'tooltip': ''};
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * Responsive.scale(context)),
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
        ],
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
    final s = Responsive.scale(context);
    final borderColor = widget.canAfford ? Colors.white70 : AppColors.berserkRed;
    
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52 * s,
          height: 52 * s,
          padding: EdgeInsets.all(4 * s),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withAlpha(100)
                : _isHovered
                    ? widget.color.withAlpha(40)
                    : Colors.black.withAlpha(80),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected ? widget.color : borderColor,
              width: widget.isSelected ? 2.5 : 1.5,
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
          child: Center(
            child: Image.asset(
              'assets/images/towers/${widget.imageName}.png',
              width: 40 * s, height: 40 * s,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(widget.icon, style: TextStyle(fontSize: Responsive.fontSize(context, 20))),
            ),
          ),
        ),
      ),
    );

    // 선택 시 가격 정보를 아이콘 위에 떠있게 (패널 높이 증가 방지)
    final contentWithInfo = SizedBox(
      width: 52 * s,
      height: 52 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (widget.isSelected)
            Positioned(
              bottom: 52 * s + 4 * s, // 아이콘 위에 배치
              left: -4 * s,
              right: -4 * s,
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(200),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.color.withAlpha(120)),
                    ),
                    child: Text(
                      '✨${widget.cost}',
                      style: TextStyle(
                        color: AppColors.sinmyeongGold,
                        fontSize: Responsive.fontSize(context, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!widget.canAfford) {
      return _wrapWithTooltip(
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: contentWithInfo,
          ),
        ),
      );
    }

    return _wrapWithTooltip(
      Draggable<TowerType>(
        data: widget.type,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
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
        childWhenDragging: Opacity(opacity: 0.3, child: contentWithInfo),
        onDragStarted: () => widget.onTap?.call(),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: contentWithInfo,
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
