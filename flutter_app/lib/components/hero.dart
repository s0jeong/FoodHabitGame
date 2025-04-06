import 'package:flame/components.dart';
import 'package:flutter_app/components/projectile.dart';
import 'package:flutter_app/game/game.dart';
import 'dart:math';

import 'package:flutter_app/main.dart';

class Hero extends SpriteComponent with HasGameRef<BattleGame> {
  double attackSpeed; // 초당 공격 횟수
  double timeSinceLastAttack = 0;
  bool isAttacking = false;
  int heroId;

  // 애니메이션 관련 변수
  double idleTimer = 0; // 대기 모션 타이머
  double attackAnimationTimer = 0; // 공격 애니메이션 타이머
  bool isAnimatingAttack = false;
  bool isCharging = false; // 돌진 상태 여부
  double chargeDistance = 200; // 돌진 거리
  double chargeSpeed = 400; // 돌진 속도
  Vector2 originalPosition; // 원래 위치 저장
  Random random = Random();

  // 점프 애니메이션 관련 변수
  bool isJumpingUp = false; // 점프 중인지 여부
  double jumpHeight = 200; // 점프 높이
  double jumpSpeed = 500; // 점프 속도

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
      size = size * 0.4; // 크기 비율 조정
    }

    // Hero가 어두운 배경 위에 보이도록 zIndex 설정
    priority = 1; // Hero의 우선순위를 높게 설정

    // 초기 위치를 화면 크기에 맞게 설정하지 않음, 대신 update에서 처리
  }

  @override
  void update(double dt) {
    super.update(dt);

    isAttacking = gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true;
    if (
      gameRef.gameWorld.enemyGroup?.enemies.isNotEmpty == true
      && gameRef.gameWorld.enemyGroup?.isMoving == false
      && gameRef.isGamePaused == false
      && gameRef.gameWorld.heroEnergy > 0
      && (gameRef.gameWorld.enemyGroup!.isPhase2Entered == false)
    ) 
    {
      isAttacking = true;
    }
    else {
      isAttacking = false;
    }

    // 화면 크기 동적으로 반영
    double screenHeight = gameRef.size.y;
    double heroPositionY = screenHeight * 0.7; // 하단에서 30% 위
    position = Vector2(position.x, heroPositionY);
    
    // 대기 모션 실행
    if (!isAttacking && !isAnimatingAttack && !isCharging) {
      animateIdle(dt);
    }

    // 공격 처리
    timeSinceLastAttack += dt;
    if (isAttacking && timeSinceLastAttack >= 1 / attackSpeed) {
      attack(dt); // 공격 시 투사체 발사
    }

    // 공격 애니메이션 실행
    if (isAnimatingAttack) {
      animateAttack(dt);
    }

    // 돌진 애니메이션
    if (isCharging) {
      animateCharge(dt);
    }

    // 점프 애니메이션
    if (heroId == 1 && isJumpingUp) {
      animateJump(dt);
    }
  }

  // 대기 모션: Y축 스케일 변화로 둠칫둠칫 효과
  void animateIdle(double dt) {
    idleTimer += dt;
    double scaleY = 1.0 + 0.05 * sin(idleTimer * 3); // 주기적 변화
    scale = Vector2(1.0, scaleY); // Y축 스케일 변화
  }

  // 공격 애니메이션: 히어로별로 다르게 구현
  void animateAttack(double dt) {
    attackAnimationTimer += dt;

    if (heroId == 0) {
      // 히어로 ID 0: 크기 변화 애니메이션
      if (attackAnimationTimer < 0.6) {
        double scaleModifier = 1.0 + 0.2 * sin(attackAnimationTimer * 10);
        scale = Vector2(scaleModifier, scaleModifier); // 크기 변화
      } else {
        resetAnimation();
      }
    } else if (heroId == 1) {
      // 히어로 ID 1: 점프 애니메이션
      isJumpingUp = true;
      if (attackAnimationTimer > 0.5) {
        resetAnimation();
      }
    } else if (heroId == 2) {
      // 히어로 ID 2: 돌진 애니메이션
      position += Vector2(0, -chargeSpeed * dt);
      if (attackAnimationTimer > 0.5) {
        resetAnimation();
      }
    } else if (heroId == 3) {
      // 히어로 ID 3: 화면을 희망하는 훌간 (Y위치 및 크기 변화)
      if (attackAnimationTimer < 0.5) {
        double shakeAmount = 5.0 * sin(attackAnimationTimer * 30);
        position = originalPosition + Vector2(random.nextDouble() * shakeAmount, random.nextDouble() * shakeAmount);
      } else {
        resetAnimation();
      }
    } else {
      // 기본 애니메이션
      resetAnimation();
    }
  }

  // 점프 애니메이션
  void animateJump(double dt) {
    // 점프를 위로
    position.y -= jumpSpeed * dt;
    if (position.y <= originalPosition.y - jumpHeight) {
      // 점프 최고점에 도달하면 내려오기 시작
      isJumpingUp = false;
    }
  }

  // 돌진 공격 애니메이션 (기본 구현)
  void animateCharge(double dt) {
    attackAnimationTimer += dt;

    if (attackAnimationTimer < 0.5) {
      position += Vector2(chargeSpeed * dt, 0); // X축으로 전반 이동
    } else {
      resetAnimation();
      isCharging = false; // 돌진 종료
    }
  }

  // 애니메이션 리셋
  void resetAnimation() {
    attackAnimationTimer = 0;
    isAnimatingAttack = false;
    position = originalPosition.clone();
    angle = 0; // 회전 초기화
    scale = Vector2(1.0, 1.0); // 크기 초기화
    isJumpingUp = false; // 점프 종료
  }

  // 공격 처리 (히어로별 투사체 또는 효과)
  void attack(double dt) {
    gameRef.gameWorld.useHeroEnergy(5); // 에너지 소모
    timeSinceLastAttack = 0;
    isAnimatingAttack = true;
    attackAnimationTimer = 0;

    // 히어로별 투사체 혹은 공격 방식
    if (heroId == 0) {
      gameRef.add(
        Projectile(heroId: heroId, position: this.position + Vector2(0, -100)),
      );
    } else if (heroId == 1) {
      gameRef.add(
        Projectile(heroId: heroId, position: this.position + Vector2(0, -100)),
      );
    } else if (heroId == 2) {
      isCharging = true; // 돌진 시작
      gameRef.add(
        Projectile(heroId: heroId, position: this.position + Vector2(0, -100)),
      );
    } else if (heroId == 3) {
      // 히어로 ID 3: 다중 투사체 발사
      for (int i = 0; i < 5; i++) {
        double angle = random.nextDouble() * pi * 2; // 랜덤 각도
        Vector2 direction = Vector2(cos(angle), sin(angle)) * 100; // 랜덤 및 방향
        gameRef.add(
          Projectile(heroId: heroId, position: this.position + Vector2(0, -100) + direction),
        );
      }
    }
  }
}
