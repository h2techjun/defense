// 해원의 문 - 영웅 스킬 패널 (인게임 UI)
// 영웅 초상화, HP 바, 스킬 쿨다운, 부활 타이머 표시

import 'package:flutter/material.dart';
import '../../common/responsive.dart';

/// 영웅 스킬 패널 데이터
class HeroSkillInfo {
  final String name;
  final String emoji;
  final String skillName;
  final double hpRatio; // 0~1
  final double cooldownRatio; // 0~1 (0=사용 가능)
  final bool isDead;
  final double reviveProgress; // 0~1 (부활 진행)
  final bool isUltimate; // 궁극기 사용 가능?
  final String reviveLabel; // 다중언어 부활 레이블
  final VoidCallback? onSkillTap;

  const HeroSkillInfo({
    required this.name,
    required this.emoji,
    required this.skillName,
    required this.hpRatio,
    required this.cooldownRatio,
    this.isDead = false,
    this.reviveProgress = 1,
    this.isUltimate = false,
    this.reviveLabel = '부활',
    this.onSkillTap,
  });
}

/// 영웅 스킬 패널 — 화면 우측 하단
class HeroSkillPanel extends StatelessWidget {
  final List<HeroSkillInfo> heroes;

  const HeroSkillPanel({super.key, required this.heroes});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: heroes.map((hero) => _HeroSkillButton(info: hero)).toList(),
    );
  }
}

class _HeroSkillButton extends StatelessWidget {
  final HeroSkillInfo info;

  const _HeroSkillButton({required this.info});

  @override
  Widget build(BuildContext context) {
    final isReady = info.cooldownRatio <= 0 && !info.isDead;

    return GestureDetector(
      onTap: isReady ? info.onSkillTap : null,
      child: Container(
        width: 80 * Responsive.scale(context),
        height: 86 * Responsive.scale(context),
        margin: EdgeInsets.only(bottom: 8 * Responsive.scale(context)),
        decoration: BoxDecoration(
          color: info.isDead
              ? const Color(0x88333333)
              : isReady
                  ? const Color(0xCC1A1A2E)
                  : const Color(0x88222233),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: info.isDead
                ? const Color(0xFF666666)
                : info.isUltimate
                    ? const Color(0xFFFFD700) // 궁극기 금테
                    : isReady
                        ? const Color(0xFF44AAFF)
                        : const Color(0xFF444466),
            width: info.isUltimate ? 2.5 : 1.5,
          ),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: info.isUltimate
                        ? const Color(0x44FFD700)
                        : const Color(0x2244AAFF),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // 쿨다운 오버레이
            if (!info.isDead && info.cooldownRatio > 0)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: info.cooldownRatio,
                      child: Container(
                        color: const Color(0x88000000),
                      ),
                    ),
                  ),
                ),
              ),

            // 부활 프로그레스
            if (info.isDead)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: info.reviveProgress,
                      child: Container(
                        color: const Color(0x44FFFFFF),
                      ),
                    ),
                  ),
                ),
              ),

            // 영웅 아이콘 + 스킬명
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    info.emoji,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 22),
                      color: info.isDead ? Colors.white30 : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    info.name,
                    style: TextStyle(
                      color: info.isDead ? Colors.white30 : Colors.white70,
                      fontSize: Responsive.fontSize(context, 8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // ⭐ 스킬명 표시
                  Container(
                    margin: EdgeInsets.only(top: 2 * Responsive.scale(context)),
                    padding: EdgeInsets.symmetric(horizontal: 4 * Responsive.scale(context), vertical: 1 * Responsive.scale(context)),
                    decoration: BoxDecoration(
                      color: isReady
                          ? const Color(0x3344AAFF)
                          : const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      info.skillName,
                      style: TextStyle(
                        color: isReady
                            ? const Color(0xFF88CCFF)
                            : Colors.white38,
                        fontSize: Responsive.fontSize(context, 7),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // HP 바
            if (!info.isDead)
              Positioned(
                bottom: 2 * Responsive.scale(context),
                left: 4 * Responsive.scale(context),
                right: 4 * Responsive.scale(context),
                child: Container(
                  height: 3 * Responsive.scale(context),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: info.hpRatio.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: info.hpRatio > 0.5
                            ? const Color(0xFF44FF44)
                            : info.hpRatio > 0.25
                                ? const Color(0xFFFFAA00)
                                : const Color(0xFFFF4444),
                      ),
                    ),
                  ),
                ),
              ),

            // 사망 표시
            if (info.isDead)
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Text(
                  '⏳ ${info.reviveLabel} ${(info.reviveProgress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: Responsive.fontSize(context, 8),
                  ),
                ),
              ),

            // 궁극기 별
            if (info.isUltimate)
              Positioned(
                top: 2,
                right: 2,
                child: Text('⭐', style: TextStyle(fontSize: Responsive.fontSize(context, 10))),
              ),
          ],
        ),
      ),
    );
  }
}
