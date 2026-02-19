// 해원의 문 - 출전 준비 화면
// 스테이지 선택 후, 전투 시작 전 영웅 파티를 편성하는 화면

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/enums.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/hero_data.dart';
import '../../data/models/wave_data.dart';
import '../../state/hero_party_provider.dart';
import '../../state/user_state.dart';

/// 영웅 해금 조건: 해당 스테이지 클리어 시 해금
const Map<HeroId, int> heroUnlockStage = {
  HeroId.kkaebi: 0,  // 기본 해금
  HeroId.miho: 3,    // 스테이지 3 클리어
  HeroId.gangrim: 5, // 스테이지 5 클리어
  HeroId.sua: 8,     // 스테이지 8 클리어
  HeroId.bari: 10,   // 스테이지 10 클리어
};

/// 출전 준비 화면 — 영웅 파티 편성 후 전투 시작
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

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ──
            _buildHeader(),

            const SizedBox(height: 12),

            // ── 스테이지 정보 ──
            _buildStageInfo(),

            const SizedBox(height: 20),

            // ── 출전 파티 (상단 슬롯 1개) ──
            _buildPartySlots(partyState),

            const SizedBox(height: 16),

            // ── 구분선 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFF333355))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '영웅 선택',
                      style: TextStyle(
                        color: Colors.white.withAlpha(120),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFF333355))),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 영웅 목록 (하단 선택 풀) ──
            Expanded(
              child: _buildHeroPool(allHeroes, partyState, userState),
            ),

            // ── 출전 버튼 ──
            _buildDeployButton(partyState),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
          ),
          const Text(
            '⚔️ 출전 준비',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A3E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4444AA)),
            ),
            child: Text(
              '영웅 1명 선택',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151530),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333366)),
      ),
      child: Row(
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stage ${widget.level.levelNumber}',
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.level.waves.length} 웨이브',
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 난이도 표시
          Row(
            children: List.generate(3, (i) {
              final difficulty = (widget.level.levelNumber / 4).ceil().clamp(1, 3);
              return Icon(
                i < difficulty ? Icons.star : Icons.star_border,
                color: const Color(0xFFFFD700),
                size: 18,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPartySlots(HeroPartyState partyState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(HeroPartyState.maxPartySize, (index) {
          final hasHero = index < partyState.party.length;
          final slot = hasHero ? partyState.party[index] : null;
          final heroData = slot != null ? GameDataLoader.getHeroes()[slot.heroId] : null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _PartySlotWidget(
              heroData: heroData,
              slotIndex: index,
              isEmpty: !hasHero,
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

  Widget _buildHeroPool(List<HeroData> allHeroes, HeroPartyState partyState, UserState userState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
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

  Widget _buildDeployButton(HeroPartyState partyState) {
    final isReady = partyState.party.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isReady ? 1.0 + _pulseController.value * 0.03 : 1.0;
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isReady
                    ? () => widget.onStartBattle(widget.level)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF333355),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isReady ? 8 : 0,
                  shadowColor: const Color(0xFF8B5CF6).withAlpha(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: isReady ? Colors.white : Colors.white38,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isReady
                          ? '⚔️ 출전! (${partyState.party.length}명)'
                          : '영웅을 선택하세요',
                      style: TextStyle(
                        color: isReady ? Colors.white : Colors.white38,
                        fontSize: 18,
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

/// 파티 슬롯 위젯 (상단 1칸)
class _PartySlotWidget extends StatelessWidget {
  final HeroData? heroData;
  final int slotIndex;
  final bool isEmpty;
  final VoidCallback? onRemove;

  const _PartySlotWidget({
    required this.heroData,
    required this.slotIndex,
    required this.isEmpty,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEmpty
        ? const Color(0xFF222244)
        : _getHeroColor(heroData!.id);

    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: color.withAlpha(isEmpty ? 60 : 40),
        borderRadius: BorderRadius.circular(16),
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
                      color: Colors.white.withAlpha(60), size: 32),
                  const SizedBox(height: 4),
                  Text(
                    '슬롯 ${slotIndex + 1}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(60),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                // 영웅 정보
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _getHeroEmoji(heroData!.id),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      heroData!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      heroData!.title,
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                // 제거 버튼
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withAlpha(180),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _getHeroColor(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:
        return const Color(0xFF4CAF50);
      case HeroId.miho:
        return const Color(0xFFE91E63);
      case HeroId.gangrim:
        return const Color(0xFF607D8B);
      case HeroId.sua:
        return const Color(0xFF2196F3);
      case HeroId.bari:
        return const Color(0xFFFFEB3B);
    }
  }

  String _getHeroEmoji(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:
        return '👹';
      case HeroId.miho:
        return '🦊';
      case HeroId.gangrim:
        return '💀';
      case HeroId.sua:
        return '🌊';
      case HeroId.bari:
        return '🌸';
    }
  }
}

/// 영웅 풀 카드 위젯 (하단 선택 영역)
class _HeroPoolCard extends StatelessWidget {
  final HeroData hero;
  final bool isSelected;
  final bool isLocked;
  final int unlockStage;
  final VoidCallback? onTap;

  const _HeroPoolCard({
    required this.hero,
    required this.isSelected,
    this.isLocked = false,
    this.unlockStage = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getHeroColor(hero.id);

    // 호버 시 영웅 상세 정보 표시
    final tooltipMessage = isLocked
        ? '🔒 ${hero.name}\nStage $unlockStage 클리어 시 해금'
        : '${_getHeroEmoji(hero.id)} ${hero.name} — ${hero.title}\n\n'
          '✨ 스킬: ${hero.skill.name}\n'
          '${hero.skill.description}\n\n'
          '❤️ HP: ${hero.baseHp.toInt()}  ⚔️ ATK: ${hero.baseAttack.toInt()}';

    return Tooltip(
      message: tooltipMessage,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isLocked
                ? const Color(0xFF0D0D1A)
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
              ? _buildLockedContent(color)
              : _buildUnlockedContent(color),
        ),
      ),
    );
  }

  Widget _buildLockedContent(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.3,
              child: Text(
                _getHeroEmoji(hero.id),
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.lock, color: Color(0xFF555577), size: 16),
            const SizedBox(height: 2),
            Text(
              hero.name,
              style: const TextStyle(
                color: Color(0xFF555577),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Stage $unlockStage',
              style: const TextStyle(
                color: Color(0xFF777799),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedContent(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 선택 체크 아이콘
        if (isSelected)
          const Positioned(
            top: 4,
            right: 4,
            child: Icon(Icons.check_circle,
                color: Color(0xFF10B981), size: 16),
          ),
        // 카드 콘텐츠
        Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getHeroEmoji(hero.id),
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(height: 2),
              Text(
                hero.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                hero.title,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              // 스탯 한 줄
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '❤️${hero.baseHp.toInt()}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '⚔️${hero.baseAttack.toInt()}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
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
    switch (id) {
      case HeroId.kkaebi:
        return const Color(0xFF4CAF50);
      case HeroId.miho:
        return const Color(0xFFE91E63);
      case HeroId.gangrim:
        return const Color(0xFF607D8B);
      case HeroId.sua:
        return const Color(0xFF2196F3);
      case HeroId.bari:
        return const Color(0xFFFFEB3B);
    }
  }

  String _getHeroEmoji(HeroId id) {
    switch (id) {
      case HeroId.kkaebi:
        return '👹';
      case HeroId.miho:
        return '🦊';
      case HeroId.gangrim:
        return '💀';
      case HeroId.sua:
        return '🌊';
      case HeroId.bari:
        return '🌸';
    }
  }
}
