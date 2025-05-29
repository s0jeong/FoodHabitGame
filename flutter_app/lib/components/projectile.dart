import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter_app/game/game.dart';
import 'package:flutter_app/main.dart';

class Projectile extends SpriteComponent with HasGameRef<BattleGame> {
  Vector2 targetPosition = Vector2(0, 0);
  final double speed = 500;
  final int heroId;

  Projectile({required this.heroId, required Vector2 position})
      : super(size: Vector2(20, 20)) {
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    sprite = spriteManager.getProjectileSprite(heroId);
    if (sprite != null) {
      size = Vector2(50, 50); // 고정 크기 10x10으로 설정
    }
    anchor = Anchor.center;

    if (gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true) {
      targetPosition = gameRef.gameWorld.getHitTarget();
    } else {
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

    if ((targetPosition - position).length < 10) {
      removeFromParent();
      gameRef.gameWorld.enemyGroup?.takeDamage(10);
      gameRef.gameWorld.enemyGroup?.enemies.forEach((enemy) {
        enemy.takeDamage();
      });
    }
  }
}