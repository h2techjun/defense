// 해원의 문 - 게임 결과 다이얼로그 (승리/패배)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_state.dart';

/// 승리 오버레이
class VictoryOverlay extends ConsumerWidget {
  final VoidCallback onContinue;
  final VoidCallback onReplay;

  const VictoryOverlay({
    super.key,
    required this.onContinue,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);

    return Container(
      color: const Color(0xBB000000),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0F29), Color(0xFF2D1B4E)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44FFD700),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌸', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFAA44)],
                ).createShader(bounds),
                child: const Text(
                  '한을 풀었습니다',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '"원혼들이 꽃이 되어 피어납니다."',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8866AA),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              _StatRow('처치한 적', '${state.enemiesKilled}'),
              _StatRow('남은 해원문 HP', '${state.gatewayHp}/${state.maxGatewayHp}'),
              _StatRow('점수', '${state.score}'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: '다시 하기',
                      onTap: onReplay,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: '계속',
                      onTap: onContinue,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 패배 오버레이
class DefeatOverlay extends ConsumerWidget {
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const DefeatOverlay({
    super.key,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);

    return Container(
      color: const Color(0xBB000000),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0F29), Color(0xFF2D0B1E)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF4444), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44FF0000),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💀', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF4444), Color(0xFFFF8800)],
                ).createShader(bounds),
                child: const Text(
                  '해원문이 무너졌습니다',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '"이승과 저승의 경계가 허물어진다..."',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF886666),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              _StatRow('처치한 적', '${state.enemiesKilled}'),
              _StatRow('도달 웨이브', '${state.currentWave}/${state.totalWaves}'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: '메뉴로',
                      onTap: onMenu,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: '재도전',
                      onTap: onRetry,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFAA99BB), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF6633AA), Color(0xFF9944CC)],
                )
              : null,
          color: isPrimary ? null : const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFFAA66DD)
                : const Color(0x44FFFFFF),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isPrimary ? Colors.white : const Color(0xFFBB99DD),
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
