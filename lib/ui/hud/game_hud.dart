// 해원의 문 - 게임 HUD (인게임 UI 오버레이)

import '../theme/glass_panel.dart';
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

  const GameHud({super.key, this.onPause, this.onNextWave, this.onSpeedToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final lang = ref.watch(gameLanguageProvider);
    final s = Responsive.scale(context);

    return Stack(
      children: [
        // ── 상단 바 ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
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
                    label: AppStrings.get(lang, 'gold'),
                    value: state.sinmyeong.toString(),
                    color: AppColors.sinmyeongGold,
                  ),
                  SizedBox(width: 16 * s),

                  // 게이트웨이 HP
                  _ResourceBadge(
                    icon: '🏛️',
                    label: AppStrings.get(lang, 'hud_gateway'),
                    value: '${state.gatewayHp}/${state.maxGatewayHp}',
                    color: state.gatewayHp > state.maxGatewayHp * 0.5
                        ? AppColors.mintGreen
                        : AppColors.berserkRed,
                  ),
                  SizedBox(width: 16 * s),

                  // 웨이브
                  _ResourceBadge(
                    icon: '🌊',
                    label: AppStrings.get(lang, 'wave'),
                    value: '${state.currentWave}/${state.totalWaves}',
                    color: AppColors.skyBlue,
                  ),
                  SizedBox(width: 16 * s),

                  // 낮/밤
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.dayCycle == DayCycle.day ? '해' : '달',
                          style: TextStyle(fontSize: Responsive.fontSize(context, 14)),
                        ),
                        SizedBox(width: 4 * s),
                        Text(
                          state.dayCycle == DayCycle.day
                              ? AppStrings.get(lang, 'hud_day')
                              : AppStrings.get(lang, 'hud_night'),
                          style: TextStyle(
                            color: state.dayCycle == DayCycle.day
                                ? const Color(0xFFFFDD66)
                                : const Color(0xFFAAAAFF),
                            fontSize: Responsive.fontSize(context, 14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 현재 시각
                  _CurrentTimeBadge(),
                  SizedBox(width: 12 * s),

                  // 게임 경과 시간
                  _ElapsedTimeBadge(elapsedSeconds: state.elapsedSeconds),
                  SizedBox(width: 12 * s),

                  // 처치 수
                  Text(
                    '💀 ${state.enemiesKilled}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: Responsive.fontSize(context, 13),
                    ),
                  ),
                  SizedBox(width: 8 * s),

                  // 배속 버튼
                  GestureDetector(
                    onTap: onSpeedToggle,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
                      decoration: BoxDecoration(
                        color: state.gameSpeed > 1.0
                            ? AppColors.peachCoral.withAlpha(60)
                            : const Color(0x44FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.gameSpeed > 1.0
                              ? AppColors.peachCoral
                              : const Color(0x66FFFFFF),
                        ),
                      ),
                      child: Text(
                        '${state.gameSpeed.toInt()}×',
                        style: TextStyle(
                          color: state.gameSpeed > 1.0
                              ? AppColors.peachCoral
                              : Colors.white70,
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4 * s),

                  // SFX 토글
                  _SoundToggleBtn(
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

                  // BGM 토글
                  _SoundToggleBtn(
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
                  SizedBox(width: 2 * s),

                  // 일시정지 버튼
                  IconButton(
                    onPressed: onPause,
                    icon: Icon(Icons.pause_circle_outline,
                        color: Colors.white70, size: Responsive.iconSize(context, 28)),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── 한(恨) 게이지 바 ──
        Positioned(
          top: 65 * s,
          left: 16 * s,
          right: 200 * s,
          child: _WailingGauge(wailing: state.wailing),
        ),

        // ── 보스 체력바 ──
        if (state.bossName != null && state.bossMaxHp > 0)
          Positioned(
            top: 90 * s,
            left: 40 * s,
            right: 40 * s,
            child: _BossHealthBar(
              name: state.bossName!,
              hp: state.bossHp,
              maxHp: state.bossMaxHp,
            ),
          ),

        // ── 다음 웨이브 미리보기 ──
        if (state.nextWaveEnemyIds.isNotEmpty)
          Positioned(
            top: 90 * s,
            right: 16 * s,
            child: _NextWavePreview(
              enemyEntries: state.nextWaveEnemyIds,
              isBoss: state.nextWaveIsBoss,
              nextWaveNum: state.currentWave + 1,
            ),
          ),

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
              child: _WailingWarningOverlay(wailing: state.wailing),
            ),
          ),
      ],
    );
  }
}

/// 곡소리(Wailing) 위험 상태일 때 화면 외곽이 불길하게 깜박이는 효과
class _WailingWarningOverlay extends StatefulWidget {
  final double wailing;
  const _WailingWarningOverlay({required this.wailing});

  @override
  State<_WailingWarningOverlay> createState() => _WailingWarningOverlayState();
}

class _WailingWarningOverlayState extends State<_WailingWarningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _playedMaxSound = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _WailingWarningOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // wailing이 100을 돌파하는 순간 1회 타격음 등 재생
    if (widget.wailing >= 100 && oldWidget.wailing < 100 && !_playedMaxSound) {
      _playedMaxSound = true;
      // 으스스한 효과음 재생 필요 시 SoundManager 사용 (여기선 디폴트 괴물/공격음 사용해 위험 알림 기능)
      SoundManager.instance.playSfx(SfxType.enemyBoss);
    } else if (widget.wailing < 100) {
      _playedMaxSound = false;
    }
    
    // 게이지에 따라 깜박임 속도 변화 (100이면 매우 빠름)
    if (widget.wailing >= 100) {
      _controller.duration = const Duration(milliseconds: 400);
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.duration = const Duration(milliseconds: 1200);
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 알파값 (Max 100%일 때는 더 강하게 빨갛게 빛남)
        final maxAlpha = widget.wailing >= 100 ? 100 : 50;
        final baseColor = widget.wailing >= 100 ? AppColors.berserkRed : const Color(0xFF660000);
        final opacity = _controller.value * maxAlpha;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: baseColor.withAlpha(opacity.toInt() + 10),
              width: 4.0 * Responsive.scale(context),
            ),
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                baseColor.withAlpha((opacity * 0.5).toInt()),
              ],
              radius: 1.5,
              stops: const [0.8, 1.0],
            ),
          ),
        );
      },
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
    final s = Responsive.scale(context);

    return GlassPanel(
      borderRadius: 12 * s,
      blurAmount: 8,
      backgroundColor: Colors.black.withAlpha(60),
      borderColor: color.withAlpha(80),
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 16 * s)),
          SizedBox(width: 4 * s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
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
    final isHigh = wailing >= 80;
    final isMid = wailing >= 50;

    // 단계별 레이블/색상
    String label;
    Color labelColor;
    if (isMax) {
      label = '😱 한(恨) 폭주!';
      labelColor = const Color(0xFFFF4444);
    } else if (isHigh) {
      label = '😨 한(恨) 위험!';
      labelColor = const Color(0xFFFF8844);
    } else if (isMid) {
      label = '😟 한(恨) 주의';
      labelColor = const Color(0xFFFFAA44);
    } else {
      label = '😢 한(恨)';
      labelColor = AppColors.cherryBlossom.withAlpha(200);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
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

/// SFX/BGM 토글 버튼 위젯
class _SoundToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _SoundToggleBtn({
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
class _CurrentTimeBadge extends StatelessWidget {
  const _CurrentTimeBadge();

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
class _ElapsedTimeBadge extends StatelessWidget {
  final double elapsedSeconds;
  const _ElapsedTimeBadge({required this.elapsedSeconds});

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

/// 보스 체력바 위젯 (화면 상단 중앙)
class _BossHealthBar extends StatelessWidget {
  final String name;
  final double hp;
  final double maxHp;

  const _BossHealthBar({
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
          // 보스 이름
          Text(
            '👹 $name',
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
          // 체력 바
          SizedBox(
            height: 12 * sc,
            child: Stack(
              children: [
                // 배경
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // HP 바
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
                // HP 수치 텍스트
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
class _NextWavePreview extends StatelessWidget {
  final List<String> enemyEntries; // "enemyId:count" 형식
  final bool isBoss;
  final int nextWaveNum;

  // 적 ID → 한글 이름 매핑
  static const Map<String, String> _enemyNames = {
    'hungryGhost': '아귀',
    'strawShoeSpirit': '짚신귀신',
    'burdenedLaborer': '짐꾼귀신',
    'maidenGhost': '손각시',
    'eggGhost': '달걀귀신',
    'bossOgreLord': '두억시니',
    'tigerSlave': '창귀',
    'fireDog': '불개',
    'shadowGolem': '석상귀',
    'oldFoxWoman': '구미호',
    'failedDragon': '이무기',
    'bossMountainLord': '산신령',
    'changGwiEvolved': '대창귀',
    'saetani': '새타니',
    'shadowChild': '그림자아이',
    'maliciousBird': '태자귀',
    'faceStealerGhost': '무면귀',
    'bossGreatEggGhost': '대왕달걀귀신',
  };

  // 적 ID → 이모지 매핑
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
  };

  const _NextWavePreview({
    required this.enemyEntries,
    required this.isBoss,
    required this.nextWaveNum,
  });

  @override
  Widget build(BuildContext context) {
    // "enemyId:count" 파싱
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
      constraints: BoxConstraints(maxWidth: 160 * sc),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8 * sc),
        border: Border.all(color: borderColor, width: isBoss ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBoss ? '⚠️' : '📋',
                style: TextStyle(fontSize: Responsive.fontSize(context, 10)),
              ),
              SizedBox(width: 4 * sc),
              Text(
                '다음 웨이브 $nextWaveNum',
                style: TextStyle(
                  color: isBoss ? const Color(0xFFFF6666) : Colors.white70,
                  fontSize: Responsive.fontSize(context, 10),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * sc),
          // 적 목록
          ...parsed.map((entry) {
            final name = _enemyNames[entry.key] ?? entry.key;
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
