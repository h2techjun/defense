// 해원의 문 - 타워 업그레이드 & 판매 다이얼로그
// 타워를 터치하면 표시되는 업그레이드/판매 패널

import 'package:flutter/material.dart';

import '../../audio/sound_manager.dart';
import '../../common/enums.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/tower_data.dart';
import '../../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/glass_panel.dart';

/// 타워 업그레이드 결과 (콜백 데이터)
sealed class TowerActionResult {}

class TowerUpgradeResult extends TowerActionResult {
  final int level;
  TowerUpgradeResult(this.level);
}

class TowerSellResult extends TowerActionResult {}

class TowerMaxUpgradeResult extends TowerActionResult {
  /// 레벨 3까지 한번에 업그레이드
  TowerMaxUpgradeResult();
}

class TowerBranchResult extends TowerActionResult {
  final TowerBranch branch;
  TowerBranchResult(this.branch);
}

/// 타워 업그레이드/판매 다이얼로그 (2열 레이아웃: 왼쪽=정보, 오른쪽=버튼)
class TowerUpgradeDialog extends StatelessWidget {
  final TowerType towerType;
  final int currentLevel;
  final int sellRefund;
  final int currentSinmyeong;
  final TowerBranch? selectedBranch;
  final void Function(TowerActionResult action) onAction;

  const TowerUpgradeDialog({
    super.key,
    required this.towerType,
    required this.currentLevel,
    required this.sellRefund,
    required this.currentSinmyeong,
    required this.onAction,
    this.selectedBranch,
  });

  @override
  Widget build(BuildContext context) {
    final towerData = GameDataLoader.getTowers()[towerType];
    if (towerData == null) return const SizedBox.shrink();

    final isMaxLevel = currentLevel >= towerData.upgrades.length;
    final nextUpgrade = isMaxLevel ? null : towerData.upgrades[currentLevel];
    // currentLevel은 1-based. 0이면 아직 기본 상태
    final currentUpgrade = currentLevel > 0 &&
            currentLevel <= towerData.upgrades.length
        ? towerData.upgrades[currentLevel - 1]
        : towerData.upgrades.isNotEmpty
            ? towerData.upgrades[0]
            : null;

    if (currentUpgrade == null) return const SizedBox.shrink();

    // 분기 미선택 + 업그레이드가 최대인 경우 -> 분기 선택 UI 표시
    final needsBranch =
        isMaxLevel && selectedBranch == null && towerData.branchA != null;
    final showBranch = needsBranch || (currentLevel == 3 && !isMaxLevel);

    return GlassPanel(
      borderRadius: 10,
      blurAmount: 8,
      backgroundColor: AppColors.surfaceDark.withAlpha(210),
      borderColor: _getColorForType(towerType).withAlpha(180),
      borderWidth: 1.0,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      boxShadow: [
        BoxShadow(
          color: _getColorForType(towerType).withAlpha(30),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(maxWidth: 130),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 타워 이름 (한 줄) ──
            Row(
              children: [
                Image.asset(
                  selectedBranch != null
                      ? 'assets/images/towers/tower_${selectedBranch!.name}.png'
                      : 'assets/images/towers/tower_${towerType.name}_${currentLevel.clamp(1, 3)}.png',
                  width: 16, height: 16, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    _getIconForType(towerType), style: const TextStyle(fontSize: 10),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${currentUpgrade.name} Lv.$currentLevel',
                    style: TextStyle(
                      color: _getColorForType(towerType),
                      fontSize: 10, fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // ── 설명 (1줄) ──
            if (towerData.description.isNotEmpty)
              Text(
                towerData.description,
                style: TextStyle(color: AppColors.textDisabled, fontSize: 8, height: 1.2),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),

            // ── 액션 버튼 ──
            if (showBranch) ...[
              _MiniButton(
                label: towerData.branchA != null ? (GameDataLoader.getBranches()[towerData.branchA]?.name ?? AppStrings.trs('branch_a')) : AppStrings.trs('branch_a'),
                cost: GameDataLoader.getBranches()[towerData.branchA]?.cost ?? 300,
                canAfford: currentSinmyeong >= (GameDataLoader.getBranches()[towerData.branchA]?.cost ?? 300),
                color: AppColors.mintGreen,
                onTap: () => onAction(TowerBranchResult(towerData.branchA!)),
              ),
              const SizedBox(height: 3),
              _MiniButton(
                label: towerData.branchB != null ? (GameDataLoader.getBranches()[towerData.branchB]?.name ?? AppStrings.trs('branch_b')) : AppStrings.trs('branch_b'),
                cost: GameDataLoader.getBranches()[towerData.branchB]?.cost ?? 300,
                canAfford: currentSinmyeong >= (GameDataLoader.getBranches()[towerData.branchB]?.cost ?? 300),
                color: AppColors.peachCoral,
                onTap: () => onAction(TowerBranchResult(towerData.branchB!)),
              ),
            ] else if (!isMaxLevel && nextUpgrade != null) ...[
              _MiniButton(
                label: AppStrings.trs('tower_upgrade_lv').replaceAll('{n}', '${currentLevel + 1}'),
                cost: nextUpgrade.cost,
                canAfford: currentSinmyeong >= nextUpgrade.cost,
                color: AppColors.mintGreen,
                onTap: () => onAction(TowerUpgradeResult(currentLevel + 1)),
              ),
              if (currentLevel < 3) ...[
                const SizedBox(height: 3),
                Builder(builder: (_) {
                  int totalCost = 0;
                  for (int i = currentLevel; i < 3 && i < towerData.upgrades.length; i++) {
                    totalCost += towerData.upgrades[i].cost;
                  }
                  return _MiniButton(
                    label: AppStrings.trs('tower_upgrade_max_btn'),
                    cost: totalCost,
                    canAfford: currentSinmyeong >= totalCost,
                    color: AppColors.peachCoral,
                    onTap: () => onAction(TowerMaxUpgradeResult()),
                  );
                }),
              ],
            ] else ...[
              Center(child: Text(AppStrings.trs('label_max_sparkle'), style: TextStyle(color: _getColorForType(towerType), fontSize: 9))),
            ],
            const SizedBox(height: 3),
            // 판매
            _MiniButton(
              label: AppStrings.trs('sell_refund').replaceAll('{amount}', '$sellRefund'),
              cost: -sellRefund,
              canAfford: true,
              color: AppColors.berserkRed,
              onTap: () => onAction(TowerSellResult()),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return AppColors.towerArcher;
      case TowerType.barracks:
        return AppColors.towerBarracks;
      case TowerType.shaman:
        return AppColors.towerShaman;
      case TowerType.artillery:
        return AppColors.towerArtillery;
      case TowerType.sotdae:
        return AppColors.towerSotdae;
    }
  }

  String _getIconForType(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return '🏹';
      case TowerType.barracks:
        return '⚔️';
      case TowerType.shaman:
        return '🔮';
      case TowerType.artillery:
        return '💣';
      case TowerType.sotdae:
        return '🪶';
    }
  }
}

/// 컴팩트 액션 버튼 (오른쪽 세로 배치용 — 라벨 위 / 비용 아래)
class _CompactActionButton extends StatelessWidget {
  final String label;
  final int cost;
  final bool canAfford;
  final Color color;
  final VoidCallback onTap;

  const _CompactActionButton({
    required this.label,
    required this.cost,
    required this.canAfford,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRefund = cost < 0;
    return GestureDetector(
      onTap: () {
        if (canAfford) {
          SoundManager.instance.playSfx(SfxType.uiClick);
          onTap();
        } else {
          SoundManager.instance.playSfx(SfxType.uiError);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color:
              canAfford ? color.withAlpha(50) : const Color(0x22333333),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canAfford
                ? color.withAlpha(150)
                : AppColors.borderDefault,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: canAfford ? AppColors.textPrimary : AppColors.textDisabled,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              isRefund ? '+${-cost}✨' : '$cost✨',
              style: TextStyle(
                color: isRefund
                    ? AppColors.mintGreen
                    : canAfford
                        ? AppColors.sinmyeongGold
                        : AppColors.berserkRed.withAlpha(170),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 초컴팩트 미니 버튼 (한 줄: 라벨 + 비용)
class _MiniButton extends StatelessWidget {
  final String label;
  final int cost;
  final bool canAfford;
  final Color color;
  final VoidCallback onTap;

  const _MiniButton({
    required this.label,
    required this.cost,
    required this.canAfford,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRefund = cost < 0;
    return GestureDetector(
      onTap: () {
        if (canAfford) {
          SoundManager.instance.playSfx(SfxType.uiClick);
          onTap();
        } else {
          SoundManager.instance.playSfx(SfxType.uiError);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: canAfford ? color.withAlpha(40) : const Color(0x18333333),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: canAfford ? color.withAlpha(120) : AppColors.borderDefault,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: canAfford ? AppColors.textPrimary : AppColors.textDisabled,
                  fontSize: 9, fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isRefund)
              Text(
                '$cost✨',
                style: TextStyle(
                  color: canAfford ? AppColors.sinmyeongGold : AppColors.berserkRed.withAlpha(150),
                  fontSize: 9, fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
