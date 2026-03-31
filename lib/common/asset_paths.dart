/// 이미지 에셋 확장자 매핑 유틸리티
/// PNG → WebP/JPG 마이그레이션 후 올바른 확장자를 반환
class AssetPaths {
  AssetPaths._();

  /// JPG로 변환된 파일 목록 (불투명 이미지)
  static const _jpgFiles = <String>{
    'app_icon',
    'bg/bg_hero_manage',
    'bg/bg_main_menu',
    'bg/bg_stage_1',
    'bg/bg_stage_2',
    'bg/bg_stage_select',
    'bg/bg_tower_manage',
    // 주의: HeroId.miho의 파일명은 'guMiho'이므로 miho_evo* 항목은 사용되지 않음
    // (heroes/miho_evo*.jpg 파일은 존재하나 코드에서 guMiho_evo*.webp를 사용)
    'objects/obj_grave_mound',
    'objects/obj_old_well',
    'objects/obj_sotdae',
  };

  /// .png 경로를 실제 확장자(.webp/.jpg)로 변환
  /// [path]는 'heroes/xxx_sprites.png' 또는 'assets/images/heroes/xxx.png' 형태
  static String resolve(String path) {
    // .png가 아니면 그대로 반환
    if (!path.endsWith('.png')) return path;

    final withoutExt = path.substring(0, path.length - 4);

    // assets/images/ 프리픽스가 있으면 제거 후 체크
    final key = withoutExt.startsWith('assets/images/')
        ? withoutExt.substring('assets/images/'.length)
        : withoutExt;

    final ext = _jpgFiles.contains(key) ? '.jpg' : '.webp';
    return '$withoutExt$ext';
  }

  /// Flame 이미지 경로 (images/ 기준 상대 경로)
  /// e.g., image('heroes/bari_tier1_sprites') → 'heroes/bari_tier1_sprites.webp'
  static String image(String nameWithoutExt) {
    final ext = _jpgFiles.contains(nameWithoutExt) ? '.jpg' : '.webp';
    return '$nameWithoutExt$ext';
  }

  /// Flutter AssetImage 경로
  /// e.g., asset('bg/bg_main_menu') → 'assets/images/bg/bg_main_menu.jpg'
  static String asset(String nameWithoutExt) {
    final ext = _jpgFiles.contains(nameWithoutExt) ? '.jpg' : '.webp';
    return 'assets/images/$nameWithoutExt$ext';
  }
}
