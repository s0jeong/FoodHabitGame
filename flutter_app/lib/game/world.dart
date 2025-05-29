// flutter_app/lib/game/world.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/enemyGroup.dart';
import 'package:flutter_app/components/hero.dart' as customhero;
import 'package:flutter_app/components/ultra_projectile.dart';
import 'package:flutter_app/game/game.dart';
import 'package:flutter_app/game_ui/ui/gauge_bar.dart';
import 'package:flutter_app/screens/preferences.dart'; // Preferences 임포트

class GameWorld extends Component with HasGameRef<BattleGame> {
  List<customhero.Hero> heroes = [];
  EnemyGroup? enemyGroup;
  final double groundYPos = 300; // 캐릭터들의 위치할 높이
  final double heroSpacing = 50; // 캐릭터 간 최소 간격 증가
  final int maxHeroes = 4;
  final int heroGoldCost = 100;

  double heroEnergy = 100;
  final double maxHeroEnergy = 100;

  // 채소 개수 및 UI 관리
  int broccoliCount = 0;
  List<SpriteComponent> vegetableSprites = []; // 채소 이미지를 관리할 리스트

  void useHeroEnergy(double amount) {
    if (heroEnergy <= 0) {
      return;
    }
    heroEnergy -= amount;
    heroEnergy = heroEnergy.clamp(0, maxHeroEnergy);
    heroEnergyBar.setValue(heroEnergy / maxHeroEnergy);
    if (heroEnergy <= 0) {
      heroEnergy = maxHeroEnergy;
    }
  }

  late GaugeBar enemyHealthBar;
  late GaugeBar heroEnergyBar;
  late GaugeBar goldBar;

  Vector2 getHitTarget() {
    if (enemyGroup == null || enemyGroup!.enemies.isEmpty) {
      return Vector2.zero();
    }
    Vector2 target = enemyGroup!.enemies[0].position;
    int rand = Random().nextInt(50) - 100;
    target += Vector2(0, rand.toDouble());
    return target;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Preferences에서 broccoliCount 가져오기
    final prefs = await Preferences.getPreferences();
    broccoliCount = prefs['broccoliCount']!;
    
    spawnUI();
    spawnInitialHeroes();
    spawnEnemies();
  }

  void spawnUI() async {
    enemyHealthBar = GaugeBar(
      direction: GaugeDirection.rightToLeft,
      mainColor: Colors.red,
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      decreaseMarginColor: Colors.yellow,
      position: Vector2(gameRef.size.x - 256, 40),
      size: Vector2(200, 30),
    );
    add(enemyHealthBar);

    heroEnergyBar = GaugeBar(
      decreaseMarginColor: Colors.greenAccent,
      direction: GaugeDirection.leftToRight,
      mainColor: Colors.lightGreenAccent,
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      position: Vector2(32, 40),
      size: Vector2(200, 30),
    );
    add(heroEnergyBar);

    goldBar = GaugeBar(
      decreaseMarginColor: Colors.yellow,
      direction: GaugeDirection.leftToRight,
      mainColor: Colors.yellow,
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      position: Vector2(gameRef.size.x / 2 - 150, 40),
      size: Vector2(300, 20),
    );
    add(goldBar);
    goldBar.setValue(gameRef.gold.toDouble());

    enemyHealthBar.setPosition(AlignType.right, gameRef.size.x);
    heroEnergyBar.setPosition(AlignType.left, gameRef.size.x);
    goldBar.setPosition(AlignType.center, gameRef.size.x);

    // 채소 이미지 추가
    await spawnVegetables();
  }

  Future<void> spawnVegetables() async {
    // 기존 채소 이미지 제거 (중복 방지)
    for (var sprite in vegetableSprites) {
      remove(sprite);
    }
    vegetableSprites.clear();

    // 채소 이미지를 게이지 바 아래로 배치
    const double vegetableSize = 40; // 채소 이미지 크기
    const double spacing = 5; // 채소 간 간격
    const double gaugeBarBottomPadding = 10; // 게이지 바 아래 여유 공간
    const double vegetablesStartXPadding = 20; // 화면 오른쪽에서 떨어진 간격

    // 위치 계산
    double startX = gameRef.size.x - broccoliCount * (vegetableSize + spacing) - vegetablesStartXPadding;
    double yPos = 40 + 30 + gaugeBarBottomPadding; // 게이지 바의 y 위치 + 높이 + 여유 공간

    for (int i = 0; i < broccoliCount; i++) {
      final sprite = SpriteComponent(
        sprite: await Sprite.load('heros/vegetable.png'),
        size: Vector2(vegetableSize, vegetableSize),
        position: Vector2(startX + i * (vegetableSize + spacing), yPos),
      );
      vegetableSprites.add(sprite);
      add(sprite);
    }
  }

  void removeVegetable() {
    if (vegetableSprites.isNotEmpty) {
      final sprite = vegetableSprites.last;
      remove(sprite); // 즉시 제거
      vegetableSprites.remove(sprite);
      broccoliCount--; // 개수 감소
    }
  }

  void spawnInitialHeroes() {
    addHero(customhero.Hero(
      position: spawnPosition(),
      attackSpeed: 1,
      heroId: 4,
    ));
    gameRef.showHeroSelectionOverlay();
  }

  void addHeroById(int heroId) {
    addHero(customhero.Hero(
      position: spawnPosition(),
      attackSpeed: 1,
      heroId: heroId,
    ));
  }

  void addHero(customhero.Hero hero) {
    if (heroes.length >= maxHeroes) {
      return;
    }
    heroes.add(hero);
    add(hero);
  }

  void spawnEnemies() {
    if (enemyGroup != null) {
      remove(enemyGroup!);
    }
    enemyGroup = EnemyGroup();
    if (gameRef.level % 1 == 0 && gameRef.level != 0) {
      enemyGroup!.isBoss = true;
      enemyHealthBar.setValue(1);
      enemyHealthBar.size = Vector2(280, 50);
      enemyHealthBar.mainColor = Colors.red;
      enemyHealthBar.setPosition(AlignType.right, gameRef.size.x);
    } else {
      enemyHealthBar.size = Vector2(200, 30);
      enemyHealthBar.mainColor = Colors.redAccent;
      enemyHealthBar.setPosition(AlignType.right, gameRef.size.x);
    }
    add(enemyGroup!);
    enemyGroup!.spawnEnemies();
    enemyHealthBar.setValue(1);
  }

  Vector2 spawnPosition() {
    const double xStart = 100; // 시작 x 위치
    const double xIncrement = 150; // x 위치 증가 단위 증가
    double newX = xStart;
    bool positionFound = false;

    while (!positionFound) {
      positionFound = true;
      for (var hero in heroes) {
        if ((hero.position.x - newX).abs() < heroSpacing) {
          positionFound = false;
          newX += xIncrement;
          break;
        }
      }
    }
    return Vector2(newX, groundYPos);
  }

  void checkEnemyGroupStatus() {
    if (enemyGroup != null && enemyGroup!.hp <= 0) {
      if (enemyGroup!.isBoss) {
        gameRef.gold += 50;
      }
      remove(enemyGroup!);
      enemyGroup = null;
      nextStage();
      goldBar.setValue(gameRef.gold / heroGoldCost);
    }
  }

  void nextStage() {
    gameRef.level++;
    gameRef.gold += 10;
    spawnEnemies();

    if (gameRef.gold >= heroGoldCost && heroes.length < maxHeroes) {
      gameRef.gold -= heroGoldCost;
      gameRef.showHeroSelectionOverlay();
    }
  }

  void spawnUltraProjectile() {
    UltraProjectile ultraProjectile = UltraProjectile(position: heroes[0].position + Vector2(0, -50));
    add(ultraProjectile);
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (var hero in heroes) {
      hero.update(dt);
    }
    checkEnemyGroupStatus();
  }
}
