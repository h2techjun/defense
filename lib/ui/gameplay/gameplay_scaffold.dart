// 게임플레이 화면 (game_screen.dart에서 추출)
// Flame 게임위젯 + HUD + 타워팝업 + 웨이브배너 + 일시정지 + 튜토리얼 Stack

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_riverpod/flame_riverpod.dart';

import '../../common/enums.dart';
import '../../ui/theme/app_colors.dart';
import '../../game/defense_game.dart';
import '../../game/components/towers/base_tower.dart';
import '../../l10n/app_strings.dart';
import '../../state/game_state.dart';
import '../../state/user_state.dart';
import '../../ui/common/ad_side_banners.dart';
import '../../ui/dialogs/game_result_dialog.dart';
import '../../ui/dialogs/tower_upgrade_dialog.dart';
import '../../ui/dialogs/tutorial_overlay.dart';
import '../../ui/hud/game_hud.dart';
import '../../ui/hud/game_tooltip.dart';
import '../../ui/hud/tower_select_panel.dart';
import '../../ui/hud/wave_announce_banner.dart';
import 'pause_menu_overlay.dart';

class GameplayScaffold extends ConsumerStatefulWidget {
  final DefenseGame game;
  final GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>> gameWidgetKey;
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback onSaveAndMenu;
  final VoidCallback onSaveAndReplay;
  final VoidCallback onSaveAndNext;
  final Future<void> Function() onRevive;
  final Future<void> Function() onDoubleReward;
  final void Function(BaseTower, TowerActionResult) onTowerAction;
  final bool showTutorial;
  final VoidCallback onTutorialFinish;

  const GameplayScaffold({
    super.key,
    required this.game,
    required this.gameWidgetKey,
    required this.onRetry,
    required this.onMenu,
    required this.onSaveAndMenu,
    required this.onSaveAndReplay,
    required this.onSaveAndNext,
    required this.onRevive,
    required this.onDoubleReward,
    required this.onTowerAction,
    required this.showTutorial,
    required this.onTutorialFinish,
  });

  @override
  ConsumerState<GameplayScaffold> createState() => _GameplayScaffoldState();
}

class _GameplayScaffoldState extends ConsumerState<GameplayScaffold> {
  TowerType? _selectedTower;
  BaseTower? _tappedTower;
  Offset _tappedTowerScreenPos = Offset.zero;
  double _tappedTowerHeight = 0;
  GameTooltipData? _tooltipData;
  Offset _mousePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  @override
  void didUpdateWidget(covariant GameplayScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      _setupCallbacks();
      _selectedTower = null;
      _tappedTower = null;
      _tooltipData = null;
    }
  }

  void _setupCallbacks() {
    widget.game.onTowerTappedCallback = (tower) => _showTowerDialog(tower);
    widget.game.onTowerPlacedCallback = () {
      setState(() { _selectedTower = null; });
    };
    widget.game.onComponentHover = (info) {
      setState(() { _tooltipData = _buildTooltipFromInfo(info); });
    };
    widget.game.onComponentHoverExit = () {
      setState(() { _tooltipData = null; });
    };
  }

  void _onTowerSelected(TowerType type) {
    setState(() {
      if (_selectedTower == type) {
        _selectedTower = null;
        widget.game.selectedTowerType = null;
      } else {
        _selectedTower = type;
        widget.game.selectedTowerType = type;
      }
    });
  }

  void _showTowerDialog(BaseTower tower) {
    if (_selectedTower != null) return;
    final gameWidgetBox = widget.gameWidgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (gameWidgetBox == null) return;
    final centerWorldPos = tower.position;
    final canvasPos = widget.game.camera.localToGlobal(centerWorldPos);
    final towerHeight = tower.size.y * widget.game.camera.viewfinder.zoom;
    final localPos = Offset(canvasPos.x, canvasPos.y);
    setState(() {
      _tappedTower = tower;
      _tappedTowerScreenPos = localPos;
      _tappedTowerHeight = towerHeight;
    });
  }

  void _dismissTowerPopup() {
    if (_tappedTower != null) {
      widget.game.clearTowerHighlight();
      setState(() { _tappedTower = null; });
    }
  }

  GameLanguage get _currentLang => ref.read(gameLanguageProvider);

  @override
  Widget build(BuildContext context) {
    return AdSideBanners(child: Scaffold(
      body: MouseRegion(
        onHover: (event) { _mousePosition = event.position; },
        child: Stack(
          children: [
            // ── Flame 게임 위젯 (드래그 타겟) ──
            Positioned.fill(
              child: DragTarget<TowerType>(
                onAcceptWithDetails: (details) {
                  final RenderBox? renderBox = widget.gameWidgetKey.currentContext?.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPos = renderBox.globalToLocal(details.offset);
                    widget.game.handleDragDrop(localPos, details.data, renderBox.size);
                  } else {
                    final RenderBox? fallbackBox = context.findRenderObject() as RenderBox?;
                    if (fallbackBox != null) {
                      final localPos = fallbackBox.globalToLocal(details.offset);
                      widget.game.handleDragDrop(localPos, details.data, fallbackBox.size);
                    }
                  }
                  setState(() { _selectedTower = null; });
                },
                builder: (context, candidateData, rejectedData) {
                  return RiverpodAwareGameWidget<DefenseGame>(
                    key: widget.gameWidgetKey,
                    game: widget.game,
                    overlayBuilderMap: {
                      'GameOverOverlay': (context, game) => DefeatOverlay(
                            onRetry: widget.onRetry,
                            onMenu: widget.onMenu,
                            onRevive: () => widget.onRevive(),
                          ),
                      'VictoryOverlay': (context, game) => VictoryOverlay(
                            onMenu: widget.onSaveAndMenu,
                            onReplay: widget.onSaveAndReplay,
                            onNextStage: widget.onSaveAndNext,
                            onDoubleReward: () => widget.onDoubleReward(),
                          ),
                    },
                  );
                },
              ),
            ),

            // ── HUD 오버레이 ──
            GameHud(
              horizontalPadding: 0,
              isSpeedLocked: !ref.watch(userStateProvider).hasSpeedPass,
              onPause: () {
                _dismissTowerPopup();
                widget.game.togglePause();
                setState(() {});
              },
              onSpeedToggle: () {
                if (!ref.read(userStateProvider).hasSpeedPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.get(_currentLang, 'msg_speed_locked')),
                      backgroundColor: Color(0xFF6633AA),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                widget.game.cycleGameSpeed();
                ref.read(gameStateProvider.notifier).setGameSpeed(widget.game.gameSpeed);
              },
            ),

            // ── 타워 업그레이드 인라인 팝업 ──
            if (_tappedTower != null)
              _buildTowerPopup(context),

            // ── 웨이브 안내 & 쿨다운 ──
            _buildWaveIndicator(),

            // ── 일시정지 메뉴 오버레이 ──
            if (widget.game.isPaused)
              PauseMenuOverlay(
                game: widget.game,
                onResume: () {
                  widget.game.togglePause();
                  setState(() {});
                },
                onRestart: () {
                  widget.game.togglePause();
                  widget.onRetry();
                },
                onExit: () {
                  widget.game.togglePause();
                  widget.onMenu();
                },
              ),

            // ── 타워 선택 패널 ──
            TowerSelectPanel(
              selectedTower: _selectedTower,
              onTowerSelected: _onTowerSelected,
            ),

            // ── 호버 툴팁 ──
            if (_tooltipData != null && !widget.showTutorial && _tappedTower == null)
              GameTooltip(
                data: _tooltipData!,
                position: _mousePosition,
              ),

            // ── 튜토리얼 오버레이 ──
            if (widget.showTutorial)
              Positioned.fill(
                child: TutorialOverlay(
                  steps: [
                    TutorialStep(
                      emoji: '🏯',
                      title: AppStrings.get(_currentLang, 'tut1_title'),
                      content: AppStrings.get(_currentLang, 'tut1_content'),
                    ),
                    TutorialStep(
                      emoji: '🗼',
                      title: AppStrings.get(_currentLang, 'tut2_title'),
                      content: AppStrings.get(_currentLang, 'tut2_content'),
                    ),
                    TutorialStep(
                      emoji: '🔥',
                      title: AppStrings.get(_currentLang, 'tut3_title'),
                      content: AppStrings.get(_currentLang, 'tut3_content'),
                    ),
                    TutorialStep(
                      emoji: '🌙',
                      title: AppStrings.get(_currentLang, 'tut4_title'),
                      content: AppStrings.get(_currentLang, 'tut4_content'),
                    ),
                    TutorialStep(
                      emoji: '👻',
                      title: AppStrings.get(_currentLang, 'tut5_title'),
                      content: AppStrings.get(_currentLang, 'tut5_content'),
                    ),
                    TutorialStep(
                      emoji: '⚔️',
                      title: AppStrings.get(_currentLang, 'tut6_title'),
                      content: AppStrings.get(_currentLang, 'tut6_content'),
                    ),
                  ],
                  onFinish: widget.onTutorialFinish,
                ),
              ),
          ],
        ),
      ),
    ));
  }

  Widget _buildTowerPopup(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissTowerPopup,
        child: Stack(
          children: [
            Builder(
              builder: (context) {
                final screenSize = MediaQuery.of(context).size;
                final popupWidth = (screenSize.width * 0.22).clamp(140.0, 180.0);
                const bottomPadding = 80.0;
                const topPadding = 50.0;

                double left = _tappedTowerScreenPos.dx + (_tappedTowerHeight / 2) + 8;
                if (left + popupWidth > screenSize.width - 8) {
                  left = _tappedTowerScreenPos.dx - (_tappedTowerHeight / 2) - popupWidth - 8;
                }
                left = left.clamp(8.0, screenSize.width - popupWidth - 8);

                double top = _tappedTowerScreenPos.dy - 40;
                final maxH = screenSize.height - top - bottomPadding;
                if (maxH < 180) {
                  top = screenSize.height - bottomPadding - 180;
                }
                top = top.clamp(topPadding, screenSize.height - bottomPadding - 160);
                final finalMaxH = screenSize.height - top - bottomPadding;

                return Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onTap: () {},
                    child: SizedBox(
                      width: popupWidth,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: finalMaxH.clamp(120, 220),
                        ),
                        child: Consumer(
                          builder: (_, consumerRef, __) {
                            final state = consumerRef.watch(gameStateProvider);
                            final tower = _tappedTower!;
                            final displayLevel = tower.upgradeLevel + 1;
                            return TowerUpgradeDialog(
                              towerType: tower.data.type,
                              currentLevel: displayLevel,
                              sellRefund: tower.sellRefund,
                              currentSinmyeong: state.sinmyeong,
                              selectedBranch: tower.selectedBranch,
                              onAction: (action) {
                                _dismissTowerPopup();
                                widget.onTowerAction(tower, action);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveIndicator() {
    return Consumer(
      builder: (_, consumerRef, __) {
        final state = consumerRef.watch(gameStateProvider);
        final wm = widget.game.waveManager;
        return StatefulBuilder(
          builder: (context, localSetState) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                localSetState(() {});
              }
            });

            if (wm.isInCooldown && wm.cooldownRemaining > 0) {
              return Positioned.fill(
                child: IgnorePointer(
                  child: WaveCooldownIndicator(
                    secondsRemaining: wm.cooldownRemaining,
                    nextWaveNumber: state.currentWave,
                  ),
                ),
              );
            }

            if (wm.isWaveActive && state.currentWave > 0) {
              final isBoss = state.currentWave == state.totalWaves;
              return Positioned.fill(
                child: IgnorePointer(
                  child: WaveAnnounceBanner(
                    key: ValueKey('wave_${state.currentWave}'),
                    waveNumber: state.currentWave,
                    totalWaves: state.totalWaves,
                    narrative: wm.currentNarrative,
                    isBossWave: isBoss,
                    enemyEntries: () {
                      final counts = <String, int>{};
                      for (final id in state.nextWaveEnemyIds) {
                        counts[id] = (counts[id] ?? 0) + 1;
                      }
                      return counts.entries.toList();
                    }(),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  // ── 툴팁 빌더 ──

  GameTooltipData _buildTooltipFromInfo(Map<String, dynamic> info) {
    final type = info['type'] as String? ?? 'unknown';
    if (type == 'tower') {
      return GameTooltipData(
        title: info['name'] as String? ?? AppStrings.get(_currentLang, 'stat_tower'),
        subtitle: 'Lv.${info['level']}',
        description: info['description'] as String?,
        color: _getTowerColor(info['towerType'] as TowerType),
        icon: _getTowerIcon(info['towerType'] as TowerType),
        imagePath: info['imagePath'] as String?,
        stats: [
          TooltipStat(AppStrings.get(_currentLang, 'stat_attack'), '${(info['damage'] as double).toStringAsFixed(0)}'),
          TooltipStat(AppStrings.get(_currentLang, 'stat_range'), '${(info['range'] as double).toStringAsFixed(0)}'),
          TooltipStat(AppStrings.get(_currentLang, 'stat_attack_speed'), '${(info['fireRate'] as double).toStringAsFixed(2)}/s'),
          if (info['specialAbility'] != null)
            TooltipStat(AppStrings.get(_currentLang, 'stat_special'), info['specialAbility'] as String? ?? '', highlight: true),
        ],
      );
    } else if (type == 'hero') {
      final isDead = info['isDead'] as bool? ?? false;
      final colorInt = info['color'] as int? ?? 0xFFFFAA00;
      final heroLevel = info['level'] as int? ?? 1;
      final heroMaxLevel = info['maxLevel'] as int? ?? 10;
      final heroXp = info['xp'] as int? ?? 0;
      final heroXpNext = info['xpForNextLevel'] as int? ?? 0;
      final xpText = heroLevel >= heroMaxLevel ? 'MAX' : '$heroXp / $heroXpNext';
      final nameKey = info['nameKey'] as String? ?? '';
      final heroName = nameKey.isNotEmpty ? AppStrings.get(_currentLang, nameKey) : '${info['name']}';
      final dmgTypeKey = 'dmg_${info['damageType']}';
      return GameTooltipData(
        title: heroName,
        subtitle: '${info['title']} · Lv.$heroLevel',
        description: '🎯 ${info['skillName']}\n${info['skillDesc']}\n⏱ ${AppStrings.get(_currentLang, 'skill_cooltime')}: ${info['skillCooldown']}${AppStrings.get(_currentLang, 'unit_seconds')}',
        color: Color(colorInt),
        icon: info['emoji'] as String? ?? '⚔️',
        imagePath: info['imagePath'] as String?,
        stats: [
          TooltipStat('HP', '${info['hp']} / ${info['maxHp']}', highlight: isDead),
          TooltipStat(AppStrings.get(_currentLang, 'stat_attack'), info['attack'] as String? ?? '-'),
          TooltipStat(AppStrings.get(_currentLang, 'stat_range'), info['range'] as String? ?? '-'),
          TooltipStat(AppStrings.get(_currentLang, 'stat_attribute'), AppStrings.get(_currentLang, dmgTypeKey)),
          TooltipStat(AppStrings.get(_currentLang, 'stat_exp'), xpText, highlight: heroLevel >= heroMaxLevel),
          if (isDead)
            TooltipStat(AppStrings.get(_currentLang, 'stat_status'), AppStrings.get(_currentLang, 'stat_dead'), highlight: true),
        ],
      );
    } else {
      return GameTooltipData(
        title: AppStrings.get(_currentLang, info['name'] as String? ?? 'stat_enemy'),
        subtitle: 'HP: ${info['hp']}',
        description: info['description'] != null ? AppStrings.get(_currentLang, info['description'] as String) : null,
        color: (info['isBerserk'] as bool? ?? false)
            ? const Color(0xFFFF4500)
            : const Color(0xFFCC3333),
        icon: '👻',
        stats: [
          TooltipStat(AppStrings.get(_currentLang, 'stat_speed'), info['speed'] as String? ?? ''),
          TooltipStat(AppStrings.get(_currentLang, 'stat_reward'), '✨${info['reward']}'),
          if ((info['abilityKeys'] as List<dynamic>? ?? []).isNotEmpty)
            TooltipStat(
              AppStrings.get(_currentLang, 'stat_ability'),
              (info['abilityKeys'] as List<dynamic>)
                  .map((k) => AppStrings.get(_currentLang, k as String))
                  .join(', '),
              highlight: true,
            ),
        ],
      );
    }
  }

  Color _getTowerColor(TowerType type) {
    switch (type) {
      case TowerType.archer:   return AppColors.towerArcher;
      case TowerType.barracks: return AppColors.towerBarracks;
      case TowerType.shaman:   return AppColors.towerShaman;
      case TowerType.artillery:return AppColors.towerArtillery;
      case TowerType.sotdae:   return AppColors.towerSotdae;
    }
  }

  String _getTowerIcon(TowerType type) {
    switch (type) {
      case TowerType.archer:   return '🛖';
      case TowerType.barracks: return '🤼';
      case TowerType.shaman:   return '🔮';
      case TowerType.artillery:return '💥';
      case TowerType.sotdae:   return '🪶';
    }
  }
}
