// 해원의 문 - 게임 내 호버 툴팁 위젯
// 마우스를 올리면 타워/적/영웅 정보를 표시합니다.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/glass_panel.dart';

/// 툴팁 데이터 모델
class GameTooltipData {
  final String title;
  final String? subtitle;
  final String? description;
  final Color color;
  final String? icon;
  final List<TooltipStat> stats;

  const GameTooltipData({
    required this.title,
    this.subtitle,
    this.description,
    this.color = AppColors.textSecondary,
    this.icon,
    this.stats = const [],
  });
}

/// 툴팁 스탯 행
class TooltipStat {
  final String label;
  final String value;
  final bool highlight;

  const TooltipStat(this.label, this.value, {this.highlight = false});
}

/// 플로팅 게임 툴팁 위젯
class GameTooltip extends StatelessWidget {
  final GameTooltipData data;
  final Offset position;

  const GameTooltip({
    super.key,
    required this.data,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // 툴팁 위치 계산 (화면 밖으로 나가지 않게)
    const tooltipWidth = 220.0;
    const tooltipHeight = 180.0;
    
    double left = position.dx + 16;
    double top = position.dy - 8;
    
    // 오른쪽 경계
    if (left + tooltipWidth > screenSize.width - 8) {
      left = position.dx - tooltipWidth - 16;
    }
    // 하단 경계
    if (top + tooltipHeight > screenSize.height - 8) {
      top = screenSize.height - tooltipHeight - 8;
    }
    // 상단 경계
    if (top < 8) top = 8;

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: 1.0,
          child: GlassPanel(
            borderRadius: 10,
            blurAmount: 12,
            backgroundColor: AppColors.surfaceDark.withAlpha(200),
            borderColor: data.color.withAlpha(120),
            borderWidth: 1.2,
            padding: const EdgeInsets.all(10),
            boxShadow: [
              BoxShadow(
                color: data.color.withAlpha(30),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 8,
              ),
            ],
            child: SizedBox(
              width: tooltipWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더: 아이콘 + 타이틀
                Row(
                  children: [
                    if (data.icon != null) ...[
                      Text(data.icon!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        data.title,
                        style: TextStyle(
                          color: data.color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // 서브타이틀
                if (data.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
                // 스탯
                if (data.stats.isNotEmpty) ...[
                  const Divider(color: AppColors.borderDefault, height: 10),
                  ...data.stats.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.label,
                          style: TextStyle(
                            color: s.highlight 
                              ? AppColors.sinmyeongGold
                              : AppColors.textDisabled,
                            fontSize: 10,
                          ),
                        ),
                        Text(s.value,
                          style: TextStyle(
                            color: s.highlight 
                              ? AppColors.sinmyeongGold 
                              : Colors.white,
                            fontSize: 10,
                            fontWeight: s.highlight 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                // 설명
                if (data.description != null) ...[
                  const Divider(color: AppColors.borderDefault, height: 10),
                  Text(
                    data.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
            ),
        ),
      ),
    );
  }
}
