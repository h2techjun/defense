// ?¥Ïõê??Î¨?- ?§ÌÇ® ?ÅÏ†ê ?îÎ©¥
// ?ÅÏõÖÎ≥??§ÌÇ® Î™©Î°ù ?úÏãú, Íµ¨Îß§/?•Ï∞© Í∏∞Îä•


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/enums.dart';
import '../../data/models/skin_data.dart';
import '../../state/skin_provider.dart';
import '../../state/user_state.dart';
import '../../services/ad_manager.dart';
import '../../common/responsive.dart';
import '../../services/game_event_bridge.dart';
import '../theme/app_colors.dart';
import '../common/hero_sprite_viewer.dart';

class SkinShopScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const SkinShopScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinState = ref.watch(skinProvider);
    final userState = ref.watch(userStateProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          // Î∞∞Í≤Ω ?êÏÖã ?¨Í≥º
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/towers/tower_sotdae_3.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
            // ?Ä?Ä ?§Îçî ?Ä?Ä
            _buildHeader(context, userState.gems, ref),

            // ?Ä?Ä ?ÅÏõÖ ??+ ?§ÌÇ® Î™©Î°ù ?Ä?Ä
            Expanded(
              child: DefaultTabController(
                length: HeroId.values.length,
                child: Column(
                  children: [
                    // ?ÅÏõÖ ??
                    TabBar(
                      isScrollable: true,
                      indicatorColor: AppColors.sinmyeongGold,
                      labelColor: AppColors.sinmyeongGold,
                      unselectedLabelColor: AppColors.lavender.withAlpha(150),
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.fontSize(context, 16)),
                      tabs: HeroId.values.map((heroId) {
                        return Tab(text: _getHeroName(heroId));
                      }).toList(),
                    ),

                    // ?§ÌÇ® Í∑∏Î¶¨??
                    Expanded(
                      child: TabBarView(
                        children: HeroId.values.map((heroId) {
                          return _buildSkinGrid(
                            context, ref, heroId, skinState,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int gems, WidgetRef ref) {
    final s = Responsive.scale(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      decoration: BoxDecoration(
        color: AppColors.bgDeepPlum.withAlpha(150),
        border: Border(bottom: BorderSide(color: AppColors.lavender.withAlpha(80), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          SizedBox(width: 8 * s),
          Text(
            '?é® ?§ÌÇ® ?ÅÏ†ê',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.fontSize(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Î≥¥ÏÑù ?úÏãú
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A4A),
              borderRadius: BorderRadius.circular(14 * s),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond, color: AppColors.skyBlue, size: 16 * s),
                SizedBox(width: 4 * s),
                Text('$gems', style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 14))),
              ],
            ),
          ),
          SizedBox(width: 6 * s),
          // Í¥ëÍ≥† ?úÏ≤≠ Î≤ÑÌäº
          _AdRewardButton(onGemsEarned: (amount) {
            ref.read(userStateProvider.notifier).addGems(amount);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('?íé +$amount Î≥¥ÏÑù ?çÎìù!'),
                backgroundColor: AppColors.skyBlue,
                duration: const Duration(seconds: 2),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkinGrid(
    BuildContext context,
    WidgetRef ref,
    HeroId heroId,
    SkinState skinState,
  ) {
    final skins = getSkinsForHero(heroId);
    // ?±Í∏â ???ïÎ†¨
    skins.sort((a, b) => a.rarity.index.compareTo(b.rarity.index));

    return GridView.builder(
      padding: Responsive.paddingAll(context, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.gridColumns(context),
        childAspectRatio: 0.6,
        crossAxisSpacing: 12 * Responsive.scale(context),
        mainAxisSpacing: 12 * Responsive.scale(context),
      ),
      itemCount: skins.length,
      itemBuilder: (context, index) {
        final skin = skins[index];
        final owned = skinState.ownedSkins.contains(skin.id);
        final equipped = skinState.equippedSkins[heroId] == skin.id;

        return _SkinCard(
          skin: skin,
          owned: owned,
          equipped: equipped,
          onTap: () => _onSkinTap(context, ref, skin, owned, equipped),
        );
      },
    );
  }

  void _onSkinTap(
    BuildContext context,
    WidgetRef ref,
    SkinData skin,
    bool owned,
    bool equipped,
  ) {
    if (equipped) return; // ?¥Î? ?•Ï∞© Ï§?

    if (owned) {
      // ?•Ï∞©
      ref.read(skinProvider.notifier).equipSkin(skin.heroId, skin.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${skin.name} ?§ÌÇ®???•Ï∞©?àÏäµ?àÎã§!'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // Íµ¨Îß§ ?ïÏù∏ ?§Ïù¥?ºÎ°úÍ∑?
      _showPurchaseDialog(context, ref, skin);
    }
  }

  void _showPurchaseDialog(
    BuildContext context, WidgetRef ref, SkinData skin,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${skin.rarity.emoji} ${skin.name}',
          style: TextStyle(color: skin.rarity.color, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ?§ÌÇ® ÎØ∏Î¶¨Î≥¥Í∏∞
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skin.primaryColor,
                border: skin.rarity.hasBorder
                    ? Border.all(color: skin.secondaryColor, width: 3)
                    : null,
                boxShadow: skin.rarity.hasGlow
                    ? [BoxShadow(color: skin.glowColor, blurRadius: 12)]
                    : null,
              ),
              child: ClipOval(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    skin.rarity == SkinRarity.common ? Colors.transparent : skin.primaryColor.withAlpha(100),
                    BlendMode.srcATop,
                  ),
                  child: HeroSpriteViewer(
                    imagePath: 'assets/images/heroes/${_getHeroFilePref(skin.heroId)}_tier${_getTierForRarity(skin.rarity)}_sprites.png',
                    width: 70,
                    height: 70,
                    fallbackText: skin.rarity.emoji,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '?±Í∏â: ${skin.rarity.displayName}',
              style: TextStyle(color: skin.rarity.color),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond, color: AppColors.skyBlue, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${skin.price}',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ï∑®ÏÜå', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
               backgroundColor: AppColors.sinmyeongGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              // Î≥¥ÏÑù Ï∞®Í∞ê
              final success = ref.read(userStateProvider.notifier).spendGems(skin.price);
              if (!success) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Î≥¥ÏÑù??Î∂ÄÏ°±Ìï©?àÎã§! Í¥ëÍ≥†Î•??úÏ≤≠?òÏó¨ Î≥¥ÏÑù???çÎìù?òÏÑ∏??'),
                    backgroundColor: Color(0xFFE53935),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              ref.read(skinProvider.notifier).unlockSkin(skin.id);
              ref.read(gameEventBridgeProvider).onSkinUnlocked();
              ref.read(skinProvider.notifier).equipSkin(skin.heroId, skin.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${skin.name} ?§ÌÇ®???çÎìù?àÏäµ?àÎã§!'),
                  backgroundColor: const Color(0xFF9C27B0),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Íµ¨Îß§'),
          ),
        ],
      ),
    );
  }

  String _getHeroName(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:  return 'Íπ®ÎπÑ';
      case HeroId.miho:    return 'ÎØ∏Ìò∏';
      case HeroId.gangrim: return 'Í∞ïÎ¶º';
      case HeroId.sua:     return '?òÏïÑ';
      case HeroId.bari:    return 'Î∞îÎ¶¨';
    }
  }
}

/// ?§ÌÇ® Ïπ¥Îìú ?ÑÏ†Ø
class _SkinCard extends StatelessWidget {
  final SkinData skin;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    // ?±Í∏âÎ≥?Í∏ÄÎ°úÏö∞ Í∞ïÎèÑ
    final double glowIntensity = switch (skin.rarity) {
      SkinRarity.common => 0,
      SkinRarity.uncommon => 4,
      SkinRarity.rare => 8,
      SkinRarity.epic => 14,
      SkinRarity.legendary => 18,
      SkinRarity.mythic => 22,
      SkinRarity.divine => 28,
    };
    // ?±Í∏âÎ≥?Î≥¥Îçî ?êÍªò
    final double borderWidth = switch (skin.rarity) {
      SkinRarity.common || SkinRarity.uncommon => 1,
      SkinRarity.rare || SkinRarity.epic => 1.5,
      SkinRarity.legendary || SkinRarity.mythic || SkinRarity.divine => 2.5,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14 * s),
          border: Border.all(
            color: equipped
                ? AppColors.sinmyeongGold
                : owned
                    ? skin.rarity.color.withAlpha(180)
                    : const Color(0x22FFFFFF),
            width: equipped ? 2.5 : borderWidth,
          ),
          boxShadow: (skin.rarity.hasGlow && owned) || equipped
              ? [
                  BoxShadow(
                    color: equipped
                        ? AppColors.sinmyeongGold.withAlpha(80)
                        : skin.glowColor.withAlpha(100),
                    blurRadius: glowIntensity,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13 * s),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Î∞∞Í≤Ω Í∑∏Îùº?îÏñ∏??
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: owned
                        ? [
                            skin.primaryColor.withAlpha(80),
                            Colors.black.withAlpha(180),
                            skin.secondaryColor.withAlpha(60),
                          ]
                        : [
                            Colors.black.withAlpha(160),
                            Colors.black.withAlpha(200),
                          ],
                  ),
                ),
              ),

              // Ï∫êÎ¶≠???¥Î?ÏßÄ (?ÄÎ∏îÎ¶¨????Ïπ¥Îìú ?ÑÏ≤¥Î•?Ï±ÑÏ?)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(top: 8 * s, left: 4 * s, right: 4 * s),
                  child: owned
                      ? ShaderMask(
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
                          blendMode: skin.rarity == SkinRarity.common
                              ? BlendMode.dstIn
                              : BlendMode.dstIn,
                          child: ColorFiltered(
                            colorFilter: skin.rarity == SkinRarity.common
                                ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                                : ColorFilter.mode(
                                    skin.primaryColor.withAlpha(40),
                                    BlendMode.srcATop,
                                  ),
                            child: HeroSpriteViewer(
                              imagePath: 'assets/images/heroes/${_getHeroFilePref(skin.heroId)}_tier${_getTierForRarity(skin.rarity)}_sprites.png',
                              width: double.infinity,
                              height: 180 * s, // ?Ä?µÏ†Å???íÏù¥ ?†Îãπ
                            ),
                          ),
                        )
                      : ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            0.2, 0.2, 0.2, 0, 0,
                            0.2, 0.2, 0.2, 0, 0,
                            0.2, 0.2, 0.2, 0, 0,
                            0, 0, 0, 0.35, 0,
                          ]),
                          child: HeroSpriteViewer(
                            imagePath: 'assets/images/heroes/${_getHeroFilePref(skin.heroId)}_tier${_getTierForRarity(skin.rarity)}_sprites.png',
                            width: double.infinity,
                            height: 180 * s,
                          ),
                        ),
                ),
              ),

              // ?ÅÎã®: ?±Í∏â Î∞∞Ï?
              Positioned(
                top: 6 * s,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          skin.rarity.color.withAlpha(120),
                          skin.rarity.color.withAlpha(50),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8 * s),
                      border: Border.all(
                        color: skin.rarity.color.withAlpha(150),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      skin.rarity.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: Colors.black.withAlpha(180), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ?†Í∏à ?ÑÏù¥ÏΩ?(ÎØ∏ÏÜå????
              if (!owned)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(10 * s),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Icon(Icons.lock_outline, color: Colors.white60, size: 20 * s),
                  ),
                ),

              // ?•Ï∞© Ï§?ÎßàÌÅ¨
              if (equipped)
                Positioned(
                  top: 6 * s,
                  right: 6 * s,
                  child: Container(
                    padding: EdgeInsets.all(4 * s),
                    decoration: BoxDecoration(
                      color: AppColors.sinmyeongGold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.sinmyeongGold.withAlpha(120), blurRadius: 8),
                      ],
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 10 * s),
                  ),
                ),

              // ?òÎã® ?§Î≤Ñ?àÏù¥ (?¥Î¶Ñ + Í∞ÄÍ≤?
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(8 * s, 12 * s, 8 * s, 8 * s),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(200),
                        Colors.black.withAlpha(230),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        skin.name,
                        style: TextStyle(
                          color: owned ? Colors.white : Colors.white60,
                          fontSize: Responsive.fontSize(context, 11),
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 6),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3 * s),
                      if (equipped)
                        Text(
                          '?•Ï∞© Ï§???,
                          style: TextStyle(
                            color: AppColors.sinmyeongGold,
                            fontSize: Responsive.fontSize(context, 9),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (!owned)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.diamond, color: AppColors.skyBlue, size: 12 * s),
                            SizedBox(width: 3 * s),
                            Text(
                              '${skin.price}',
                              style: TextStyle(
                                color: AppColors.skyBlue,
                                fontSize: Responsive.fontSize(context, 11),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Î≥¥Ïú† Ï§?,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: Responsive.fontSize(context, 9),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}







/// Í¥ëÍ≥† ?úÏ≤≠ Î≥¥ÏÉÅ Î≤ÑÌäº
class _AdRewardButton extends StatefulWidget {
  final void Function(int gems) onGemsEarned;

  const _AdRewardButton({required this.onGemsEarned});

  @override
  State<_AdRewardButton> createState() => _AdRewardButtonState();
}

class _AdRewardButtonState extends State<_AdRewardButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final adMgr = AdManager.instance;
    final canWatch = adMgr.canShowRewardedAd && !_loading;
    final remaining = adMgr.remainingDailyRewarded;
    final s = Responsive.scale(context);

    return Tooltip(
      message: 'Í¥ëÍ≥† ?úÏ≤≠?òÍ≥† 30Î≥¥ÏÑù ?çÎìù (${remaining}???®Ïùå)',
      child: GestureDetector(
        onTap: canWatch ? _watchAd : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 5 * s),
          decoration: BoxDecoration(
            gradient: canWatch
                ? const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
                  )
                : null,
            color: canWatch ? null : const Color(0xFF444444),
            borderRadius: BorderRadius.circular(14 * s),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loading)
                SizedBox(
                  width: 12 * s, height: 12 * s,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.play_circle_fill,
                  color: canWatch ? Colors.white : Colors.grey,
                  size: 14 * s,
                ),
              SizedBox(width: 3 * s),
              Text(
                '+30',
                style: TextStyle(
                  color: canWatch ? Colors.white : Colors.grey,
                  fontSize: Responsive.fontSize(context, 11),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 2 * s),
              Icon(
                Icons.diamond,
                color: canWatch ? AppColors.skyBlue : Colors.grey,
                size: 12 * s,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _watchAd() async {
    setState(() => _loading = true);

    await AdManager.instance.init();
    final reward = await AdManager.instance.showRewardedAd();

    if (mounted) {
      setState(() => _loading = false);
      if (reward != null) {
        widget.onGemsEarned(reward.gems);
      }
    }
  }
}

// ?Ä?Ä ?¨Ìçº ?®Ïàò: ?ÅÏõÖ/?ëÎëê??Î∞??∞Ïñ¥ ÎßµÌïë ?Ä?Ä

String _getHeroFilePref(HeroId id) {
  switch (id) {
    case HeroId.kkaebi:  return 'kkaebi';
    case HeroId.miho:    return 'guMiho';
    case HeroId.gangrim: return 'gangrim';
    case HeroId.sua:     return 'sua';
    case HeroId.bari:    return 'bari';
  }
}

int _getTierForRarity(SkinRarity rarity) {
  switch (rarity) {
    case SkinRarity.common: return 1;
    case SkinRarity.rare: return 2;
    case SkinRarity.epic: return 3;
    case SkinRarity.legendary: return 4;
  }
}

