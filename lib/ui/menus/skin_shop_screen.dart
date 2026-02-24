// 해원의 문 - 스킨 상점 화면
// 영웅별 스킨 목록 표시, 구매/장착 기능

import 'dart:ui';
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

class SkinShopScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const SkinShopScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinState = ref.watch(skinProvider);
    final userState = ref.watch(userStateProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
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
                      unselectedLabelColor: Colors.grey,
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
    );
  }

  Widget _buildHeader(BuildContext context, int gems, WidgetRef ref) {
    final s = Responsive.scale(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF333366))),
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
        childAspectRatio: 0.75,
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
            ),
            const SizedBox(height: 12),
            Text(
              '등급: ${skin.rarity.displayName}',
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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12 * s),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(60),
          borderRadius: BorderRadius.circular(12 * s),
          border: equipped
              ? Border.all(color: AppColors.sinmyeongGold, width: 2)
              : (owned
                  ? Border.all(color: skin.rarity.color.withAlpha(128), width: 1)
                  : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 등급 배지
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
              decoration: BoxDecoration(
                color: skin.rarity.color.withAlpha(51),
                borderRadius: BorderRadius.circular(6 * s),
              ),
              child: Text(
                skin.rarity.displayName,
                style: TextStyle(
                  color: skin.rarity.color,
                  fontSize: Responsive.fontSize(context, 10),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10 * s),

            // 스킨 미리보기 (원형)
            Container(
              width: 50 * s,
              height: 50 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: owned ? skin.primaryColor : skin.primaryColor.withAlpha(77),
                border: skin.rarity.hasBorder
                    ? Border.all(color: skin.secondaryColor, width: 2)
                    : null,
                boxShadow: skin.rarity.hasGlow && owned
                    ? [BoxShadow(color: skin.glowColor, blurRadius: 8)]
                    : null,
              ),
              child: !owned
                  ? Icon(Icons.lock, color: Colors.white38, size: 20 * s)
                  : null,
            ),
            SizedBox(height: 8 * s),

            // 스킨 이름
            Text(
              skin.name,
              style: TextStyle(
                color: owned ? Colors.white : Colors.grey,
                fontSize: Responsive.fontSize(context, 11),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4 * s),

            // 상태 표시
            if (equipped)
              Text(
                '장착 중',
                style: TextStyle(color: AppColors.sinmyeongGold, fontSize: Responsive.fontSize(context, 10)),
              )
            else if (!owned)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diamond, color: AppColors.skyBlue, size: 12 * s),
                  SizedBox(width: 2 * s),
                  Text(
                    '${skin.price}',
                    style: TextStyle(color: AppColors.skyBlue, fontSize: Responsive.fontSize(context, 11)),
                  ),
                ],
              ),
          ],
        ),
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
