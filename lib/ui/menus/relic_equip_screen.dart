// 해원의 문 — 유물 장착 화면 (반응형)
// 영웅 선택 → 유물 슬롯 → 장착/해제

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../data/models/relic_data.dart';
import '../../state/relic_provider.dart';
import '../theme/app_colors.dart';

/// 유물 장착 화면
class RelicEquipScreen extends ConsumerStatefulWidget {
  const RelicEquipScreen({super.key});

  @override
  ConsumerState<RelicEquipScreen> createState() => _RelicEquipScreenState();
}

class _RelicEquipScreenState extends ConsumerState<RelicEquipScreen> {
  HeroId _selectedHero = HeroId.kkaebi;

  static const _heroNames = {
    HeroId.kkaebi: '깨비',
    HeroId.miho: '미호',
    HeroId.gangrim: '강림',
    HeroId.sua: '수아',
    HeroId.bari: '바리',
  };

  static const _heroEmojis = {
    HeroId.kkaebi: '👹',
    HeroId.miho: '🦊',
    HeroId.gangrim: '💀',
    HeroId.sua: '🌊',
    HeroId.bari: '🔔',
  };

  @override
  Widget build(BuildContext context) {
    final relicState = ref.watch(relicProvider);
    final equippedRelicId = relicState.equippedRelics[_selectedHero];
    final s = Responsive.scale(context);
    final isLand = Responsive.isLandscape(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0E2E),
      appBar: AppBar(
        title: Text('유물 장착', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Responsive.fontSize(context, 18),
        )),
        backgroundColor: AppColors.surfaceMid,
        foregroundColor: const Color(0xFFE8D5B7),
        elevation: 0,
        toolbarHeight: 48 * s,
      ),
      body: isLand
          ? _buildLandscape(equippedRelicId, relicState, s)
          : _buildPortrait(equippedRelicId, relicState, s),
    );
  }

  Widget _buildPortrait(RelicId? equippedRelicId, RelicState relicState, double s) {
    return Column(
      children: [
        _buildHeroSelector(s),
        SizedBox(height: 12 * s),
        _buildEquippedSlot(equippedRelicId, s),
        SizedBox(height: 12 * s),
        Expanded(child: _buildRelicGrid(relicState, s)),
      ],
    );
  }

  Widget _buildLandscape(RelicId? equippedRelicId, RelicState relicState, double s) {
    return Row(
      children: [
        // 좌: 영웅 선택 + 장착슬롯
        SizedBox(
          width: Responsive.adaptiveWidth(context, 0.35),
          child: Column(
            children: [
              _buildHeroSelector(s),
              SizedBox(height: 10 * s),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 8 * s),
                  child: _buildEquippedSlot(equippedRelicId, s),
                ),
              ),
            ],
          ),
        ),
        // 우: 유물 그리드
        Expanded(child: _buildRelicGrid(relicState, s)),
      ],
    );
  }

  Widget _buildHeroSelector(double s) {
    return Container(
      height: 60 * s,
      color: AppColors.surfaceMid.withOpacity(0.5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 6 * s),
        children: HeroId.values.map((heroId) {
          final isSelected = heroId == _selectedHero;
          return GestureDetector(
            onTap: () => setState(() => _selectedHero = heroId),
            child: Container(
              width: 54 * s,
              margin: EdgeInsets.symmetric(horizontal: 3 * s),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6B3FA0)
                    : const Color(0xFF1A0E2E),
                borderRadius: BorderRadius.circular(10 * s),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE8D5B7)
                      : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _heroEmojis[heroId] ?? '?',
                    style: TextStyle(fontSize: Responsive.fontSize(context, 18)),
                  ),
                  Text(
                    _heroNames[heroId] ?? '',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 9),
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEquippedSlot(RelicId? equippedId, double s) {
    final relic = equippedId != null ? allRelics[equippedId] : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14 * s),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
      margin: EdgeInsets.symmetric(horizontal: 14 * s),
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceMid,
            const Color(0xFF4A2C8A).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(
          color: const Color(0xFFE8D5B7).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48 * s,
            height: 48 * s,
            decoration: BoxDecoration(
              color: relic != null
                  ? const Color(0xFF6B3FA0)
                  : const Color(0xFF1A0E2E),
              borderRadius: BorderRadius.circular(10 * s),
              border: Border.all(
                color: relic != null
                    ? AppColors.sinmyeongGold
                    : Colors.white24,
              ),
            ),
            child: Center(
              child: Text(
                relic?.iconEmoji ?? '✦',
                style: TextStyle(fontSize: Responsive.fontSize(context, 24)),
              ),
            ),
          ),
          SizedBox(width: 14 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relic?.nameKo ?? '슬롯 비어있음',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 14),
                    fontWeight: FontWeight.bold,
                    color: relic != null
                        ? AppColors.sinmyeongGold
                        : Colors.white38,
                  ),
                ),
                SizedBox(height: 3 * s),
                Text(
                  relic?.description ?? '유물을 장착해주세요',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 10),
                    color: relic != null ? Colors.white70 : Colors.white30,
                  ),
                ),
              ],
            ),
          ),
          if (relic != null)
            IconButton(
              onPressed: () {
                ref.read(relicProvider.notifier).unequipRelic(_selectedHero);
              },
              icon: Icon(Icons.close, color: Colors.redAccent, size: 18 * s),
            ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildRelicGrid(RelicState relicState, double s) {
    final cols = Responsive.value<int>(context, phone: 2, tablet: 3, desktop: 4);

    return GridView.builder(
      padding: EdgeInsets.all(14 * s),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10 * s,
        crossAxisSpacing: 10 * s,
        childAspectRatio: 1.2,
      ),
      itemCount: allRelics.length,
      itemBuilder: (context, index) {
        final relicId = RelicId.values[index];
        final relic = allRelics[relicId]!;
        final isUnlocked = relicState.unlockedRelics.contains(relicId);
        final isEquippedHere = relicState.equippedRelics[_selectedHero] == relicId;

        final equippedByOther = relicState.equippedRelics.entries
            .where((e) => e.value == relicId && e.key != _selectedHero)
            .isNotEmpty;

        return GestureDetector(
          onTap: isUnlocked && !isEquippedHere
              ? () => ref.read(relicProvider.notifier).equipRelic(_selectedHero, relicId)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isEquippedHere
                  ? const Color(0xFF6B3FA0)
                  : isUnlocked
                      ? AppColors.surfaceMid
                      : const Color(0xFF0D0618),
              borderRadius: BorderRadius.circular(10 * s),
              border: Border.all(
                color: isEquippedHere
                    ? AppColors.sinmyeongGold
                    : isUnlocked
                        ? const Color(0xFFE8D5B7).withOpacity(0.4)
                        : Colors.white12,
                width: isEquippedHere ? 2 : 1,
              ),
            ),
            padding: EdgeInsets.all(10 * s),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isUnlocked ? relic.iconEmoji : '🔒',
                  style: TextStyle(fontSize: Responsive.fontSize(context, 24)),
                ),
                SizedBox(height: 6 * s),
                Text(
                  relic.nameKo,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 11),
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : Colors.white30,
                  ),
                ),
                SizedBox(height: 3 * s),
                Text(
                  isUnlocked
                      ? relic.description
                      : relic.unlockCondition,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 8),
                    color: isUnlocked ? Colors.white60 : Colors.white24,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (equippedByOther) ...[
                  SizedBox(height: 2 * s),
                  Text(
                    '(다른 영웅 장착 중)',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 7),
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
