// 해원의 문 - 게임 HUD (인게임 UI 오버레이)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/enums.dart';
import '../../state/game_state.dart';

/// 인게임 HUD - 자원, 한 게이지, 웨이브 정보 표시
class GameHud extends ConsumerWidget {
  final VoidCallback? onPause;
  final VoidCallback? onNextWave;

  const GameHud({super.key, this.onPause, this.onNextWave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);

    return Stack(
      children: [
        // ── 상단 바 ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Color(0x00000000)],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // 신명 (자원)
                  _ResourceBadge(
                    icon: '✨',
                    label: '신명',
                    value: state.sinmyeong.toString(),
                    color: const Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 16),

                  // 게이트웨이 HP
                  _ResourceBadge(
                    icon: '🏛️',
                    label: '해원문',
                    value: '${state.gatewayHp}/${state.maxGatewayHp}',
                    color: state.gatewayHp > state.maxGatewayHp * 0.5
                        ? const Color(0xFF44FF44)
                        : const Color(0xFFFF4444),
                  ),
                  const SizedBox(width: 16),

                  // 웨이브
                  _ResourceBadge(
                    icon: '🌊',
                    label: '웨이브',
                    value: '${state.currentWave}/${state.totalWaves}',
                    color: const Color(0xFF88CCFF),
                  ),
                  const SizedBox(width: 16),

                  // 낮/밤
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.dayCycle == DayCycle.day
                          ? const Color(0x44FFAA00)
                          : const Color(0x44000088),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: state.dayCycle == DayCycle.day
                            ? const Color(0xFFFFAA00)
                            : const Color(0xFF4444FF),
                      ),
                    ),
                    child: Text(
                      state.dayCycle == DayCycle.day ? '☀️ 낮' : '🌙 밤',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 처치 수
                  Text(
                    '💀 ${state.enemiesKilled}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 일시정지 버튼
                  IconButton(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause_circle_outline,
                        color: Colors.white70, size: 28),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── 한(恨) 게이지 바 ──
        Positioned(
          top: 65,
          left: 16,
          right: 200,
          child: _WailingGauge(wailing: state.wailing),
        ),

        // ── 밤 오버레이 ──
        if (state.dayCycle == DayCycle.night)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: const Color(0x22000066),
              ),
            ),
          ),
      ],
    );
  }
}

/// 자원 배지 위젯
class _ResourceBadge extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _ResourceBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x44000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(color: color.withAlpha(180), fontSize: 9),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 한(恨) 게이지 위젯
class _WailingGauge extends StatelessWidget {
  final double wailing;

  const _WailingGauge({required this.wailing});

  @override
  Widget build(BuildContext context) {
    final ratio = (wailing / 100).clamp(0.0, 1.0);
    final isMax = wailing >= 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isMax ? '😱 한(恨) 폭주!' : '😢 한(恨)',
              style: TextStyle(
                color: isMax ? const Color(0xFFFF4444) : const Color(0xFFAA88CC),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${wailing.toInt()}%',
              style: TextStyle(
                color: isMax ? const Color(0xFFFF4444) : Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: isMax
                      ? [const Color(0xFFFF0000), const Color(0xFFFF4444)]
                      : [const Color(0xFF6633AA), const Color(0xFFAA44FF)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
