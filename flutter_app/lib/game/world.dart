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
  late double groundYPos; // 동적으로 계산될 캐릭터들의 위치 높이
  late double heroSpacing; // 동적으로 계산될 캐릭터 간 간격
  late double gaugeHeight; // 게이지 바 높이
  final int maxHeroes = 4;
  final int heroGoldCost = 100;

  double heroEnergy = 100;
  final double maxHeroEnergy = 100;
  bool isEnergyDepleted = false;

  // 채소 개수 및 UI 관리
  int broccoliCount = 0;
  List<SpriteComponent> vegetableSprites = []; // 채소 이미지를 관리할 리스트

  void useHeroEnergy(double amount) {
    if (heroEnergy <= 0) {
      if (!isEnergyDepleted) {
        isEnergyDepleted = true;
        // 보스전이고, 보스의 체력이 임계치에 가까운 경우 먹기 인식을 시작하지 않음
        if (enemyGroup?.isBoss == true && 
            !enemyGroup!.isPhase2 && 
            enemyGroup!.hp <= (500 * 0.35)) { // 35%로 여유를 둠
          // 먹기 인식 시작하지 않고 에너지만 고갈 상태로 표시
          return;
        }
        gameRef.showEatCameraOverlay();
      }
      return;
    }
    heroEnergy -= amount;
    heroEnergy = heroEnergy.clamp(0, maxHeroEnergy);
    heroEnergyBar.setValue(heroEnergy / maxHeroEnergy);
    
    if (heroEnergy <= 0) {
      isEnergyDepleted = true;
      // 보스전이고, 보스의 체력이 임계치에 가까운 경우 먹기 인식을 시작하지 않음
      if (enemyGroup?.isBoss == true && 
          !enemyGroup!.isPhase2 && 
          enemyGroup!.hp <= (500 * 0.35)) { // 35%로 여유를 둠
        // 먹기 인식 시작하지 않고 에너지만 고갈 상태로 표시
        return;
      }
      gameRef.showEatCameraOverlay();
    }
  }

  void restoreEnergy(double amount) {
    heroEnergy = (heroEnergy + amount).clamp(0, maxHeroEnergy);
    heroEnergyBar.setValue(heroEnergy / maxHeroEnergy);
    isEnergyDepleted = false;
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
    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;
    
    // 게이지 바 크기 계산
    final gaugeWidth = screenWidth * 0.25;
    gaugeHeight = screenHeight * 0.04;
    final topPadding = screenHeight * 0.05; // 화면 상단에서 15% 위치로 수정 (기존 5%에서 변경)

    enemyHealthBar = GaugeBar(
      direction: GaugeDirection.rightToLeft,
      mainColor: Colors.red,
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      decreaseMarginColor: Colors.yellow,
      position: Vector2(screenWidth - gaugeWidth - 32, topPadding),
      size: Vector2(gaugeWidth, gaugeHeight),
    );
    add(enemyHealthBar);

    heroEnergyBar = GaugeBar(
      decreaseMarginColor: Colors.greenAccent,
      direction: GaugeDirection.leftToRight,
      mainColor: Colors.lightGreenAccent,
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      position: Vector2(32, topPadding),
      size: Vector2(gaugeWidth, gaugeHeight),
    );
    add(heroEnergyBar);

    goldBar = GaugeBar(
      decreaseMarginColor: Colors.yellow,
      direction: GaugeDirection.leftToRight,
      mainColor: Colors.yellow,
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      position: Vector2(screenWidth / 2 - gaugeWidth * 0.6, topPadding),
      size: Vector2(gaugeWidth * 1.2, gaugeHeight * 0.8),
    );
    add(goldBar);
    goldBar.setValue(gameRef.gold.toDouble());

    // 게이지 바 위치 조정
    enemyHealthBar.setPosition(AlignType.right, screenWidth);
    heroEnergyBar.setPosition(AlignType.left, screenWidth);
    goldBar.setPosition(AlignType.center, screenWidth);

    // 캐릭터 위치 및 간격 계산
    groundYPos = screenHeight * 0.85; // 화면 높이의 85% 위치에 캐릭터 배치 (기존 70%에서 수정)
    heroSpacing = screenWidth * 0.06;

    await spawnVegetables();
  }

  Future<void> spawnVegetables() async {
    for (var sprite in vegetableSprites) {
      remove(sprite);
    }
    vegetableSprites.clear();

    final screenWidth = gameRef.size.x;
    final screenHeight = gameRef.size.y;
    
    final vegetableSize = screenWidth * 0.05;
    final spacing = vegetableSize * 0.2;
    final gaugeBarBottomPadding = screenHeight * 0.02;
    final vegetablesStartXPadding = screenWidth * 0.02;

    double startX = screenWidth - broccoliCount * (vegetableSize + spacing) - vegetablesStartXPadding;
    double yPos = screenHeight * 0.15 + gaugeHeight + gaugeBarBottomPadding; // 게이지 바 위치에 맞춰 조정

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
    final xPos = heroSpacing + heroes.length * (heroSpacing * 2);
    return Vector2(xPos, groundYPos);
  }

  void checkEnemyGroupStatus() {
    if (enemyGroup != null && enemyGroup!.hp <= 0) {
      if (enemyGroup!.isBoss) {
        gameRef.gold += 50;
        // 보스 처치 시 게임 클리어 알림창 표시
        gameRef.overlays.add('GameClearOverlay');
        gameRef.isGamePaused = true;
      }
      remove(enemyGroup!);
      enemyGroup = null;
      nextStage();
      goldBar.setValue(gameRef.gold / heroGoldCost);
      
      // 영웅 추가 가능 여부 확인 및 UI 표시
      if (canAddHero()) {
        showHeroAdditionDialog();
      }
    }
  }

  // 영웅 추가 가능 여부 체크
  bool canAddHero() {
    return heroes.length < maxHeroes && gameRef.gold >= heroGoldCost;
  }

  // 영웅 추가 시도
  bool tryAddHero() {
    if (canAddHero()) {
      gameRef.gold -= heroGoldCost;
      goldBar.setValue(gameRef.gold / heroGoldCost);
      gameRef.showHeroSelectionOverlay();
      return true;
    }
    return false;
  }

  // 영웅 추가 다이얼로그 표시
  void showHeroAdditionDialog() {
    gameRef.overlays.add('HeroAdditionDialog');
  }

  void nextStage() {
    gameRef.level++;
    gameRef.gold += 10;
    spawnEnemies();
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
