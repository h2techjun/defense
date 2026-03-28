// 해원의 문 - HUD 오버레이 위젯 모음
// WailingGauge, WailingWarningOverlay, BossHealthBar, NextWavePreview

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/responsive.dart';
import '../../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// 한(恨) 게이지 위젯
class HudWailingGauge extends ConsumerWidget {
  final double wailing;

  const HudWailingGauge({super.key, required this.wailing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = (wailing / 100).clamp(0.0, 1.0);
    final isMax = wailing >= 100;
    final isHigh = wailing >= 80;
    final isMid = wailing >= 50;

    // 단계별 레이블/색상
    String label;
    Color labelColor;
    if (isMax) {
      label = 'hud_wailing_max';
      labelColor = const Color(0xFFFF4444);
    } else if (isHigh) {
      label = 'hud_wailing_high';
      labelColor = const Color(0xFFFF8844);
    } else if (isMid) {
      label = 'hud_wailing_mid';
      labelColor = const Color(0xFFFFAA44);
    } else {
      label = 'hud_wailing_low';
      labelColor = AppColors.cherryBlossom.withAlpha(200);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              tr(ref, label),
              style: TextStyle(
                color: labelColor,
                fontSize: Responsive.fontSize(context, 10),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4 * Responsive.scale(context)),
            Text(
              '${wailing.toInt()}%',
              style: TextStyle(
                color: isMax ? const Color(0xFFFF4444) : Colors.white60,
                fontSize: Responsive.fontSize(context, 10),
              ),
            ),
          ],
        ),
        SizedBox(height: 2 * Responsive.scale(context)),
        Container(
          height: 6 * Responsive.scale(context),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(3 * Responsive.scale(context)),
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
                      : isHigh
                          ? [const Color(0xFFFF6600), const Color(0xFFFF8844)]
                          : isMid
                              ? [const Color(0xFFCC8800), const Color(0xFFFFAA44)]
                              : [AppColors.cherryBlossom, AppColors.cherryBlossom.withAlpha(200)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 곡소리(Wailing) 위험 상태일 때 화면 외곽이 불길하게 깜박이는 효과
class HudWailingWarningOverlay extends StatefulWidget {
  final double wailing;
  const HudWailingWarningOverlay({super.key, required this.wailing});

  @override
  State<HudWailingWarningOverlay> createState() => _HudWailingWarningOverlayState();
}

class _HudWailingWarningOverlayState extends State<HudWailingWarningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ((widget.wailing - 80) / 20).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = (_controller.value * intensity * 40).toInt().clamp(0, 60);
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Color.fromARGB(alpha, 255, 0, 0),
              width: 3 * intensity + 1,
            ),
          ),
        );
      },
    );
  }
}

/// 보스 체력바 위젯 (화면 상단 중앙)
class HudBossHealthBar extends StatelessWidget {
  final String name;
  final double hp;
  final double maxHp;

  const HudBossHealthBar({
    super.key,
    required this.name,
    required this.hp,
    required this.maxHp,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (hp / maxHp).clamp(0.0, 1.0);
    final isLowHp = ratio < 0.3;

    final sc = Responsive.scale(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * sc, vertical: 6 * sc),
      decoration: BoxDecoration(
        color: const Color(0xCC1A0A2E),
        borderRadius: BorderRadius.circular(8 * sc),
        border: Border.all(
          color: isLowHp ? AppColors.berserkRed : AppColors.sinmyeongGold,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLowHp ? AppColors.berserkRed : AppColors.sinmyeongGold)
                .withAlpha(60),
            blurRadius: 8 * sc,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '👹 ${AppStrings.trs(name)}',
            style: TextStyle(
              color: AppColors.sinmyeongGold,
              fontSize: Responsive.fontSize(context, 13),
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(color: Color(0xFF000000), blurRadius: 4),
              ],
            ),
          ),
          SizedBox(height: 4 * sc),
          SizedBox(
            height: 12 * sc,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: isLowHp
                            ? [const Color(0xFFFF2222), const Color(0xFFCC0000)]
                            : [const Color(0xFFFF4444), const Color(0xFFDD2222)],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${hp.toInt()} / ${maxHp.toInt()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 9),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      shadows: const [
                        Shadow(color: Color(0xFF000000), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 다음 웨이브 적 미리보기 위젯
class HudNextWavePreview extends StatelessWidget {
  final List<String> enemyEntries;
  final bool isBoss;
  final int nextWaveNum;

  static const Map<String, String> _enemyNameKeys = {
    'hungryGhost': 'enemy_hungryGhost',
    'strawShoeSpirit': 'enemy_strawShoeSpirit',
    'burdenedLaborer': 'enemy_burdenedLaborer',
    'maidenGhost': 'enemy_maidenGhost',
    'eggGhost': 'enemy_eggGhost',
    'bossOgreLord': 'enemy_bossOgreLord',
    'tigerSlave': 'enemy_tigerSlave',
    'fireDog': 'enemy_fireDog',
    'shadowGolem': 'enemy_shadowGolem',
    'oldFoxWoman': 'enemy_oldFoxWoman',
    'failedDragon': 'enemy_failedDragon',
    'bossMountainLord': 'enemy_bossMountainLord',
    'changGwiEvolved': 'enemy_changGwiEvolved',
    'saetani': 'enemy_saetani',
    'shadowChild': 'enemy_shadowChild',
    'maliciousBird': 'enemy_maliciousBird',
    'faceStealerGhost': 'enemy_faceStealerGhost',
    'bossGreatEggGhost': 'enemy_bossGreatEggGhost',
    // Chapter 4 - Shadow Palace
    'courtAssassin': 'enemy_courtAssassin',
    'corruptOfficial': 'enemy_corruptOfficial',
    'royalGuardGhost': 'enemy_royalGuardGhost',
    'curseScribe': 'enemy_curseScribe',
    'puppetDancer': 'enemy_puppetDancer',
    'bossTyrantKing': 'enemy_bossTyrantKing',
    // Chapter 5 - Threshold of Death
    'underworldMessenger': 'enemy_underworldMessenger',
    'wailingBanshee': 'enemy_wailingBanshee',
    'boneGolem': 'enemy_boneGolem',
    'soulChainGhost': 'enemy_soulChainGhost',
    'infernoSpirit': 'enemy_infernoSpirit',
    'bossGatekeeper': 'enemy_bossGatekeeper',
  };


  static const Map<String, String> _enemyIcons = {
    'hungryGhost': '👻',
    'strawShoeSpirit': '👣',
    'burdenedLaborer': '🎒',
    'maidenGhost': '👩',
    'eggGhost': '🥚',
    'bossOgreLord': '👹',
    'tigerSlave': '🐯',
    'fireDog': '🔥',
    'shadowGolem': '🗿',
    'oldFoxWoman': '🦊',
    'failedDragon': '🐉',
    'bossMountainLord': '⛰️',
    'changGwiEvolved': '💀',
    'saetani': '🐦',
    'shadowChild': '👤',
    'maliciousBird': '🦅',
    'faceStealerGhost': '🎭',
    'bossGreatEggGhost': '🥚',
    // Chapter 4 - Shadow Palace
    'courtAssassin': '🗡️',
    'corruptOfficial': '💰',
    'royalGuardGhost': '🛡️',
    'curseScribe': '📜',
    'puppetDancer': '🪆',
    'bossTyrantKing': '👑',
    // Chapter 5 - Threshold of Death
    'underworldMessenger': '💀',
    'wailingBanshee': '😭',
    'boneGolem': '🦴',
    'soulChainGhost': '⛓️',
    'infernoSpirit': '🔥',
    'bossGatekeeper': '🚪',
  };

  const HudNextWavePreview({
    super.key,
    required this.enemyEntries,
    required this.isBoss,
    required this.nextWaveNum,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = <MapEntry<String, int>>[];
    for (final entry in enemyEntries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        parsed.add(MapEntry(parts[0], int.tryParse(parts[1]) ?? 0));
      }
    }

    final borderColor = isBoss
        ? const Color(0xFFFF4444)
        : const Color(0x66FFFFFF);
    final bgColor = isBoss
        ? const Color(0x66330000)
        : const Color(0x88000000);

    final sc = Responsive.scale(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * sc, vertical: 6 * sc),
      constraints: BoxConstraints(maxWidth: 200 * sc),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8 * sc),
        border: Border.all(color: borderColor, width: isBoss ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBoss ? '⚠️' : '📋',
                style: TextStyle(fontSize: Responsive.fontSize(context, 10)),
              ),
              SizedBox(width: 4 * sc),
              Text(
                AppStrings.trs('wave_next').replaceAll('{n}', '$nextWaveNum'),
                style: TextStyle(
                  color: isBoss ? const Color(0xFFFF6666) : Colors.white70,
                  fontSize: Responsive.fontSize(context, 10),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * sc),
          ...parsed.map((entry) {
            final nameKey = _enemyNameKeys[entry.key];
            final name = nameKey != null ? AppStrings.trs(nameKey) : entry.key;
            final icon = _enemyIcons[entry.key] ?? '👾';
            final isBossEnemy = entry.key.toLowerCase().contains('boss');
            return Padding(
              padding: EdgeInsets.only(bottom: 2 * sc),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: TextStyle(fontSize: Responsive.fontSize(context, 12))),
                  SizedBox(width: 4 * sc),
                  Flexible(
                    child: Text(
                      '$name ×${entry.value}',
                      style: TextStyle(
                        color: isBossEnemy
                            ? const Color(0xFFFF8888)
                            : Colors.white60,
                        fontSize: Responsive.fontSize(context, 10),
                        fontWeight: isBossEnemy
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
