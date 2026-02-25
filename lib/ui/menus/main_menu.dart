// 해원의 문 - 메인 메뉴 (반응형 가로/세로 레이아웃)

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/sound_manager.dart';
import '../../common/responsive.dart';
import '../../l10n/app_strings.dart';
import '../../services/fullscreen_service.dart';
import '../../state/unclaimed_rewards_provider.dart';
import '../widgets/notification_badge.dart';

/// 메인 메뉴 화면
class MainMenu extends ConsumerWidget {
  final VoidCallback onStageSelect;
  final VoidCallback onHeroManage;
  final VoidCallback onTowerManage;
  final VoidCallback onSkinShop;
  final VoidCallback onPackageShop;
  final VoidCallback onEndlessTower;
  final VoidCallback onSeasonPass;
  final VoidCallback onAchievement;
  final VoidCallback onDailyQuest;
  final VoidCallback onLoreCollection;

  const MainMenu({super.key, required this.onStageSelect, required this.onHeroManage, required this.onTowerManage, required this.onSkinShop, required this.onPackageShop, required this.onEndlessTower, required this.onSeasonPass, required this.onAchievement, required this.onDailyQuest, required this.onLoreCollection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(gameLanguageProvider);
    final s = Responsive.scale(context);
    final isLand = Responsive.isLandscape(context);

    return Scaffold(
      // 웹 전용: 전체화면 토글 FAB
      floatingActionButton: kIsWeb ? _buildFullscreenFab(s) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffoldBg,
          image: DecorationImage(
            image: AssetImage('assets/images/bg/bg_main_menu.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isLand && constraints.maxWidth > 600) {
                // ── 가로 모드: 좌(타이틀) + 우(버튼) ──
                return Row(
                  children: [
                    // 왼쪽: 타이틀 영역
                    Expanded(
                      flex: 4,
                      child: _buildTitleSection(context, lang, s),
                    ),
                    // 오른쪽: 버튼 영역
                    Expanded(
                      flex: 5,
                      child: _buildButtonSection(context, ref, lang, s, isLandscape: true),
                    ),
                  ],
                );
              } else {
                // ── 세로 모드: 기존 레이아웃 (스크롤) ──
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
                        _buildTitleSection(context, lang, s),
                        SizedBox(height: 40 * s),
                        _buildButtonSection(context, ref, lang, s, isLandscape: false),
                        SizedBox(height: 24 * s),
                        _buildFooter(context, lang, s),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  /// 타이틀 섹션 (門 + 해원문 + 부제)
  Widget _buildTitleSection(BuildContext context, GameLanguage lang, double s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 門 장식
          Container(
            padding: EdgeInsets.all(20 * s),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cherryBlossom.withAlpha(180),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cherryBlossom.withAlpha(60),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Text(
              '門',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 64),
                color: AppColors.cherryBlossom,
                fontWeight: FontWeight.w300,
                shadows: [
                  Shadow(
                    color: AppColors.cherryBlossom.withAlpha(180),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 28 * s),

          // 게임 타이틀
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.cherryBlossom, AppColors.peachCoral, AppColors.cherryBlossom],
            ).createShader(bounds),
            child: Text(
              AppStrings.get(lang, 'app_title'),
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 48),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8 * s,
              ),
            ),
          ),
          SizedBox(height: 6 * s),
          Text(
            AppStrings.get(lang, 'app_subtitle'),
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 14),
              color: AppColors.cherryBlossom.withAlpha(140),
              letterSpacing: 6 * s,
              fontWeight: FontWeight.w300,
            ),
          ),

          SizedBox(height: 12 * s),

          // 부제
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 8 * s),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cherryBlossom.withAlpha(50)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppStrings.get(lang, 'app_tagline'),
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 12),
                color: AppColors.cherryBlossom.withAlpha(200),
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 버튼 섹션
  Widget _buildButtonSection(BuildContext context, WidgetRef ref, GameLanguage lang, double s, {required bool isLandscape}) {
    // 미수령 보상 체크
    final unclaimed = ref.watch(unclaimedRewardsProvider);

    final buttons = [
      _ButtonData(AppStrings.get(lang, 'menu_battle'), onStageSelect, true),
      _ButtonData(AppStrings.get(lang, 'menu_heroes'), onHeroManage, false),
      _ButtonData(AppStrings.get(lang, 'menu_towers'), onTowerManage, false),
      _ButtonData('📋 일일 미션', onDailyQuest, false, showBadge: unclaimed.hasDailyQuest),
      _ButtonData('📜 설화도감', onLoreCollection, false),
      _ButtonData('🎨 스킨 상점', onSkinShop, false),
      _ButtonData('💰 상점 패키지', onPackageShop, false),
      _ButtonData('🗼 무한의 탑', onEndlessTower, false),
      _ButtonData('🌸 시즌 패스', onSeasonPass, false, showBadge: unclaimed.hasSeasonPass),
      _ButtonData('🏆 업적 & 랭킹', onAchievement, false, showBadge: unclaimed.hasAchievements),
      _ButtonData(AppStrings.get(lang, 'menu_settings'), () => _showSettingsDialog(context, ref), false),
    ];

    if (isLandscape) {
      // 가로 모드: 스크롤 가능한 2열 그리드
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16 * s, horizontal: 20 * s),
        child: Column(
          children: [
            // 전투 시작은 풀 너비로
            _MenuButton(
              label: buttons[0].label,
              onTap: buttons[0].onTap,
              isPrimary: true,
            ),
            SizedBox(height: 12 * s),
            // 나머지 2열 그리드
            Wrap(
              spacing: 10 * s,
              runSpacing: 8 * s,
              children: buttons.skip(1).map((btn) {
                return SizedBox(
                  width: (Responsive.screenWidth(context) * 0.5 - 40 * s) / 2,
                  child: NotificationBadge(
                    show: btn.showBadge,
                    child: _MenuButton(
                      label: btn.label,
                      onTap: btn.onTap,
                      isPrimary: btn.isPrimary,
                      compact: true,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16 * s),
            _buildFooter(context, lang, s),
          ],
        ),
      );
    } else {
      // 세로 모드: 세로 리스트
      return Column(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            NotificationBadge(
              show: buttons[i].showBadge,
              child: _MenuButton(
                label: buttons[i].label,
                onTap: buttons[i].onTap,
                isPrimary: buttons[i].isPrimary,
              ),
            ),
            if (i < buttons.length - 1) SizedBox(height: (buttons[i].isPrimary ? 16 : 10) * s),
          ],
        ],
      );
    }
  }

  /// 전체화면 토글 FAB (웹 전용)
  Widget _buildFullscreenFab(double s) {
    return StatefulBuilder(
      builder: (context, setState) {
        final fs = FullscreenService.instance;
        fs.syncState(); // ESC로 나간 경우 동기화

        return FloatingActionButton.small(
          heroTag: 'fullscreen_fab',
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          tooltip: fs.isFullscreen ? '전체화면 해제' : '전체화면',
          onPressed: () async {
            await fs.toggle();
            setState(() {});
          },
          child: Icon(
            fs.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white.withValues(alpha: 0.9),
            size: 22 * s,
          ),
        );
      },
    );
  }

  /// 하단 인용구 + 언어
  Widget _buildFooter(BuildContext context, GameLanguage lang, double s) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40 * s),
          child: Text(
            AppStrings.get(lang, 'menu_quote'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 11),
              color: AppColors.cherryBlossom.withAlpha(100),
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ),
        SizedBox(height: 12 * s),
        Text(
          '${lang.flag} ${lang.displayName}',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, 11),
            color: const Color(0xFF554477),
          ),
        ),
      ],
    );
  }

  /// 설정 다이얼로그
  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _SettingsDialog(ref: ref),
    );
  }
}

/// 버튼 데이터 모델
class _ButtonData {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool showBadge;
  _ButtonData(this.label, this.onTap, this.isPrimary, {this.showBadge = false});
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
    final s = Responsive.scale(context);
    return Dialog(
      backgroundColor: AppColors.bgWarmDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.cardRadius + 8),
        side: BorderSide(color: AppColors.cherryBlossom.withAlpha(180)),
      ),
      child: SizedBox(
        width: Responsive.value(context, phone: 300.0, tablet: 360.0, desktop: 400.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: EdgeInsets.all(16 * s),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.cherryBlossom.withAlpha(50))),
                ),
                child: Row(
                  children: [
                    Text('⚙️', style: TextStyle(fontSize: Responsive.fontSize(context, 24))),
                    SizedBox(width: 12 * s),
                    Text(
                      AppStrings.get(currentLang, 'menu_settings'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 20),
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
                padding: EdgeInsets.all(16 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 언어 선택 (드롭다운) ──
                    _sectionLabel('🌐', AppStrings.get(currentLang, 'settings_language'), s),
                    SizedBox(height: 8 * s),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12 * s),
                      decoration: BoxDecoration(
                        color: AppColors.borderDefault.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppDesign.panelRadius + 2),
                        border: Border.all(color: AppColors.borderHighlight.withAlpha(68)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<GameLanguage>(
                          value: currentLang,
                          dropdownColor: AppColors.bgWarmDark,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.borderHighlight),
                          style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 14)),
                          items: GameLanguage.values.map((lang) {
                            return DropdownMenuItem<GameLanguage>(
                              value: lang,
                              child: Text(
                                '${lang.flag}  ${lang.displayName}',
                                style: TextStyle(
                                  color: lang == currentLang ? AppColors.borderHighlight : Colors.white70,
                                  fontWeight: lang == currentLang ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (lang) async {
                            if (lang != null) {
                              await AppStrings.loadLanguage(lang);
                              widget.ref.read(gameLanguageProvider.notifier).state = lang;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 20 * s),

                    // ── 효과음 (SFX) ──
                    _sectionLabel('🔊', '효과음 (SFX)', s),
                    SizedBox(height: 8 * s),
                    _audioRow(
                      enabled: _sfxOn,
                      volume: _sfxVol,
                      s: s,
                      onToggle: () {
                        setState(() { _sfxOn = !_sfxOn; });
                        SoundManager.instance.toggleSfx();
                      },
                      onChanged: (val) {
                        setState(() { _sfxVol = val; });
                        SoundManager.instance.setSfxVolume(val);
                      },
                    ),

                    SizedBox(height: 16 * s),

                    // ── 배경음악 (BGM) ──
                    _sectionLabel('🎵', '배경음악 (BGM)', s),
                    SizedBox(height: 8 * s),
                    _audioRow(
                      enabled: _bgmOn,
                      volume: _bgmVol,
                      s: s,
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

              SizedBox(height: 8 * s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String icon, String label, double s) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: Responsive.fontSize(context, 16))),
        SizedBox(width: 8 * s),
        Text(label, style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 14), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _audioRow({
    required bool enabled,
    required double volume,
    required double s,
    required VoidCallback onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        // 켜기/끄기 버튼
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 36 * s,
            height: 36 * s,
            decoration: BoxDecoration(
              color: enabled ? AppColors.cherryBlossom.withAlpha(60) : AppColors.borderDefault.withAlpha(20),
              borderRadius: BorderRadius.circular(AppDesign.panelRadius),
              border: Border.all(color: enabled ? AppColors.borderHighlight : AppColors.borderDefault),
            ),
            child: Center(
              child: Icon(
                enabled ? Icons.volume_up : Icons.volume_off,
                color: enabled ? AppColors.borderHighlight : Colors.white38,
                size: 20 * s,
              ),
            ),
          ),
        ),
        SizedBox(width: 8 * s),
        // 볼륨 슬라이더
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: enabled ? AppColors.borderHighlight : Colors.white24,
              inactiveTrackColor: AppColors.borderDefault.withAlpha(20),
              thumbColor: enabled ? AppColors.borderHighlight : Colors.white38,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7 * s),
              trackHeight: 4 * s,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 14 * s),
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
          width: 36 * s,
          child: Text(
            '${(volume * 100).toInt()}%',
            style: TextStyle(
              color: enabled ? Colors.white70 : Colors.white24,
              fontSize: Responsive.fontSize(context, 11),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// 메뉴 버튼 (반응형)
class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool compact;

  const _MenuButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    final btnWidth = compact ? double.infinity : 260 * s;

    return GestureDetector(
      onTap: () {
        SoundManager.instance.playSfx(SfxType.uiClick);
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 10 * s : 16 * s),
        child: BackdropFilter(
          filter: isPrimary
              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
              : ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: btnWidth,
            padding: EdgeInsets.symmetric(
              vertical: (compact ? 10 : 14) * s,
              horizontal: compact ? 8 * s : 0,
            ),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                      colors: [AppColors.cherryBlossom, AppColors.peachCoral],
                    )
                  : null,
              color: isPrimary ? null : Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(compact ? 10 * s : 16 * s),
              border: Border.all(
                color: isPrimary
                    ? AppColors.cherryBlossom.withAlpha(180)
                    : Colors.white.withAlpha(30),
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: AppColors.cherryBlossom.withAlpha(60),
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
                color: isPrimary ? Colors.white : AppColors.cherryBlossom.withAlpha(220),
                fontSize: Responsive.fontSize(context, compact ? 13 : 16),
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 2 * s,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
