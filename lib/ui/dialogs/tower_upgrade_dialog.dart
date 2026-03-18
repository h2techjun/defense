// 해원의 문 - 타워 업그레이드 & 판매 다이얼로그
// 타워를 터치하면 표시되는 업그레이드/판매 패널

import 'package:flutter/material.dart';

import '../../audio/sound_manager.dart';
import '../../common/enums.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/tower_data.dart';
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
      borderRadius: 16,
      blurAmount: 10,
      backgroundColor: AppColors.surfaceDark.withAlpha(200),
      borderColor: _getColorForType(towerType).withAlpha(180),
      borderWidth: 1.5,
      padding: const EdgeInsets.all(10),
      boxShadow: [
        BoxShadow(
          color: _getColorForType(towerType).withAlpha(40),
          blurRadius: 20,
          spreadRadius: 4,
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(maxWidth: 125),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 타워 이름 & 아이콘 ──
            Row(
              children: [
                Image.asset(
                  selectedBranch != null
                      ? 'assets/images/towers/tower_${selectedBranch!.name}.png'
                      : 'assets/images/towers/tower_${towerType.name}_${currentLevel.clamp(1, 3)}.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    _getIconForType(towerType),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${currentUpgrade.name} Lv.$currentLevel',
                    style: TextStyle(
                      color: _getColorForType(towerType),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── 액션 버튼 영역 (세로 3단 배치) ──
            if (showBranch) ...[
              _buildBranchButton(towerData.branchA, towerData),
              const SizedBox(height: 4),
              _buildBranchButton(towerData.branchB, towerData),
            ] else if (!isMaxLevel && nextUpgrade != null) ...[
              // 1단: 업그레이드 버튼
              _CompactActionButton(
                label: '⬆ Lv.${currentLevel + 1}',
                cost: nextUpgrade.cost,
                canAfford: currentSinmyeong >= nextUpgrade.cost,
                color: AppColors.mintGreen,
                onTap: () => onAction(TowerUpgradeResult(currentLevel + 1)),
              ),
              const SizedBox(height: 4),
              // 2단: MAX 업그레이드 버튼
              if (currentLevel < 3) ...[
                Builder(builder: (_) {
                  int totalCost = 0;
                  for (int i = currentLevel;
                      i < 3 && i < towerData.upgrades.length;
                      i++) {
                    totalCost += towerData.upgrades[i].cost;
                  }
                  return _CompactActionButton(
                    label: '⚡ MAX',
                    cost: totalCost,
                    canAfford: currentSinmyeong >= totalCost,
                    color: AppColors.peachCoral,
                    onTap: () => onAction(TowerMaxUpgradeResult()),
                  );
                }),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.center,
                  child: const Text('✨ MAX', style: TextStyle(color: AppColors.textDisabled, fontSize: 10)),
                )
              ],
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '✨ 최대 레벨',
                    style: TextStyle(
                        color: _getColorForType(towerType), fontSize: 11),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            // 3단: 판매 버튼
            _CompactActionButton(
              label: '🪙 판매 (+$sellRefund)',
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
        return '로켓포';
      case TowerBranch.spiritHunter:
        return '퇴령';
      case TowerBranch.generalTotem:
        return '천하대장군';
      case TowerBranch.goblinRing:
        return '도깨비 고리';
      case TowerBranch.shamanTemple:
        return '만신당';
      case TowerBranch.grimReaperOffice:
        return '저승사자 출장소';
      case TowerBranch.fireDragon:
        return '화룡';
      case TowerBranch.heavenlyThunder:
        return '벼락진천뢰';
      case TowerBranch.phoenixTotem:
        return '봉황솟단';
      case TowerBranch.earthSpiritAltar:
        return '지신제단';
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
