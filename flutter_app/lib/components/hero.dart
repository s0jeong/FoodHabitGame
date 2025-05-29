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
      double screenWidth = gameRef.size.x;
      double heroSize = screenWidth * 0.15; // 화면 너비의 15%
      size = Vector2(heroSize, heroSize);
    }
    priority = 1;
    updateAnimationParameters(); // 초기 애니메이션 파라미터 설정
  }

  // 애니메이션 관련 변수들을 화면 크기에 맞게 조정
  void updateAnimationParameters() {
    double screenWidth = gameRef.size.x;
    double screenHeight = gameRef.size.y;
    
    // 점프 관련 파라미터
    jumpHeight = screenHeight * 0.25;
    jumpSpeed = screenWidth * 0.4;
    
    // 돌진 관련 파라미터
    chargeDistance = screenWidth * 0.2;
    chargeSpeed = screenWidth * 0.3;
    
    // 원래 위치 업데이트
    originalPosition.y = screenHeight * 0.92; // 화면 하단에서 15% 위에 위치 (기존 30%에서 수정)
    if (!isJumping) {
      position.y = originalPosition.y;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    updateAnimationParameters();

    // 적군이 완전히 도착한 후에만 공격 가능하도록 수정
    if (
      gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true &&
      gameRef.gameWorld.enemyGroup?.isMoving == false &&
      gameRef.isGamePaused == false &&
      gameRef.gameWorld.heroEnergy > 0 &&
      !gameRef.gameWorld.isEnergyDepleted &&
      (gameRef.gameWorld.enemyGroup!.isPhase2Entered == false)
    ) {
      isAttacking = true;
      // 공격 시작 시 타이머 초기화
      if (timeSinceLastAttack >= 1 / attackSpeed) {
        timeSinceLastAttack = 0;
      }
    } else {
      isAttacking = false;
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
    double screenHeight = gameRef.size.y;
    double scaleY = 1.0 + (screenHeight * 0.0001) * sin(idleTimer * 3); // 화면 크기에 비례한 애니메이션
    scale = Vector2(1.0, scaleY);
  }

  void animateAttack(double dt) {
    attackAnimationTimer += dt;
    double screenWidth = gameRef.size.x;
    double screenHeight = gameRef.size.y;

    if (heroId == 0) {
      if (attackAnimationTimer < 0.6) {
        double scaleModifier = 1.0 + (screenWidth * 0.0002) * sin(attackAnimationTimer * 10);
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
        double shakeAmount = (screenWidth * 0.005) * sin(attackAnimationTimer * 30);
        position = originalPosition + Vector2(
          random.nextDouble() * shakeAmount,
          random.nextDouble() * shakeAmount
        );
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
      double screenWidth = gameRef.size.x;
      double chargeAmount = chargeSpeed * dt;
      position.x = min(position.x + chargeAmount, originalPosition.x + (screenWidth * 0.3));
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
    double energyCost = 0;
    switch (heroId) {
      case 0:
        energyCost = 3.0;
        break;
      case 1:
        energyCost = 4.0;
        break;
      case 2:
        energyCost = 5.0;
        break;
      case 3:
        energyCost = 6.0;
        break;
      default:
        energyCost = 3.0;
    }

    gameRef.gameWorld.useHeroEnergy(energyCost);
    
    if (gameRef.gameWorld.heroEnergy > 0) {
      timeSinceLastAttack = 0;
      isAnimatingAttack = true;
      attackAnimationTimer = 0;

      // 적군이 완전히 도착한 후에만 발사체 생성
      if (!gameRef.gameWorld.enemyGroup!.isMoving) {
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
  }
}