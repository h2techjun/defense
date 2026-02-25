// Gateway of Regrets: Soul Defense (해원문)
// 한국 설화 기반 타워 디펜스 RPG
// Flutter + Flame Engine

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
import 'ui/menus/lore_collection_screen.dart';
import 'state/endless_tower_provider.dart';
import 'ui/hud/game_hud.dart';
import 'ui/hud/tower_select_panel.dart';
import 'ui/hud/hero_skill_panel.dart';
import 'ui/menus/hero_deploy_screen.dart';
import 'ui/dialogs/game_result_dialog.dart';
import 'ui/dialogs/tower_upgrade_dialog.dart';
import 'ui/hud/game_tooltip.dart';
import 'state/user_state.dart';
import 'state/hero_party_provider.dart';
import 'ui/hud/wave_announce_banner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/dialogs/story_cutscene_dialog.dart';
import 'ui/dialogs/tutorial_overlay.dart';
import 'data/models/story_data.dart';
import 'l10n/app_strings.dart';

Future<void> main() async {
  debugPrint('🚀 [main] Flutter app starting...');
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 및 BaaS 클라이언트 동기화
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ [main] .env 파일 로드 실패 (프로덕션 환경에서는 정상): $e');
  }
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // 더미 값이 아닐 때만 실제 DB 초기화
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty && supabaseUrl != 'YOUR_SUPABASE_URL_HERE') {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // 가로 모드 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 상태바 숨기기
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // JSON 데이터 로드 (실패 시 하드코딩 폴백 자동 전환)
  await GameDataLoader.initFromJson();

  // 사용자 언어 설정 복원 및 다국어 로드
  await AppStrings.init(GameLanguage.ko);

  runApp(
    const ProviderScope(
      child: GatewayOfRegretsApp(),
    ),
  );
}

/// 앱 루트
class GatewayOfRegretsApp extends StatelessWidget {
  const GatewayOfRegretsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gateway of Regrets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        colorSchemeSeed: AppColors.cherryBlossom,
        textTheme: GoogleFonts.notoSansKrTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const GameScreen(),
    );
  }
}

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
  bool _isSoundLoaded = false;
  bool _showTutorial = false; // 튜토리얼 표시 여부
  final _gameWidgetKey = GlobalKey<RiverpodAwareGameWidgetState<DefenseGame>>();

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
      case TowerType.archer:   return '🏹';
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
      // 마지막 스테이지 → 메뉴 복귀
      _returnToMenu();
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
      print('[SAVE] Ch.$chapter 스테이지 ${_currentLevel!.levelNumber} 클리어! 별: ${gameState.starRating}');

      // 영웅 해금 체크
      final userState = ref.read(userStateProvider);
      final newlyUnlocked = <HeroId>[];
      for (final entry in heroUnlockStage.entries) {
        if (entry.value > 0 &&
            entry.value <= _currentLevel!.levelNumber &&
            !userState.unlockedHeroes.contains(entry.key)) {
          ref.read(userStateProvider.notifier).unlockHero(entry.key);
          newlyUnlocked.add(entry.key);
          print('[UNLOCK] 영웅 해금: ${entry.key.name} (Stage ${entry.value} 조건 충족)');
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

    final gameWidgetSize = gameWidgetBox.size;
    final gameSize = _game.size;

    // 게임 좌표를 화면 비율로 변환
    final scaleX = gameWidgetSize.width / gameSize.x;
    final scaleY = gameWidgetSize.height / gameSize.y;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // 게임이 화면 중앙에 위치할 때의 오프셋
    final offsetX = (gameWidgetSize.width - gameSize.x * scale) / 2;
    final offsetY = (gameWidgetSize.height - gameSize.y * scale) / 2;

    // 타워 중심 화면 좌표
    final centerX = tower.position.x * scale + offsetX;
    final centerY = tower.position.y * scale + offsetY;
    final towerHeight = tower.size.y * scale;

    // GameWidget의 글로벌 위치 추가
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
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 22),
        label: Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
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
    // 메인 메뉴
    if (_currentScreen == 'mainMenu') {
      // 메뉴 BGM 재생
      SoundManager.instance.init().then((_) {
        SoundManager.instance.playBgm(BgmType.menu);
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

    // 패키지 상점
    if (_currentScreen == 'packageShop') {
      return PackageShopScreen(
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


    return Scaffold(
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
                  // 드롭 위치를 게임 엔진에 전달
                  _game.handleDragDrop(details.offset, details.data);
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

            // ── HUD 오버레이 ──
            GameHud(
              onPause: () {
                _dismissTowerPopup();
                _game.togglePause();
                setState(() {}); // UI 갱신
              },
              onSpeedToggle: () {
                _game.cycleGameSpeed();
                ref.read(gameStateProvider.notifier).setGameSpeed(_game.gameSpeed);
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
                          const popupWidth = 240.0;
                          const popupHeight = 200.0; // 예상 높이
                          const gap = 8.0;

                          // 좌우 위치: 타워 중심 기준
                          final left = (_tappedTowerScreenPos.dx - popupWidth / 2)
                              .clamp(8.0, screenSize.width - popupWidth - 8);

                          // 상하 위치: 화면 하단 55% 이하면 위에 표시
                          final bool showAbove = _tappedTowerScreenPos.dy > screenSize.height * 0.55;
                          final top = showAbove
                              ? (_tappedTowerScreenPos.dy - _tappedTowerHeight / 2 - popupHeight - gap)
                                  .clamp(8.0, screenSize.height - popupHeight - 8)
                              : (_tappedTowerScreenPos.dy + _tappedTowerHeight / 2 + gap)
                                  .clamp(8.0, screenSize.height - popupHeight - 8);

                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onTap: () {}, // 팝업 내부 클릭 시 닫기 방지
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
                      width: 280,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                          const Icon(Icons.pause_circle_outline,
                              color: Color(0xFF8B5CF6), size: 48),
                          const SizedBox(height: 12),
                          const Text('일시정지',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              )),
                          const SizedBox(height: 28),
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
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
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

            // ── 영웅 스킬 패널 (우측 하단) ──
            _buildHeroSkillPanel(),

            // ── 호버 툴팁 ──
            if (_tooltipData != null && !_showTutorial)
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
                      title: '환영합니다, 마스터!',
                      content: '해원의 문에 오신 것을 환영합니다.\n먼저, 전장 우측 하단의 [타워 아이콘]을 클릭하거나 드래그하여 배치 영역에 놓아보세요.',
                      tooltipOffset: Offset(100, 100),
                    ),
                    TutorialStep(
                      title: '원혼의 접근',
                      content: '밤이 되면 영혼형 몬스터가 출몰합니다.\n영혼형 몬스터는 [정화] 속성 타워(솟대 등) 혹은 [마법] 속성 타워에 약합니다.',
                      tooltipOffset: Offset(100, 100),
                    ),
                    TutorialStep(
                      title: '영웅의 힘',
                      content: '배치된 영웅은 강력한 스킬을 보유하고 있습니다.\n쿨타임이 차면 우측 하단의 스킬 아이콘을 눌러 전황을 뒤집으세요!',
                      tooltipOffset: Offset(100, 100),
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
    );
  }
}
