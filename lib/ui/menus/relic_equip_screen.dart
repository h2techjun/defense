// 해원의 문 — 유물 장착 화면
// 영웅 선택 → 유물 슬롯 → 장착/해제

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/enums.dart';
import '../../data/models/relic_data.dart';
import '../../state/relic_provider.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFF1A0E2E),
      appBar: AppBar(
        title: const Text('유물 장착', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D1B69),
        foregroundColor: const Color(0xFFE8D5B7),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── 영웅 선택 탭 ──
          _buildHeroSelector(),

          const SizedBox(height: 16),

          // ── 현재 장착 유물 ──
          _buildEquippedSlot(equippedRelicId),

          const SizedBox(height: 16),

          // ── 유물 목록 ──
          Expanded(
            child: _buildRelicGrid(relicState),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSelector() {
    return Container(
      height: 70,
      color: const Color(0xFF2D1B69).withOpacity(0.5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: HeroId.values.map((heroId) {
          final isSelected = heroId == _selectedHero;
          return GestureDetector(
            onTap: () => setState(() => _selectedHero = heroId),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6B3FA0)
                    : const Color(0xFF1A0E2E),
                borderRadius: BorderRadius.circular(12),
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
                    style: const TextStyle(fontSize: 22),
                  ),
                  Text(
                    _heroNames[heroId] ?? '',
                    style: TextStyle(
                      fontSize: 10,
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

  Widget _buildEquippedSlot(RelicId? equippedId) {
    final relic = equippedId != null ? allRelics[equippedId] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D1B69),
            const Color(0xFF4A2C8A).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8D5B7).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // 슬롯 아이콘
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: relic != null
                  ? const Color(0xFF6B3FA0)
                  : const Color(0xFF1A0E2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: relic != null
                    ? const Color(0xFFFFD700)
                    : Colors.white24,
              ),
            ),
            child: Center(
              child: Text(
                relic?.iconEmoji ?? '✦',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 유물 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relic?.nameKo ?? '슬롯 비어있음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: relic != null
                        ? const Color(0xFFFFD700)
                        : Colors.white38,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relic?.description ?? '유물을 장착해주세요',
                  style: TextStyle(
                    fontSize: 11,
                    color: relic != null ? Colors.white70 : Colors.white30,
                  ),
                ),
              ],
            ),
          ),

          // 해제 버튼
          if (relic != null)
            IconButton(
              onPressed: () {
                ref.read(relicProvider.notifier).unequipRelic(_selectedHero);
              },
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildRelicGrid(RelicState relicState) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: allRelics.length,
      itemBuilder: (context, index) {
        final relicId = RelicId.values[index];
        final relic = allRelics[relicId]!;
        final isUnlocked = relicState.unlockedRelics.contains(relicId);
        final isEquippedHere = relicState.equippedRelics[_selectedHero] == relicId;

        // 다른 영웅이 장착 중인지
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
                      ? const Color(0xFF2D1B69)
                      : const Color(0xFF0D0618),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEquippedHere
                    ? const Color(0xFFFFD700)
                    : isUnlocked
                        ? const Color(0xFFE8D5B7).withOpacity(0.4)
                        : Colors.white12,
                width: isEquippedHere ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isUnlocked ? relic.iconEmoji : '🔒',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  relic.nameKo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : Colors.white30,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUnlocked
                      ? relic.description
                      : relic.unlockCondition,
                  style: TextStyle(
                    fontSize: 9,
                    color: isUnlocked ? Colors.white60 : Colors.white24,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (equippedByOther) ...[
                  const SizedBox(height: 2),
                  const Text(
                    '(다른 영웅 장착 중)',
                    style: TextStyle(fontSize: 8, color: Colors.orangeAccent),
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
