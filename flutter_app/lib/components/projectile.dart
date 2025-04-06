import 'dart:math'; // atan2를 사용하기 위해 추가
import 'package:flame/components.dart';
import 'package:flutter_app/game/game.dart';
import 'package:flutter_app/main.dart';

class Projectile extends SpriteComponent with HasGameRef<BattleGame> {
  Vector2 targetPosition = Vector2(0, 0);
  final double speed = 1000;
  final int heroId;

  Projectile({required this.heroId, required Vector2 position})
      : super(size: Vector2(20, 20)) {
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    sprite = spriteManager.getProjectileSprite(heroId);
    if (sprite != null) {
      size = Vector2(sprite!.src.width.toDouble(), sprite!.src.height.toDouble());
      size = size * 0.5;
    }
    anchor = Anchor.center;

    // 적군이 있을 때만 목표 설정
    if (gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true) {
      targetPosition = gameRef.gameWorld.getHitTarget();
    } else {
      // 적이 없을 경우, 목표를 투사체의 현재 위치로 설정하여 화면 밖으로 날아가지 않도록 함
      targetPosition = position;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    Vector2 direction = targetPosition - position;
    direction.normalize();
    position += direction * speed * dt;

    angle = atan2(direction.y, direction.x);

    if (position.x < 0 || position.x > gameRef.size.x || position.y < 0 || position.y > gameRef.size.y) {
      removeFromParent();
    }

    // 목표에 도달했을 때, 충돌 감지 후 적에게 데미지
    if ((targetPosition - position).length < 10) {
      removeFromParent();
      gameRef.gameWorld.enemyGroup?.takeDamage(10); // 적에게 10의 데미지를 줌
      gameRef.gameWorld.enemyGroup?.enemies.forEach((enemy) {
        enemy.takeDamage(); // 적이 맞을 때 효과 적용
      });
    }
  }
}
