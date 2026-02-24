// 🎨 팝 코리안 고스트 — 아트 디렉션 컬러 팔레트 v2
// GDD §I-B.2 기준 · "귀엽고 밝고 따뜻한" 톤
// 레퍼런스: 쿠키런 킹덤, 케이팝 데몬 헌터스

import 'package:flutter/material.dart';

/// 앱 전역 컬러 팔레트 — "팝 코리안 고스트" 스타일
/// 어두운 세계관 속 밝고 따뜻한 팝 색상
abstract class AppColors {
  AppColors._();

  // ── 메인 팔레트 (따뜻하고 밝은 톤) ──

  /// 🌸 벚꽃 핑크 — 주 컬러. UI 하이라이트, 활성 상태, 영웅 스킬
  static const Color cherryBlossom = Color(0xFFFF7EB3);

  /// 🍑 피치 코랄 — 강조. 버튼 그라디언트, 따뜻한 악센트
  static const Color peachCoral = Color(0xFFFF9A76);

  /// 💜 라벤더 — 신비/영혼. 원혼, 정화, 밤 모드 (밝은 보라)
  static const Color lavender = Color(0xFFC084FC);

  /// 🟡 신명 골드 — 재화. 신명석, 금, 보상 연출
  static const Color sinmyeongGold = Color(0xFFFBBF24);

  /// 🌿 민트 그린 — 힐/버프. 치유, 체력 바, 안전 상태
  static const Color mintGreen = Color(0xFF34D399);

  /// 🔴 광폭 레드 — 위험. 광폭화, 데미지, 경고
  static const Color berserkRed = Color(0xFFEF4444);

  /// 🩵 하늘 블루 — 보조. 물 속성, 웨이브, 쿨타임
  static const Color skyBlue = Color(0xFF38BDF8);

  // ── 배경 (어두운 세계관은 유지) ──

  /// 부드러운 밤색 배경 (상단)
  static const Color bgWarmDark = Color(0xFF1E1226);

  /// 짙은 자주 배경 (하단)
  static const Color bgDeepPlum = Color(0xFF150D1E);

  /// 기본 스캐폴드 배경
  static const Color scaffoldBg = Color(0xFF120A1A);

  // ── UI 서피스 ──

  /// 카드/패널 배경 (따뜻한 반투명)
  static const Color surfaceDark = Color(0xFF1E1528);

  /// 카드/패널 배경 (더 어두운)
  static const Color surfaceDarker = Color(0xFF140E1C);

  /// 카드/패널 배경 (중간)
  static const Color surfaceMid = Color(0xFF221730);

  /// 보더 기본
  static const Color borderDefault = Color(0x33FFFFFF);

  /// 보더 하이라이트 (벚꽃 핑크)
  static const Color borderHighlight = Color(0xFFFF7EB3);

  /// 보더 악센트 (피치)
  static const Color borderAccent = Color(0xFFFF9A76);

  // ── 텍스트 ──

  /// 기본 텍스트
  static const Color textPrimary = Colors.white;

  /// 보조 텍스트
  static const Color textSecondary = Color(0xB3FFFFFF); // white70

  /// 비활성 텍스트
  static const Color textDisabled = Color(0x99FFFFFF); // white60

  // ── 타워 속성 컬러 (밝고 선명) ──

  /// 화살탑 — 민트 그린
  static const Color towerArcher = Color(0xFF34D399);

  /// 병사탑 — 하늘 블루
  static const Color towerBarracks = Color(0xFF38BDF8);

  /// 무당탑 — 라벤더
  static const Color towerShaman = Color(0xFFC084FC);

  /// 포탑/화염탑 — 피치 코랄
  static const Color towerArtillery = Color(0xFFFF9A76);

  /// 솟대 — 신명 골드
  static const Color towerSotdae = Color(0xFFFBBF24);

  // ── 상태 컬러 ──

  /// 성공/완료
  static const Color success = mintGreen;

  /// 경고
  static const Color warning = sinmyeongGold;

  /// 에러/위험
  static const Color error = berserkRed;

  /// 정보
  static const Color info = skyBlue;

  // ── 등급별 컬러 (스킨/아이템) ──

  /// 기본 (Common)
  static const Color rarityCommon = Color(0xFF9CA3AF);

  /// 수련 (Uncommon)
  static const Color rarityUncommon = Color(0xFF34D399);

  /// 정제 (Rare)
  static const Color rarityRare = Color(0xFF38BDF8);

  /// 명작 (Epic)
  static const Color rarityEpic = Color(0xFFC084FC);

  /// 걸작 (Legendary)
  static const Color rarityLegendary = Color(0xFFFBBF24);

  /// 전설 (Mythic) — 벚꽃 핑크
  static const Color rarityMythic = Color(0xFFFF7EB3);

  /// 한정 (Divine)
  static const Color rarityDivine = Color(0xFFFF6B6B);

  // ── 그라디언트 ──

  /// 배경 그라디언트 (위→아래) — 따뜻한 어둠
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgWarmDark, bgDeepPlum],
  );

  /// 프라이머리 버튼 그라디언트 (벚꽃→피치)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cherryBlossom, peachCoral],
  );

  /// 정화 이펙트 그라디언트
  static const LinearGradient purifyGradient = LinearGradient(
    colors: [cherryBlossom, lavender],
  );

  /// 광폭화 그라디언트
  static const LinearGradient berserkGradient = LinearGradient(
    colors: [berserkRed, Color(0xFF7C2D12)],
  );

  /// 보상 연출 그라디언트
  static const LinearGradient rewardGradient = LinearGradient(
    colors: [sinmyeongGold, peachCoral],
  );
}

/// UI 디자인 토큰 — GDD §I-B.4 기준
abstract class AppDesign {
  AppDesign._();

  /// 버튼 둥근 모서리
  static const double buttonRadius = 16.0;

  /// 카드 둥근 모서리
  static const double cardRadius = 12.0;

  /// 패널 둥근 모서리 (작은)
  static const double panelRadius = 8.0;

  /// 전환 애니메이션 (기본)
  static const Duration transitionFast = Duration(milliseconds: 200);

  /// 전환 애니메이션 (보통)
  static const Duration transitionNormal = Duration(milliseconds: 300);

  /// 전환 애니메이션 (느린)
  static const Duration transitionSlow = Duration(milliseconds: 400);

  /// 글로우 효과 (네온)
  static List<BoxShadow> neonGlow(Color color, {double blur = 12}) => [
        BoxShadow(color: color.withAlpha(80), blurRadius: blur, spreadRadius: 1),
        BoxShadow(color: color.withAlpha(40), blurRadius: blur * 2, spreadRadius: 2),
      ];

  /// 카드 데코레이션 (글래스모피즘)
  static BoxDecoration glassCard({
    Color? borderColor,
    double borderWidth = 1,
  }) =>
      BoxDecoration(
        color: AppColors.surfaceDark.withAlpha(200),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: borderColor ?? AppColors.borderDefault,
          width: borderWidth,
        ),
      );
}
