// 해원의 문 - 메인 메뉴 (다중언어 지원)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/sound_manager.dart';
import '../../common/responsive.dart';
import '../../l10n/app_strings.dart';

/// 메인 메뉴 화면
class MainMenu extends ConsumerWidget {
  final VoidCallback onStageSelect;
  final VoidCallback onHeroManage;
  final VoidCallback onTowerManage;
  final VoidCallback onSkinShop;
  final VoidCallback onEndlessTower;
  final VoidCallback onSeasonPass;
  final VoidCallback onAchievement;

  const MainMenu({super.key, required this.onStageSelect, required this.onHeroManage, required this.onTowerManage, required this.onSkinShop, required this.onEndlessTower, required this.onSeasonPass, required this.onAchievement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(gameLanguageProvider);

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                // 타이틀 장식
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context, 20)),
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
                  child: Text(
                    '門',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 64),
                      color: const Color(0xFFCC88FF),
                      fontWeight: FontWeight.w300,
                      shadows: const [
                        Shadow(
                          color: Color(0xFFAA44FF),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: Responsive.spacing(context, 32)),

                // 게임 타이틀
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFCC88FF), Color(0xFFFFAA44), Color(0xFFCC88FF)],
                  ).createShader(bounds),
                  child: Text(
                    AppStrings.get(lang, 'app_title'),
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 48),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: Responsive.spacing(context, 8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get(lang, 'app_subtitle'),
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    color: const Color(0xFF8866AA),
                    letterSpacing: Responsive.spacing(context, 6),
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
                  child: Text(
                    AppStrings.get(lang, 'app_tagline'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAA88CC),
                      letterSpacing: 2,
                    ),
                  ),
                ),

                SizedBox(height: Responsive.spacing(context, 60)),

                // 시작 버튼
                _MenuButton(
                  label: AppStrings.get(lang, 'menu_battle'),
                  onTap: onStageSelect,
                  isPrimary: true,
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: AppStrings.get(lang, 'menu_heroes'),
                  onTap: onHeroManage,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: AppStrings.get(lang, 'menu_towers'),
                  onTap: onTowerManage,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: AppStrings.get(lang, 'menu_lore'),
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: '🎨 스킨 상점',
                  onTap: onSkinShop,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: '🗼 무한의 탑',
                  onTap: onEndlessTower,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: '🌸 시즌 패스',
                  onTap: onSeasonPass,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: '🏆 업적 & 랭킹',
                  onTap: onAchievement,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  label: AppStrings.get(lang, 'menu_settings'),
                  onTap: () => _showSettingsDialog(context, ref),
                ),

                const SizedBox(height: 40),

                // 인용구
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    AppStrings.get(lang, 'menu_quote'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF665588),
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ),

                // 현재 언어 표시
                const SizedBox(height: 16),
                Text(
                  '${lang.flag} ${lang.displayName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF554477),
                  ),
                ),
              ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 설정 다이얼로그 (언어 선택 포함)
  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _SettingsDialog(ref: ref),
    );
  }
}

/// 설정 다이얼로그
class _SettingsDialog extends StatefulWidget {
  final WidgetRef ref;
  const _SettingsDialog({required this.ref});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late double _sfxVol;
  late double _bgmVol;
  late bool _sfxOn;
  late bool _bgmOn;

  @override
  void initState() {
    super.initState();
    final sm = SoundManager.instance;
    _sfxVol = sm.sfxVolume;
    _bgmVol = sm.bgmVolume;
    _sfxOn = sm.sfxEnabled;
    _bgmOn = sm.bgmEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = widget.ref.read(gameLanguageProvider);
    return Dialog(
      backgroundColor: const Color(0xFF1A0F29),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF6633AA)),
      ),
      child: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x33CC88FF))),
                ),
                child: Row(
                  children: [
                    const Text('⚙️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.get(currentLang, 'menu_settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 언어 선택 (드롭다운) ──
                    _sectionLabel('🌐', AppStrings.get(currentLang, 'settings_language')),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x22FFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x44CC88FF)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<GameLanguage>(
                          value: currentLang,
                          dropdownColor: const Color(0xFF1A0F29),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFCC88FF)),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: GameLanguage.values.map((lang) {
                            return DropdownMenuItem<GameLanguage>(
                              value: lang,
                              child: Text(
                                '${lang.flag}  ${lang.displayName}',
                                style: TextStyle(
                                  color: lang == currentLang ? const Color(0xFFCC88FF) : Colors.white70,
                                  fontWeight: lang == currentLang ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (lang) {
                            if (lang != null) {
                              widget.ref.read(gameLanguageProvider.notifier).state = lang;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 효과음 (SFX) ──
                    _sectionLabel('🔊', '효과음 (SFX)'),
                    const SizedBox(height: 8),
                    _audioRow(
                      enabled: _sfxOn,
                      volume: _sfxVol,
                      onToggle: () {
                        setState(() { _sfxOn = !_sfxOn; });
                        SoundManager.instance.toggleSfx();
                      },
                      onChanged: (val) {
                        setState(() { _sfxVol = val; });
                        SoundManager.instance.setSfxVolume(val);
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── 배경음악 (BGM) ──
                    _sectionLabel('🎵', '배경음악 (BGM)'),
                    const SizedBox(height: 8),
                    _audioRow(
                      enabled: _bgmOn,
                      volume: _bgmVol,
                      onToggle: () {
                        setState(() { _bgmOn = !_bgmOn; });
                        SoundManager.instance.toggleBgm();
                      },
                      onChanged: (val) {
                        setState(() { _bgmVol = val; });
                        SoundManager.instance.setBgmVolume(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String icon, String label) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _audioRow({
    required bool enabled,
    required double volume,
    required VoidCallback onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        // 켜기/끄기 버튼
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: enabled ? const Color(0x44CC88FF) : const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: enabled ? const Color(0xFFCC88FF) : const Color(0x33FFFFFF)),
            ),
            child: Center(
              child: Icon(
                enabled ? Icons.volume_up : Icons.volume_off,
                color: enabled ? const Color(0xFFCC88FF) : Colors.white38,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 볼륨 슬라이더
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: enabled ? const Color(0xFFCC88FF) : Colors.white24,
              inactiveTrackColor: const Color(0x22FFFFFF),
              thumbColor: enabled ? const Color(0xFFCC88FF) : Colors.white38,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        // 퍼센트
        SizedBox(
          width: 36,
          child: Text(
            '${(volume * 100).toInt()}%',
            style: TextStyle(
              color: enabled ? Colors.white70 : Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
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
    final s = Responsive.scale(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 260 * s,
        padding: EdgeInsets.symmetric(vertical: 14 * s),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF6633AA), Color(0xFF9944CC)],
                )
              : null,
          color: isPrimary ? null : const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(16 * s),
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
            fontSize: 16 * s,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 2 * s,
          ),
        ),
      ),
    );
  }
}
