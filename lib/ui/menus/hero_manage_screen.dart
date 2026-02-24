// 해원의 문 - 영웅(수호자) 관리 화면
// 영웅 선택, 정보 확인, 진화 단계별 능력 열람

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/enums.dart';
import '../../common/responsive.dart';
import '../../data/game_data_loader.dart';
import '../../data/models/hero_data.dart';
import '../../l10n/app_strings.dart';
import '../../services/save_manager.dart';
import '../../game/components/actors/base_hero.dart';
import '../theme/app_colors.dart';

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
    return Scaffold(
      body: Container(
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
                      child: _buildHeroList(),
                    ),
                    // 오른쪽: 영웅 상세
                    Expanded(
                      child: _buildHeroDetail(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
  Widget _buildHeroList() {
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
          return _buildHeroCard(hero, isSelected);
        },
      ),
    );
  }

  /// 영웅 카드 (리스트 아이템)
  Widget _buildHeroCard(HeroData hero, bool isSelected) {
    final color = _getHeroColor(hero.id);
    return GestureDetector(
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
                child: Image.asset(
                  'assets/images/heroes/hero_${_getHeroFileName(hero.id)}_1.png',
                  width: 40 * Responsive.scale(context),
                  height: 40 * Responsive.scale(context),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      _getHeroEmoji(hero.id),
                      style: TextStyle(fontSize: Responsive.fontSize(context, 18)),
                    ),
                  ),
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
  Widget _buildHeroDetail() {
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
            // 영웅 이름 & 칭호
            _buildNameSection(hero, color),
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
  Widget _buildNameSection(HeroData hero, Color color) {
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
                child: Image.asset(
                  'assets/images/heroes/hero_${_getHeroFileName(hero.id)}_1.png',
                  width: 72 * Responsive.scale(context),
                  height: 72 * Responsive.scale(context),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      _getHeroEmoji(hero.id),
                      style: TextStyle(fontSize: Responsive.fontSize(context, 32)),
                    ),
                  ),
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
                hero.name,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 28),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4 * Responsive.scale(context)),
              Text(
                hero.title,
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
  Widget _buildEvolutionTabs(HeroData hero, Color color) {
    return Row(
      children: List.generate(hero.evolutions.length, (i) {
        final evo = hero.evolutions[i];
        final isSelected = i == _selectedEvolutionIndex;
        final tierName = switch (evo.tier) {
          EvolutionTier.base => AppStrings.get(ref.watch(gameLanguageProvider), 'evo_base'),
          EvolutionTier.intermediate => AppStrings.get(ref.watch(gameLanguageProvider), 'evo_intermediate'),
          EvolutionTier.ultimate => AppStrings.get(ref.watch(gameLanguageProvider), 'evo_ultimate'),
        };
        final tierIcon = switch (evo.tier) {
          EvolutionTier.base => '⚪',
          EvolutionTier.intermediate => '🔵',
          EvolutionTier.ultimate => '🟣',
        };

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedEvolutionIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < hero.evolutions.length - 1 ? 6 : 0),
              padding: EdgeInsets.symmetric(vertical: 10 * Responsive.scale(context)),
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color.withValues(alpha: 0.5) : const Color(0x22FFFFFF),
                ),
              ),
              child: Column(
                children: [
                  Text(tierIcon, style: TextStyle(fontSize: Responsive.fontSize(context, 14))),
                  const SizedBox(height: 2),
                  Text(
                    tierName,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 11),
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  /// 배경 이야기
  Widget _buildBackstorySection(HeroData hero, Color color) {
    return Container(
      padding: EdgeInsets.all(12 * Responsive.scale(context)),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x11FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 설화',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 13),
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hero.backstory,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
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
      HeroId.miho => 'miho',
      HeroId.gangrim => 'gangrim',
      HeroId.sua => 'sua',
      HeroId.bari => 'bari',
    };
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
