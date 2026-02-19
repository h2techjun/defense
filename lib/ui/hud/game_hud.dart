// 해원의 문 - 게임 HUD (인게임 UI 오버레이)

import 'package:flutter/material.dart';
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
                    color: const Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 16),

                  // 게이트웨이 HP
                  _ResourceBadge(
                    icon: '🏛️',
                    label: AppStrings.get(lang, 'hud_gateway'),
                    value: '${state.gatewayHp}/${state.maxGatewayHp}',
                    color: state.gatewayHp > state.maxGatewayHp * 0.5
                        ? const Color(0xFF44FF44)
                        : const Color(0xFFFF4444),
                  ),
                  const SizedBox(width: 16),

                  // 웨이브
                  _ResourceBadge(
                    icon: '🌊',
                    label: AppStrings.get(lang, 'wave'),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.dayCycle == DayCycle.day ? '해' : '달',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.dayCycle == DayCycle.day
                              ? AppStrings.get(lang, 'hud_day')
                              : AppStrings.get(lang, 'hud_night'),
                          style: TextStyle(
                            color: state.dayCycle == DayCycle.day
                                ? const Color(0xFFFFDD66)
                                : const Color(0xFFAAAAFF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 현재 시각
                  _CurrentTimeBadge(),
                  const SizedBox(width: 12),

                  // 게임 경과 시간
                  _ElapsedTimeBadge(elapsedSeconds: state.elapsedSeconds),
                  const SizedBox(width: 12),

                  // 처치 수
                  Text(
                    '💀 ${state.enemiesKilled}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 배속 버튼
                  GestureDetector(
                    onTap: onSpeedToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: state.gameSpeed > 1.0
                            ? const Color(0x44FF8800)
                            : const Color(0x44FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.gameSpeed > 1.0
                              ? const Color(0xFFFF8800)
                              : const Color(0x66FFFFFF),
                        ),
                      ),
                      child: Text(
                        '${state.gameSpeed.toInt()}×',
                        style: TextStyle(
                          color: state.gameSpeed > 1.0
                              ? const Color(0xFFFF8800)
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

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
                  const SizedBox(width: 2),

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
                  const SizedBox(width: 2),

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
    final s = Responsive.scale(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: const Color(0x44000000),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: color.withAlpha(100)),
      ),
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
      labelColor = const Color(0xFFAA88CC);
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
                      : isHigh
                          ? [const Color(0xFFFF6600), const Color(0xFFFF8844)]
                          : isMid
                              ? [const Color(0xFFCC8800), const Color(0xFFFFAA44)]
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
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active ? const Color(0x44FFFFFF) : const Color(0x22FF4444),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? const Color(0x66FFFFFF) : const Color(0x66FF4444),
            ),
          ),
          child: Icon(
            icon,
            color: active ? Colors.white70 : const Color(0xFFFF6666),
            size: 20,
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x44000000),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x44FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🕐', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x44000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4488CCFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⏱️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$min:$sec',
            style: const TextStyle(
              color: Color(0xFF88CCFF),
              fontSize: 13,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC1A0A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLowHp ? const Color(0xFFFF4444) : const Color(0xFFFFD700),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLowHp ? const Color(0xFFFF4444) : const Color(0xFFFFD700))
                .withAlpha(60),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 보스 이름
          Text(
            '👹 $name',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Color(0xFF000000), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 체력 바
          SizedBox(
            height: 12,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      shadows: [
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 160),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
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
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 4),
              Text(
                '다음 웨이브 $nextWaveNum',
                style: TextStyle(
                  color: isBoss ? const Color(0xFFFF6666) : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 적 목록
          ...parsed.map((entry) {
            final name = _enemyNames[entry.key] ?? entry.key;
            final icon = _enemyIcons[entry.key] ?? '👾';
            final isBossEnemy = entry.key.toLowerCase().contains('boss');
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '$name ×${entry.value}',
                      style: TextStyle(
                        color: isBossEnemy
                            ? const Color(0xFFFF8888)
                            : Colors.white60,
                        fontSize: 10,
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
