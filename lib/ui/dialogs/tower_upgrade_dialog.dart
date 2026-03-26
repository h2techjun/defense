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
                style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 8, height: 1.2),
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
                label: '⬆ Lv.${currentLevel + 1}',
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
                    label: '⚡ MAX',
                    cost: totalCost,
                    canAfford: currentSinmyeong >= totalCost,
                    color: AppColors.peachCoral,
                    onTap: () => onAction(TowerMaxUpgradeResult()),
                  );
                }),
              ],
            ] else ...[
              Center(child: Text('✨ MAX', style: TextStyle(color: _getColorForType(towerType), fontSize: 9))),
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

  Widget _buildBranchButton(TowerBranch? branch, TowerData towerData) {
    if (branch == null) return const SizedBox.shrink();
    final bd = GameDataLoader.getBranches()[branch];
    final branchName = bd?.name ?? _getBranchName(branch);
    final cost = bd?.cost ?? 300;

    return _CompactActionButton(
      label: '🔱 $branchName',
      cost: cost,
      canAfford: currentSinmyeong >= cost,
      color: AppColors.peachCoral,
      onTap: () => onAction(TowerBranchResult(branch)),
    );
  }

  String _getBranchName(TowerBranch branch) {
    switch (branch) {
      case TowerBranch.rocketBattery:
        return 'branch_rocket';
      case TowerBranch.spiritHunter:
        return 'branch_exorcist';
      case TowerBranch.generalTotem:
        return 'branch_general';
      case TowerBranch.goblinRing:
        return 'branch_goblin_ring';
      case TowerBranch.shamanTemple:
        return 'branch_pantheon';
      case TowerBranch.grimReaperOffice:
        return 'branch_reaper_office';
      case TowerBranch.fireDragon:
        return 'branch_fire_dragon';
      case TowerBranch.heavenlyThunder:
        return 'branch_thunder';
      case TowerBranch.phoenixTotem:
        return 'branch_phoenix_totem';
      case TowerBranch.earthSpiritAltar:
        return 'branch_earth_altar';
    }
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

// ====================================================================
// Helper widgets
// ====================================================================

/// 스탯 한 줄 (단순 label: value)
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight
                  ? AppColors.sinmyeongGold
                  : AppColors.textDisabled,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: highlight ? AppColors.sinmyeongGold : Colors.white,
                fontSize: 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 현재 -> 다음 레벨 비교 스탯 행
class _CompareStatRow extends StatelessWidget {
  final String label;
  final double current;
  final double? next;
  final String Function(double) format;

  const _CompareStatRow({
    required this.label,
    required this.current,
    this.next,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final hasNext = next != null && next != current;
    final diff = hasNext ? next! - current : 0.0;
    final isPositive = diff > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // 라벨
          SizedBox(
            width: 45,
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.textDisabled, fontSize: 13),
            ),
          ),
          // 값 영역 (길어지면 자동 축소되도록 FittedBox 적용)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  // 현재값
                  Text(
                    format(current),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  // 다음값 미리보기
                  if (hasNext) ...[
                    const SizedBox(width: 4),
                    Text(
                      '→',
                      style: TextStyle(
                        color: Colors.white.withAlpha(100),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      format(next!),
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.mintGreen
                            : AppColors.sinmyeongGold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isPositive
                          ? '(+${diff.toStringAsFixed(diff == diff.roundToDouble() ? 0 : 2)})'
                          : '(${diff.toStringAsFixed(diff == diff.roundToDouble() ? 0 : 2)})',
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.mintGreen.withAlpha(180)
                            : AppColors.sinmyeongGold.withAlpha(180),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 액션 버튼 (업그레이드/판매) — 전체 너비 버전
class _ActionButton extends StatelessWidget {
  final String label;
  final int cost;
  final bool canAfford;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              canAfford ? color.withAlpha(50) : const Color(0x22333333),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: canAfford
                ? color.withAlpha(150)
                : AppColors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      canAfford ? Colors.white : AppColors.textDisabled,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              isRefund ? '+${-cost}✨' : '$cost✨',
              style: TextStyle(
                color: isRefund
                    ? AppColors.mintGreen
                    : canAfford
                        ? AppColors.sinmyeongGold
                        : AppColors.berserkRed.withAlpha(170),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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
                color: canAfford ? Colors.white : AppColors.textDisabled,
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
                  color: canAfford ? Colors.white : AppColors.textDisabled,
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
