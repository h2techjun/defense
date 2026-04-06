// 해원의 문 - 게임 화면 (메인메뉴 ↔ 게임플레이 전환)
// main.dart에서 분리 (P0-1 리팩토링)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_riverpod/flame_riverpod.dart';

import 'common/enums.dart';
import 'common/debug_log.dart';
import 'data/game_data_loader.dart';
import 'data/models/wave_data.dart';
import 'data/models/story_data.dart';
import 'data/models/achievement_data.dart';
import 'game/defense_game.dart';
import 'game/components/towers/base_tower.dart';
import 'audio/sound_manager.dart';
import 'state/game_state.dart';
import 'state/user_state.dart';
import 'state/daily_quest_provider.dart';
import 'state/skin_provider.dart';
import 'state/achievement_provider.dart';
import 'services/ad_manager.dart';
import 'services/cloud_save_manager.dart';
import 'services/crazygames.dart';
import 'l10n/app_strings.dart';
import 'ui/dialogs/hero_unlock_dialog.dart';
import 'ui/dialogs/story_cutscene_dialog.dart';
import 'ui/dialogs/tower_upgrade_dialog.dart';
import 'ui/menus/main_menu.dart';
import 'ui/menus/stage_select_screen.dart';
import 'ui/menus/hero_manage/hero_manage_screen.dart';
import 'ui/menus/tower_manage_screen.dart';
import 'ui/menus/skin_shop_screen.dart';
import 'ui/menus/endless_tower_screen.dart';
import 'ui/menus/season_pass_screen.dart';
import 'ui/menus/achievement_screen.dart';
import 'ui/menus/daily_quest_screen.dart';
import 'ui/menus/lore_collection_screen.dart';
import 'ui/menus/hero_deploy_screen.dart';
import 'ui/gameplay/gameplay_scaffold.dart';

/// 게임 화면 (메인메뉴 ↔ 게임 전환)
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late DefenseGame _game;
  String _currentScreen = 'mainMenu';
  LevelData? _currentLevel;
  bool _showTutorial = false;
  GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>> _gameWidgetKey =
      GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>>();

  // 앱 라이프사이클 — 백그라운드 전환 시 자동 일시정지 추적
  bool _pausedByLifecycle = false;

  /// 현재 언어
  GameLanguage get _currentLang => ref.read(gameLanguageProvider);

  // ── 라이프사이클 ──

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    dlog('🚀 [GameScreen] initState 시작');
    _game = DefenseGame();
    // 세이브 데이터 로드 + 클라우드 동기화
    Future.microtask(() async {
      dlog('🚀 [GameScreen] 세이브 데이터 로드 시작');
      await ref.read(userStateProvider.notifier).loadFromSave();
      await ref.read(dailyQuestProvider.notifier).loadFromSave();
      await ref.read(skinProvider.notifier).loadFromSave();
      dlog('🚀 [GameScreen] 세이브 데이터 로드 완료');

      try {
        final result = await CloudSaveManager.instance.appStartSync();
        dlog('☁️ [GameScreen] 클라우드 동기화 결과: $result');
        if (result == CloudSyncResult.success) {
          await ref.read(userStateProvider.notifier).loadFromSave();
          dlog('☁️ [GameScreen] 클라우드 데이터 반영 완료');
        }
      } on Exception catch (e) {
        dlog('☁️ [GameScreen] 클라우드 동기화 스킵: $e');
      }

      // CrazyGames: 로딩 완료 + 게임플레이 시작
      CrazyGamesService.loadingStop();
      CrazyGamesService.gameplayStart();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    dlog('📱 [GameScreen] 앱 라이프사이클 전환: $state');
    if (_currentScreen != 'gameplay') return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (!_game.isPaused && _game.isGameRunning) {
          dlog('📱 [GameScreen] 백그라운드 전환 → 자동 일시정지');
          _game.togglePause();
          _pausedByLifecycle = true;
          setState(() {});
        }
        break;
      case AppLifecycleState.resumed:
        if (_pausedByLifecycle) {
          dlog('📱 [GameScreen] 포그라운드 복귀 → 일시정지 메뉴 유지');
          _pausedByLifecycle = false;
          setState(() {});
        }
        break;
      default:
        break;
    }
  }

  // ── 화면 전환 ──

  void _navigateTo(String screen, {LevelData? level}) {
    setState(() {
      _currentScreen = screen;
      if (level != null) _currentLevel = level;
    });
  }

  // ── 게임 리셋 (재시작/다음스테이지/메뉴복귀 공용) ──

  void _resetGame() {
    _game = DefenseGame();
    _gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>>();
  }

  // ── 레벨 시작 / 종료 ──

  void _startLevel(LevelData level, {GameMode mode = GameMode.campaign}) {
    _navigateTo('gameplay', level: level);

    void startGame() {
      Future.microtask(() {
        SoundManager.instance.stopBgm();
        _game.startLevel(level, mode: mode);

        final userState = ref.read(userStateProvider);
        if (mode == GameMode.campaign && level.levelNumber == 1 && !userState.hasCompletedTutorial) {
          setState(() { _showTutorial = true; });
          _game.pauseEngine();
        }
      });
    }

    // 캠페인 모드 스토리 컷씬 분기
    if (mode == GameMode.campaign) {
      final scenes = _getStoryScenes(level.levelNumber);
      if (scenes != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => StoryCutsceneDialog(
            scenes: scenes,
            onFinish: () {
              Navigator.of(ctx).pop();
              startGame();
            },
          ),
        );
        return;
      }
    }

    startGame();
  }

  List<StoryScene>? _getStoryScenes(int levelNumber) {
    switch (levelNumber) {
      case 1:  return StoryData.introSequence;
      case 21: return StoryData.ep1ToEp2;
      case 41: return StoryData.ep2ToEp3;
      case 61: return StoryData.ep3ToEp4;
      case 81: return StoryData.ep4ToEp5;
      default: return null;
    }
  }

  void _returnToMenu() {
    final returnScreen = (_game.currentGameMode == GameMode.endlessTower ||
        _game.currentGameMode == GameMode.dailyChallenge)
        ? 'endlessTower'
        : 'stageSelect';
    _resetGame();
    _navigateTo(returnScreen);
    ref.read(gameStateProvider.notifier).setPhase(GamePhase.mainMenu);
    SoundManager.instance.stopBgm();
    SoundManager.instance.playBgm(BgmType.menu);
  }

  void _restartLevel() {
    if (_currentLevel == null) return;
    _game.overlays.remove('GameOverOverlay');
    _game.overlays.remove('VictoryOverlay');
    _resetGame();
    setState(() {});
    Future.microtask(() {
      _game.startLevel(_currentLevel!);
    });
  }

  void _goToNextStage() async {
    if (_currentLevel == null) return;



    final levels = GameDataLoader.getAllLevels();
    final currentIndex = levels.indexWhere(
      (l) => l.levelNumber == _currentLevel!.levelNumber,
    );
    if (currentIndex >= 0 && currentIndex < levels.length - 1) {
      final nextLevel = levels[currentIndex + 1];
      _game.overlays.remove('VictoryOverlay');
      _resetGame();
      setState(() {});
      _startLevel(nextLevel);
    } else {
      _returnToMenu();
    }
  }

  // ── 광고 보상 ──

  Future<void> _handleAdRevive() async {
    final reward = await AdManager.instance.showRewardedAd(
      purpose: RewardedAdPurpose.revive,
    );
    if (reward != null && mounted) {
      final maxHp = ref.read(gameStateProvider).maxGatewayHp;
      ref.read(gameStateProvider.notifier).reviveGateway((maxHp * 0.5).toInt());
      _game.overlays.remove('GameOverOverlay');
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get(_currentLang, 'msg_revive')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleAdDoubleReward() async {
    final reward = await AdManager.instance.showRewardedAd(
      purpose: RewardedAdPurpose.doubleReward,
    );
    if (reward != null && mounted) {
      ref.read(userStateProvider.notifier).addGems(30);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get(_currentLang, 'msg_double_reward')),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── 진행 저장 ──

  void _saveProgress() {
    if (_currentLevel == null) return;
    final gameState = ref.read(gameStateProvider);
    if (gameState.phase != GamePhase.victory) return;

    final chapter = _getChapterForLevel(_currentLevel!.levelNumber);
    ref.read(userStateProvider.notifier).completeLevel(
      chapter,
      _currentLevel!.levelNumber,
      gameState.starRating,
    );
    dlog('[SAVE] Ch.$chapter 스테이지 ${_currentLevel!.levelNumber} 클리어! 별: ${gameState.starRating}');

    // 영웅 해금 체크
    final userState = ref.read(userStateProvider);
    final newlyUnlocked = <HeroId>[];
    for (final entry in heroUnlockStage.entries) {
      if (entry.value > 0 &&
          entry.value <= _currentLevel!.levelNumber &&
          !userState.unlockedHeroes.contains(entry.key)) {
        ref.read(userStateProvider.notifier).unlockHero(entry.key);
        newlyUnlocked.add(entry.key);
        dlog('[UNLOCK] 영웅 해금: ${entry.key.name} (Stage ${entry.value} 조건 충족)');
      }
    }

    if (newlyUnlocked.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (!mounted) return;
        for (final heroId in newlyUnlocked) {
          if (!mounted) break;
          await showHeroUnlockDialog(context, heroId);
        }
      });
    }
  }

  int _getChapterForLevel(int levelNumber) {
    if (levelNumber <= 20) return 1;
    if (levelNumber <= 40) return 2;
    if (levelNumber <= 60) return 3;
    if (levelNumber <= 80) return 4;
    return 5;
  }

  // ── 타워 액션 ──

  void _handleTowerAction(BaseTower tower, TowerActionResult action) {
    final stateNotifier = ref.read(gameStateProvider.notifier);

    switch (action) {
      case TowerSellResult():
        stateNotifier.addSinmyeong(tower.sellRefund);
        final slotIndex = _game.gameMap.findSlotAt(tower.position);
        if (slotIndex != null) {
          _game.gameMap.freeSlot(slotIndex);
        }
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
        }
        break;
    }
  }

  // ── 빌드 ──

  @override
  Widget build(BuildContext context) {
    // 업적 달성 알림 리스너
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
                          Text(AppStrings.get(_currentLang, 'msg_achievement'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(achievement.name, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('💎${achievement.rewardGems}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                backgroundColor: const Color(0xFF6633AA),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
            SoundManager.instance.playSfx(SfxType.uiUpgrade);
          }
        } on Exception catch (e) {
          dlog('[GameScreen] 업적 달성 알림 처리 오류: $e');
        }
      }
    });

    // ── 메뉴 화면 라우팅 ──
    final menuWidget = _buildMenuScreen();
    if (menuWidget != null) return menuWidget;

    // ── 게임플레이 ──
    return GameplayScaffold(
      game: _game,
      gameWidgetKey: _gameWidgetKey,
      onRetry: _restartLevel,
      onMenu: _returnToMenu,
      onSaveAndMenu: () { _saveProgress(); _returnToMenu(); },
      onSaveAndReplay: () { _saveProgress(); _restartLevel(); },
      onSaveAndNext: () { _saveProgress(); _goToNextStage(); },
      onRevive: _handleAdRevive,
      onDoubleReward: _handleAdDoubleReward,
      onTowerAction: _handleTowerAction,
      showTutorial: _showTutorial,
      onTutorialFinish: () {
        setState(() { _showTutorial = false; });
        ref.read(userStateProvider.notifier).completeTutorial();
        _game.resumeEngine();
      },
    );
  }

  /// 메뉴 화면 빌드 — gameplay이면 null 반환
  Widget? _buildMenuScreen() {
    switch (_currentScreen) {
      case 'mainMenu':
        SoundManager.instance.init().then((_) {
          SoundManager.instance.playBgm(BgmType.menu);
        }).catchError((e) {
          dlog('⚠️ [GameScreen] SoundManager 초기화/BGM 실패: $e');
        });
        return MainMenu(
          onStageSelect:   () => _navigateTo('stageSelect'),
          onHeroManage:    () => _navigateTo('heroManage'),
          onTowerManage:   () => _navigateTo('towerManage'),
          onSkinShop:      () => _navigateTo('skinShop'),
          onEndlessTower:  () => _navigateTo('endlessTower'),
          onSeasonPass:    () => _navigateTo('seasonPass'),
          onAchievement:   () => _navigateTo('achievement'),
          onDailyQuest:    () => _navigateTo('dailyQuest'),
          onLoreCollection:() => _navigateTo('loreCollection'),
        );
      case 'towerManage':
        return TowerManageScreen(onBack: () => _navigateTo('mainMenu'));
      case 'skinShop':
        return SkinShopScreen(onBack: () => _navigateTo('mainMenu'));
      case 'endlessTower':
        return EndlessTowerScreen(
          onBack: () => _navigateTo('mainMenu'),
          onStartLevel: (level, mode) => _startLevel(level, mode: mode),
        );
      case 'seasonPass':
        return SeasonPassScreen(onBack: () => _navigateTo('mainMenu'));
      case 'achievement':
        return AchievementScreen(onBack: () => _navigateTo('mainMenu'));
      case 'dailyQuest':
        return DailyQuestScreen(onBack: () => _navigateTo('mainMenu'));
      case 'loreCollection':
        return LoreCollectionScreen(onBack: () => _navigateTo('mainMenu'));
      case 'heroManage':
        return HeroManageScreen(onBack: () => _navigateTo('mainMenu'));
      case 'stageSelect':
        return StageSelectScreen(
          onBack: () => _navigateTo('mainMenu'),
          onLevelSelected: (level) => _navigateTo('heroDeploy', level: level),
        );
      case 'heroDeploy':
        if (_currentLevel != null) {
          return HeroDeployScreen(
            level: _currentLevel!,
            onBack: () => _navigateTo('stageSelect'),
            onStartBattle: _startLevel,
          );
        }
        return null;
      default:
        return null; // gameplay → GameplayScaffold 사용
    }
  }
}
