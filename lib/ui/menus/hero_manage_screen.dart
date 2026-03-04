// 해원의 문 - 영웅(수호자) 관리 화면


// 영웅 선택, 정보 확인, 진화 단계별 능력 열람





import 'dart:ui';


import 'package:flutter/material.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../common/enums.dart';


import '../../common/responsive.dart';


import '../../data/game_data_loader.dart';


import '../../data/models/hero_data.dart';
import '../../data/models/story_data.dart';
import '../../l10n/app_strings.dart';
import '../common/hero_sprite_viewer.dart';
import '../../services/save_manager.dart';
import '../../game/components/actors/base_hero.dart';
import '../../state/skin_provider.dart';
import '../../game/components/actors/base_hero.dart';


import '../../state/skin_provider.dart';


import '../../data/models/skin_data.dart';


import '../theme/app_colors.dart';


import '../theme/themed_scaffold.dart';


import '../widgets/touch_button.dart';


import '../common/hero_sprite_viewer.dart';





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





  int _getHeroLevel(HeroId id) => _heroLevelCache[id]?['level'] ?? 1;


  int _getHeroXp(HeroId id) => _heroLevelCache[id]?['xp'] ?? 0;





  @override


  void dispose() {


    _glowController.dispose();


    super.dispose();


  }





  HeroData get _selectedHero => GameDataLoader.getHeroes()[_selectedHeroId]!;





  @override


  Widget build(BuildContext context) {
    final skinState = ref.watch(skinProvider);

    return Scaffold(


      body: Stack(


        children: [


          // 배경 에셋


          Positioned.fill(


            child: Opacity(


              opacity: 0.2,


              child: Image.asset(


                'assets/images/bg/bg_hero_manage.png',


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


                      child: _buildHeroList(skinState),


                    ),


                    // 오른쪽: 영웅 상세


                    Expanded(


                      child: _buildHeroDetail(skinState),


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


          GestureDetector(


            onTap: widget.onBack,


            child: Container(


              padding: EdgeInsets.all(8 * Responsive.scale(context)),


              decoration: BoxDecoration(


                color: const Color(0x22FFFFFF),


                borderRadius: BorderRadius.circular(8),


                border: Border.all(color: const Color(0x44FFFFFF)),


              ),


              child: Icon(


                Icons.arrow_back,


                color: AppColors.lavender,


                size: 20 * Responsive.scale(context),


              ),


            ),


          ),


          SizedBox(width: 16 * Responsive.scale(context)),


          ShaderMask(


            shaderCallback: (bounds) => const LinearGradient(


              colors: [AppColors.lavender, const Color(0xFFFFAA44)],


            ).createShader(bounds),


            child: Text(


              '👥 수호자',


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


              color: const Color(0x22FFFFFF),


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





  /// 영웅 리스트 (왼쪽 패널)


  Widget _buildHeroList(SkinState skinState) {


    final heroes = GameDataLoader.getHeroes().values.toList();


    return Container(


      margin: EdgeInsets.only(left: 12 * Responsive.scale(context), bottom: 12 * Responsive.scale(context)),


      decoration: BoxDecoration(


        color: const Color(0x15FFFFFF),


        borderRadius: BorderRadius.circular(16),


        border: Border.all(color: const Color(0x22FFFFFF)),


      ),


      child: ListView.builder(


        padding: EdgeInsets.all(8 * Responsive.scale(context)),


        itemCount: heroes.length,


        itemBuilder: (context, index) {


          final hero = heroes[index];


          final isSelected = hero.id == _selectedHeroId;


          return _buildHeroCard(hero, isSelected, skinState);


        },


      ),


    );


  }





  /// 영웅 카드 (리스트 아이템)


  Widget _buildHeroCard(HeroData hero, bool isSelected, SkinState skinState) {


    final color = _getHeroColor(hero.id);


    return TouchButton(


      borderRadius: BorderRadius.circular(12),


      padding: EdgeInsets.zero,


      onTap: () {


        setState(() {
          _selectedHeroId = hero.id;
          _selectedEvolutionIndex = 0;
        });


      },


      child: ClipRRect(


        borderRadius: BorderRadius.circular(12),


        child: BackdropFilter(


          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),


          child: AnimatedContainer(


        duration: const Duration(milliseconds: 200),


        margin: EdgeInsets.only(bottom: 6 * Responsive.scale(context)),


        padding: EdgeInsets.all(10 * Responsive.scale(context)),


        decoration: BoxDecoration(


          gradient: isSelected


              ? LinearGradient(


                  colors: [


                    color.withValues(alpha: 0.3),


                    color.withValues(alpha: 0.1),


                  ],


                )


              : null,


          color: isSelected ? null : const Color(0x08FFFFFF),


          borderRadius: BorderRadius.circular(12),


          border: Border.all(


            color: isSelected ? color.withValues(alpha: 0.6) : const Color(0x11FFFFFF),


            width: isSelected ? 1.5 : 1,


          ),


          boxShadow: isSelected


              ? [


                  BoxShadow(


                    color: color.withValues(alpha: 0.2),


                    blurRadius: 12,


                    spreadRadius: 1,


                  ),


                ]


              : null,


        ),


        child: Row(


          children: [


            // 영웅 아이콘


            Container(


              width: 40 * Responsive.scale(context),


              height: 40 * Responsive.scale(context),


              decoration: BoxDecoration(


                shape: BoxShape.circle,


                gradient: RadialGradient(


                  colors: [color, color.withValues(alpha: 0.3)],


                ),


                border: isSelected


                    ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5)


                    : null,


              ),


              child: ClipOval(
                child: HeroSpriteViewer(
                  imagePath: 'assets/images/heroes/${_getHeroFileName(hero.id)}_tier1_sprites.png',
                  width: 40 * Responsive.scale(context),
                  height: 40 * Responsive.scale(context),
                  fallbackText: _getHeroEmoji(hero.id),
                ),
              ),
            ),


            SizedBox(width: 8 * Responsive.scale(context)),


            Expanded(


              child: Column(


                crossAxisAlignment: CrossAxisAlignment.start,


                children: [


                  Text(


                    hero.name,


                    style: TextStyle(


                      color: isSelected ? Colors.white : Colors.white70,


                      fontSize: Responsive.fontSize(context, 14),


                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,


                    ),


                  ),


                  Text(


                    _getRoleLabel(hero.id),


                    style: TextStyle(


                      color: color.withValues(alpha: 0.8),


                      fontSize: Responsive.fontSize(context, 10),


                    ),


                  ),


                ],


              ),


            ),


          ],


        ),


      ),


          ),


        ),


    );


  }





  /// 영웅 상세 (오른쪽 패널)


  Widget _buildHeroDetail(SkinState skinState) {


    final hero = _selectedHero;


    final color = _getHeroColor(hero.id);


    final evo = hero.evolutions[_selectedEvolutionIndex.clamp(0, hero.evolutions.length - 1)];





    return Container(


      margin: EdgeInsets.only(left: 8 * Responsive.scale(context), right: 12 * Responsive.scale(context), bottom: 12 * Responsive.scale(context)),


      decoration: BoxDecoration(


        color: const Color(0x10FFFFFF),


        borderRadius: BorderRadius.circular(16),


        border: Border.all(color: const Color(0x22FFFFFF)),


      ),


      child: SingleChildScrollView(


        padding: EdgeInsets.all(20 * Responsive.scale(context)),


        child: Column(


          crossAxisAlignment: CrossAxisAlignment.start,


          children: [


            // 영웅 이름 & 초상화 (포트레이트)
            _buildNameSection(hero, color, skinState),
            SizedBox(height: 16 * Responsive.scale(context)),

            // 장착된 스킨 프리뷰 (스킨상점 카드 스타일)
          _buildEquippedSkinCard(hero, color, skinState),
          SizedBox(height: 16 * Responsive.scale(context)),

          // 스킨 외형 미리보기 (코스메틱)
          _buildSkinPreviewSection(hero, color),
          SizedBox(height: 16 * Responsive.scale(context)),

            // 진화 단계 선택
            _buildEvolutionTabs(hero, color),
            SizedBox(height: 16 * Responsive.scale(context)),


            // 진화 설명


            _buildEvolutionInfo(evo, color),


            SizedBox(height: 20 * Responsive.scale(context)),


            // 스탯 바


            _buildStatBars(hero, evo, color),


            SizedBox(height: 20 * Responsive.scale(context)),


            // 스킬 정보


            _buildSkillSection(hero, color),


            SizedBox(height: 20 * Responsive.scale(context)),


            // 배경 설화


            _buildBackstorySection(hero, color),


            SizedBox(height: 16 * Responsive.scale(context)),


            // 대사


            if (hero.barks.isNotEmpty) _buildBarksSection(hero, color),


          ],


        ),


      ),


    );


  }





  /// 이름 섹션


  Widget _buildNameSection(HeroData hero, Color color, SkinState skinState) {


    // 장착 중인 스킨 데이터 가져오기


    final skinId = skinState.equippedSkins[hero.id];


    final skins = getSkinsForHero(hero.id);


    final equippedSkin = skinId != null 


        ? skins.firstWhere((s) => s.id == skinId, orElse: () => skins.first)


        : skins.where((s) => s.rarity == SkinRarity.common).firstOrNull;





    final displayName = equippedSkin?.name ?? hero.name;


    final displayTitle = equippedSkin?.rarity.displayName != null 


        ? '${equippedSkin!.rarity.displayName} 등급 ' + hero.title


        : hero.title;





    return Row(


      children: [


        // 큰 영웅 아바타


        AnimatedBuilder(


          animation: _glowController,


          builder: (context, child) {


            return Container(


              width: 72 * Responsive.scale(context),


              height: 72 * Responsive.scale(context),


              decoration: BoxDecoration(


                shape: BoxShape.circle,


                gradient: RadialGradient(


                  colors: [


                    color,


                    color.withValues(alpha: 0.2 + _glowController.value * 0.3),


                  ],


                ),


                border: Border.all(


                  color: color.withValues(alpha: 0.5 + _glowController.value * 0.3),


                  width: 2,


                ),


                boxShadow: [


                  BoxShadow(


                    color: color.withValues(alpha: 0.3 + _glowController.value * 0.2),


                    blurRadius: 20,


                    spreadRadius: 4,


                  ),


                ],


              ),


              child: ClipOval(
                child: HeroSpriteViewer(
                  imagePath: 'assets/images/heroes/${_getHeroFileName(hero.id)}_tier1_sprites.png',
                  width: 72 * Responsive.scale(context),
                  height: 72 * Responsive.scale(context),
                  fallbackText: _getHeroEmoji(hero.id),
                ),
              ),
            );
          },
        ),


        SizedBox(width: 16 * Responsive.scale(context)),


        Expanded(


          child: Column(


            crossAxisAlignment: CrossAxisAlignment.start,


            children: [


              Text(


                displayName,


                style: TextStyle(


                  fontSize: Responsive.fontSize(context, 28),


                  fontWeight: FontWeight.bold,


                  color: Colors.white,


                  letterSpacing: 2,


                ),


              ),


              SizedBox(height: 4 * Responsive.scale(context)),


              Text(


                displayTitle,


                style: TextStyle(


                  fontSize: Responsive.fontSize(context, 14),


                  color: color.withValues(alpha: 0.9),


                  fontStyle: FontStyle.italic,


                ),


              ),


              SizedBox(height: 4 * Responsive.scale(context)),


              Row(


                children: [


                  _buildTag(_getRoleLabel(hero.id), color),


                  SizedBox(width: 6 * Responsive.scale(context)),


                  _buildTag(_getDamageLabel(hero.damageType), _getDamageColor(hero.damageType)),


                ],


              ),


              SizedBox(height: 8 * Responsive.scale(context)),


              // 레벨 & XP 바


              _buildLevelXpBar(hero.id, color),


            ],


          ),


        ),


      ],


    );


  }


  Widget _buildEquippedSkinCard(HeroData hero, Color color, SkinState skinState) {
    final s = Responsive.scale(context);
    final skinId = skinState.equippedSkins[hero.id];
    final skins = getSkinsForHero(hero.id);
    final skin = skinId != null
        ? skins.firstWhere((s) => s.id == skinId, orElse: () => skins.first)
        : skins.where((s) => s.rarity == SkinRarity.common).firstOrNull ?? skins.first;

    final double glowIntensity = switch (skin.rarity) {
      SkinRarity.common => 0.0,
      SkinRarity.rare => 8.0,
      SkinRarity.epic => 14.0,
      SkinRarity.legendary => 18.0,
    };

    final int tier = switch (skin.rarity) {
      SkinRarity.common => 1,
      SkinRarity.rare => 2,
      SkinRarity.epic => 3,
      SkinRarity.legendary => 4,
    };

    return Container(
      height: 140 * s,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(
          color: AppColors.sinmyeongGold,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sinmyeongGold.withAlpha(60),
            blurRadius: glowIntensity > 0 ? glowIntensity : 4.0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12 * s),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 그라디언트
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    skin.primaryColor.withAlpha(80),
                    Colors.black.withAlpha(180),
                    skin.secondaryColor.withAlpha(60),
                  ],
                ),
              ),
            ),
            // 영웅 스프라이트 렌더링
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: 8 * s),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white,
                        skin.primaryColor.withAlpha(160),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 0.85, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ColorFiltered(
                    colorFilter: skin.rarity == SkinRarity.common
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                        : ColorFilter.mode(
                            skin.primaryColor.withAlpha(40),
                            BlendMode.srcATop,
                          ),
                    child: HeroSpriteViewer(
                      imagePath: 'assets/images/heroes/${_getHeroFileName(hero.id)}_tier${tier}_sprites.png',
                      width: double.infinity,
                      height: 140 * s,
                      fallbackText: skin.rarity.emoji,
                    ),
                  ),
                ),
              ),
            ),
            // 왼쪽 상단 스킨 이름 배지
            Positioned(
              left: 12 * s,
              top: 12 * s,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(8 * s),
                  border: Border.all(color: skin.rarity.color.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skin.rarity.emoji,
                      style: TextStyle(fontSize: 12 * s),
                    ),
                    SizedBox(width: 4 * s),
                    Text(
                      skin.name,
                      style: TextStyle(
                        color: skin.rarity.color,
                        fontSize: 12 * s,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEquippedSkinSprite(HeroId heroId, SkinState skinState) {


    final skinId = skinState.equippedSkins[heroId];


    final skins = getSkinsForHero(heroId);


    final equippedSkin = skinId != null 


        ? skins.firstWhere((s) => s.id == skinId, orElse: () => skins.first)


        : skins.where((s) => s.rarity == SkinRarity.common).firstOrNull ?? skins.first;


    


    final tier = switch (equippedSkin.rarity) {


      SkinRarity.common => 1,


      SkinRarity.rare => 2,


      SkinRarity.epic => 3,


      SkinRarity.legendary => 4,


    };


    


    return 'assets/images/heroes/${_getHeroFileName(heroId)}_tier${tier}_sprites.png';


  }





  /// 레벨 & XP 진행률 바


  Widget _buildLevelXpBar(HeroId heroId, Color color) {


    final level = _getHeroLevel(heroId);


    final xp = _getHeroXp(heroId);


    final isMaxLevel = level >= BaseHero.maxLevel;


    final xpNeeded = isMaxLevel ? 0 : BaseHero.xpForLevel(level);


    final xpRatio = isMaxLevel ? 1.0 : (xpNeeded > 0 ? (xp / xpNeeded).clamp(0.0, 1.0) : 0.0);





    return Column(


      crossAxisAlignment: CrossAxisAlignment.start,


      children: [


        Row(


          children: [


            // 레벨 배지


            Container(


              padding: EdgeInsets.symmetric(horizontal: 8 * Responsive.scale(context), vertical: 2 * Responsive.scale(context)),


              decoration: BoxDecoration(


                gradient: LinearGradient(


                  colors: [


                    color.withValues(alpha: 0.3),


                    color.withValues(alpha: 0.1),


                  ],


                ),


                borderRadius: BorderRadius.circular(6),


                border: Border.all(color: color.withValues(alpha: 0.4)),


              ),


              child: Text(


                'Lv.$level',


                style: TextStyle(


                  fontSize: Responsive.fontSize(context, 12),


                  fontWeight: FontWeight.bold,


                  color: Colors.white,


                ),


              ),


            ),


            SizedBox(width: 8 * Responsive.scale(context)),


            // XP 바


            Expanded(


              child: Container(


                height: 6 * Responsive.scale(context),


                decoration: BoxDecoration(


                  color: const Color(0x22FFFFFF),


                  borderRadius: BorderRadius.circular(3),


                ),


                child: FractionallySizedBox(


                  alignment: Alignment.centerLeft,


                  widthFactor: xpRatio,


                  child: Container(


                    decoration: BoxDecoration(


                      gradient: LinearGradient(


                        colors: isMaxLevel


                            ? [const Color(0xFFFF8C00), AppColors.sinmyeongGold]


                            : [color.withValues(alpha: 0.6), color],


                      ),


                      borderRadius: BorderRadius.circular(3),


                      boxShadow: [


                        BoxShadow(


                          color: color.withValues(alpha: 0.4),


                          blurRadius: 4,


                        ),


                      ],


                    ),


                  ),


                ),


              ),


            ),


            SizedBox(width: 8 * Responsive.scale(context)),


            // XP 텍스트


            Text(


              isMaxLevel ? 'MAX' : '$xp / $xpNeeded',


              style: TextStyle(


                fontSize: Responsive.fontSize(context, 10),


                color: isMaxLevel ? AppColors.sinmyeongGold : Colors.white70,


                fontWeight: isMaxLevel ? FontWeight.bold : FontWeight.normal,


              ),


            ),


          ],


        ),


      ],


    );


  }





  /// 태그 뱃지


  Widget _buildTag(String label, Color color) {


    return Container(


      padding: EdgeInsets.symmetric(horizontal: 8 * Responsive.scale(context), vertical: 3 * Responsive.scale(context)),


      decoration: BoxDecoration(


        color: color.withValues(alpha: 0.15),


        borderRadius: BorderRadius.circular(8),


        border: Border.all(color: color.withValues(alpha: 0.3)),


      ),


      child: Text(


        label,


        style: TextStyle(


          fontSize: Responsive.fontSize(context, 10),


          color: color,


          fontWeight: FontWeight.w600,


        ),


      ),


    );


  }





  /// 진화 단계 탭


  /// 진화 단계 탭 (스탯 관련 — 기본/중급/궁극)
  Widget _buildEvolutionTabs(HeroData hero, Color color) {
    return Row(
      children: List.generate(hero.evolutions.length, (i) {
        final evo = hero.evolutions[i];
        final isSelected = i == _selectedEvolutionIndex;
        final heroFileName = _getHeroFileName(hero.id);
        final tierNumber = i + 1;

        // 진화 단계별 스타일
        final tierColor = switch (evo.tier) {
          EvolutionTier.base => const Color(0xFF9E9E9E),
          EvolutionTier.intermediate => const Color(0xFF42A5F5),
          EvolutionTier.ultimate => const Color(0xFFAB47BC),
        };
        final tierLabel = switch (evo.tier) {
          EvolutionTier.base => AppStrings.get(ref.watch(gameLanguageProvider), 'evo_base'),
          EvolutionTier.intermediate => AppStrings.get(ref.watch(gameLanguageProvider), 'evo_intermediate'),
          EvolutionTier.ultimate => AppStrings.get(ref.watch(gameLanguageProvider), 'evo_ultimate'),
        };
        final tierBadge = switch (evo.tier) {
          EvolutionTier.base => 'Lv.1',
          EvolutionTier.intermediate => 'Lv.15',
          EvolutionTier.ultimate => 'Lv.35',
        };

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedEvolutionIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: i < hero.evolutions.length - 1 ? 6 : 0),
              padding: EdgeInsets.symmetric(vertical: 8 * Responsive.scale(context), horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tierColor.withValues(alpha: 0.35),
                          tierColor.withValues(alpha: 0.1),
                        ],
                      )
                    : null,
                color: isSelected ? null : const Color(0x08FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? tierColor.withValues(alpha: 0.6) : const Color(0x22FFFFFF),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: tierColor.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 스프라이트 미리보기 (원형)
                  Container(
                    width: 40 * Responsive.scale(context),
                    height: 40 * Responsive.scale(context),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? tierColor : tierColor.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected && evo.tier == EvolutionTier.ultimate
                          ? [BoxShadow(color: tierColor.withValues(alpha: 0.5), blurRadius: 10)]
                          : null,
                    ),
                    child: ClipOval(
                      child: HeroSpriteViewer(
                        imagePath: 'assets/images/heroes/${heroFileName}_evo${tierNumber}_sprites.png',
                        width: 40 * Responsive.scale(context),
                        height: 40 * Responsive.scale(context),
                        fallbackText: evo.tier == EvolutionTier.base ? '⚪' : evo.tier == EvolutionTier.intermediate ? '🔵' : '🟣',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 이름
                  Text(
                    tierLabel,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 10),
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 레벨 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: isSelected ? 0.25 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tierBadge,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 8),
                        color: isSelected ? tierColor : Colors.white38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 스킨 미리보기 섹션 (코스메틱 — 기본/정제/명작/전설)
  Widget _buildSkinPreviewSection(HeroData hero, Color color) {
    final heroFileName = _getHeroFileName(hero.id);
    final skins = SkinRarity.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          children: [
            Text(
              '🎨 ${AppStrings.get(ref.watch(gameLanguageProvider), 'skin_preview')}',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * Responsive.scale(context)),
        // 스킨 카드 4개 가로 배치
        Row(
          children: List.generate(skins.length, (i) {
            final rarity = skins[i];
            final tierNumber = i + 1;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < skins.length - 1 ? 6 : 0),
                padding: EdgeInsets.symmetric(vertical: 8 * Responsive.scale(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      rarity.color.withValues(alpha: 0.15),
                      rarity.color.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: rarity.color.withValues(alpha: 0.3)),
                  boxShadow: rarity.hasGlow
                      ? [BoxShadow(color: rarity.color.withValues(alpha: 0.2), blurRadius: 8)]
                      : null,
                ),
                child: Column(
                  children: [
                    // 스프라이트
                    Container(
                      width: 36 * Responsive.scale(context),
                      height: 36 * Responsive.scale(context),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: rarity.hasBorder
                            ? Border.all(color: rarity.color, width: 1.5)
                            : null,
                        boxShadow: rarity.hasGlow
                            ? [BoxShadow(color: rarity.color.withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                      child: ClipOval(
                        child: HeroSpriteViewer(
                          imagePath: 'assets/images/heroes/${heroFileName}_tier${tierNumber}_sprites.png',
                          width: 36 * Responsive.scale(context),
                          height: 36 * Responsive.scale(context),
                          fallbackText: rarity.emoji,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 등급 이름
                    Text(
                      rarity.displayName,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 9),
                        color: rarity.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }





  /// 진화 단계 정보


  Widget _buildEvolutionInfo(HeroEvolutionData evo, Color color) {


    return Container(


      padding: EdgeInsets.all(12 * Responsive.scale(context)),


      decoration: BoxDecoration(


        color: color.withValues(alpha: 0.05),


        borderRadius: BorderRadius.circular(10),


        border: Border.all(color: color.withValues(alpha: 0.15)),


      ),


      child: Column(


        crossAxisAlignment: CrossAxisAlignment.start,


        children: [


          Text(


            '✨ ${evo.visualName}',


            style: TextStyle(


              fontSize: Responsive.fontSize(context, 15),


              fontWeight: FontWeight.bold,


              color: Colors.white,


            ),


          ),


          const SizedBox(height: 4),


          Text(


            evo.description,


            style: TextStyle(


              fontSize: Responsive.fontSize(context, 12),


              color: Colors.white.withValues(alpha: 0.7),


              height: 1.4,


            ),


          ),


          if (evo.hpMultiplier > 1.0 || evo.attackMultiplier > 1.0 || evo.rangeMultiplier > 1.0)


            Padding(


              padding: const EdgeInsets.only(top: 8),


              child: Wrap(


                spacing: 8,


                children: [


                  if (evo.hpMultiplier > 1.0)


                    _buildMultiplierChip('HP', evo.hpMultiplier, const Color(0xFF44DD44)),


                  if (evo.attackMultiplier > 1.0)


                    _buildMultiplierChip(AppStrings.get(ref.watch(gameLanguageProvider), 'stat_attack'), evo.attackMultiplier, const Color(0xFFFF6644)),


                  if (evo.rangeMultiplier > 1.0)


                    _buildMultiplierChip(AppStrings.get(ref.watch(gameLanguageProvider), 'stat_range'), evo.rangeMultiplier, const Color(0xFF44AAFF)),


                ],


              ),


            ),


        ],


      ),


    );


  }





  Widget _buildMultiplierChip(String stat, double mult, Color color) {


    return Container(


      padding: EdgeInsets.symmetric(horizontal: 6 * Responsive.scale(context), vertical: 2 * Responsive.scale(context)),


      decoration: BoxDecoration(


        color: color.withValues(alpha: 0.15),


        borderRadius: BorderRadius.circular(6),


      ),


      child: Text(


        '$stat ×${mult.toStringAsFixed(1)}',


        style: TextStyle(


          fontSize: Responsive.fontSize(context, 10),


          color: color,


          fontWeight: FontWeight.bold,


        ),


      ),


    );


  }





  /// 스탯 바


  Widget _buildStatBars(HeroData hero, HeroEvolutionData evo, Color color) {


    final lang = ref.watch(gameLanguageProvider);


    final stats = [


      ('HP', hero.baseHp * evo.hpMultiplier, 1000.0, const Color(0xFF44DD44)),


      (AppStrings.get(lang, 'stat_attack_power'), hero.baseAttack * evo.attackMultiplier, 200.0, const Color(0xFFFF6644)),


      (AppStrings.get(lang, 'stat_range'), hero.baseRange * evo.rangeMultiplier, 400.0, const Color(0xFF44AAFF)),


      (AppStrings.get(lang, 'stat_speed'), hero.baseSpeed, 100.0, const Color(0xFFFFBB44)),


    ];





    return Column(


      crossAxisAlignment: CrossAxisAlignment.start,


      children: [


        Text(


          '📊 ${AppStrings.get(ref.watch(gameLanguageProvider), "hero_stats")}',


          style: TextStyle(


            fontSize: Responsive.fontSize(context, 14),


            fontWeight: FontWeight.bold,


            color: Colors.white,


          ),


        ),


        const SizedBox(height: 8),


        ...stats.map((s) => _buildStatBar(s.$1, s.$2, s.$3, s.$4)),


      ],


    );


  }





  Widget _buildStatBar(String label, double value, double max, Color color) {


    final ratio = (value / max).clamp(0.0, 1.0);


    return Padding(


      padding: EdgeInsets.only(bottom: 6 * Responsive.scale(context)),


      child: Row(


        children: [


          SizedBox(


            width: 60 * Responsive.scale(context),


            child: Text(


              label,


              style: TextStyle(


                fontSize: Responsive.fontSize(context, 11),


                color: Colors.white.withValues(alpha: 0.7),


              ),


            ),


          ),


          Expanded(


            child: Container(


              height: 8 * Responsive.scale(context),


              decoration: BoxDecoration(


                color: const Color(0x22FFFFFF),


                borderRadius: BorderRadius.circular(4),


              ),


              child: FractionallySizedBox(


                alignment: Alignment.centerLeft,


                widthFactor: ratio,


                child: Container(


                  decoration: BoxDecoration(


                    gradient: LinearGradient(


                      colors: [color.withValues(alpha: 0.8), color],


                    ),


                    borderRadius: BorderRadius.circular(4),


                    boxShadow: [


                      BoxShadow(


                        color: color.withValues(alpha: 0.4),


                        blurRadius: 4,


                      ),


                    ],


                  ),


                ),


              ),


            ),


          ),


          SizedBox(width: 8 * Responsive.scale(context)),


          SizedBox(


            width: 40 * Responsive.scale(context),


            child: Text(


              value.toInt().toString(),


              textAlign: TextAlign.right,


              style: TextStyle(


                fontSize: Responsive.fontSize(context, 11),


                color: color,


                fontWeight: FontWeight.bold,


              ),


            ),


          ),


        ],


      ),


    );


  }





  /// 스킬 섹션


  Widget _buildSkillSection(HeroData hero, Color color) {


    final skill = hero.skill;


    return Container(


      padding: EdgeInsets.all(12 * Responsive.scale(context)),


      decoration: BoxDecoration(


        gradient: LinearGradient(


          colors: [


            color.withValues(alpha: 0.1),


            Colors.transparent,


          ],


        ),


        borderRadius: BorderRadius.circular(12),


        border: Border.all(color: color.withValues(alpha: 0.2)),


      ),


      child: Column(


        crossAxisAlignment: CrossAxisAlignment.start,


        children: [


          Row(


            children: [


              Container(


                width: 36 * Responsive.scale(context),


                height: 36 * Responsive.scale(context),


                decoration: BoxDecoration(


                  shape: BoxShape.circle,


                  gradient: RadialGradient(


                    colors: [color, color.withValues(alpha: 0.3)],


                  ),


                  border: Border.all(color: AppColors.sinmyeongGold, width: 2),


                ),


                child: Center(


                  child: Text('⚡', style: TextStyle(fontSize: Responsive.fontSize(context, 16))),


                ),


              ),


              const SizedBox(width: 10),


              Expanded(


                child: Column(


                  crossAxisAlignment: CrossAxisAlignment.start,


                  children: [


                    Text(


                      skill.name,


                      style: TextStyle(


                        fontSize: Responsive.fontSize(context, 14),


                        fontWeight: FontWeight.bold,


                        color: Colors.white,


                      ),


                    ),


                    Text(


                      '${AppStrings.get(ref.watch(gameLanguageProvider), "skill_cooltime")}: ${skill.cooldown.toInt()}s | ${AppStrings.get(ref.watch(gameLanguageProvider), "range")}: ${skill.range.toInt()}',


                      style: TextStyle(


                        fontSize: Responsive.fontSize(context, 10),


                        color: Colors.white.withValues(alpha: 0.5),


                      ),


                    ),


                  ],


                ),


              ),


            ],


          ),


          const SizedBox(height: 8),


          Text(


            skill.description,


            style: TextStyle(


              fontSize: Responsive.fontSize(context, 12),


              color: Colors.white.withValues(alpha: 0.8),


              height: 1.4,


            ),


          ),


          const SizedBox(height: 6),


          Row(


            children: [


              _buildTag('${AppStrings.get(ref.watch(gameLanguageProvider), "skill_damage")}: ${skill.damage.toInt()}', const Color(0xFFFF6644)),


              if (skill.duration > 0) ...[


                const SizedBox(width: 6),


                _buildTag('${AppStrings.get(ref.watch(gameLanguageProvider), "skill_duration")}: ${skill.duration.toInt()}s', const Color(0xFF44AAFF)),


              ],


            ],


          ),


        ],


      ),


    );


  }





  /// 배경 이야기 (버튼 클릭 시 상세 팝업 오픈)


  Widget _buildBackstorySection(HeroData hero, Color color) {


    return Container(


      padding: EdgeInsets.all(12 * Responsive.scale(context)),


      decoration: BoxDecoration(


        color: color.withValues(alpha: 0.1),


        borderRadius: BorderRadius.circular(10),


        border: Border.all(color: color.withValues(alpha: 0.2)),


      ),


      child: Row(


        mainAxisAlignment: MainAxisAlignment.spaceBetween,


        children: [


          Row(


            children: [


              const Text('📜', style: TextStyle(fontSize: 20)),


              const SizedBox(width: 8),


              Column(


                crossAxisAlignment: CrossAxisAlignment.start,


                children: [


                  Text(


                    '영웅 배경 스토리',


                    style: TextStyle(


                      fontSize: Responsive.fontSize(context, 13),


                      fontWeight: FontWeight.bold,


                      color: Colors.white,


                    ),


                  ),


                  Text(


                    '${hero.name}의 숨겨진 과거를 확인하세요.',


                    style: TextStyle(


                      fontSize: Responsive.fontSize(context, 10),


                      color: Colors.white.withValues(alpha: 0.6),


                    ),


                  ),


                ],


              ),


            ],


          ),


          ElevatedButton(


            onPressed: () => _showLoreDialog(hero, color),


            style: ElevatedButton.styleFrom(


              backgroundColor: color.withValues(alpha: 0.3),


              foregroundColor: Colors.white,


              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),


            ),


            child: const Text('읽어보기'),


          ),


        ],


      ),


    );


  }





  /// 영웅 상세 스토리 모달 팝업


  void _showLoreDialog(HeroData hero, Color color) {


    // story_data.dart 에 정의된 상세 텍스트 로드 (없으면 기본 backstory 대체)


    final loreText = StoryData.heroLoreData[hero.id.name] ?? hero.backstory;





    showDialog(


      context: context,


      builder: (ctx) {


        return BackdropFilter(


          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),


          child: AlertDialog(


            backgroundColor: AppColors.surfaceDark.withOpacity(0.9),


            shape: RoundedRectangleBorder(


              borderRadius: BorderRadius.circular(20),


              side: BorderSide(color: color.withValues(alpha: 0.5), width: 2),


            ),


            title: Row(


              children: [


                Text(_getHeroEmoji(hero.id), style: const TextStyle(fontSize: 24)),


                const SizedBox(width: 8),


                Text(


                  '${hero.name}의 전설',


                  style: TextStyle(color: color, fontWeight: FontWeight.bold),


                ),


              ],


            ),


            content: SingleChildScrollView(


              child: Text(


                loreText,


                style: const TextStyle(


                  fontSize: 14,


                  color: Colors.white,


                  height: 1.6,


                ),


              ),


            ),


            actions: [


              TextButton(


                onPressed: () => Navigator.of(ctx).pop(),


                child: Text('닫기', style: TextStyle(color: color)),


              ),


            ],


          ),


        );


      },


    );


  }





  /// 대사


  Widget _buildBarksSection(HeroData hero, Color color) {


    return Column(


      crossAxisAlignment: CrossAxisAlignment.start,


      children: [


        const Text(


          '💬 대사',


          style: TextStyle(


            fontSize: 13,


            fontWeight: FontWeight.bold,


            color: Colors.white70,


          ),


        ),


        const SizedBox(height: 6),


        ...hero.barks.entries.map((entry) {


          final lang = ref.watch(gameLanguageProvider);


          final situationLabel = switch (entry.key) {


            'deploy' => AppStrings.get(lang, 'bark_deploy'),


            'skill' => AppStrings.get(lang, 'bark_skill'),


            'idle' => AppStrings.get(lang, 'bark_idle'),


            'boss' => AppStrings.get(lang, 'bark_boss'),


            _ => entry.key,


          };


          return Padding(


            padding: const EdgeInsets.only(bottom: 4),


            child: Row(


              crossAxisAlignment: CrossAxisAlignment.start,


              children: [


                Container(


                  width: 44 * Responsive.scale(context),


                  padding: EdgeInsets.symmetric(horizontal: 4 * Responsive.scale(context), vertical: 2 * Responsive.scale(context)),


                  decoration: BoxDecoration(


                    color: color.withValues(alpha: 0.1),


                    borderRadius: BorderRadius.circular(4),


                  ),


                  child: Text(


                    situationLabel,


                    textAlign: TextAlign.center,


                    style: TextStyle(


                      fontSize: Responsive.fontSize(context, 9),


                      color: color,


                      fontWeight: FontWeight.w600,


                    ),


                  ),


                ),


                const SizedBox(width: 8),


                Expanded(


                  child: Text(


                    '"${entry.value}"',


                    style: TextStyle(


                      fontSize: Responsive.fontSize(context, 11),


                      color: Colors.white.withValues(alpha: 0.6),


                      fontStyle: FontStyle.italic,


                    ),


                  ),


                ),


              ],


            ),


          );


        }),


      ],


    );


  }





  // ═══════════════════


  // 헬퍼 메서드


  // ═══════════════════





  Color _getHeroColor(HeroId id) {


    return switch (id) {


      HeroId.kkaebi => const Color(0xFF44BB44),


      HeroId.miho => const Color(0xFFFF66AA),


      HeroId.gangrim => const Color(0xFF7744CC),


      HeroId.sua => const Color(0xFF44AAFF),


      HeroId.bari => const Color(0xFFFFBB44),


    };


  }





  String _getHeroEmoji(HeroId id) {


    return switch (id) {


      HeroId.kkaebi => '👹',


      HeroId.miho => '🦊',


      HeroId.gangrim => '💀',


      HeroId.sua => '🌊',


      HeroId.bari => '🪬',


    };


  }





  String _getHeroFileName(HeroId id) {


    return switch (id) {


      HeroId.kkaebi => 'kkaebi',


      HeroId.miho => 'guMiho',


      HeroId.gangrim => 'gangrim',


      HeroId.sua => 'sua',


      HeroId.bari => 'bari',


    };


  }





  /// 현재 영웅의 해금된 최고 진화 단계 번호


  int _getCurrentHeroTier(HeroId id) {


    final level = _getHeroLevel(id);


    if (level >= 20) return 3;


    if (level >= 10) return 2;


    return 1;


  }





  /// 현재 선택된 진화 탭의 티어 번호


  int _getSelectedTierNumber() {


    return _selectedEvolutionIndex + 1;


  }





  String _getRoleLabel(HeroId id) {


    final lang = ref.watch(gameLanguageProvider);


    return switch (id) {


      HeroId.kkaebi => AppStrings.get(lang, 'hero_role_tanker'),


      HeroId.miho => AppStrings.get(lang, 'hero_role_mage'),


      HeroId.gangrim => AppStrings.get(lang, 'hero_role_sniper'),


      HeroId.sua => AppStrings.get(lang, 'hero_role_cc'),


      HeroId.bari => AppStrings.get(lang, 'hero_role_support'),


    };


  }





  String _getDamageLabel(DamageType type) {


    final lang = ref.watch(gameLanguageProvider);


    return switch (type) {


      DamageType.physical => AppStrings.get(lang, 'dmg_physical'),


      DamageType.magical => AppStrings.get(lang, 'dmg_magical'),


      DamageType.purification => AppStrings.get(lang, 'dmg_purification'),


    };


  }





  Color _getDamageColor(DamageType type) {


    return switch (type) {


      DamageType.physical => const Color(0xFFFF8844),


      DamageType.magical => const Color(0xFF8844FF),


      DamageType.purification => const Color(0xFFFFDD44),


    };


  }


}


