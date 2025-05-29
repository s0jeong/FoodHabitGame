import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/enemy.dart';
import 'package:flutter_app/game/game.dart';
import 'dart:async';


class EnemyGroup extends Component with HasGameRef<BattleGame> {
  int maxHp = 100;
  int hp = 100; // 그룹 전체 체력
  bool isBoss = false; // 보스 여부
  bool isPhase2 = false; // 보스 페이즈 2 여부
  List<Enemy> enemies = []; // 개별 적군 리스트
  bool isMoving = true; 
  bool isPhase2Entered = false;
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 나중에 사용할 수 있도록 주석 처리
    /*if (isBoss) {
      _darkenBackground();
    }*/
  }

  // 나중에 사용할 수 있도록 함수는 유지
  void _darkenBackground() {
    final darkOverlay = RectangleComponent(
      position: Vector2.zero(),
      size: gameRef.size,
      paint: Paint()..color = Color(0x80000000),
    );
    add(darkOverlay);
  }

  void spawnEnemies() {
    // 적군이 완전히 도착한 후에 isMoving을 false로 설정
    Future.delayed(Duration(seconds: 2), () {
      if (isBoss) {
        // 보스 등장
        hp = 500;
        enemies = [];

        int rand = Random().nextInt(5);
        var boss = Enemy(enemyID: rand, isBoss: true);
        
        // 화면 크기에 따른 보스 위치 계산
        double screenWidth = gameRef.size.x;
        double screenHeight = gameRef.size.y;
        double startX = screenWidth + (screenWidth * 0.1); // 화면 너비의 10% 만큼 오른쪽에서 시작
        boss.position = Vector2(startX, gameRef.gameWorld.groundYPos);

        // 크기 효과도 화면 크기에 맞게 조정
        boss.add(ScaleEffect.to(
          Vector2.all(1.2 * (screenWidth / 1000)), // 기준 화면 너비 1000px 기준으로 스케일 조정
          EffectController(duration: 1.0)
        ));
        
        Future.delayed(const Duration(seconds: 1), () {
          boss.add(OpacityEffect.to(1.0, EffectController(duration: 1.0)));
        });

        enemies.add(boss);
        add(boss);

      } else {
        // 일반 적군 생성
        for (int i = 0; i < 2; i++) {
          int rand = Random().nextInt(5);
          var enemy = Enemy(enemyID: rand);

          double screenWidth = gameRef.size.x;
          double spacing = screenWidth * 0.3; // 적군 간 간격을 화면 너비의 30%로 설정
          double startX = screenWidth + (screenWidth * 0.1) + (i * spacing);
          enemy.position = Vector2(startX, gameRef.gameWorld.groundYPos);

          enemies.add(enemy);
          add(enemy);

          enemy.opacity = 0;
          enemy.add(
            OpacityEffect.to(1.0, EffectController(duration: 1.0)),
          );

          addShakeEffect(enemy);
        }
      }
      maxHp = hp;

      // 적군 이동 위치 계산
      double screenWidth = gameRef.size.x;
      for (int i = 0; i < enemies.length; i++) {
        var enemy = enemies[i];
        double targetX = screenWidth * (isBoss ? 0.7 : (0.7 - (i * 0.15))); // 보스는 화면의 70%, 일반 적군은 간격을 두고 배치

        enemy.add(
          MoveEffect.to(
            Vector2(targetX, gameRef.gameWorld.groundYPos),
            EffectController(duration: 2.0), // 이동 시간을 2초로 늘림
            onComplete: () {
              // 마지막 적군이 도착했을 때만 isMoving을 false로 설정
              if (i == enemies.length - 1) {
                Future.delayed(Duration(milliseconds: 500), () {
                  isMoving = false;
                });
              }
            },
          ),
        );

        addShakeEffect(enemy);
      }
    });
  }

  void addShakeEffect(Enemy enemy) {
    double screenHeight = gameRef.size.y;
    double shakeAmount = screenHeight * 0.01; // 화면 높이의 1%만큼 흔들기

    final shakeEffect = SequenceEffect(
      [
        MoveByEffect(
          Vector2(0, shakeAmount),
          EffectController(duration: 0.2, alternate: true, repeatCount: 3),
        ),
        MoveByEffect(
          Vector2(0, -shakeAmount),
          EffectController(duration: 0.2, alternate: true, repeatCount: 3),
        ),
      ],
    );
    enemy.add(shakeEffect);
  }

  void takeDamage(int damage) {
    //화면 밖에있을 땐 공격 무시
    if (isMoving) {
      return;
    }

    // 보스 페이즈 2 진입 조건 수정
    if (isBoss && !isPhase2 && hp <= (500 * 0.3)) { // 70% 체력에서 페이즈 2 진입
      isPhase2 = true;
      isPhase2Entered = true;
      gameRef.gameWorld.enemyHealthBar.mainColor = Colors.orange;
      print('Boss entered Phase 2!');
      
      // 야채 인식 카메라 표시
      Future.delayed(Duration(milliseconds: 500), () {
        gameRef.showVegetableCameraOverlay();
      });
      return;
    }

    // 페이즈 2에서는 일반 공격 무시
    if (isBoss && isPhase2) {
      return;
    }

    hp -= damage;
    hp = max(0, hp);
    gameRef.gameWorld.enemyHealthBar.setValue(hp / maxHp); // 체력바 갱신
    
    print('EnemyGroup took $damage damage. HP: $hp');

    if (hp <= 0) {
      for (var enemy in enemies) {
        enemy.die();
        enemy.addExplosionEffect();
      }

      Future.delayed(Duration(seconds: 1), () {
        gameRef.gameWorld.checkEnemyGroupStatus(); 
        removeFromParent();
      });
    }
  }

  void takeUltDamage() {
    // 화면 밖에 있을 땐 공격 무시
    if (isMoving) {
      return;
    }

    // 페이즈 2에서는 궁극기 데미지로 즉시 처치
    if (isBoss && isPhase2) {
      hp = 0;
      gameRef.gameWorld.enemyHealthBar.setValue(0);
      
      for (var enemy in enemies) {
        enemy.die();
        enemy.addExplosionEffect();
      }

      Future.delayed(Duration(seconds: 1), () {
        gameRef.gameWorld.checkEnemyGroupStatus();
        removeFromParent();
      });
      return;
    }

    // 일반 상황에서의 궁극기 데미지 처리
    hp = 0;
    gameRef.gameWorld.enemyHealthBar.setValue(0);

    for (var enemy in enemies) {
      enemy.die();
      enemy.addExplosionEffect();
    }

    Future.delayed(Duration(seconds: 1), () {
      gameRef.gameWorld.checkEnemyGroupStatus();
      removeFromParent();
    });
  }
}
