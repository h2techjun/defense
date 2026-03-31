// 해원의 문 - 영웅(수호자) 관리 화면
// 영웅 선택, 정보 확인, 진화 단계별 능력 열람

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/enums.dart';
import '../../../common/responsive.dart';
import '../../../data/game_data_loader.dart';
import '../../../data/models/hero_data.dart';
import '../../../l10n/app_strings.dart';
import '../../../services/save_manager.dart';
import '../../theme/app_colors.dart';
import '../../../common/asset_paths.dart';
import 'hero_detail_panel.dart';
import 'hero_list_panel.dart';

/// 영웅 관리 화면
class HeroManageScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const HeroManageScreen({super.key, required this.onBack});

  @override
  ConsumerState<HeroManageScreen> createState() => _HeroManageScreenState();
}

class _HeroManageScreenState extends ConsumerState<HeroManageScreen>
    with SingleTickerProviderStateMixin {
  HeroId _selectedHeroId = HeroId.kkaebi;
  int _selectedEvolutionIndex = 0;

  // 영웅별 레벨/XP 캐시
  final Map<HeroId, Map<String, int>> _heroLevelCache = {};

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadAllHeroLevels();
  }

  /// 모든 영웅 레벨/XP 로드
  Future<void> _loadAllHeroLevels() async {
    for (final id in HeroId.values) {
      final data = await SaveManager.instance.loadHeroLevel(id);
      _heroLevelCache[id] = data;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  HeroData get _selectedHero => GameDataLoader.getHeroes()[_selectedHeroId]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 에셋
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                AssetPaths.asset('bg/bg_hero_manage'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.scaffoldBg,
                  AppColors.bgDeepPlum,
                  AppColors.surfaceMid,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Row(
                      children: [
                        // 왼쪽: 영웅 목록
                        SizedBox(
                          width: 200 * Responsive.scale(context),
                          child: HeroListPanel(
                            selectedHeroId: _selectedHeroId,
                            onHeroSelected: (id) {
                              setState(() {
                                _selectedHeroId = id;
                                _selectedEvolutionIndex = 0;
                              });
                            },
                          ),
                        ),
                        // 오른쪽: 영웅 상세
                        Expanded(
                          child: HeroDetailPanel(
                            hero: _selectedHero,
                            selectedEvolutionIndex: _selectedEvolutionIndex,
                            glowAnimation: _glowController,
                            heroLevelCache: _heroLevelCache,
                            onEvolutionIndexChanged: (i) {
                              setState(() => _selectedEvolutionIndex = i);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상단 헤더
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * Responsive.scale(context), vertical: 12 * Responsive.scale(context)),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: AppStrings.get(ref.watch(gameLanguageProvider), 'back'),
            child: GestureDetector(
              onTap: widget.onBack,
              child: Container(
                padding: EdgeInsets.all(8 * Responsive.scale(context)),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOverlayDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceOverlay),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.lavender,
                  size: 20 * Responsive.scale(context),
                ),
              ),
            ),
          ),
          SizedBox(width: 16 * Responsive.scale(context)),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.lavender, Color(0xFFFFAA44)],
            ).createShader(bounds),
            child: Text(
              tr(ref, 'hero_guardian_label'),
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * Responsive.scale(context), vertical: 6 * Responsive.scale(context)),
            decoration: BoxDecoration(
              color: AppColors.surfaceOverlayDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppStrings.get(ref.watch(gameLanguageProvider), 'hero_select_prompt'),
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 11),
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
