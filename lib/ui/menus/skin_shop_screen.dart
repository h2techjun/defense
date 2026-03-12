// 해원의 문 - 스킨 상점 화면
// 영웅별 스킨 목록 표시, 구매/장착 기능


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
          // 배경 에셋 투과
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/objects/obj_sotdae.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
            // ── 헤더 ──
            _buildHeader(context, userState.gems, ref),

            // ── 영웅 탭 + 스킨 목록 ──
            Expanded(
              child: DefaultTabController(
                length: HeroId.values.length,
                child: Column(
                  children: [
                    // 영웅 탭
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

                    // 스킨 그리드
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
            '🎨 스킨 상점',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.fontSize(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 보석 표시
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
          // 광고 시청 버튼
          _AdRewardButton(onGemsEarned: (amount) {
            ref.read(userStateProvider.notifier).addGems(amount);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('💎 +$amount 보석 획득!'),
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
    // 등급 순 정렬
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
    if (equipped) return; // 이미 장착 중

    if (owned) {
      // 장착
      ref.read(skinProvider.notifier).equipSkin(skin.heroId, skin.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${skin.name} 스킨을 장착했습니다!'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // 구매 확인 다이얼로그
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
            // 스킨 미리보기
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
              '등급: ${skin.rarity.displayName}',
              style: TextStyle(color: skin.rarity.color),
            ),
            // 이펙트 설명 (있는 경우만)
            if (skin.effectDescription != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: skin.rarity.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: skin.rarity.color.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡ ', style: TextStyle(fontSize: 14)),
                    Flexible(
                      child: Text(
                        skin.effectDescription!,
                        style: TextStyle(color: skin.rarity.color, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 배경 스토리 (있는 경우만)
            if (skin.lore != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  skin.lore!,
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
               backgroundColor: AppColors.sinmyeongGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              // 보석 차감
              final success = ref.read(userStateProvider.notifier).spendGems(skin.price);
              if (!success) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('보석이 부족합니다! 광고를 시청하여 보석을 획득하세요.'),
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
                  content: Text('${skin.name} 스킨을 획득했습니다!'),
                  backgroundColor: const Color(0xFF9C27B0),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('구매'),
          ),
        ],
      ),
    );
  }

  String _getHeroName(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:  return '깨비';
      case HeroId.miho:    return '미호';
      case HeroId.gangrim: return '강림';
      case HeroId.sua:     return '수아';
      case HeroId.bari:    return '바리';
    }
  }
}

/// 스킨 카드 위젯
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
    // 등급별 글로우 강도
    final double glowIntensity = switch (skin.rarity) {
      SkinRarity.common => 0.0,
      SkinRarity.rare => 8.0,
      SkinRarity.epic => 14.0,
      SkinRarity.legendary => 18.0,
    };
    // 등급별 보더 두께
    final double borderWidth = switch (skin.rarity) {
      SkinRarity.common => 1.0,
      SkinRarity.rare => 1.5,
      SkinRarity.epic => 1.5,
      SkinRarity.legendary => 2.5,
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
              // 배경 그라디언트
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

              // 캐릭터 이미지 (풀블리드 — 카드 전체를 채움)
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
                              height: 180 * s, // 대략적인 높이 할당
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

              // 상단: 등급 배지
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

              // 잠금 아이콘 (미소유 시)
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

              // 장착 중 마크
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

              // 하단 오버레이 (이름 + 가격)
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
                          '장착 중 ✨',
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
                          '보유 중',
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







/// 광고 시청 보상 버튼
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
      message: '광고 시청하고 30보석 획득 (${remaining}회 남음)',
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

// ── 헬퍼 함수: 영웅/접두사 및 티어 맵핑 ──

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
