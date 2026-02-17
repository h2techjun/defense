// 해원의 문 - 메인 메뉴

import 'package:flutter/material.dart';

/// 메인 메뉴 화면
class MainMenu extends StatelessWidget {
  final VoidCallback onStartGame;

  const MainMenu({super.key, required this.onStartGame});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0221),
              Color(0xFF1A0F29),
              Color(0xFF2D1B4E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 타이틀 장식
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6633AA),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44AA44FF),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Text(
                    '門',
                    style: TextStyle(
                      fontSize: 64,
                      color: Color(0xFFCC88FF),
                      fontWeight: FontWeight.w300,
                      shadows: [
                        Shadow(
                          color: Color(0xFFAA44FF),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 게임 타이틀
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFCC88FF), Color(0xFFFFAA44), Color(0xFFCC88FF)],
                  ).createShader(bounds),
                  child: const Text(
                    '해원의 문',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'GATEWAY OF REGRETS',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8866AA),
                    letterSpacing: 6,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 12),

                // 부제
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x33CC88FF)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '한국 설화 기반 타워 디펜스 RPG',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAA88CC),
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // 시작 버튼
                _MenuButton(
                  label: '⚔️  전투 시작',
                  onTap: onStartGame,
                  isPrimary: true,
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: '👥  수호자 (영웅)',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: '📖  설화 도감',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: '⚙️  설정',
                  onTap: () {},
                ),

                const SizedBox(height: 40),

                // 인용구
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '"원한이 깊으면 귀신이 되고,\n한을 풀어주면 꽃이 핀다."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF665588),
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 메뉴 버튼
class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _MenuButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF6633AA), Color(0xFF9944CC)],
                )
              : null,
          color: isPrimary ? null : const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFFAA66DD)
                : const Color(0x44FFFFFF),
          ),
          boxShadow: isPrimary
              ? const [
                  BoxShadow(
                    color: Color(0x44AA44FF),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isPrimary ? Colors.white : const Color(0xFFBB99DD),
            fontSize: 16,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
