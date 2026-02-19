// 해원의 문 - 낮/밤 사이클 시스템

import 'package:flame/components.dart';
import '../../common/enums.dart';
import '../../common/constants.dart';

/// 낮/밤 사이클 시스템
/// 낮: 물리형 적 등장, 타워 정상 작동
/// 밤: 영혼형 적 회피율 +50%, 타워 범위 -30%
class DayNightSystem extends Component {
  DayCycle _currentCycle = DayCycle.day;
  double _timer = 0;
  bool _manualControl = false; // 웨이브 데이터에 의해 제어될 때

  DayCycle get currentCycle => _currentCycle;
  bool get isNight => _currentCycle == DayCycle.night;

  /// 밤의 배경 어둡기 (0=완전 밝음, 1=완전 어두움)
  double get nightOverlayOpacity => isNight ? 0.4 : 0.0;

  /// 웨이브에 의한 수동 전환
  void setCycle(DayCycle cycle) {
    _manualControl = true;
    if (_currentCycle != cycle) {
      _currentCycle = cycle;
      _timer = 0;
    }
  }

  /// 맵 오브젝트(당산나무)에 의한 강제 전환
  void forceCycle(DayCycle cycle) {
    _currentCycle = cycle;
    _timer = 0;
    // 수동 제어는 해제 — 자동 사이클이 이후 정상 진행
    _manualControl = false;
  }

  /// 영혼형 적의 회피 보너스 계산
  double getEvasionBonus(ArmorType armorType) {
    if (isNight && armorType == ArmorType.spiritual) {
      return GameConstants.nightEvasionBonus;
    }
    return 0.0;
  }

  /// 타워 범위 배율
  double getTowerRangeMultiplier() {
    if (isNight) {
      return 1.0 - GameConstants.nightRangeReduction; // 0.7
    }
    return 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_manualControl) return;

    // 자동 사이클 (사용하지 않을 때만)
    _timer += dt;
    final duration = _currentCycle == DayCycle.day
        ? GameConstants.dayDuration
        : GameConstants.nightDuration;

    if (_timer >= duration) {
      _timer = 0;
      _currentCycle =
          _currentCycle == DayCycle.day ? DayCycle.night : DayCycle.day;
    }
  }
}
