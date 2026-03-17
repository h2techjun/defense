// 해원의 문 - 게임 HUD (인게임 UI 오버레이)


import 'hud_widgets.dart';
import 'hud_overlays.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../l10n/app_strings.dart';
import '../../state/game_state.dart';
import '../../audio/sound_manager.dart';

/// 인게임 HUD - 자원, 한 게이지, 웨이브 정보 표시
class GameHud extends ConsumerWidget {
  final VoidCallback? onPause;
  final VoidCallback? onNextWave;
  final VoidCallback? onSpeedToggle;
  final bool isSpeedLocked; // 2배속 잠금 여부
  final double horizontalPadding; // 좌우 광고 여백 (AdSideBanners 대응)

  const GameHud({super.key, this.onPause, this.onNextWave, this.onSpeedToggle, this.isSpeedLocked = false, this.horizontalPadding = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final lang = ref.watch(gameLanguageProvider);
    final s = Responsive.uiScale(context);
    final isPhone = Responsive.deviceType(context) == DeviceType.phone;
    final gap = isPhone ? 6.0 * s : 16.0 * s;
    final smallGap = isPhone ? 4.0 * s : 8.0 * s;

    // IgnorePointer(absorbing: false) isn't strictly necessary for a Stack if it doesn't have an opaque background, but
    // to guarantee taps fall through to the Flame game beneath, we ensure the parent doesn't absorb touches in empty areas.
    return Stack(
      // hitTestBehavior: HitTestBehavior.deferToChild 로 설정하면 빈 공간의 터치를 무시하고 아래로 전달합니다.
      clipBehavior: Clip.none,
      children: [
        // ── 상단 바 ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Stack(
            children: [
              // 배경 그라데이션 (터치 통과)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xCC000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
              // 인터랙티브 HUD 요소 (터치 가능)
              Container(
                padding: EdgeInsets.symmetric(horizontal: (isPhone ? 6 * s : 16 * s) + horizontalPadding, vertical: isPhone ? 4 * s : 8 * s),
                child: SafeArea(
                  child: Row(
                    children: [
                      // 신명 (자원)
                      HudResourceBadge(
                        icon: '✨',
                        label: isPhone ? null : AppStrings.get(lang, 'gold'),
                        value: state.sinmyeong.toString(),
                        color: AppColors.sinmyeongGold,
                      ),
                    SizedBox(width: gap),

                    // 게이트웨이 HP
                    HudResourceBadge(
                      icon: '🏛️',
                      label: isPhone ? null : AppStrings.get(lang, 'hud_gateway'),
                      value: '${state.gatewayHp}/${state.maxGatewayHp}',
                      color: state.gatewayHp > state.maxGatewayHp * 0.5
                          ? AppColors.mintGreen
                          : AppColors.berserkRed,
                    ),
                    SizedBox(width: gap),

                    // 웨이브
                    HudResourceBadge(
                      icon: '🌊',
                      label: isPhone ? null : AppStrings.get(lang, 'wave'),
                      value: '${state.currentWave}/${state.totalWaves}',
                      color: AppColors.skyBlue,
                    ),
                    SizedBox(width: gap),

                    // 낮/밤
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 * s : 10 * s, vertical: 4 * s),
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
                        state.dayCycle == DayCycle.day ? '☀️' : '🌙',
                        style: TextStyle(fontSize: Responsive.fontSize(context, isPhone ? 12 : 14)),
                      ),
                    ),

                    const Spacer(),

                    // 현재 시각 (폰에서 숨김)
                    if (!isPhone) ...[
                      HudCurrentTimeBadge(),
                      SizedBox(width: 12 * s),
                    ],

                    // 게임 경과 시간 (폰에서 숨김)
                    if (!isPhone) ...[
                      HudElapsedTimeBadge(elapsedSeconds: state.elapsedSeconds),
                      SizedBox(width: 12 * s),
                    ],

                    // 처치 수
                    Text(
                      '💀 ${state.enemiesKilled}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: Responsive.fontSize(context, isPhone ? 11 : 13),
                      ),
                    ),
                    SizedBox(width: isPhone ? 4 * s : 8 * s),

                    // 배속 버튼
                    GestureDetector(
                      onTap: isSpeedLocked ? null : onSpeedToggle,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 * s : 10 * s, vertical: isPhone ? 4 * s : 6 * s),
                        decoration: BoxDecoration(
                          color: isSpeedLocked
                              ? const Color(0x33FFFFFF)
                              : state.gameSpeed > 1.0
                                  ? AppColors.peachCoral.withAlpha(60)
                                  : const Color(0x44FFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSpeedLocked
                                ? const Color(0x44FFFFFF)
                                : state.gameSpeed > 1.0
                                    ? AppColors.peachCoral
                                    : const Color(0x66FFFFFF),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSpeedLocked)
                              Icon(Icons.lock, color: Colors.white38, size: Responsive.fontSize(context, isPhone ? 10 : 12)),
                            if (isSpeedLocked) SizedBox(width: 2 * s),
                            Text(
                              isSpeedLocked ? '2×' : '${state.gameSpeed.toInt()}×',
                              style: TextStyle(
                                color: isSpeedLocked
                                    ? Colors.white38
                                    : state.gameSpeed > 1.0
                                        ? AppColors.peachCoral
                                        : Colors.white70,
                                fontSize: Responsive.fontSize(context, isPhone ? 12 : 14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // SFX/BGM 토글 (폰에서 숨김 — 일시정지 메뉴에서 접근)
                    if (!isPhone) ...[
                      SizedBox(width: 4 * s),
                      HudSoundToggleBtn(
                        icon: SoundManager.instance.sfxEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        active: SoundManager.instance.sfxEnabled,
                        tooltip: 'SFX',
                        onTap: () {
                          SoundManager.instance.toggleSfx();
                          SoundManager.instance.playSfx(SfxType.uiClick);
                          (context as Element).markNeedsBuild();
                        },
                      ),
                      SizedBox(width: 2 * s),
                      HudSoundToggleBtn(
                        icon: SoundManager.instance.bgmEnabled
                            ? Icons.music_note
                            : Icons.music_off,
                        active: SoundManager.instance.bgmEnabled,
                        tooltip: 'BGM',
                        onTap: () {
                          SoundManager.instance.toggleBgm();
                          (context as Element).markNeedsBuild();
                        },
                      ),
                    ],
                    SizedBox(width: 2 * s),

                    // 일시정지 버튼
                    IconButton(
                      onPressed: onPause,
                      icon: Icon(Icons.pause_circle_outline,
                          color: Colors.white70, size: Responsive.iconSize(context, isPhone ? 24 : 28)),
                      padding: EdgeInsets.zero,
                      constraints: isPhone ? const BoxConstraints(minWidth: 32, minHeight: 32) : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
        
        // ── 한(恨) 게이지 바 ──
        Positioned(
          top: isPhone ? 48 * s : 65 * s,
          left: (isPhone ? 8 * s : 16 * s) + horizontalPadding,
          right: (isPhone ? 60 * s : 200 * s) + horizontalPadding,
          child: HudWailingGauge(wailing: state.wailing),
        ),

        // ── 보스 체력바 ──
        if (state.bossName != null && state.bossMaxHp > 0)
          Positioned(
            top: isPhone ? 70 * s : 90 * s,
            left: (isPhone ? 16 * s : 40 * s) + horizontalPadding,
            right: (isPhone ? 16 * s : 40 * s) + horizontalPadding,
            child: HudBossHealthBar(
              name: state.bossName!,
              hp: state.bossHp,
              maxHp: state.bossMaxHp,
            ),
          ),

        // (다음 웨이브 미리보기 → 중앙 배너로 이동됨)

        // ── 밤 오버레이 ──
        if (state.dayCycle == DayCycle.night)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000044),
                      Color(0x22000088),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
        // ── 곡소리(원혼) 위험 오버레이 ──
        if (state.wailing >= 80)
          Positioned.fill(
            child: IgnorePointer(
              child: HudWailingWarningOverlay(wailing: state.wailing),
            ),
          ),
      ],
    );
  }
}

// 하위 위젯들은 hud_widgets.dart와 hud_overlays.dart로 분리됨

// 하위 위젯들은 hud_widgets.dart와 hud_overlays.dart로 분리됨

