// 해원의 문 - 영웅 스탯/스킬 섹션
// 진화 탭, 진화 정보, 배율 칩, 스탯 바, 스킬 정보 카드

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/enums.dart';
import '../../../common/responsive.dart';
import '../../../data/models/hero_data.dart';
import '../../../l10n/app_strings.dart';
import '../../../state/user_state.dart';
import '../../common/hero_sprite_viewer.dart';
import '../../theme/app_colors.dart';
import '../../../common/asset_paths.dart';
import 'hero_helpers.dart';

class HeroStatsSection extends ConsumerWidget {
  final HeroData hero;
  final Color color;
  final int selectedEvolutionIndex;
  final ValueChanged<int> onEvolutionIndexChanged;

  const HeroStatsSection({
    super.key,
    required this.hero,
    required this.color,
    required this.selectedEvolutionIndex,
    required this.onEvolutionIndexChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evo = hero.evolutions[selectedEvolutionIndex.clamp(0, hero.evolutions.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 진화 단계 선택
        _buildEvolutionTabs(context, ref, hero, color),
        SizedBox(height: 16 * Responsive.scale(context)),

        // 진화 설명
        _buildEvolutionInfo(context, ref, evo, color),
        SizedBox(height: 20 * Responsive.scale(context)),

        // 스탯 바
        _buildStatBars(context, ref, hero, evo, color),
        SizedBox(height: 20 * Responsive.scale(context)),

        // 스킬 정보
        _buildSkillSection(context, ref, hero, color),
      ],
    );
  }

  /// 진화 단계 탭 (스탯 관련 -- 기본/중급/궁극)
  Widget _buildEvolutionTabs(BuildContext context, WidgetRef ref, HeroData hero, Color color) {
    final heroLevel = ref.watch(userStateProvider).heroLevels[hero.id] ?? 1;

    return Row(
      children: List.generate(hero.evolutions.length, (i) {
        final evo = hero.evolutions[i];
        final isSelected = i == selectedEvolutionIndex;
        final heroFileName = getHeroFileName(hero.id);
        final tierNumber = i + 1;

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
        final requiredLevel = switch (evo.tier) {
          EvolutionTier.base => 1,
          EvolutionTier.intermediate => 15,
          EvolutionTier.ultimate => 35,
        };
        final tierBadge = 'Lv.$requiredLevel';
        final isLocked = heroLevel < requiredLevel;

        return Expanded(
          child: GestureDetector(
            onTap: isLocked ? null : () => onEvolutionIndexChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: i < hero.evolutions.length - 1 ? 6 : 0),
              padding: EdgeInsets.symmetric(vertical: 8 * Responsive.scale(context), horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected && !isLocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tierColor.withValues(alpha: 0.35),
                          tierColor.withValues(alpha: 0.1),
                        ],
                      )
                    : null,
                color: isSelected && !isLocked ? null : const Color(0x08FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLocked
                      ? AppColors.surfaceOverlayDim
                      : isSelected
                          ? tierColor.withValues(alpha: 0.6)
                          : AppColors.surfaceOverlayDim,
                  width: isSelected && !isLocked ? 1.5 : 1,
                ),
                boxShadow: isSelected && !isLocked
                    ? [BoxShadow(color: tierColor.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: Opacity(
                opacity: isLocked ? 0.4 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 스프라이트 또는 잠금 아이콘
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40 * Responsive.scale(context),
                          height: 40 * Responsive.scale(context),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLocked
                                  ? AppColors.textGhost
                                  : isSelected ? tierColor : tierColor.withValues(alpha: 0.3),
                              width: isSelected && !isLocked ? 2 : 1,
                            ),
                            boxShadow: isSelected && !isLocked && evo.tier == EvolutionTier.ultimate
                                ? [BoxShadow(color: tierColor.withValues(alpha: 0.5), blurRadius: 10)]
                                : null,
                          ),
                          child: ClipOval(
                            child: HeroSpriteViewer(
                              imagePath: AssetPaths.asset('heroes/${heroFileName}_evo${tierNumber}_sprites'),
                              width: 40 * Responsive.scale(context),
                              height: 40 * Responsive.scale(context),
                              fallbackText: evo.tier == EvolutionTier.base ? '⚪' : evo.tier == EvolutionTier.intermediate ? '🔵' : '🟣',
                            ),
                          ),
                        ),
                        if (isLocked)
                          Icon(Icons.lock, color: AppColors.textDisabled, size: 20 * Responsive.scale(context)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tierLabel,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 10),
                        color: isLocked ? Colors.white30 : isSelected ? Colors.white : AppColors.textMid,
                        fontWeight: isSelected && !isLocked ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: isSelected && !isLocked ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tierBadge,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 8),
                          color: isLocked ? Colors.white30 : isSelected ? tierColor : AppColors.textFaint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 진화 단계 정보
  Widget _buildEvolutionInfo(BuildContext context, WidgetRef ref, HeroEvolutionData evo, Color color) {
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
            '✨ ${AppStrings.trs(evo.visualName)}',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 15),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.trs(evo.description),
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
                    _buildMultiplierChip(context, 'HP', evo.hpMultiplier, const Color(0xFF44DD44)),
                  if (evo.attackMultiplier > 1.0)
                    _buildMultiplierChip(context, AppStrings.get(ref.watch(gameLanguageProvider), 'stat_attack'), evo.attackMultiplier, AppColors.statAttack),
                  if (evo.rangeMultiplier > 1.0)
                    _buildMultiplierChip(context, AppStrings.get(ref.watch(gameLanguageProvider), 'stat_range'), evo.rangeMultiplier, AppColors.statRange),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiplierChip(BuildContext context, String stat, double mult, Color color) {
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
  Widget _buildStatBars(BuildContext context, WidgetRef ref, HeroData hero, HeroEvolutionData evo, Color color) {
    final lang = ref.watch(gameLanguageProvider);
    final stats = [
      ('HP', hero.baseHp * evo.hpMultiplier, 1000.0, const Color(0xFF44DD44)),
      (AppStrings.get(lang, 'stat_attack_power'), hero.baseAttack * evo.attackMultiplier, 200.0, AppColors.statAttack),
      (AppStrings.get(lang, 'stat_range'), hero.baseRange * evo.rangeMultiplier, 400.0, AppColors.statRange),
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
        ...stats.map((s) => _buildStatBar(context, s.$1, s.$2, s.$3, s.$4)),
      ],
    );
  }

  Widget _buildStatBar(BuildContext context, String label, double value, double max, Color color) {
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
                color: AppColors.surfaceOverlayDim,
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
  Widget _buildSkillSection(BuildContext context, WidgetRef ref, HeroData hero, Color color) {
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
                      AppStrings.trs(skill.name),
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
            AppStrings.trs(skill.description),
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 12),
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTag(context, '${AppStrings.get(ref.watch(gameLanguageProvider), "skill_damage")}: ${skill.damage.toInt()}', AppColors.statAttack),
              if (skill.duration > 0) ...[
                const SizedBox(width: 6),
                _buildTag(context, '${AppStrings.get(ref.watch(gameLanguageProvider), "skill_duration")}: ${skill.duration.toInt()}s', AppColors.statRange),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 태그 뱃지
  Widget _buildTag(BuildContext context, String label, Color color) {
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
}
