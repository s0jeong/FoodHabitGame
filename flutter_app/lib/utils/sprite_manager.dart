// flutter_app/utils/sprite_manager.dart
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class SpriteManager {
  final String apple = 'apple';
  final String carrot = 'carrot';
  final String eggPlant = 'eggplant';
  final String banana = 'banana';
  final String pa = 'pa';

  final String enemyIcecream1 = 'ice_1';
  final String enemyIcecream2 = 'ice_2';
  final String enemyIcecream3 = 'ice_3';
  final String enemyPizza1 = 'pizza_1';
  final String enemyPizza2 = 'pizza_2';
  final String hotdog = 'hotdog';

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
    0: 1, // apple
    1: 1, // carrot
    2: 3, // eggplant
    3: 2, // banana
  };
  final Map<int, Uint8List> _heroImages = {}; // 캐싱 추가

  final Map<String, SpriteAnimation> _animations = {};

  Future<Sprite> loadSprite(String name, String folderPath) async {
    final fullPath = '$folderPath/$name.png';
    final sprite = await Sprite.load(fullPath);
    _sprites[name] = sprite;
    return sprite;
  }

  Future<SpriteAnimation> loadAnimation(String basePath, int frameCount, double stepTime) async {
    final frames = await Future.wait(List.generate(frameCount,
        (i) => Sprite.load('$basePath/frame_$i.png')));
    return SpriteAnimation.spriteList(frames, stepTime: stepTime);
  }

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

  // 영웅 스프라이트를 Uint8List로 변환 및 캐싱
  Future<void> preloadHeroImages() async {
    for (var id in _heroNameID.keys) {
      final sprite = _sprites[_heroNameID[id]];
      if (sprite != null) {
        final ui.Image image = await sprite.toImage();
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          _heroImages[id] = byteData.buffer.asUint8List();
          print('Cached hero image for ID: $id');
        }
      }
    }
  }

  Future<void> preloadAnimations() async {
    _animations['apple_attack'] = await loadAnimation('heros/apple_attack', 5, 0.1);
    _animations['carrot_attack'] = await loadAnimation('heros/carrot_attack', 6, 0.08);
    _animations['eggplant_attack'] = await loadAnimation('heros/eggplant_attack', 4, 0.12);
    _animations['banana_attack'] = await loadAnimation('heros/banana_attack', 7, 0.09);
  }

  Sprite? getSprite(String name) => _sprites[name];

  Sprite? getSpriteByHeroID(int id) => _sprites[_heroNameID[id]];

  Sprite? getEnemySpriteByHeroID(int id) => _sprites[_enemyNameID[id]];

  Sprite? getProjectileSprite(int heroId) => _sprites[_projectileNameID[_projectileIdbyHeroId[heroId]]];

  SpriteAnimation? getAnimation(String name) => _animations[name];

  Sprite? getUltraProjectileSprite() => _sprites[bro];

  // 캐싱된 영웅 이미지 반환
  Uint8List? getHeroImageById(int id) => _heroImages[id];
}