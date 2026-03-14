// ?�원??�?- 게임 ?�면 (메인메뉴 ??게임?�레???�환)
// main.dart?�서 분리 (P0-1 리팩?�링)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_riverpod/flame_riverpod.dart';

import 'common/enums.dart';
import 'ui/theme/app_colors.dart';
import 'data/game_data_loader.dart';
import 'data/models/wave_data.dart';
import 'ui/dialogs/hero_unlock_dialog.dart';
import 'game/defense_game.dart';
import 'game/components/towers/base_tower.dart';
import 'audio/sound_manager.dart';
import 'state/game_state.dart';
import 'ui/menus/main_menu.dart';
import 'ui/menus/stage_select_screen.dart';
import 'ui/menus/hero_manage_screen.dart';
import 'ui/menus/tower_manage_screen.dart';
import 'ui/menus/skin_shop_screen.dart';
import 'ui/menus/endless_tower_screen.dart';
import 'ui/menus/season_pass_screen.dart';
import 'ui/menus/achievement_screen.dart';
import 'ui/menus/package_shop_screen.dart';
import 'ui/menus/daily_quest_screen.dart';
import 'state/daily_quest_provider.dart';
import 'state/skin_provider.dart';
import 'ui/menus/lore_collection_screen.dart';

import 'ui/hud/game_hud.dart';
import 'ui/hud/tower_select_panel.dart';
import 'ui/hud/hero_skill_panel.dart';
import 'ui/menus/hero_deploy_screen.dart';
import 'ui/dialogs/game_result_dialog.dart';
import 'ui/dialogs/tower_upgrade_dialog.dart';
import 'ui/hud/game_tooltip.dart';
import 'state/user_state.dart';
import 'state/achievement_provider.dart';
import 'data/models/achievement_data.dart';

import 'ui/hud/wave_announce_banner.dart';
import 'ui/dialogs/story_cutscene_dialog.dart';
import 'ui/dialogs/tutorial_overlay.dart';
import 'data/models/story_data.dart';
import 'common/responsive.dart';
import 'ui/common/ad_side_banners.dart';

/// 게임 ?�면 (메인메뉴 ??게임 ?�환)
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late DefenseGame _game;
  String _currentScreen = 'mainMenu'; // mainMenu, stageSelect, heroManage, heroDeploy, gameplay
  LevelData? _currentLevel;
  TowerType? _selectedTower;

  bool _showTutorial = false; // ?�토리얼 ?�시 ?��?
  final _gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>>();

  // ?�팁 ?�태
  GameTooltipData? _tooltipData;
  Offset _mousePosition = Offset.zero;

  // ?�???�그?�이???�업 ?�태
  BaseTower? _tappedTower;
  Offset _tappedTowerScreenPos = Offset.zero;
  double _tappedTowerHeight = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('?? [GameScreen] initState ?�작');
    _game = DefenseGame();
    _setupGameCallbacks();
    // ?�이�??�이??로드
    Future.microtask(() async {
      debugPrint('?? [GameScreen] ?�이�??�이??로드 ?�작');
      await ref.read(userStateProvider.notifier).loadFromSave();
      await ref.read(dailyQuestProvider.notifier).loadFromSave();
      await ref.read(skinProvider.notifier).loadFromSave();
      debugPrint('?? [GameScreen] ?�이�??�이??로드 ?�료');
    });
  }

  void _setupGameCallbacks() {
    // ?�???�릭 ???�매/?�그?�이???�이?�로�?
    _game.onTowerTappedCallback = (tower) {
      _showTowerDialog(tower);
    };
    // ?�???�치 ???�택 ?�제
    _game.onTowerPlacedCallback = () {
      setState(() {
        _selectedTower = null;
      });
    };
    // ?�버 ?�팁
    _game.onComponentHover = (info) {
      setState(() {
        _tooltipData = _buildTooltipFromInfo(info);
      });
    };
    _game.onComponentHoverExit = () {
      setState(() {
        _tooltipData = null;
      });
    };
  }

  /// ?�버 ?�보 ???�팁 ?�이??변??
  GameTooltipData _buildTooltipFromInfo(Map<String, dynamic> info) {
    final type = info['type'] as String;
    if (type == 'tower') {
      return GameTooltipData(
        title: info['name'] as String? ?? '?�??,
        subtitle: 'Lv.${info['level']}',
        description: info['description'] as String?,
        color: _getTowerColor(info['towerType'] as TowerType),
        icon: _getTowerIcon(info['towerType'] as TowerType),
        stats: [
          TooltipStat('공격??, '${(info['damage'] as double).toStringAsFixed(0)}'),
          TooltipStat('?�거�?, '${(info['range'] as double).toStringAsFixed(0)}'),
          TooltipStat('공격?�도', '${(info['fireRate'] as double).toStringAsFixed(2)}/s'),
          if (info['specialAbility'] != null)
            TooltipStat('?�수', info['specialAbility'] as String, highlight: true),
        ],
      );
    } else if (type == 'hero') {
      // ?�웅 ?�팁
      final isDead = info['isDead'] as bool? ?? false;
      final colorInt = info['color'] as int? ?? 0xFFFFAA00;
      final heroLevel = info['level'] as int? ?? 1;
      final heroMaxLevel = info['maxLevel'] as int? ?? 10;
      final heroXp = info['xp'] as int? ?? 0;
      final heroXpNext = info['xpForNextLevel'] as int? ?? 0;
      final xpText = heroLevel >= heroMaxLevel
          ? 'MAX'
          : '$heroXp / $heroXpNext';
      return GameTooltipData(
        title: '${info['name']}',
        subtitle: '${info['title']} · Lv.$heroLevel',
        description: '?�� ${info['skillName']}\n${info['skillDesc']}\n??쿨�??? ${info['skillCooldown']}�?,
        color: Color(colorInt),
        icon: info['emoji'] as String? ?? '?�️',
        stats: [
          TooltipStat('HP', '${info['hp']} / ${info['maxHp']}',
            highlight: isDead),
          TooltipStat('공격??, info['attack'] as String? ?? '-'),
          TooltipStat('?�거�?, info['range'] as String? ?? '-'),
          TooltipStat('?�성', info['damageType'] as String? ?? '-'),
          TooltipStat('경험�?, xpText, highlight: heroLevel >= heroMaxLevel),
          if (isDead)
            TooltipStat('?�태', '?? 부???��?, highlight: true),
        ],
      );
    } else {
      // ??
      return GameTooltipData(
        title: info['name'] as String? ?? '??,
        subtitle: 'HP: ${info['hp']}',
        description: info['description'] as String?,
        color: (info['isBerserk'] as bool? ?? false)
            ? const Color(0xFFFF4500)
            : const Color(0xFFCC3333),
        icon: '?��',
        stats: [
          TooltipStat('?�도', info['speed'] as String? ?? ''),
          TooltipStat('보상', '??{info['reward']}'),
          if ((info['abilities'] as String? ?? '').isNotEmpty)
            TooltipStat('?�력', info['abilities'] as String, highlight: true),
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
      case TowerType.archer:   return '?��';
      case TowerType.barracks: return '?��';
      case TowerType.shaman:   return '?��';
      case TowerType.artillery:return '?��';
      case TowerType.sotdae:   return '?��';
    }
  }

  void _startLevel(LevelData level, {GameMode mode = GameMode.campaign}) {
    setState(() {
      _currentScreen = 'gameplay';
      _currentLevel = level;
    });

    void startGame() {
      Future.microtask(() {
        SoundManager.instance.stopBgm();
        _game.startLevel(level, mode: mode);

        // ?�토리얼 ?�리�?(캠페??1?�테?��? & 미완�???
        final userState = ref.read(userStateProvider);
        if (mode == GameMode.campaign && level.levelNumber == 1 && !userState.hasCompletedTutorial) {
          setState(() {
            _showTutorial = true;
          });
          _game.pauseEngine(); // ?�토리얼???�있???�안 ?�진 ?��?
        }
      });
    }

    // 캠페??모드??경우 ?�벨 조건???�라 ?�토�?컷씬 ?�생 분기
    if (mode == GameMode.campaign) {
      List<StoryScene>? scenes;
      if (level.levelNumber == 1) {
        scenes = StoryData.introSequence;
      } else if (level.levelNumber == 21) {
        scenes = StoryData.ep1ToEp2;
      } else if (level.levelNumber == 41) {
        scenes = StoryData.ep2ToEp3;
      } else if (level.levelNumber == 61) {
        scenes = StoryData.ep3ToEp4;
      } else if (level.levelNumber == 81) {
        scenes = StoryData.ep4ToEp5;
      }

      if (scenes != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => StoryCutsceneDialog(
            scenes: scenes!,
            onFinish: () {
              Navigator.of(ctx).pop();
              startGame();
            },
          ),
        );
        return; // ?�이?�로�?콜백?�서 ?�제 게임???�작?�도�??��?
      }
    }

    startGame();
  }

  void _returnToMenu() {
    setState(() {
      _currentScreen = 'stageSelect';
      _selectedTower = null;
    });
    _game = DefenseGame();
    _setupGameCallbacks();
    ref.read(gameStateProvider.notifier).setPhase(GamePhase.mainMenu);
    SoundManager.instance.stopBgm();
    SoundManager.instance.playBgm(BgmType.menu);
  }

  void _restartLevel() {
    if (_currentLevel == null) return;
    _game.overlays.remove('GameOverOverlay');
    _game.overlays.remove('VictoryOverlay');
    _game = DefenseGame();
    _setupGameCallbacks();
    setState(() {
      _selectedTower = null;
    });
    Future.microtask(() {
      _game.startLevel(_currentLevel!);
    });
  }

  void _goToNextStage() {
    if (_currentLevel == null) return;
    final levels = GameDataLoader.getAllLevels();
    final currentIndex = levels.indexWhere(
      (l) => l.levelNumber == _currentLevel!.levelNumber,
    );
    if (currentIndex >= 0 && currentIndex < levels.length - 1) {
      final nextLevel = levels[currentIndex + 1];
      _game.overlays.remove('VictoryOverlay');
      _game = DefenseGame();
      _setupGameCallbacks();
      setState(() {
        _selectedTower = null;
      });
      _startLevel(nextLevel);
    } else {
      // 마�?�??�테?��? ??메뉴 복�?
      _returnToMenu();
    }
  }

  /// ?�벨 번호�?챕터 번호 계산
  int _getChapterForLevel(int levelNumber) {
    if (levelNumber <= 20) return 1;
    if (levelNumber <= 40) return 2;
    if (levelNumber <= 60) return 3;
    if (levelNumber <= 80) return 4;
    return 5;
  }

  /// ?�리 ??진행 ?�황 ?�??
  void _saveProgress() {
    if (_currentLevel == null) return;
    final gameState = ref.read(gameStateProvider);
    if (gameState.phase == GamePhase.victory) {
      final chapter = _getChapterForLevel(_currentLevel!.levelNumber);
      ref.read(userStateProvider.notifier).completeLevel(
        chapter,
        _currentLevel!.levelNumber,
        gameState.starRating,
      );
      debugPrint('[SAVE] Ch.$chapter ?�테?��? ${_currentLevel!.levelNumber} ?�리?? �? ${gameState.starRating}');

      // ?�웅 ?�금 체크
      final userState = ref.read(userStateProvider);
      final newlyUnlocked = <HeroId>[];
      for (final entry in heroUnlockStage.entries) {
        if (entry.value > 0 &&
            entry.value <= _currentLevel!.levelNumber &&
            !userState.unlockedHeroes.contains(entry.key)) {
          ref.read(userStateProvider.notifier).unlockHero(entry.key);
          newlyUnlocked.add(entry.key);
          debugPrint('[UNLOCK] ?�웅 ?�금: ${entry.key.name} (Stage ${entry.value} 조건 충족)');
        }
      }

      // ?�금 축하 ?�업 ?�시 (?�리 ?�면 ?�에 ?�차 ?�시)
      if (newlyUnlocked.isNotEmpty && mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () async {
          for (final heroId in newlyUnlocked) {
            if (!mounted) break;
            await showHeroUnlockDialog(context, heroId);
          }
        });
      }
    }
  }

  void _onTowerSelected(TowerType type) {
    setState(() {
      // ?��?: 같�? ?�?��? ?�시 ?�르�??�제
      if (_selectedTower == type) {
        _selectedTower = null;
        _game.selectedTowerType = null;
      } else {
        _selectedTower = type;
        _game.selectedTowerType = type;
      }
    });
  }

  /// 배치???�???�릭 ?????�매/?�그?�이???�이?�로�?
  void _showTowerDialog(BaseTower tower) {
    // ?�???�택 중이�?무시 (배치 모드)
    if (_selectedTower != null) return;

    // ?�?�의 게임 좌표 ???�면 좌표 변??
    final gameWidgetBox = _gameWidgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (gameWidgetBox == null) return;

    final gameWidgetSize = gameWidgetBox.size;
    final gameSize = _game.size;

    // 게임 좌표�??�면 비율�?변??
    final scaleX = gameWidgetSize.width / gameSize.x;
    final scaleY = gameWidgetSize.height / gameSize.y;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // 게임???�면 중앙???�치???�의 ?�프??
    final offsetX = (gameWidgetSize.width - gameSize.x * scale) / 2;
    final offsetY = (gameWidgetSize.height - gameSize.y * scale) / 2;

    // ?�??중심 ?�면 좌표
    final centerX = tower.position.x * scale + offsetX;
    final centerY = tower.position.y * scale + offsetY;
    final towerHeight = tower.size.y * scale;

    // GameWidget??글로벌 ?�치 추�?
    final globalPos = gameWidgetBox.localToGlobal(Offset.zero);

    setState(() {
      _tappedTower = tower;
      _tappedTowerScreenPos = Offset(
        centerX + globalPos.dx,
        centerY + globalPos.dy,
      );
      _tappedTowerHeight = towerHeight;
    });
  }

  void _dismissTowerPopup() {
    if (_tappedTower != null) {
      _game.clearTowerHighlight();
      setState(() {
        _tappedTower = null;
      });
    }
  }

  /// ?�???�션 처리 (?�매/?�그?�이??분기)
  void _handleTowerAction(BaseTower tower, TowerActionResult action) {
    final stateNotifier = ref.read(gameStateProvider.notifier);

    switch (action) {
      case TowerSellResult():
        // ?�불 금액 추�?
        stateNotifier.addSinmyeong(tower.sellRefund);
        // ?�롯 ?�제
        final slotIndex = _game.gameMap.findSlotAt(tower.position);
        if (slotIndex != null) {
          _game.gameMap.freeSlot(slotIndex);
        }
        // ?�???�거
        tower.removeFromParent();
        break;

      case TowerUpgradeResult(level: final newLevel):
        final upgradeCost = tower.data.upgrades[newLevel - 1].cost;
        if (stateNotifier.spendSinmyeong(upgradeCost)) {
          tower.upgrade();
          SoundManager.instance.playSfx(SfxType.uiUpgrade);
        }
        break;

      case TowerMaxUpgradeResult():
        // ?�벨 3까�? ?�차 ?�그?�이??(비용 ?�차 차감)
        while (tower.upgradeLevel < 3 && tower.upgradeLevel < tower.data.upgrades.length) {
          final cost = tower.data.upgrades[tower.upgradeLevel].cost;
          if (!stateNotifier.spendSinmyeong(cost)) break;
          tower.upgrade();
        }
        break;

      case TowerBranchResult(branch: final branch):
        final branchCost = tower.data.upgrades.length > 3
            ? tower.data.upgrades[3].cost
            : 300;
        if (stateNotifier.spendSinmyeong(branchCost)) {
          tower.selectBranch(branch);
          // selectBranch ?��??�서 upgradeLevel = 4 ?�정 ?�료
        }
        break;
    }
  }

  /// ?�시?��? 메뉴 버튼 빌더
  Widget _buildPauseMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final s = Responsive.uiScale(context);
    return SizedBox(
      width: double.infinity,
      height: 48 * s,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 22 * s),
        label: Text(label,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.fontSize(context, 15),
              fontWeight: FontWeight.w600,
            )),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// ?�운???��? 버튼 빌더 (?�시?��? 메뉴??
  Widget _buildSoundToggle({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final s = Responsive.uiScale(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          color: active ? const Color(0x338B5CF6) : const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF8B5CF6) : const Color(0x44FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white38, size: 20 * s),
            SizedBox(width: 6 * s),
            Text(label, style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontSize: Responsive.fontSize(context, 12),
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  /// ?�웅 ?�킬 ?�널 빌더 (?�시�??�태 반영)
  Widget _buildHeroSkillPanel() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: StatefulBuilder(
        builder: (context, localSetState) {
          // 250ms마다 ?�웅 ?�태 갱신
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted && _currentScreen == 'gameplay') {
              localSetState(() {});
            }
          });

          final heroes = _game.activeHeroes;
          if (heroes.isEmpty) return const SizedBox.shrink();

          final heroInfos = <HeroSkillInfo>[];
          for (int i = 0; i < heroes.length; i++) {
            final hero = heroes[i];
            final heroEmoji = _getHeroEmoji(hero.data.id);

            // HeroId ???�일�?매핑
            String heroFileName;
            switch (hero.data.id) {
              case HeroId.kkaebi: heroFileName = 'kkaebi'; break;
              case HeroId.miho: heroFileName = 'miho'; break;
              case HeroId.gangrim: heroFileName = 'gangrim'; break;
              case HeroId.sua: heroFileName = 'sua'; break;
              case HeroId.bari: heroFileName = 'bari'; break;
            }

            heroInfos.add(HeroSkillInfo(
              name: hero.data.name,
              emoji: heroEmoji,
              heroId: heroFileName,
              skillName: hero.data.skill.name,
              hpRatio: hero.maxHp > 0 ? (hero.hp / hero.maxHp).clamp(0, 1) : 0,
              cooldownRatio: hero.skillCooldownRatio,
              isDead: hero.isDead,
              reviveProgress: hero.reviveProgress,
              isUltimate: hero.skillReady,
              onSkillTap: () {
                _game.useHeroSkill(i);
              },
            ));
          }

          return HeroSkillPanel(heroes: heroInfos);
        },
      ),
    );
  }

  /// ?�웅 ID�??�모지
  String _getHeroEmoji(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:
        return '?��'; // ?�깨�?
      case HeroId.miho:
        return '?��'; // ?�우
      case HeroId.gangrim:
        return '??'; // ?�?�차??
      case HeroId.sua:
        return '?��'; // 물의 ?�령
      case HeroId.bari:
        return '?��'; // 바리공주
    }
  }


  /// ?�인 ?�이?�로�?(?�시???��?�???비�????�션)
  void _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.buttonRadius),
          side: const BorderSide(color: AppColors.borderAccent, width: 1),
        ),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.berserkRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('?�인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ?�적 ?�성 ?�림 리스??
    ref.listen<String?>(lastAchievedIdProvider, (prev, next) {
      if (next != null && next != prev) {
        try {
          final achievement = allAchievements.firstWhere((a) => a.id == next);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Text(achievement.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('?�� ?�적 ?�성!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(achievement.name, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('?��${achievement.rewardGems}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                backgroundColor: const Color(0xFF6633AA),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
            // ?�과???�생 (SFX)
            SoundManager.instance.playSfx(SfxType.uiUpgrade);
          }
        } catch (_) {}
      }
    });

    // 메인 메뉴
    if (_currentScreen == 'mainMenu') {
      // 메뉴 BGM ?�생 (?�러 ?�전 처리 ???�에???�?�아??방�?)
      SoundManager.instance.init().then((_) {
        SoundManager.instance.playBgm(BgmType.menu);
      }).catchError((e) {
        debugPrint('?�️ [GameScreen] SoundManager 초기??BGM ?�패: $e');
      });
      return MainMenu(
        onStageSelect: () {
          setState(() {
            _currentScreen = 'stageSelect';
          });
        },
        onHeroManage: () {
          setState(() {
            _currentScreen = 'heroManage';
          });
        },
        onTowerManage: () {
          setState(() {
            _currentScreen = 'towerManage';
          });
        },
        onSkinShop: () {
          setState(() {
            _currentScreen = 'skinShop';
          });
        },
        onPackageShop: () {
          setState(() {
            _currentScreen = 'packageShop';
          });
        },
        onEndlessTower: () {
          setState(() {
            _currentScreen = 'endlessTower';
          });
        },
        onSeasonPass: () {
          setState(() {
            _currentScreen = 'seasonPass';
          });
        },
        onAchievement: () {
          setState(() {
            _currentScreen = 'achievement';
          });
        },
        onDailyQuest: () {
          setState(() {
            _currentScreen = 'dailyQuest';
          });
        },
        onLoreCollection: () {
          setState(() {
            _currentScreen = 'loreCollection';
          });
        },
      );
    }

    // ?�??관�?
    if (_currentScreen == 'towerManage') {
      return TowerManageScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      );
    }

    // ?�킨 ?�점
    if (_currentScreen == 'skinShop') {
      return SkinShopScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      // ?�킨 ?�점 ?�기
      );
    }

    // 무한????
    if (_currentScreen == 'endlessTower') {
      return EndlessTowerScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
        onStartLevel: (level, mode) {
          _startLevel(level, mode: mode);
        },
      // 무한?????�기
      );
    }

    // ?�즌 ?�스
    if (_currentScreen == 'seasonPass') {
      return SeasonPassScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      // ?�즌 ?�스 ?�기
      );
    }

    // ?�적 & ??��
    if (_currentScreen == 'achievement') {
      return AchievementScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      // ?�적 ?�기
      );
    }

    // ?�키지 ?�점
    if (_currentScreen == 'packageShop') {
      return PackageShopScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      // ?�키지 ?�점 ?�기
      );
    }

    // ?�일 미션
    if (_currentScreen == 'dailyQuest') {
      return DailyQuestScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      // ?�일 미션 ?�기
      );
    }

    // ?�화?�감
    if (_currentScreen == 'loreCollection') {
      return LoreCollectionScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      // ?�화?�감 ?�기
      );
    }

    // ?�웅 관�?
    if (_currentScreen == 'heroManage') {
      return HeroManageScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      // ?�웅관�??�기
      );
    }

    // ?�테?��? ?�택
    if (_currentScreen == 'stageSelect') {
      return StageSelectScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
        onLevelSelected: (level) {
          setState(() {
            _currentLevel = level;
            _currentScreen = 'heroDeploy';
          });
        },
      // ?�테?��??�택 ?�기
      );
    }

    // 출전 준�??�면
    if (_currentScreen == 'heroDeploy' && _currentLevel != null) {
      return HeroDeployScreen(
        level: _currentLevel!,
        onBack: () {
          setState(() {
            _currentScreen = 'stageSelect';
          });
        },
        onStartBattle: _startLevel,
      );
    }


    return AdSideBanners(child: Scaffold(
      body: MouseRegion(
        onHover: (event) {
          _mousePosition = event.position;
        },
        child: Stack(
          children: [
            // ?�?� Flame 게임 ?�젯 (?�래�??��? ?�?�
            Positioned.fill(
              child: DragTarget<TowerType>(
                onAcceptWithDetails: (details) {
                  // ?�롭 ?�치�?게임 ?�진???�달
                  _game.handleDragDrop(details.offset, details.data);
                  // ?�래�????�택 ?�태 초기??(UI ?�데?�트)
                  setState(() {
                    _selectedTower = null;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return RiverpodAwareGameWidget<DefenseGame>(
                    key: _gameWidgetKey,
                    game: _game,
                    overlayBuilderMap: {
                      'GameOverOverlay': (context, game) => DefeatOverlay(
                            onRetry: _restartLevel,
                            onMenu: _returnToMenu,
                          ),
                      'VictoryOverlay': (context, game) => VictoryOverlay(
                            onMenu: () {
                              _saveProgress();
                              _returnToMenu();
                            },
                            onReplay: () {
                              _saveProgress();
                              _restartLevel();
                            },
                            onNextStage: () {
                              _saveProgress();
                              _goToNextStage();
                            },
                          ),
                    },
                  );
                },
              ),
            ),

            // ?�?� HUD ?�버?�이 ?�?�
            GameHud(
              isSpeedLocked: !ref.watch(userStateProvider).hasSpeedPass,
              onPause: () {
                _dismissTowerPopup();
                _game.togglePause();
                setState(() {}); // UI 갱신
              },
              onSpeedToggle: () {
                if (!ref.read(userStateProvider).hasSpeedPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('?�� ?�점?�서 ?�무 ?�품??구매?�면 2배속???�금?�니??'),
                      backgroundColor: Color(0xFF6633AA),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                _game.cycleGameSpeed();
                ref.read(gameStateProvider.notifier).setGameSpeed(_game.gameSpeed);
              },
            ),

            // ?�?� ?�???�그?�이???�라???�업 ?�?�
            if (_tappedTower != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _dismissTowerPopup,
                  child: Stack(
                    children: [
                      Builder(
                        builder: (context) {
                          final screenSize = MediaQuery.of(context).size;
                          final s = Responsive.uiScale(context);
                          final popupWidth = 240.0 * s;
                          final popupHeight = 200.0 * s;
                          const gap = 8.0;
                          final bottomPadding = 100.0 * s;
                          final topPadding = 50.0 * s;

                          // 좌우 ?�치: ?�??중심 기�?
                          final left = (_tappedTowerScreenPos.dx - popupWidth / 2)
                              .clamp(8.0, screenSize.width - popupWidth - 8);

                          // ?�하 ?�치: ?�면 ?�단 55% ?�하�??�에 ?�시
                          final bool showAbove = _tappedTowerScreenPos.dy > screenSize.height * 0.55;
                          final top = showAbove
                              ? (_tappedTowerScreenPos.dy - _tappedTowerHeight / 2 - popupHeight - gap)
                                  .clamp(topPadding, screenSize.height - popupHeight - bottomPadding)
                              : (_tappedTowerScreenPos.dy + _tappedTowerHeight / 2 + gap)
                                  .clamp(topPadding, screenSize.height - popupHeight - bottomPadding);

                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onTap: () {}, // ?�업 ?��? ?�릭 ???�기 방�?
                              child: SizedBox(
                                width: popupWidth,
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
                                        _handleTowerAction(tower, action);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // ?�?� ?�이�??�내 & 쿨다???�?�
            Consumer(
              builder: (_, consumerRef, __) {
                final state = consumerRef.watch(gameStateProvider);
                final wm = _game.waveManager;
                return StatefulBuilder(
                  builder: (context, localSetState) {
                    // 300ms 주기�?쿨다??갱신
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted && _currentScreen == 'gameplay') {
                        localSetState(() {});
                      }
                    });

                    // 쿨다??카운?�다???�시
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

                    // ?�이�??�작 배너 (?�이�??�성 ???�시 ?�시)
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
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                );
              },
            ),

            // ?�시?��? 메뉴 ?�버?�이
            if (_game.isPaused)
              Positioned.fill(
                child: Container(
                  color: const Color(0xCC000000),
                  child: Center(
                    child: Container(
                      width: 280 * Responsive.uiScale(context),
                      padding: EdgeInsets.symmetric(
                        vertical: 32 * Responsive.uiScale(context),
                        horizontal: 24 * Responsive.uiScale(context),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause_circle_outline,
                              color: const Color(0xFF8B5CF6), size: 48 * Responsive.uiScale(context)),
                          SizedBox(height: 12 * Responsive.uiScale(context)),
                          Text('?�시?��?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.fontSize(context, 22),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              )),
                          SizedBox(height: 8 * Responsive.uiScale(context)),
                          // 경과 ?�간 (?�에??HUD?�서 ?�겨졌으므�??�기???�시)
                          Consumer(
                            builder: (_, consumerRef, __) {
                              final gs = consumerRef.watch(gameStateProvider);
                              final mins = gs.elapsedSeconds ~/ 60;
                              final secs = gs.elapsedSeconds % 60;
                              return Text(
                                '??${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: Responsive.fontSize(context, 13),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16 * Responsive.uiScale(context)),
                          // SFX / BGM ?��? (??�� ?�시)
                          StatefulBuilder(
                            builder: (ctx, localSetState) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSoundToggle(
                                    icon: SoundManager.instance.sfxEnabled
                                        ? Icons.volume_up
                                        : Icons.volume_off,
                                    label: 'SFX',
                                    active: SoundManager.instance.sfxEnabled,
                                    onTap: () {
                                      SoundManager.instance.toggleSfx();
                                      localSetState(() {});
                                    },
                                  ),
                                  SizedBox(width: 16 * Responsive.uiScale(context)),
                                  _buildSoundToggle(
                                    icon: SoundManager.instance.bgmEnabled
                                        ? Icons.music_note
                                        : Icons.music_off,
                                    label: 'BGM',
                                    active: SoundManager.instance.bgmEnabled,
                                    onTap: () {
                                      SoundManager.instance.toggleBgm();
                                      localSetState(() {});
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 20 * Responsive.uiScale(context)),
                          // 계속?�기 버튼
                          _buildPauseMenuButton(
                            icon: Icons.play_arrow_rounded,
                            label: '계속?�기',
                            color: const Color(0xFF10B981),
                            onTap: () {
                              _game.togglePause();
                              setState(() {});
                            },
                          ),
                          SizedBox(height: 12 * Responsive.uiScale(context)),
                          // ?�시??버튼
                          _buildPauseMenuButton(
                            icon: Icons.refresh_rounded,
                            label: '처음부??,
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              _showConfirmDialog(
                                title: '?�시??,
                                message: '처음부???�시 ?�작?�시겠습?�까?',
                                onConfirm: () {
                                  _game.togglePause();
                                  _restartLevel();
                                },
                              );
                            },
                          ),
                          SizedBox(height: 12 * Responsive.uiScale(context)),
                          // 메뉴�??��?�?버튼
                          _buildPauseMenuButton(
                            icon: Icons.home_rounded,
                            label: '메뉴�??��?�?,
                            color: const Color(0xFFEF4444),
                            onTap: () {
                              _showConfirmDialog(
                                title: '?��?�?,
                                message: '메뉴�??�아가?�겠?�니�?\n?�재 진행 ?�황?� ?�라집니??',
                                onConfirm: () {
                                  _game.togglePause();
                                  _returnToMenu();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ?�?� ?�???�택 ?�널 ?�?�
            TowerSelectPanel(
              selectedTower: _selectedTower,
              onTowerSelected: _onTowerSelected,
            ),

            // ?�?� ?�웅 ?�킬 ?�널 (?�측 ?�단) ?�?�
            _buildHeroSkillPanel(),

            // ?�?� ?�버 ?�팁 (?�???�그?�이???�업 ?�려?�으�??��?) ?�?�
            if (_tooltipData != null && !_showTutorial && _tappedTower == null)
              GameTooltip(
                data: _tooltipData!,
                position: _mousePosition,
              ),

            // ?�?� ?�토리얼 ?�버?�이 ?�?�
            if (_showTutorial)
              Positioned.fill(
                child: TutorialOverlay(
                  steps: const [
                    TutorialStep(
                      title: '?�영?�니?? 마스??',
                      content: '?�원??문에 ?�신 것을 ?�영?�니??\n먼�?, ?�장 ?�측 ?�단??[?�???�이�????�릭?�거???�래그하??배치 ?�역???�아보세??',
                      tooltipOffset: Offset(100, 100),
                    ),
                    TutorialStep(
                      title: '?�혼???�근',
                      content: '밤이 ?�면 ?�혼??몬스?��? 출몰?�니??\n?�혼??몬스?�는 [?�화] ?�성 ?�???��? ?? ?��? [마법] ?�성 ?�?�에 ?�합?�다.',
                      tooltipOffset: Offset(100, 100),
                    ),
                    TutorialStep(
                      title: '?�웅????,
                      content: '배치???�웅?� 강력???�킬??보유?�고 ?�습?�다.\n쿨�??�이 차면 ?�측 ?�단???�킬 ?�이콘을 ?�러 ?�황???�집?�세??',
                      tooltipOffset: Offset(100, 100),
                    ),
                  ],
                  onFinish: () {
                    setState(() {
                      _showTutorial = false;
                    });
                    ref.read(userStateProvider.notifier).completeTutorial();
                    _game.resumeEngine(); // 게임 ?�개
                  },
                ),
              ),
          ],
        ),
      ),
    ));
  }
}
