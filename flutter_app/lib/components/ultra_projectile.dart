import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter_app/components/projectile.dart';
import 'package:flutter_app/main.dart';

class UltraProjectile extends Projectile {
  double currentSpeed = 0; // 현재 속도
  late double maxSpeedMultiplier;
  late double acceleration;

  UltraProjectile({required Vector2 position})
      : super(heroId: 0, position: position);

  @override
  Future<void> onLoad() async {
    sprite = spriteManager.getUltraProjectileSprite();
    if (sprite == null) {
      print("Failed to load ultra projectile sprite.");
      return;
    }

    // 화면 크기에 따른 크기 및 속도 계산
    double screenWidth = gameRef.size.x;
    double screenHeight = gameRef.size.y;
    
    // 울트라 발사체는 일반 발사체보다 더 크게 설정
    double projectileSize = screenWidth * 0.08; // 화면 너비의 8%
    size = Vector2(projectileSize, projectileSize);
    
    // 속도 관련 파라미터 설정
    maxSpeedMultiplier = 3.0;
    acceleration = screenWidth * 0.000005; // 화면 크기에 비례한 가속도
    speed = screenWidth * 0.5; // 기본 속도는 화면 너비의 50%

    anchor = Anchor.center;

    // 적군이 있을 때만 목표 설정
    targetPosition = gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true 
        ? gameRef.gameWorld.getHitTarget() 
        : position; // 적이 없을 경우 현재 위치로 설정
  }

  @override
  void update(double dt) {
    // 화면 크기에 따른 충돌 범위 계산
    double screenWidth = gameRef.size.x;
    double collisionRange = screenWidth * 0.015; // 화면 너비의 1.5%

    // 가속도를 적용하여 현재 속도를 증가시킴
    currentSpeed += acceleration * dt;

    // 최고 속도를 제한함
    double maxSpeed = speed * maxSpeedMultiplier;
    if (currentSpeed > maxSpeed) {
      currentSpeed = maxSpeed;
    }

    Vector2 direction = targetPosition - position;
    direction.normalize();
    position += direction * currentSpeed * dt;

    angle = atan2(direction.y, direction.x);

    // 화면 밖으로 나갔는지 확인
    if (position.x < 0 || position.x > gameRef.size.x || position.y < 0 || position.y > gameRef.size.y) {
      removeFromParent();
      return; // Early exit if removed
    }

    // 목표에 도달했을 때 충돌 감지 후 궁극적인 데미지 적용
    if ((targetPosition - position).length < collisionRange) {
      removeFromParent();
      gameRef.gameWorld.enemyGroup?.takeUltDamage(); // 궁극적인 데미지를 줌
      gameRef.gameWorld.enemyGroup?.enemies.forEach((enemy) {
        enemy.takeDamage(); // 적이 맞을 때 효과 적용
      });
    }
  }
}
