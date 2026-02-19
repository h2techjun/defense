// 해원의 문 - 웨이브 안내 배너 (Wave Announcement Banner)
// 웨이브 시작 시 드라마틱한 안내 + 쿨다운 카운트다운

import 'dart:async';
import 'package:flutter/material.dart';

/// 웨이브 안내 배너 — HUD 위에 오버레이
class WaveAnnounceBanner extends StatefulWidget {
  final int waveNumber;
  final int totalWaves;
  final String? narrative;
  final bool isBossWave;

  const WaveAnnounceBanner({
    super.key,
    required this.waveNumber,
    required this.totalWaves,
    this.narrative,
    this.isBossWave = false,
  });

  @override
  State<WaveAnnounceBanner> createState() => _WaveAnnounceBannerState();
}

class _WaveAnnounceBannerState extends State<WaveAnnounceBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideIn;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideIn = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );

    _ctrl.forward();

    // 3초 후 자동 페이드 아웃
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBoss = widget.isBossWave;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _slideIn.value),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(top: 100),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isBoss
                  ? [const Color(0xDD8B0000), const Color(0xDDFF2200)]
                  : [const Color(0xDD1A0A30), const Color(0xDD2D1B69)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBoss
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF8B5CF6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isBoss
                    ? const Color(0x88FF0000)
                    : const Color(0x888B5CF6),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 웨이브 번호
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBoss) ...[
                    const Text('💀 ', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isBoss
                        ? '보스 웨이브!'
                        : '웨이브 ${widget.waveNumber}',
                    style: TextStyle(
                      color: isBoss
                          ? const Color(0xFFFF6644)
                          : const Color(0xFFE0D0FF),
                      fontSize: isBoss ? 28 : 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: isBoss
                              ? const Color(0xFFFF0000)
                              : const Color(0xFF8B5CF6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  if (isBoss) ...[
                    const SizedBox(width: 8),
                    const Text(' 💀', style: TextStyle(fontSize: 24)),
                  ],
                ],
              ),
              // 진행율
              if (!isBoss) ...[
                const SizedBox(height: 4),
                Text(
                  '${widget.waveNumber} / ${widget.totalWaves}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              // 내러티브
              if (widget.narrative != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.narrative!,
                  style: TextStyle(
                    color: isBoss
                        ? const Color(0xFFFFAAAA)
                        : const Color(0xFFB8A0DD),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 웨이브 쿨다운 카운트다운 위젯
class WaveCooldownIndicator extends StatelessWidget {
  final double secondsRemaining;
  final int nextWaveNumber;

  const WaveCooldownIndicator({
    super.key,
    required this.secondsRemaining,
    required this.nextWaveNumber,
  });

  @override
  Widget build(BuildContext context) {
    final seconds = secondsRemaining.ceil();
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 100),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xCC1A0A30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF6B4FB0),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x448B5CF6),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '다음 웨이브 $nextWaveNumber',
              style: const TextStyle(
                color: Color(0xFFB8A0DD),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$seconds',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 36,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0xFFFFD700), blurRadius: 20),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '타워를 배치하세요!',
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
