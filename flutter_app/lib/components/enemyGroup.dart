import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/enemy.dart';
import 'package:flutter_app/game/game.dart';


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
    if (isBoss) {
      _darkenBackground();
    }
  }

  void _darkenBackground() {
    final darkOverlay = RectangleComponent(
      position: Vector2.zero(), // 화면 전체
      size: gameRef.size, // 게임 화면 크기
      paint: Paint()..color = Color(0x80000000), // 반투명 어두운 색
    );
    add(darkOverlay); // 덮개 추가
  }

  void spawnEnemies() {
    //2초 뒤 isMoving을 false로 설정
    Future.delayed(Duration(seconds: 2), () {
      isMoving = false;
    });
    
    Future.delayed(Duration(seconds: 2), () {
      if (isBoss) {
        // 보스 등장
        hp = 500; // 보스 체력 설정
        
        enemies = [];

        int rand = Random().nextInt(5);
        var boss = Enemy(enemyID: rand, isBoss: true); // 보스는 단일 Enemy
        double startX = gameRef.size.x + 100;
        boss.position = Vector2(startX, gameRef.gameWorld.groundYPos);

        // 크기 효과와 나타나는 효과를 분리하여 순차적으로 적용
        boss.add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 1.0)));
        
        Future.delayed(const Duration(seconds: 1), () {
          boss.add(OpacityEffect.to(1.0, EffectController(duration: 1.0)));
        });

        enemies.add(boss);
        add(boss);

      } else {
        for (int i = 0; i < 2; i++) {
          int rand = Random().nextInt(5);
          var enemy = Enemy(enemyID: rand);

          double startX =
              gameRef.size.x + 100 + (i * 300); // 첫 번째 적은 100, 두 번째 적은 300에 배치
          enemy.position = Vector2(startX, gameRef.gameWorld.groundYPos);

          // enemies.add(enemy);
          enemies.add(enemy);
          add(enemy);

          enemy.opacity = 0;
          enemy.add(
            OpacityEffect.to(1.0, EffectController(duration: 1.0)),
          );

          // 흔들림 효과 추가
          addShakeEffect(enemy);
        }
      }
      maxHp = hp; // 최대 체력 설정

      // 적이 화면으로 이동하는 애니메이션
      for (int i = 0; i < enemies.length; i++) {
        var enemy = enemies[i];
        double targetX = gameRef.size.x - (300 - (i * 150));

        enemy.add(
          MoveEffect.to(
            Vector2(targetX, gameRef.gameWorld.groundYPos),
            EffectController(duration: 1),
          ),
        );

        // 흔들림 효과 추가
        addShakeEffect(enemy);
      }
    });
    
    
  }

  // 흔들림 효과를 추가하는 메서드
  void addShakeEffect(Enemy enemy) {
    // MoveByEffect를 반복적으로 적용하여 좌우로 흔들림 효과 구현
    final shakeEffect = SequenceEffect(
      [
        MoveByEffect(
          Vector2(0, 10), // 오른쪽으로 10 이동
          EffectController(duration: 0.2, alternate: true, repeatCount: 3),
        ),
        MoveByEffect(
          Vector2(0, -10), // 왼쪽으로 10 이동
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
    if (isBoss && isPhase2) {
      // 페이즈 2에서는 일반 공격 무시
      if (isBoss && isPhase2 && !isPhase2Entered) {
        isPhase2Entered = true;
        gameRef.gameWorld.enemyHealthBar.mainColor = Colors.orange;

        Future.delayed(Duration(milliseconds: 200), () {
          gameRef.showVegetableCameraOverlay();
          //gameRef.gameWorld.spawnUltraProjectile();
        });
        
      }
      return;
      
    }

    hp -= damage;
    hp = max(0, hp);
    gameRef.gameWorld.enemyHealthBar.setValue(hp / maxHp); // 체력바 갱신
    
    print('EnemyGroup took $damage damage. HP: $hp');

    if (isBoss && !isPhase2 && hp <= (500 * 0.3)) {
      // 보스가 체력 70% 소진 시 페이즈 2로 전환
      isPhase2 = true;
      print('Boss entered Phase 2!');
    }

    if (hp <= 0) {
      for (var enemy in enemies) {
        enemy.die(); // 모든 적군의 죽음 애니메이션 실행
        // 각 적에 대해 폭발 파티클 추가
        enemy.addExplosionEffect(); // 폭발 파티클 추가
      }

      // 적군 애니메이션이 종료될 시간까지 대기 후 그룹 삭제
      Future.delayed(Duration(seconds: 1), () {
        gameRef.gameWorld.checkEnemyGroupStatus(); 
        removeFromParent(); // 적군 그룹 삭제
      });
    }
  }

  void takeUltDamage() {
    // 화면 밖에 있을 땐 공격 무시
    if (isMoving) {
      return;
    }
    hp = 0;
    gameRef.gameWorld.enemyHealthBar.setValue(0); // 체력바 갱신

    for (var enemy in enemies) {
      enemy.die(); // 모든 적군의 죽음 애니메이션 실행
      // 각 적에 대해 폭발 파티클 추가
      enemy.addExplosionEffect(); // 폭발 파티클 추가
    }

    // 적군 애니메이션이 종료될 시간까지 대기 후 그룹 삭제
    Future.delayed(Duration(seconds: 1), () {
      gameRef.gameWorld.checkEnemyGroupStatus();
      removeFromParent(); // 적군 그룹 삭제
    });
  }
}
