import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter_app/components/projectile.dart';
import 'package:flutter_app/main.dart';

class UltraProjectile extends Projectile {
  double currentSpeed = 0; // 현재 속도
  final double maxSpeedMultiplier = 3; // 최고 속도 배수
  final double acceleration = 0.005; // 가속도

  UltraProjectile({required Vector2 position})
      : super(heroId: 0, position: position);

  @override
  Future<void> onLoad() async {
    // 다른 이미지를 사용하여 스프라이트를 로드합니다.
    sprite = spriteManager.getUltraProjectileSprite();
    if (sprite == null) {
      print("Failed to load ultra projectile sprite.");
      return;
    }

    // 크기를 2배로 조정
    size = Vector2(sprite!.src.width.toDouble(), sprite!.src.height.toDouble());
    anchor = Anchor.center;

    // 적군이 있을 때만 목표 설정
    targetPosition = gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true 
        ? gameRef.gameWorld.getHitTarget() 
        : position; // 적이 없을 경우 현재 위치로 설정
  }

  @override
  void update(double dt) {
    super.update(dt);

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
    if ((targetPosition - position).length < 10) {
      // Trigger explosion effect here (if applicable)
      removeFromParent();
      gameRef.gameWorld.enemyGroup?.takeUltDamage(); // 궁극적인 데미지를 줌
      gameRef.gameWorld.enemyGroup?.enemies.forEach((enemy) {
        enemy.takeDamage(); // 적이 맞을 때 효과 적용
      });
    }
  }
}
