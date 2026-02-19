// 해원의 문 - 게임 결과 다이얼로그 (승리/패배)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../state/game_state.dart';

/// 승리 오버레이
class VictoryOverlay extends ConsumerWidget {
  final VoidCallback onMenu;
  final VoidCallback onReplay;
  final VoidCallback onNextStage;

  const VictoryOverlay({
    super.key,
    required this.onMenu,
    required this.onReplay,
    required this.onNextStage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final lang = ref.watch(gameLanguageProvider);

    return Container(
      color: const Color(0xBB000000),
      child: Center(
        child: Container(
          width: 360,
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
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFAA44)],
                ).createShader(bounds),
                child: Text(
                  AppStrings.get(lang, 'victory_title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.get(lang, 'victory_quote'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8866AA),
                  fontStyle: FontStyle.italic,
                ),
              ),

              // ── 별 평가 ──
              const SizedBox(height: 16),
              _StarRating(stars: state.starRating),
              const SizedBox(height: 16),

              // ── 통계 ──
              _StatRow(AppStrings.get(lang, 'stat_kills'), '${state.enemiesKilled}'),
              _StatRow(AppStrings.get(lang, 'stat_hp'), '${state.gatewayHp}/${state.maxGatewayHp}'),
              _StatRow(AppStrings.get(lang, 'stat_score'), '${state.score}'),
              const SizedBox(height: 24),

              // ── 3버튼 ──
              Row(
                children: [
                  // 나가기
                  Expanded(
                    child: _DialogButton(
                      label: AppStrings.get(lang, 'return_menu'),
                      icon: Icons.exit_to_app,
                      onTap: onMenu,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 다시 하기
                  Expanded(
                    child: _DialogButton(
                      label: AppStrings.get(lang, 'replay'),
                      icon: Icons.replay,
                      onTap: onReplay,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 다음 스테이지
                  Expanded(
                    child: _DialogButton(
                      label: AppStrings.get(lang, 'next_stage'),
                      icon: Icons.arrow_forward,
                      onTap: onNextStage,
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
    final lang = ref.watch(gameLanguageProvider);

    return Container(
      color: const Color(0xBB000000),
      child: Center(
        child: Container(
          width: 360,
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
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF4444), Color(0xFFFF8800)],
                ).createShader(bounds),
                child: Text(
                  AppStrings.get(lang, 'defeat_title'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.get(lang, 'defeat_quote'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF886666),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

              // ── 팁 ──
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x22FFAA00),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x44FFAA00)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.get(lang, 'defeat_tip'),
                        style: TextStyle(
                          color: Color(0xFFFFCC66),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 통계 ──
              _StatRow(AppStrings.get(lang, 'stat_kills'), '${state.enemiesKilled}'),
              _StatRow(AppStrings.get(lang, 'stat_wave'), '${state.currentWave}/${state.totalWaves}'),
              const SizedBox(height: 24),

              // ── 2버튼 ──
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: AppStrings.get(lang, 'return_menu'),
                      icon: Icons.exit_to_app,
                      onTap: onMenu,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _DialogButton(
                      label: AppStrings.get(lang, 'retry'),
                      icon: Icons.replay,
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

/// 별 평가 위젯 (순차 팝업 애니메이션)
class _StarRating extends StatefulWidget {
  final int stars;
  const _StarRating({required this.stars});

  @override
  State<_StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<_StarRating>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    _scaleAnims = _controllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();

    _opacityAnims = _controllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: const Interval(0, 0.4)),
      );
    }).toList();

    // 순차 시작 (0.4초 간격)
    for (int i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 400 + i * 400), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isEarned = i < widget.stars;
        if (!isEarned) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.star_outline_rounded,
              size: 36,
              color: const Color(0x44FFFFFF),
            ),
          );
        }
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: _opacityAnims[i].value,
                child: Transform.scale(
                  scale: _scaleAnims[i].value,
                  child: Icon(
                    Icons.star_rounded,
                    size: 44,
                    color: const Color(0xFFFFD700),
                    shadows: const [
                      Shadow(
                        color: Color(0x88FFD700),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
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
  final IconData? icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.icon,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16,
                color: isPrimary ? Colors.white : const Color(0xFFBB99DD)),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isPrimary ? Colors.white : const Color(0xFFBB99DD),
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
