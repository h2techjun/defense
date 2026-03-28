// 해원의 문 - 영웅 관리 헬퍼 메서드
// 영웅별 색상, 이모지, 파일명, 역할, 데미지 타입 관련 유틸리티

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/enums.dart';
import '../../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';

Color getHeroColor(HeroId id) {
  return switch (id) {
    HeroId.kkaebi => const Color(0xFF44BB44),
    HeroId.miho => const Color(0xFFFF66AA),
    HeroId.gangrim => const Color(0xFF7744CC),
    HeroId.sua => AppColors.statRange,
    HeroId.bari => const Color(0xFFFFBB44),
  };
}

String getHeroEmoji(HeroId id) {
  return switch (id) {
    HeroId.kkaebi => '👹',
    HeroId.miho => '🦊',
    HeroId.gangrim => '💀',
    HeroId.sua => '🌊',
    HeroId.bari => '🪬',
  };
}

String getHeroFileName(HeroId id) {
  return switch (id) {
    HeroId.kkaebi => 'kkaebi',
    HeroId.miho => 'guMiho',
    HeroId.gangrim => 'gangrim',
    HeroId.sua => 'sua',
    HeroId.bari => 'bari',
  };
}

String getRoleLabel(WidgetRef ref, HeroId id) {
  final lang = ref.watch(gameLanguageProvider);
  return switch (id) {
    HeroId.kkaebi => AppStrings.get(lang, 'hero_role_tanker'),
    HeroId.miho => AppStrings.get(lang, 'hero_role_mage'),
    HeroId.gangrim => AppStrings.get(lang, 'hero_role_sniper'),
    HeroId.sua => AppStrings.get(lang, 'hero_role_cc'),
    HeroId.bari => AppStrings.get(lang, 'hero_role_support'),
  };
}

String getDamageLabel(WidgetRef ref, DamageType type) {
  final lang = ref.watch(gameLanguageProvider);
  return switch (type) {
    DamageType.physical => AppStrings.get(lang, 'dmg_physical'),
    DamageType.magical => AppStrings.get(lang, 'dmg_magical'),
    DamageType.purification => AppStrings.get(lang, 'dmg_purification'),
  };
}

Color getDamageColor(DamageType type) {
  return switch (type) {
    DamageType.physical => const Color(0xFFFF8844),
    DamageType.magical => const Color(0xFF8844FF),
    DamageType.purification => const Color(0xFFFFDD44),
  };
}
