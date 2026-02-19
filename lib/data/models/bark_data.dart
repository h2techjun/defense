// 해원의 문 — 영웅 대사(Barks) 데이터 모델
// GDD §7.3 기반: 보스 등장/처치, 아군 위기, 밤 전환 등 상황별 대사

/// 대사 트리거 상황
enum BarkTrigger {
  /// 보스 등장 시
  bossAppear,

  /// 보스 처치 시
  bossKill,

  /// 아군 위기 (게이트웨이 HP 30% 이하)
  allyDanger,

  /// 밤 전환 시
  nightTransition,

  /// 영웅 궁극기 사용 시
  ultimateUsed,

  /// 전투 시작 시
  battleStart,
}

/// 영웅별 대사 데이터
class BarkData {
  final String heroId;
  final BarkTrigger trigger;
  final List<String> lines; // 랜덤 선택

  const BarkData({
    required this.heroId,
    required this.trigger,
    required this.lines,
  });
}
