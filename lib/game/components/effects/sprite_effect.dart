// 해원의 문 - 스프라이트 다중 프레임 기반 2D 이펙트 컴포넌트

import 'package:flame/components.dart';
import '../../defense_game.dart';

enum SpriteEffectType {
  fire,       // 5 프레임 (fx_fire_1 ~ 5)
  lightning,  // 5 프레임 (fx_lightning_1 ~ 5)
  hit         // 4 프레임 (fx_hit_1 ~ 4)
}

/// Vertex AI가 여러 장 생산한 프리미엄 2D 이펙트를 부드럽게 연속 재생하는 컴포넌트
class SpriteEffect extends SpriteAnimationComponent with HasGameRef<DefenseGame> {
  final SpriteEffectType type;
  final double stepTime;
  final bool loop;

  SpriteEffect({
    required this.type,
    required Vector2 position,
    Vector2? size,
    this.stepTime = 0.08, // 애니메이션 속도
    this.loop = false,
  }) : super(
          position: position,
          size: size ?? Vector2.all(40),
          anchor: Anchor.center,
          removeOnFinish: !loop, // loop 꺼지면 재생 끝나는 순간 자동 소멸 (Flame 지원 기능)
        );

  @override
  Future<void> onLoad() async {
    int frameCount;
    String prefix;

    switch (type) {
      case SpriteEffectType.fire:
        frameCount = 5;
        prefix = 'effects/fx_fire';
        break;
      case SpriteEffectType.lightning:
        frameCount = 5;
        prefix = 'effects/fx_lightning';
        break;
      case SpriteEffectType.hit:
        frameCount = 4;
        prefix = 'effects/fx_hit';
        break;
    }

    final sprites = <Sprite>[];
    for (int i = 1; i <= frameCount; i++) {
        try {
            final image = await game.images.load('${prefix}_$i.png');
            sprites.add(Sprite(image));
        } catch (e) {
            // 아직 에셋이 생성되지 않은 프레임은 무시 (에러 방지)
            // print('SpriteEffect 렌더링 폴백 - 프레임 누락: ${prefix}_$i.png');
        }
    }
    
    if (sprites.isNotEmpty) {
      animation = SpriteAnimation.spriteList(sprites, stepTime: stepTime, loop: loop);
    } else {
        // 단 1장의 프레임도 로드 실패 시 무한 대기 방지 및 메모리 정리 위해 즉시 삭제
        removeFromParent();
    }
  }
}
