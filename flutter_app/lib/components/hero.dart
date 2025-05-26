import 'package:flame/components.dart';
import 'package:flutter_app/components/projectile.dart';
import 'package:flutter_app/game/game.dart';
import 'dart:math';

import 'package:flutter_app/main.dart';

class Hero extends SpriteComponent with HasGameRef<BattleGame> {
  double attackSpeed;
  double timeSinceLastAttack = 0;
  bool isAttacking = false;
  int heroId;

  // 애니메이션 관련 변수
  double idleTimer = 0;
  double attackAnimationTimer = 0;
  bool isAnimatingAttack = false;
  bool isCharging = false;
  double chargeDistance = 200;
  double chargeSpeed = 400;
  Vector2 originalPosition;
  Random random = Random();

  // 점프 애니메이션 관련 변수
  bool isJumping = false; // 점프 전체 상태
  bool isJumpingUp = false; // 점프 상승 단계
  double jumpHeight = 200;
  double jumpSpeed = 500;
  double jumpTime = 0; // 점프 진행 시간
  double jumpDuration = 0.8; // 점프 전체 지속 시간 (상승 + 하강)

  Hero({required this.heroId, required Vector2 position, required this.attackSpeed})
      : originalPosition = position.clone(),
        super(size: Vector2(50, 50)) {
    this.position = position;
    anchor = Anchor.bottomCenter;
  }

  @override
  Future<void> onLoad() async {
    sprite = spriteManager.getSpriteByHeroID(heroId);
    if (sprite != null) {
      size = Vector2(sprite!.src.width.toDouble(), sprite!.src.height.toDouble());
      size = Vector2(170, 170);
    }
    priority = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);

    isAttacking = gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true;
    if (
      gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true &&
      gameRef.gameWorld.enemyGroup?.isMoving == false &&
      gameRef.isGamePaused == false &&
      gameRef.gameWorld.heroEnergy > 0 &&
      (gameRef.gameWorld.enemyGroup!.isPhase2Entered == false)
    ) {
      isAttacking = true;
    } else {
      isAttacking = false;
    }

    double screenHeight = gameRef.size.y;
    double heroPositionY = screenHeight * 0.7;
    originalPosition.y = heroPositionY; // originalPosition 동기화
    if (!isJumping) {
      position.y = heroPositionY; // 점프 중이 아닐 때만 위치 고정
    }

    if (!isAttacking && !isAnimatingAttack && !isCharging && !isJumping) {
      animateIdle(dt);
    }

    timeSinceLastAttack += dt;
    if (isAttacking && timeSinceLastAttack >= 1 / attackSpeed) {
      attack(dt);
    }

    if (isAnimatingAttack) {
      animateAttack(dt);
    }

    if (isCharging) {
      animateCharge(dt);
    }

    if (isJumping) {
      animateJump(dt);
    }
  }

  void animateIdle(double dt) {
    idleTimer += dt;
    double scaleY = 1.0 + 0.05 * sin(idleTimer * 3);
    scale = Vector2(1.0, scaleY);
  }

  void animateAttack(double dt) {
    attackAnimationTimer += dt;

    if (heroId == 0) {
      if (attackAnimationTimer < 0.6) {
        double scaleModifier = 1.0 + 0.2 * sin(attackAnimationTimer * 10);
        scale = Vector2(scaleModifier, scaleModifier);
      } else {
        resetAnimation();
      }
    } else if (heroId == 1) {
      if (!isJumping) {
        isJumping = true;
        isJumpingUp = true;
        jumpTime = 0;
      }
      if (attackAnimationTimer > jumpDuration) {
        resetAnimation();
      }
    } else if (heroId == 2) {
      isCharging = true;
      if (attackAnimationTimer > 0.5) {
        resetAnimation();
      }
    } else if (heroId == 3) {
      if (attackAnimationTimer < 0.5) {
        double shakeAmount = 5.0 * sin(attackAnimationTimer * 30);
        position = originalPosition + Vector2(random.nextDouble() * shakeAmount, random.nextDouble() * shakeAmount);
      } else {
        resetAnimation();
      }
    } else {
      resetAnimation();
    }
  }

  void animateJump(double dt) {
    jumpTime += dt;
    double t = jumpTime / (jumpDuration / 2); // 상승/하강 각각 절반 시간
    double progress = t < 1.0 ? t : 2.0 - t; // 상승(0->1), 하강(1->0)
    double height = -jumpHeight * progress * (progress - 2); // 포물선 공식

    position.y = originalPosition.y - height;
    print('점프 진행: time=$jumpTime, progress=$progress, height=$height, position.y=${position.y}');

    if (t >= 2.0) {
      isJumping = false;
      isJumpingUp = false;
      position.y = originalPosition.y;
      resetAnimation();
    }
  }

  void animateCharge(double dt) {
    attackAnimationTimer += dt;
    if (attackAnimationTimer < 0.5) {
      position.x += chargeSpeed * dt;
    } else {
      isCharging = false;
      resetAnimation();
    }
  }

  void resetAnimation() {
    attackAnimationTimer = 0;
    isAnimatingAttack = false;
    isCharging = false;
    isJumping = false;
    isJumpingUp = false;
    jumpTime = 0;
    position = originalPosition.clone();
    angle = 0;
    scale = Vector2(1.0, 1.0);
  }

  void attack(double dt) {
    gameRef.gameWorld.useHeroEnergy(5);
    timeSinceLastAttack = 0;
    isAnimatingAttack = true;
    attackAnimationTimer = 0;

    if (heroId == 0) {
      gameRef.add(
        Projectile(heroId: heroId, position: this.position + Vector2(0, -100)),
      );
    } else if (heroId == 1) {
      gameRef.add(
        Projectile(heroId: heroId, position: this.position + Vector2(0, -100)),
      );
    } else if (heroId == 2) {
      isCharging = true;
      gameRef.add(
        Projectile(heroId: heroId, position: this.position + Vector2(0, -100)),
      );
    } else if (heroId == 3) {
      for (int i = 0; i < 5; i++) {
        double angle = random.nextDouble() * pi * 2;
        Vector2 direction = Vector2(cos(angle), sin(angle)) * 100;
        gameRef.add(
          Projectile(heroId: heroId, position: this.position + Vector2(0, -100) + direction),
        );
      }
    }
  }
}