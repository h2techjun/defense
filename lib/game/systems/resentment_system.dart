// 해원의 문 - 원한(한) 시스템
// 한(Wailing) 게이지 관리, 100% 시 타워 디버프

import 'package:flame/components.dart';
import '../../common/constants.dart';
import '../defense_game.dart';

/// 원한(한) 게이지 시스템
/// 적이 오래 생존하면 한 게이지가 올라갑니다.
/// 100% 도달 시 전체 타워 공격속도 감소.
class ResentmentSystem extends Component with HasGameReference<DefenseGame> {
  double _accumulator = 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.isGameRunning) return;

    // 살아있는 적 수에 비례하여 한 게이지 증가
    _accumulator += dt;
    if (_accumulator >= 2.0) {
      _accumulator = 0;

      final enemyCount = game.world.children
          .whereType<dynamic>()
          .where((c) => c.runtimeType.toString() == 'BaseEnemy')
          .length;

      if (enemyCount > 0) {
        final wailingIncrease = enemyCount * 0.5;
        game.ref.read(gameStateProvider.notifier).addWailing(wailingIncrease);
      }
    }
  }
}
