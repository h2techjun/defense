// 해원의 문 - 타워 업그레이드 & 판매 다이얼로그
// 타워를 터치하면 표시되는 업그레이드/판매 패널

import 'package:flutter/material.dart';

import '../../common/enums.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/tower_data.dart';

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

/// 타워 업그레이드/판매 다이얼로그
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
    final currentUpgrade = currentLevel > 0 && currentLevel <= towerData.upgrades.length
        ? towerData.upgrades[currentLevel - 1]
        : towerData.upgrades.isNotEmpty ? towerData.upgrades[0] : null;

    if (currentUpgrade == null) return const SizedBox.shrink();

    // 분기 미선택 + 업그레이드가 최대인 경우 → 분기 선택 UI 표시
    final needsBranch = isMaxLevel && selectedBranch == null 
        && towerData.branchA != null;
    final showBranch = needsBranch || (currentLevel == 3 && !isMaxLevel);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEE1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getColorForType(towerType).withAlpha(180),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getColorForType(towerType).withAlpha(40),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 타워 이름 & 레벨 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentUpgrade.name} (Lv.$currentLevel)',
                style: TextStyle(
                  color: _getColorForType(towerType),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getIconForType(towerType),
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── 현재 스탯 + 다음 레벨 미리보기 ──
          _CompareStatRow(
            label: '공격력',
            current: currentUpgrade.damage,
            next: nextUpgrade?.damage,
            format: (v) => v.toStringAsFixed(0),
          ),
          _CompareStatRow(
            label: '사거리',
            current: currentUpgrade.range,
            next: nextUpgrade?.range,
            format: (v) => v.toStringAsFixed(0),
          ),
          _CompareStatRow(
            label: '공속',
            current: currentUpgrade.fireRate,
            next: nextUpgrade?.fireRate,
            format: (v) => '${v.toStringAsFixed(2)}/s',
          ),
          if (currentUpgrade.specialAbility != null)
            _StatRow('특수', currentUpgrade.specialAbility!,
                highlight: true),
          if (nextUpgrade?.specialAbility != null &&
              currentUpgrade.specialAbility != nextUpgrade!.specialAbility)
            _StatRow('🆕 특수', nextUpgrade.specialAbility!,
                highlight: true),
          const Divider(color: Color(0x33FFFFFF), height: 16),

          // ── 업그레이드 버튼 ──
          if (showBranch) ...[
            _buildBranchButton(towerData.branchA, towerData),
            const SizedBox(height: 6),
            _buildBranchButton(towerData.branchB, towerData),
          ] else if (!isMaxLevel && nextUpgrade != null) ...[
            _ActionButton(
              label: '⬆ ${nextUpgrade.name} (Lv.${currentLevel + 1})',
              cost: nextUpgrade.cost,
              canAfford: currentSinmyeong >= nextUpgrade.cost,
              color: const Color(0xFF4CAF50),
              onTap: () => onAction(TowerUpgradeResult(currentLevel + 1)),
            ),
            // MAX 업그레이드 버튼 (현재 레벨이 3 미만일 때만)
            if (currentLevel < 3) ...[
              const SizedBox(height: 4),
              Builder(builder: (_) {
                // 현재 레벨 ~ 레벨 3까지의 총 비용 계산
                int totalCost = 0;
                for (int i = currentLevel; i < 3 && i < towerData.upgrades.length; i++) {
                  totalCost += towerData.upgrades[i].cost;
                }
                return _ActionButton(
                  label: '⚡ MAX (Lv.3)',
                  cost: totalCost,
                  canAfford: currentSinmyeong >= totalCost,
                  color: const Color(0xFFFF9800),
                  onTap: () => onAction(TowerMaxUpgradeResult()),
                );
              }),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: const Text(
                '최대 레벨',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 6),

          // ── 판매 버튼 ──
          _ActionButton(
            label: '🪙 판매',
            cost: -sellRefund,
            canAfford: true,
            color: const Color(0xFFFF6B6B),
            onTap: () => onAction(TowerSellResult()),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchButton(TowerBranch? branch, TowerData towerData) {
    if (branch == null) return const SizedBox.shrink();
    // 분기 데이터에서 실제 비용·설명 가져오기
    final bd = GameDataLoader.getBranches()[branch];
    final branchName = bd?.name ?? _getBranchName(branch);
    final cost = bd?.cost ?? 300;
    final description = bd?.specialAbility ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButton(
          label: '🔱 $branchName',
          cost: cost,
          canAfford: currentSinmyeong >= cost,
          color: const Color(0xFFFF9800),
          onTap: () => onAction(TowerBranchResult(branch)),
        ),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2, bottom: 4),
            child: Text(
              description,
              style: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  String _getBranchName(TowerBranch branch) {
    switch (branch) {
      case TowerBranch.rocketBattery:
        return '신기전';
      case TowerBranch.spiritHunter:
        return '신궁';
      case TowerBranch.generalTotem:
        return '천하대장군';
      case TowerBranch.goblinRing:
        return '도깨비 씨름판';
      case TowerBranch.shamanTemple:
        return '만신전';
      case TowerBranch.grimReaperOffice:
        return '저승사자 출장소';
      case TowerBranch.fireDragon:
        return '화차';
      case TowerBranch.heavenlyThunder:
        return '비격진천뢰';
      case TowerBranch.phoenixTotem:
        return '수호신단';
      case TowerBranch.earthSpiritAltar:
        return '지신제단';
    }
  }

  Color _getColorForType(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return const Color(0xFF228B22);
      case TowerType.barracks:
        return const Color(0xFF4169E1);
      case TowerType.shaman:
        return const Color(0xFF9400D3);
      case TowerType.artillery:
        return const Color(0xFFB22222);
      case TowerType.sotdae:
        return const Color(0xFFFFD700);
    }
  }

  String _getIconForType(TowerType type) {
    switch (type) {
      case TowerType.archer:
        return '🏹';
      case TowerType.barracks:
        return '🤼';
      case TowerType.shaman:
        return '🔮';
      case TowerType.artillery:
        return '💥';
      case TowerType.sotdae:
        return '🪶';
    }
  }
}

/// 스탯 한 줄 (단순)
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? const Color(0xFFFFD700) : const Color(0xFF999999),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFFFFD700) : Colors.white,
              fontSize: 11,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// 현재 → 다음 레벨 비교 스탯 행
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
            width: 42,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
            ),
          ),
          // 현재값
          Text(
            format(current),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          // 다음값 미리보기
          if (hasNext) ...[
            const SizedBox(width: 4),
            Text(
              '→',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              format(next!),
              style: TextStyle(
                color: isPositive
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFFBBF24),
                fontSize: 11,
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
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.7)
                    : const Color(0xFFFBBF24).withValues(alpha: 0.7),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 액션 버튼 (업그레이드/판매)
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
      onTap: canAfford ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: canAfford ? color.withAlpha(50) : const Color(0x22333333),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: canAfford ? color.withAlpha(150) : const Color(0x33FFFFFF),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: canAfford ? Colors.white : const Color(0xFF666666),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              isRefund ? '+${-cost}✨' : '${cost}✨',
              style: TextStyle(
                color: isRefund
                    ? const Color(0xFF44FF44)
                    : canAfford
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFFF6666),
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
