// ?�원??�?- 출전 준�??�면 (반응??
// ?�테?��? ?�택 ?? ?�투 ?�작 ???�웅 ?�티�??�성?�는 ?�면

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/hero_data.dart';
import '../../data/models/wave_data.dart';
import '../../state/hero_party_provider.dart';
import '../../state/user_state.dart';
import '../theme/app_colors.dart';
import '../theme/themed_scaffold.dart';
import '../widgets/touch_button.dart';
import '../common/hero_sprite_viewer.dart';

/// ?�웅 ?�금 조건: ?�당 ?�테?��? ?�리?????�금
const Map<HeroId, int> heroUnlockStage = {
  HeroId.kkaebi: 0,  // 기본 ?�금
  HeroId.miho: 3,    // ?�테?��? 3 ?�리??
  HeroId.gangrim: 5, // ?�테?��? 5 ?�리??
  HeroId.sua: 8,     // ?�테?��? 8 ?�리??
  HeroId.bari: 10,   // ?�테?��? 10 ?�리??
};

/// ?�웅 ?�일�?매핑
String _getHeroFileName(HeroId id) {
  return switch (id) {
    HeroId.kkaebi => 'kkaebi',
    HeroId.miho => 'guMiho',
    HeroId.gangrim => 'gangrim',
    HeroId.sua => 'sua',
    HeroId.bari => 'bari',
  };
}

/// 출전 준�??�면 ???�웅 ?�티 ?�성 ???�투 ?�작
class HeroDeployScreen extends ConsumerStatefulWidget {
  final LevelData level;
  final VoidCallback onBack;
  final void Function(LevelData level) onStartBattle;

  const HeroDeployScreen({
    super.key,
    required this.level,
    required this.onBack,
    required this.onStartBattle,
  });

  @override
  ConsumerState<HeroDeployScreen> createState() => _HeroDeployScreenState();
}

class _HeroDeployScreenState extends ConsumerState<HeroDeployScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partyState = ref.watch(heroPartyProvider);
    final userState = ref.watch(userStateProvider);
    final allHeroes = GameDataLoader.getHeroes().values.toList();
    final s = Responsive.scale(context);
    final isLand = Responsive.isLandscape(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: isLand
            ? _buildLandscapeLayout(partyState, userState, allHeroes, s)
            : _buildPortraitLayout(partyState, userState, allHeroes, s),
      ),
    );
  }

  Widget _buildPortraitLayout(HeroPartyState partyState, UserState userState, List<HeroData> allHeroes, double s) {
    return Column(
      children: [
        _buildHeader(s),
        SizedBox(height: 12 * s),
        _buildStageInfo(s),
        SizedBox(height: 16 * s),
        _buildPartySlots(partyState, s),
        SizedBox(height: 12 * s),
        _buildDivider(s),
        SizedBox(height: 12 * s),
        Expanded(child: _buildHeroPool(allHeroes, partyState, userState, s)),
        _buildDeployButton(partyState, s),
        SizedBox(height: 12 * s),
      ],
    );
  }

  Widget _buildLandscapeLayout(HeroPartyState partyState, UserState userState, List<HeroData> allHeroes, double s) {
    return Row(
      children: [
        // �? ?�테?��? ?�보 + ?�티 + 출전 버튼
        SizedBox(
          width: Responsive.adaptiveWidth(context, 0.35),
          child: Column(
            children: [
              _buildHeader(s),
              SizedBox(height: 8 * s),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12 * s),
                  child: Column(
                    children: [
                      _buildStageInfo(s),
                      SizedBox(height: 12 * s),
                      _buildPartySlots(partyState, s),
                    ],
                  ),
                ),
              ),
              _buildDeployButton(partyState, s),
              SizedBox(height: 8 * s),
            ],
          ),
        ),
        // ?? ?�웅 ?�
        Expanded(
          child: Column(
            children: [
              SizedBox(height: 8 * s),
              _buildDivider(s, label: '?�웅 ?�택'),
              SizedBox(height: 8 * s),
              Expanded(child: _buildHeroPool(allHeroes, partyState, userState, s)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(double s) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            iconSize: 22 * s,
          ),
          Text(
            '?�️ 출전 준�?,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.fontSize(context, 20),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A3E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4444AA)),
            ),
            child: Text(
              '?�웅 1�??�택',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: Responsive.fontSize(context, 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageInfo(double s) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20 * s),
      padding: EdgeInsets.all(10 * s),
      decoration: BoxDecoration(
        color: const Color(0xFF151530),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333366)),
      ),
      child: Row(
        children: [
          Text('?���?, style: TextStyle(fontSize: Responsive.fontSize(context, 24))),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stage ${widget.level.levelNumber}',
                  style: TextStyle(
                    color: AppColors.lavender,
                    fontSize: Responsive.fontSize(context, 13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.level.waves.length} ?�이�?,
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: Responsive.fontSize(context, 11),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              final difficulty = (widget.level.levelNumber / 4).ceil().clamp(1, 3);
              return Icon(
                i < difficulty ? Icons.star : Icons.star_border,
                color: AppColors.sinmyeongGold,
                size: 16 * s,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPartySlots(HeroPartyState partyState, double s) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(HeroPartyState.maxPartySize, (index) {
          final hasHero = index < partyState.party.length;
          final slot = hasHero ? partyState.party[index] : null;
          final heroData = slot != null ? GameDataLoader.getHeroes()[slot.heroId] : null;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            child: _PartySlotWidget(
              heroData: heroData,
              slotIndex: index,
              isEmpty: !hasHero,
              s: s,
              onRemove: hasHero
                  ? () {
                      ref.read(heroPartyProvider.notifier).removeHero(slot!.heroId);
                    }
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDivider(double s, {String label = '?�웅 ?�택'}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * s),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF333355))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * s),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: Responsive.fontSize(context, 11),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFF333355))),
        ],
      ),
    );
  }

  Widget _buildHeroPool(List<HeroData> allHeroes, HeroPartyState partyState, UserState userState, double s) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 130 * s,
          mainAxisSpacing: 8 * s,
          crossAxisSpacing: 8 * s,
          childAspectRatio: 0.85,
        ),
        itemCount: allHeroes.length,
        itemBuilder: (context, index) {
          final hero = allHeroes[index];
          final isSelected = partyState.containsHero(hero.id);
          final isUnlocked = userState.unlockedHeroes.contains(hero.id);
          final requiredStage = heroUnlockStage[hero.id] ?? 0;

          return _HeroPoolCard(
            hero: hero,
            isSelected: isSelected,
            isLocked: !isUnlocked,
            unlockStage: requiredStage,
            s: s,
            onTap: !isUnlocked
                ? null
                : () {
                    if (isSelected) {
                      ref.read(heroPartyProvider.notifier).removeHero(hero.id);
                    } else {
                      ref.read(heroPartyProvider.notifier).addHero(hero.id);
                    }
                  },
          );
        },
      ),
    );
  }

  Widget _buildDeployButton(HeroPartyState partyState, double s) {
    final isReady = partyState.party.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * s),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isReady ? 1.0 + _pulseController.value * 0.03 : 1.0;
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: double.infinity,
              height: 48 * s,
              child: ElevatedButton(
                onPressed: isReady
                    ? () => widget.onStartBattle(widget.level)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady
                      ? AppColors.lavender
                      : const Color(0xFF333355),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14 * s),
                  ),
                  elevation: isReady ? 8 : 0,
                  shadowColor: AppColors.lavender.withAlpha(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: isReady ? Colors.white : Colors.white38,
                      size: 24 * s,
                    ),
                    SizedBox(width: 8 * s),
                    Text(
                      isReady
                          ? '?�️ 출전! (${partyState.party.length}�?'
                          : '?�웅???�택?�세??,
                      style: TextStyle(
                        color: isReady ? Colors.white : Colors.white38,
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ?�티 ?�롯 ?�젯 (반응??
class _PartySlotWidget extends StatelessWidget {
  final HeroData? heroData;
  final int slotIndex;
  final bool isEmpty;
  final double s;
  final VoidCallback? onRemove;

  const _PartySlotWidget({
    required this.heroData,
    required this.slotIndex,
    required this.isEmpty,
    required this.s,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEmpty
        ? const Color(0xFF222244)
        : _getHeroColor(heroData!.id);

    return Container(
      width: 90 * s,
      height: 110 * s,
      decoration: BoxDecoration(
        color: color.withAlpha(isEmpty ? 60 : 40),
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(
          color: isEmpty
              ? const Color(0xFF444466).withAlpha(100)
              : color.withAlpha(180),
          width: isEmpty ? 1 : 2,
        ),
        boxShadow: isEmpty
            ? []
            : [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      color: Colors.white.withAlpha(60), size: 28 * s),
                  SizedBox(height: 4 * s),
                  Text(
                    '?�롯 ${slotIndex + 1}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(60),
                      fontSize: Responsive.fontSize(context, 9),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 36 * s, height: 36 * s,
                        child: OverflowBox(
                          maxWidth: 36 * s * 3, maxHeight: 36 * s,
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/images/heroes/${_getHeroFileName(heroData!.id)}_tier1_sprites.png',
                            height: 36 * s, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(
                              _getHeroEmoji(heroData!.id),
                              style: TextStyle(fontSize: Responsive.fontSize(context, 28)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * s),
                    Text(
                      heroData!.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 12),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      heroData!.title,
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: Responsive.fontSize(context, 9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Positioned(
                  top: 2 * s,
                  right: 2 * s,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 18 * s,
                      height: 18 * s,
                      decoration: BoxDecoration(
                        color: AppColors.berserkRed.withAlpha(180),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 10 * s),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _getHeroColor(HeroId id) {
    return switch (id) {
      HeroId.kkaebi => const Color(0xFF4CAF50),
      HeroId.miho => const Color(0xFFE91E63),
      HeroId.gangrim => const Color(0xFF607D8B),
      HeroId.sua => const Color(0xFF2196F3),
      HeroId.bari => const Color(0xFFFFEB3B),
    };
  }

  String _getHeroEmoji(HeroId id) {
    return switch (id) {
      HeroId.kkaebi => '?��',
      HeroId.miho => '?��',
      HeroId.gangrim => '??',
      HeroId.sua => '?��',
      HeroId.bari => '?��',
    };
  }
}

/// ?�웅 ?� 카드 ?�젯 (반응??
class _HeroPoolCard extends StatelessWidget {
  final HeroData hero;
  final bool isSelected;
  final bool isLocked;
  final int unlockStage;
  final double s;
  final VoidCallback? onTap;

  const _HeroPoolCard({
    required this.hero,
    required this.isSelected,
    this.isLocked = false,
    this.unlockStage = 0,
    required this.s,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getHeroColor(hero.id);

    final tooltipMessage = isLocked
        ? '?�� ${hero.name}\nStage $unlockStage ?�리?????�금'
        : '${_getHeroEmoji(hero.id)} ${hero.name} ??${hero.title}\n\n'
          '???�킬: ${hero.skill.name}\n'
          '${hero.skill.description}\n\n'
          '?�️ HP: ${hero.baseHp.toInt()}  ?�️ ATK: ${hero.baseAttack.toInt()}';

    return Tooltip(
      message: tooltipMessage,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: Responsive.fontSize(context, 11),
        height: 1.5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE1A1A3E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(40),
            blurRadius: 12,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isLocked
                ? AppColors.scaffoldBg
                : isSelected
                    ? color.withAlpha(50)
                    : const Color(0xFF1A1A35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLocked
                  ? const Color(0xFF222233)
                  : isSelected
                      ? color
                      : const Color(0xFF333355),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: isLocked
              ? _buildLockedContent(context, color)
              : _buildUnlockedContent(context, color),
        ),
      ),
          ),
        ),
    );
  }

  Widget _buildLockedContent(BuildContext context, Color color) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.3,
              child: ClipOval(
                child: HeroSpriteViewer(
                  imagePath: 'assets/images/heroes/${_getHeroFileName(hero.id)}_tier1_sprites.png',
                  width: 28 * s,
                  height: 28 * s,
                  fallbackText: _getHeroEmoji(hero.id),
                ),
              ),
            ),
            SizedBox(height: 2 * s),
            Icon(Icons.lock, color: const Color(0xFF555577), size: 14 * s),
            SizedBox(height: 2 * s),
            Text(
              hero.name,
              style: TextStyle(
                color: const Color(0xFF555577),
                fontSize: Responsive.fontSize(context, 11),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Stage $unlockStage',
              style: TextStyle(
                color: const Color(0xFF777799),
                fontSize: Responsive.fontSize(context, 9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedContent(BuildContext context, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isSelected)
          Positioned(
            top: 4 * s,
            right: 4 * s,
            child: Icon(Icons.check_circle,
                color: const Color(0xFF10B981), size: 14 * s),
          ),
        Padding(
          padding: EdgeInsets.all(6 * s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: HeroSpriteViewer(
                  imagePath: 'assets/images/heroes/${_getHeroFileName(hero.id)}_tier1_sprites.png',
                  width: 28 * s,
                  height: 28 * s,
                  fallbackText: _getHeroEmoji(hero.id),
                ),
              ),
              SizedBox(height: 2 * s),
              Text(
                hero.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, 11),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                hero.title,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: Responsive.fontSize(context, 9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3 * s),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '?�️${hero.baseHp.toInt()}',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: Responsive.fontSize(context, 9),
                    ),
                  ),
                  SizedBox(width: 4 * s),
                  Text(
                    '?�️${hero.baseAttack.toInt()}',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: Responsive.fontSize(context, 9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getHeroColor(HeroId id) {
    return switch (id) {
      HeroId.kkaebi => const Color(0xFF4CAF50),
      HeroId.miho => const Color(0xFFE91E63),
      HeroId.gangrim => const Color(0xFF607D8B),
      HeroId.sua => const Color(0xFF2196F3),
      HeroId.bari => const Color(0xFFFFEB3B),
    };
  }

  String _getHeroEmoji(HeroId id) {
    return switch (id) {
      HeroId.kkaebi => '?��',
      HeroId.miho => '?��',
      HeroId.gangrim => '??',
      HeroId.sua => '?��',
      HeroId.bari => '?��',
    };
  }
}
