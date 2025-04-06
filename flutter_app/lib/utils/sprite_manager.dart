import 'package:flame/sprite.dart';
import 'package:flame/components.dart';

class SpriteManager {
  // 오탈자 방지를 위해 변수로 선언해서 사용
  // heros
  // assets/images/heros
  final String apple = 'apple';
  final String carrot = 'carrot';
  final String eggPlant = 'eggplant';
  final String banana = 'banana';
  final String pa = 'pa';

  // enemies
  // assets/images/enemies
  final String enemyIcecream1 = 'ice_1';
  final String enemyIcecream2 = 'ice_2';
  final String enemyIcecream3 = 'ice_3';
  final String enemyPizza1 = 'pizza_1';
  final String enemyPizza2 = 'pizza_2';
  final String hotdog = 'hotdog';

  // projectiles
  final String arrow = 'arrow';
  final String sword = 'sword';
  final String swordStrike = 'sword_strike';
  final String doubleSwordStrike = 'double_sword_strike';

  final String bro = 'bro';

  final Map<String, Sprite> _sprites = {};
  final Map<int, String> _heroNameID = {
    0: 'apple',
    1: 'carrot',
    2: 'eggplant',
    3: 'banana',
    4: 'pa',
  };
  final Map<int, String> _enemyNameID = {
    0: 'ice_1',
    1: 'ice_2',
    2: 'ice_3',
    3: 'pizza_1',
    4: 'pizza_2',
    5: 'hotdog',
  };
  final Map<int, String> _projectileNameID = {
    0: 'arrow',
    1: 'sword',
    2: 'sword_strike',
    3: 'double_sword_strike',
  };
  final Map<int, int> _projectileIdbyHeroId = {
    // heroId : projectileId
    0: 1, // apple
    1: 0, // carrot
    2: 3, // eggplant
    3: 2, // banana
    4: 0, // pa
  };

  // 애니메이션 관련 추가
  final Map<String, SpriteAnimation> _animations = {};

  /// Load a specific sprite by its key
  Future<Sprite> loadSprite(String name, String folderPath) async {
    final fullPath = '$folderPath/$name.png';
    final sprite = await Sprite.load(fullPath);
    _sprites[name] = sprite;
    return sprite;
  }

  /// Load animation from a sequence of images
  Future<SpriteAnimation> loadAnimation(String basePath, int frameCount, double stepTime) async {
    final frames = await Future.wait(List.generate(frameCount, 
      (i) => Sprite.load('$basePath/frame_$i.png')
    ));
    return SpriteAnimation.spriteList(frames, stepTime: stepTime);
  }

  /// 앱 시작 시 모든 이미지를 로드하며 변수에 저장함
  Future<void> preloadAll() async {
    const heroPath = 'heros';
    const enemyPath = 'enemies';
    const projectilePath = 'projectiles';

    await Future.wait([
      loadSprite(apple, heroPath),
      loadSprite(carrot, heroPath),
      loadSprite(eggPlant, heroPath),
      loadSprite(banana, heroPath),
      loadSprite(pa, heroPath),
      loadSprite(enemyIcecream1, enemyPath),
      loadSprite(enemyIcecream2, enemyPath),
      loadSprite(enemyIcecream3, enemyPath),
      loadSprite(enemyPizza1, enemyPath),
      loadSprite(enemyPizza2, enemyPath),
      loadSprite(hotdog, enemyPath),
      loadSprite(arrow, projectilePath),
      loadSprite(sword, projectilePath),
      loadSprite(swordStrike, projectilePath),
      loadSprite(doubleSwordStrike, projectilePath),

      loadSprite(bro, heroPath),
    ]);

    print('Loaded sprites: ${_sprites.length}');
  }

  /// Load all animations
  Future<void> preloadAnimations() async {
    _animations['apple_attack'] = await loadAnimation('heros/apple_attack', 5, 0.1);
    _animations['carrot_attack'] = await loadAnimation('heros/carrot_attack', 6, 0.08);
    _animations['eggplant_attack'] = await loadAnimation('heros/eggplant_attack', 4, 0.12);
    _animations['banana_attack'] = await loadAnimation('heros/banana_attack', 7, 0.09);
  }

  /// Get a sprite by its name
  Sprite? getSprite(String name) {
    return _sprites[name];
  }

  Sprite? getSpriteByHeroID(int id) {
    return _sprites[_heroNameID[id]];
  }

  Sprite? getEnemySpriteByHeroID(int id) {
    return _sprites[_enemyNameID[id]];
  }

  Sprite? getProjectileSprite(int heroId) {
    return _sprites[_projectileNameID[_projectileIdbyHeroId[heroId]]]; 
  }

  SpriteAnimation? getAnimation(String name) => _animations[name];

  Sprite? getUltraProjectileSprite() {
    //return bro
    return _sprites[bro];
  }
}
