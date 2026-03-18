// 해원의 문 - 게임 화면 (메인메뉴 ↔ 게임플레이 전환)
// main.dart에서 분리 (P0-1 리팩토링)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flame/components.dart';

import 'common/enums.dart';
import 'common/constants.dart';
import 'ui/theme/app_colors.dart';
import 'data/game_data_loader.dart';
import 'data/models/wave_data.dart';
import 'ui/dialogs/hero_unlock_dialog.dart';
import 'game/defense_game.dart';
import 'game/components/towers/base_tower.dart';
import 'audio/sound_manager.dart';
import 'state/game_state.dart';
import 'state/user_state.dart';
import 'services/ad_manager.dart';
import 'ui/menus/main_menu.dart';
import 'ui/menus/stage_select_screen.dart';
import 'ui/menus/hero_manage_screen.dart';
import 'ui/menus/tower_manage_screen.dart';
import 'ui/menus/skin_shop_screen.dart';
import 'ui/menus/endless_tower_screen.dart';
import 'ui/menus/season_pass_screen.dart';
import 'ui/menus/achievement_screen.dart';

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

/// 게임 화면 (메인메뉴 ↔ 게임 전환)
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

  bool _showTutorial = false; // 튜토리얼 표시 여부
  GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>> _gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>>();

  // 툴팁 상태
  GameTooltipData? _tooltipData;
  Offset _mousePosition = Offset.zero;

  // 타워 업그레이드 팝업 상태
  BaseTower? _tappedTower;
  Offset _tappedTowerScreenPos = Offset.zero;
  double _tappedTowerHeight = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 [GameScreen] initState 시작');
    _game = DefenseGame();
    _setupGameCallbacks();
    // 세이브 데이터 로드
    Future.microtask(() async {
      debugPrint('🚀 [GameScreen] 세이브 데이터 로드 시작');
      await ref.read(userStateProvider.notifier).loadFromSave();
      await ref.read(dailyQuestProvider.notifier).loadFromSave();
      await ref.read(skinProvider.notifier).loadFromSave();
      debugPrint('🚀 [GameScreen] 세이브 데이터 로드 완료');
    });
  }

  void _setupGameCallbacks() {
    // 타워 클릭 → 판매/업그레이드 다이얼로그
    _game.onTowerTappedCallback = (tower) {
      _showTowerDialog(tower);
    };
    // 타워 설치 후 선택 해제
    _game.onTowerPlacedCallback = () {
      setState(() {
        _selectedTower = null;
      });
    };
    // 호버 툴팁
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

  /// 호버 정보 → 툴팁 데이터 변환
  GameTooltipData _buildTooltipFromInfo(Map<String, dynamic> info) {
    final type = info['type'] as String;
    if (type == 'tower') {
      return GameTooltipData(
        title: info['name'] as String? ?? '타워',
        subtitle: 'Lv.${info['level']}',
        description: info['description'] as String?,
        color: _getTowerColor(info['towerType'] as TowerType),
        icon: _getTowerIcon(info['towerType'] as TowerType),
        imagePath: info['imagePath'] as String?,
        stats: [
          TooltipStat('공격력', '${(info['damage'] as double).toStringAsFixed(0)}'),
          TooltipStat('사거리', '${(info['range'] as double).toStringAsFixed(0)}'),
          TooltipStat('공격속도', '${(info['fireRate'] as double).toStringAsFixed(2)}/s'),
          if (info['specialAbility'] != null)
            TooltipStat('특수', info['specialAbility'] as String, highlight: true),
        ],
      );
    } else if (type == 'hero') {
      // 영웅 툴팁
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
        description: '🎯 ${info['skillName']}\n${info['skillDesc']}\n⏱ 쿨타임: ${info['skillCooldown']}초',
        color: Color(colorInt),
        icon: info['emoji'] as String? ?? '⚔️',
        imagePath: info['imagePath'] as String?,
        stats: [
          TooltipStat('HP', '${info['hp']} / ${info['maxHp']}',
            highlight: isDead),
          TooltipStat('공격력', info['attack'] as String? ?? '-'),
          TooltipStat('사거리', info['range'] as String? ?? '-'),
          TooltipStat('속성', info['damageType'] as String? ?? '-'),
          TooltipStat('경험치', xpText, highlight: heroLevel >= heroMaxLevel),
          if (isDead)
            TooltipStat('상태', '💀 부활 대기', highlight: true),
        ],
      );
    } else {
      // 적
      return GameTooltipData(
        title: info['name'] as String? ?? '적',
        subtitle: 'HP: ${info['hp']}',
        description: info['description'] as String?,
        color: (info['isBerserk'] as bool? ?? false)
            ? const Color(0xFFFF4500)
            : const Color(0xFFCC3333),
        icon: '👻',
        stats: [
          TooltipStat('속도', info['speed'] as String? ?? ''),
          TooltipStat('보상', '✨${info['reward']}'),
          if ((info['abilities'] as String? ?? '').isNotEmpty)
            TooltipStat('능력', info['abilities'] as String, highlight: true),
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

  void _startLevel(LevelData level, {GameMode mode = GameMode.campaign}) {
    setState(() {
      _currentScreen = 'gameplay';
      _currentLevel = level;
    });

    void startGame() {
      Future.microtask(() {
        SoundManager.instance.stopBgm();
        _game.startLevel(level, mode: mode);

        // 튜토리얼 트리거 (캠페인 1스테이지 & 미완료 시)
        final userState = ref.read(userStateProvider);
        if (mode == GameMode.campaign && level.levelNumber == 1 && !userState.hasCompletedTutorial) {
          setState(() {
            _showTutorial = true;
          });
          _game.pauseEngine(); // 튜토리얼이 떠있는 동안 엔진 정지
        }
      });
    }

    // 캠페인 모드일 경우 레벨 조건에 따라 스토리 컷씬 재생 분기
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
        return; // 다이얼로그 콜백에서 실제 게임을 시작하도록 대기
      }
    }

    startGame();
  }

  void _returnToMenu() {
    setState(() {
      if (_game.currentGameMode == GameMode.endlessTower || _game.currentGameMode == GameMode.dailyChallenge) {
        _currentScreen = 'endlessTower';
      } else {
        _currentScreen = 'stageSelect';
      }
      _selectedTower = null;
    });
    _game = DefenseGame();
    _gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>>();
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
    _gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>>();
    _setupGameCallbacks();
    setState(() {
      _selectedTower = null;
    });
    Future.microtask(() {
      _game.startLevel(_currentLevel!);
    });
  }

  void _goToNextStage() async {
    if (_currentLevel == null) return;

    // 전면 광고 (3판마다)
    AdManager.instance.recordStageComplete();
    if (AdManager.instance.shouldShowInterstitial) {
      await AdManager.instance.showInterstitialAd();
    }

    final levels = GameDataLoader.getAllLevels();
    final currentIndex = levels.indexWhere(
      (l) => l.levelNumber == _currentLevel!.levelNumber,
    );
    if (currentIndex >= 0 && currentIndex < levels.length - 1) {
      final nextLevel = levels[currentIndex + 1];
      _game.overlays.remove('VictoryOverlay');
      _game = DefenseGame();
      _gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>>();
      _setupGameCallbacks();
      setState(() {
        _selectedTower = null;
      });
      _startLevel(nextLevel);
    } else {
      // 마지막 스테이지 → 메뉴 복귀
      _returnToMenu();
    }
  }

  /// 광고 보고 부활 (패배 시 HP 50% 회복)
  Future<void> _handleAdRevive() async {
    final reward = await AdManager.instance.showRewardedAd(
      purpose: RewardedAdPurpose.revive,
    );
    if (reward != null && mounted) {
      // 게이트웨이 HP 50% 회복
      final maxHp = ref.read(gameStateProvider).maxGatewayHp;
      ref.read(gameStateProvider.notifier).reviveGateway((maxHp * 0.5).toInt());
      _game.overlays.remove('GameOverOverlay');
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💚 부활! 게이트웨이 HP가 50% 회복되었습니다!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 광고 보고 보상 2배 (승리 시 보석 추가)
  Future<void> _handleAdDoubleReward() async {
    final reward = await AdManager.instance.showRewardedAd(
      purpose: RewardedAdPurpose.doubleReward,
    );
    if (reward != null && mounted) {
      // 보석 30개 추가 지급 (2배 보상)
      ref.read(userStateProvider.notifier).addGems(30);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ 보상 2배! 💎 보석 30개 추가 획득!'),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 레벨 번호로 챕터 번호 계산
  int _getChapterForLevel(int levelNumber) {
    if (levelNumber <= 20) return 1;
    if (levelNumber <= 40) return 2;
    if (levelNumber <= 60) return 3;
    if (levelNumber <= 80) return 4;
    return 5;
  }

  /// 승리 시 진행 상황 저장
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
      debugPrint('[SAVE] Ch.$chapter 스테이지 ${_currentLevel!.levelNumber} 클리어! 별: ${gameState.starRating}');

      // 영웅 해금 체크
      final userState = ref.read(userStateProvider);
      final newlyUnlocked = <HeroId>[];
      for (final entry in heroUnlockStage.entries) {
        if (entry.value > 0 &&
            entry.value <= _currentLevel!.levelNumber &&
            !userState.unlockedHeroes.contains(entry.key)) {
          ref.read(userStateProvider.notifier).unlockHero(entry.key);
          newlyUnlocked.add(entry.key);
          debugPrint('[UNLOCK] 영웅 해금: ${entry.key.name} (Stage ${entry.value} 조건 충족)');
        }
      }

      // 해금 축하 팝업 표시 (승리 화면 위에 순차 표시)
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
      // 토글: 같은 타워를 다시 누르면 해제
      if (_selectedTower == type) {
        _selectedTower = null;
        _game.selectedTowerType = null;
      } else {
        _selectedTower = type;
        _game.selectedTowerType = type;
      }
    });
  }

  /// 배치된 타워 클릭 시 → 판매/업그레이드 다이얼로그
  void _showTowerDialog(BaseTower tower) {
    // 타워 선택 중이면 무시 (배치 모드)
    if (_selectedTower != null) return;

    // 타워의 게임 좌표 → 화면 좌표 변환
    final gameWidgetBox = _gameWidgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (gameWidgetBox == null) return;

    // Flame 카메라를 이용하여 월드 좌표를 게임 위젯(Canvas) 기준 로컬 좌표로 변환
    // BaseTower는 Anchor.center를 사용하므로 position이 이미 중심을 의미합니다.
    final Vector2 centerWorldPos = tower.position;
    final Vector2 canvasPos = _game.camera.localToGlobal(centerWorldPos);

    // 타워 크기도 화면 배율에 맞게 조정 (카메라 줌 적용)
    // GameWidget이 꽉 채워지지 않고 letterbox가 생겼을 수 있으므로 그 부분도 고려됩니다.
    final towerHeight = tower.size.y * _game.camera.viewfinder.zoom;

    // GameWidget 기준 로컬 좌표가 곧 Stack 내의 좌상단 기준 좌표와 동일합니다.
    // (Positioned.fill 내부에 GameWidget이 있기 때문)
    final localPos = Offset(canvasPos.x, canvasPos.y);

    setState(() {
      _tappedTower = tower;
      _tappedTowerScreenPos = localPos;
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

  /// 타워 액션 처리 (판매/업그레이드/분기)
  void _handleTowerAction(BaseTower tower, TowerActionResult action) {
    final stateNotifier = ref.read(gameStateProvider.notifier);

    switch (action) {
      case TowerSellResult():
        // 환불 금액 추가
        stateNotifier.addSinmyeong(tower.sellRefund);
        // 슬롯 해제
        final slotIndex = _game.gameMap.findSlotAt(tower.position);
        if (slotIndex != null) {
          _game.gameMap.freeSlot(slotIndex);
        }
        // 타워 제거
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
        // 레벨 3까지 순차 업그레이드 (비용 순차 차감)
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
          // selectBranch 내부에서 upgradeLevel = 4 설정 완료
        }
        break;
    }
  }

  /// 일시정지 메뉴 버튼 빌더
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

  /// 사운드 토글 버튼 빌더 (일시정지 메뉴용)
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

  /// 영웅 스킬 패널 빌더 (실시간 상태 반영)
  Widget _buildHeroSkillPanel() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: StatefulBuilder(
        builder: (context, localSetState) {
          // 250ms마다 영웅 상태 갱신
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

            // HeroId → 파일명 매핑
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

  /// 영웅 ID별 이모지
  String _getHeroEmoji(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:
        return '👹'; // 도깨비
      case HeroId.miho:
        return '🦊'; // 여우
      case HeroId.gangrim:
        return '💀'; // 저승차사
      case HeroId.sua:
        return '🌊'; // 물의 정령
      case HeroId.bari:
        return '🌸'; // 바리공주
    }
  }


  /// 확인 다이얼로그 (재시작/나가기 등 비가역 액션)
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
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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
                          const Text('🏆 업적 달성!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            // 효과음 재생 (SFX)
            SoundManager.instance.playSfx(SfxType.uiUpgrade);
          }
        } catch (_) {}
      }
    });

    // 메인 메뉴
    if (_currentScreen == 'mainMenu') {
      // 메뉴 BGM 재생 (에러 안전 처리 — 웹에서 타임아웃 방지)
      SoundManager.instance.init().then((_) {
        SoundManager.instance.playBgm(BgmType.menu);
      }).catchError((e) {
        debugPrint('⚠️ [GameScreen] SoundManager 초기화/BGM 실패: $e');
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

    // 타워 관리
    if (_currentScreen == 'towerManage') {
      return TowerManageScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      );
    }

    // 스킨 상점
    if (_currentScreen == 'skinShop') {
      return SkinShopScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      );
    }

    // 무한의 탑
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
      );
    }

    // 시즌 패스
    if (_currentScreen == 'seasonPass') {
      return SeasonPassScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      );
    }

    // 업적 & 랭킹
    if (_currentScreen == 'achievement') {
      return AchievementScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      );
    }



    // 일일 미션
    if (_currentScreen == 'dailyQuest') {
      return DailyQuestScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      );
    }

    // 설화도감
    if (_currentScreen == 'loreCollection') {
      return LoreCollectionScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      );
    }

    // 영웅 관리
    if (_currentScreen == 'heroManage') {
      return HeroManageScreen(
        onBack: () {
          setState(() {
            _currentScreen = 'mainMenu';
          });
        },
      );
    }

    // 스테이지 선택
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
      );
    }

    // 출전 준비 화면
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
            // ── Flame 게임 위젯 (드래그 타겟) ──
            Positioned.fill(
              child: DragTarget<TowerType>(
                onAcceptWithDetails: (details) {
                  // RenderBox를 통해 게임 위젯 기준 로컬 좌표 획득
                  final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final s = Responsive.scale(context);
                    // DragTarget accepts details.offset which is the local touch position.
                    // We must reverse the Responsive UI scale factor before passing to Flame's native resolution.
                    final centerPos = details.offset; //Offset(details.offset.dx / s, details.offset.dy / s);
                    final localPos = renderBox.globalToLocal(centerPos);
                    
                    debugPrint('[DRAG DEBUG] Raw details.offset: ${details.offset}');
                    debugPrint('[DRAG DEBUG] Reverse S: $s => centerPos: $centerPos');
                    debugPrint('[DRAG DEBUG] renderBox.globalToLocal => $localPos');
                    
                    _game.handleDragDrop(localPos, details.data, renderBox.size);
                  } else {
                    final s = Responsive.scale(context);
                    final centerPos = Offset(details.offset.dx / s, details.offset.dy / s);
                    _game.handleDragDrop(centerPos, details.data, null);
                  }
                  // 드래그 후 선택 상태 초기화 (UI 업데이트)
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
                            onRevive: () => _handleAdRevive(),
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
                            onDoubleReward: () => _handleAdDoubleReward(),
                          ),
                    },
                  );
                },
              ),
            ),

            // ── HUD 오버레이 ──
            Builder(
              builder: (context) {
                // 광고 사이드 마진 계산 (AdSideBanners와 동일 공식)
                final screenW = MediaQuery.of(context).size.width;
                final screenH = MediaQuery.of(context).size.height;
                final visibleH = GameConstants.gameHeight + 120;
                final tileW = screenH * (GameConstants.gameWidth / visibleH);
                final adMargin = ((screenW - tileW) / 2).clamp(0.0, 300.0);
                final effectiveMargin = adMargin >= 60 ? adMargin : 0.0;

                return GameHud(
                  horizontalPadding: effectiveMargin,
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
                          content: Text('🔒 상점에서 아무 상품을 구매하면 2배속이 해금됩니다!'),
                          backgroundColor: Color(0xFF6633AA),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    _game.cycleGameSpeed();
                    ref.read(gameStateProvider.notifier).setGameSpeed(_game.gameSpeed);
                  },
                );
              },
            ),

            // ── 타워 업그레이드 인라인 팝업 ──
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
                          // 팝업 너비: 화면의 42% 이하, 최대 300px
                          final popupWidth = (screenSize.width * 0.42).clamp(220.0, 300.0);
                          // 하단/상단 보호 영역 (타워패널, HUD)
                          final bottomPadding = 80.0;
                          final topPadding = 50.0;

                          // 좌우 위치
                          double left = _tappedTowerScreenPos.dx + (_tappedTowerHeight / 2) + 8;
                          if (left + popupWidth > screenSize.width - 8) {
                            left = _tappedTowerScreenPos.dx - (_tappedTowerHeight / 2) - popupWidth - 8;
                          }
                          left = left.clamp(8.0, screenSize.width - popupWidth - 8);

                          // 세로 위치: 화면 중간~하단 사이에 위치
                          double top = _tappedTowerScreenPos.dy - 40;
                          final maxH = screenSize.height - top - bottomPadding;
                          // maxH가 너무 작으면 위로 올려서 최소 180px 확보
                          if (maxH < 180) {
                            top = screenSize.height - bottomPadding - 180;
                          }
                          top = top.clamp(topPadding, screenSize.height - bottomPadding - 160);
                          final finalMaxH = screenSize.height - top - bottomPadding;

                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onTap: () {}, // 팝업 내부 클릭 시 닫기 방지
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
                                          _handleTowerAction(tower, action);
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
              ),

            // ── 웨이브 안내 & 쿨다운 ──
            Consumer(
              builder: (_, consumerRef, __) {
                final state = consumerRef.watch(gameStateProvider);
                final wm = _game.waveManager;
                return StatefulBuilder(
                  builder: (context, localSetState) {
                    // 300ms 주기로 쿨다운 갱신
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted && _currentScreen == 'gameplay') {
                        localSetState(() {});
                      }
                    });

                    // 쿨다운 카운트다운 표시
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

                    // 웨이브 시작 배너 (웨이브 활성 시 잠시 표시)
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
            ),

            // 일시정지 메뉴 오버레이
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
                          Text('일시정지',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.fontSize(context, 22),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              )),
                          SizedBox(height: 8 * Responsive.uiScale(context)),
                          // 경과 시간 (폰에서 HUD에서 숨겨졌으므로 여기서 표시)
                          Consumer(
                            builder: (_, consumerRef, __) {
                              final gs = consumerRef.watch(gameStateProvider);
                              final mins = gs.elapsedSeconds ~/ 60;
                              final secs = gs.elapsedSeconds % 60;
                              return Text(
                                '⏱ ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: Responsive.fontSize(context, 13),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16 * Responsive.uiScale(context)),
                          // SFX / BGM 토글 (항상 표시)
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
                          // 계속하기 버튼
                          _buildPauseMenuButton(
                            icon: Icons.play_arrow_rounded,
                            label: '계속하기',
                            color: const Color(0xFF10B981),
                            onTap: () {
                              _game.togglePause();
                              setState(() {});
                            },
                          ),
                          SizedBox(height: 12 * Responsive.uiScale(context)),
                          // 재시작 버튼
                          _buildPauseMenuButton(
                            icon: Icons.refresh_rounded,
                            label: '처음부터',
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              _showConfirmDialog(
                                title: '재시작',
                                message: '처음부터 다시 시작하시겠습니까?',
                                onConfirm: () {
                                  _game.togglePause();
                                  _restartLevel();
                                },
                              );
                            },
                          ),
                          SizedBox(height: 12 * Responsive.uiScale(context)),
                          // 메뉴로 나가기 버튼
                          _buildPauseMenuButton(
                            icon: Icons.home_rounded,
                            label: '메뉴로 나가기',
                            color: const Color(0xFFEF4444),
                            onTap: () {
                              _showConfirmDialog(
                                title: '나가기',
                                message: '메뉴로 돌아가시겠습니까?\n현재 진행 상황은 사라집니다.',
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

            // ── 타워 선택 패널 ──
            TowerSelectPanel(
              selectedTower: _selectedTower,
              onTowerSelected: _onTowerSelected,
            ),

            

            // ── 호버 툴팁 (타워 업그레이드 팝업 열려있으면 숨김) ──
            if (_tooltipData != null && !_showTutorial && _tappedTower == null)
              GameTooltip(
                data: _tooltipData!,
                position: _mousePosition,
              ),

            // ── 튜토리얼 오버레이 ──
            if (_showTutorial)
              Positioned.fill(
                child: TutorialOverlay(
                  steps: const [
                    TutorialStep(
                      emoji: '🏯',
                      title: '해원의 문에 오신 것을 환영합니다!',
                      content: '이곳은 이승과 저승 사이의 해원문입니다.\n마스터가 되어 원한의 악귀들을 정화하고\n영혼을 승천시키세요!',
                    ),
                    TutorialStep(
                      emoji: '🗼',
                      title: '타워 배치하기',
                      content: '하단의 타워 아이콘을 길게 누른 뒤\n초록색 배치 슬롯 위에 드래그하세요.\n\n타워는 신명(⚡) 자원으로 건설합니다.\n좋은 위치에 배치하면 전투가 유리해져요!',
                    ),
                    TutorialStep(
                      emoji: '🔥',
                      title: '타워의 속성 (오행)',
                      content: '🔥 화(火) 봉화대 — 범위 공격\n💧 수(水) 선녀천 — 감속/디버프\n🌿 목(木) 당산목 — 다중 타격\n⚔️ 금(金) 종루 — 단일 강타\n🪨 토(土) 서낭당 — 병사 소환\n\n속성 조합이 전략의 핵심입니다!',
                    ),
                    TutorialStep(
                      emoji: '🌙',
                      title: '낮과 밤의 순환',
                      content: '☀️ 낮에는 화·목 타워가 강해집니다.\n🌙 밤에는 수·금 타워가 강해지고\n  스텔스 적이 출몰합니다.\n⏳ 전환기에는 토 타워가 강화됩니다.\n\n시간대에 맞춰 타워를 배치하세요!',
                    ),
                    TutorialStep(
                      emoji: '👻',
                      title: '원혼 정화 시스템',
                      content: '적을 처치하면 원혼이 떨어지고\n자동으로 정화되어 신명(자원)을 획득!\n\n⚠️ 정화가 밀리면 \"곡소리\" 게이지가\n올라가 타워가 약해지고, 100%가 되면\n모든 적이 광폭화합니다!',
                    ),
                    TutorialStep(
                      emoji: '⚔️',
                      title: '영웅의 전투',
                      content: '영웅은 범위 내 적을 자동으로 공격하고\n스킬도 쿨타임이 차면 자동 발동됩니다.\n\n💡 영웅을 터치하면 즉시 스킬 발동!\n드래그하면 위치를 옮길 수 있어요.\n\n준비 되셨나요? 전투를 시작합니다!',
                    ),
                  ],
                  onFinish: () {
                    setState(() {
                      _showTutorial = false;
                    });
                    ref.read(userStateProvider.notifier).completeTutorial();
                    _game.resumeEngine(); // 게임 재개
                  },
                ),
              ),
          ],
        ),
      ),
    ));
  }
}
