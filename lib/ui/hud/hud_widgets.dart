// 해원의 문 - HUD 위젯 모음
// ResourceBadge, SoundToggleBtn, CurrentTimeBadge, ElapsedTimeBadge

import 'package:flutter/material.dart';


import '../../common/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/glass_panel.dart';

/// 자원 배지 위젯 (신명, 게이트웨이 HP, 웨이브 표시)
class HudResourceBadge extends StatelessWidget {
  final String icon;
  final String? label;
  final String value;
  final Color color;

  const HudResourceBadge({
    super.key,
    required this.icon,
    this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final isPhone = Responsive.deviceType(context) == DeviceType.phone;
    final hPad = isPhone ? 6.0 * s : 10.0 * s;

    return GlassPanel(
      borderRadius: 12 * s,
      blurAmount: 8,
      backgroundColor: Colors.black.withAlpha(60),
      borderColor: color.withAlpha(80),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4 * s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: (isPhone ? 13 : 16) * s)),
          SizedBox(width: (isPhone ? 2 : 4) * s),
          if (label != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label!,
                  style: TextStyle(color: color.withAlpha(180), fontSize: 9 * s),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14 * s,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: (isPhone ? 12 : 14) * s,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// SFX/BGM 토글 버튼 위젯
class HudSoundToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const HudSoundToggleBtn({
    super.key,
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: GlassPanel(
          borderRadius: 8 * Responsive.scale(context),
          blurAmount: 6,
          backgroundColor: active ? Colors.white.withAlpha(30) : AppColors.berserkRed.withAlpha(20),
          borderColor: active ? Colors.white.withAlpha(50) : AppColors.berserkRed.withAlpha(60),
          padding: EdgeInsets.all(6 * Responsive.scale(context)),
          child: Icon(
            icon,
            color: active ? Colors.white70 : AppColors.berserkRed.withAlpha(180),
            size: Responsive.iconSize(context, 20),
          ),
        ),
      ),
    );
  }
}

/// 현재 시각 표시 (매초 갱신)
class HudCurrentTimeBadge extends StatelessWidget {
  const HudCurrentTimeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        final isPm = now.hour >= 12;
        final h12 = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
        final timeStr =
            '${h12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
        final sc = Responsive.scale(context);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8 * sc, vertical: 4 * sc),
          decoration: BoxDecoration(
            color: const Color(0x44000000),
            borderRadius: BorderRadius.circular(10 * sc),
            border: Border.all(color: const Color(0x44FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🕐', style: TextStyle(fontSize: Responsive.fontSize(context, 12))),
              SizedBox(width: 4 * sc),
              Text(
                timeStr,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: Responsive.fontSize(context, 13),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 게임 경과 시간 표시
class HudElapsedTimeBadge extends StatelessWidget {
  final double elapsedSeconds;
  const HudElapsedTimeBadge({super.key, required this.elapsedSeconds});

  @override
  Widget build(BuildContext context) {
    final totalSec = elapsedSeconds.toInt();
    final min = (totalSec ~/ 60).toString().padLeft(2, '0');
    final sec = (totalSec % 60).toString().padLeft(2, '0');

    final sc = Responsive.scale(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * sc, vertical: 4 * sc),
      decoration: BoxDecoration(
        color: const Color(0x44000000),
        borderRadius: BorderRadius.circular(10 * sc),
        border: Border.all(color: AppColors.skyBlue.withAlpha(68)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⏱️', style: TextStyle(fontSize: Responsive.fontSize(context, 12))),
          SizedBox(width: 4 * sc),
          Text(
            '$min:$sec',
            style: TextStyle(
              color: AppColors.skyBlue,
              fontSize: Responsive.fontSize(context, 13),
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
