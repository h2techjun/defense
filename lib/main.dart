// 해원의 문 (Gateway of Regrets)
// 한국 설화 기반 타워 디펜스 RPG
// Flutter + Flame Engine

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';

import 'common/enums.dart';
import 'data/game_data_loader.dart';
import 'game/defense_game.dart';
import 'state/game_state.dart';
import 'ui/menus/main_menu.dart';
import 'ui/hud/game_hud.dart';
import 'ui/hud/tower_select_panel.dart';
import 'ui/dialogs/game_result_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 가로 모드 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 상태바 숨기기
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const ProviderScope(
      child: HaewonDefenseApp(),
    ),
  );
}

/// 앱 루트
class HaewonDefenseApp extends StatelessWidget {
  const HaewonDefenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '해원의 문',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'NotoSansKR',
        scaffoldBackgroundColor: const Color(0xFF0D0221),
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
  bool _showMainMenu = true;
  TowerType? _selectedTower;

  @override
  void initState() {
    super.initState();
    _game = DefenseGame();
  }

  void _startGame() {
    setState(() {
      _showMainMenu = false;
    });

    // 챕터 1, 레벨 1 시작
    Future.microtask(() {
      _game.startLevel(GameDataLoader.chapter1Level1);
    });
  }

  void _returnToMenu() {
    setState(() {
      _showMainMenu = true;
      _selectedTower = null;
    });
    // 게임 리셋
    _game = DefenseGame();
    ref.read(gameStateProvider.notifier).setPhase(GamePhase.mainMenu);
  }

  void _restartLevel() {
    _game.overlays.remove('GameOverOverlay');
    _game.overlays.remove('VictoryOverlay');
    _game = DefenseGame();
    setState(() {});
    Future.microtask(() {
      _game.startLevel(GameDataLoader.chapter1Level1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMainMenu) {
      return MainMenu(onStartGame: _startGame);
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Flame 게임 위젯 ──
          RiverpodAwareGameWidget<DefenseGame>(
            game: _game,
            overlayBuilderMap: {
              'GameOverOverlay': (context, game) => DefeatOverlay(
                onRetry: _restartLevel,
                onMenu: _returnToMenu,
              ),
              'VictoryOverlay': (context, game) => VictoryOverlay(
                onContinue: _returnToMenu,
                onReplay: _restartLevel,
              ),
            },
          ),

          // ── HUD 오버레이 ──
          GameHud(
            onPause: () {
              // TODO: 일시정지 구현
            },
          ),

          // ── 타워 선택 패널 ──
          TowerSelectPanel(
            selectedTower: _selectedTower,
            onTowerSelected: (type) {
              setState(() {
                _selectedTower = _selectedTower == type ? null : type;
              });
            },
          ),
        ],
      ),
    );
  }
}
