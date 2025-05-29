import 'package:flame/components.dart';
import 'package:flutter_app/game/game.dart';
import 'package:flutter_app/main.dart';

class Projectile extends SpriteComponent with HasGameRef<BattleGame> {
  Vector2 targetPosition = Vector2(0, 0);
  late double speed;
  final int heroId;
  late double rotationSpeed;

  Projectile({required this.heroId, required Vector2 position})
      : super(size: Vector2(20, 20)) {
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    sprite = spriteManager.getProjectileSprite(heroId);
    if (sprite != null) {
      double screenWidth = gameRef.size.x;
      double screenHeight = gameRef.size.y;
      
      // 화면 크기에 따른 발사체 크기와 속도 계산
      double projectileSize = screenWidth * (heroId == 2 ? 0.08 : 0.04); // 울트라 발사체는 8%, 일반 발사체는 4%
      size = Vector2(projectileSize, projectileSize);
      
      speed = screenWidth * 0.4; // 화면 너비의 40%
      rotationSpeed = screenWidth * 0.002; // 화면 크기에 따른 회전 속도
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
    
    // 화면 크기에 따른 이동 속도 조정
    double currentSpeed = speed;
    if (heroId == 2) { // 울트라 발사체
      currentSpeed *= 1.2; // 20% 더 빠르게
    }
    
    position += direction * currentSpeed * dt;

    // 발사체 회전 애니메이션
    angle += rotationSpeed * dt;

    // 화면 크기에 따른 충돌 범위 계산
    double screenWidth = gameRef.size.x;
    double collisionRange = screenWidth * (heroId == 2 ? 0.02 : 0.01); // 울트라 발사체는 2%, 일반 발사체는 1%

    if (position.x < 0 || position.x > gameRef.size.x || position.y < 0 || position.y > gameRef.size.y) {
      removeFromParent();
    }

    if ((targetPosition - position).length < collisionRange) {
      removeFromParent();
      // 울트라 발사체는 더 큰 데미지
      int damage = heroId == 2 ? 30 : 10;
      gameRef.gameWorld.enemyGroup?.takeDamage(damage);
      gameRef.gameWorld.enemyGroup?.enemies.forEach((enemy) {
        enemy.takeDamage();
      });
    }
  }
}