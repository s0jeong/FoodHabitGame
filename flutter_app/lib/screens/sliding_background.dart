import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';

class SlidingBackground extends Component with HasGameRef<FlameGame> {
  final List<SpriteComponent> backgrounds = [];
  final double slideSpeed;
  final double overlapRatio;

  SlidingBackground(this.slideSpeed, {this.overlapRatio = 0.8});

  @override
  Future<void> onLoad() async {
    await _initializeBackground();
  }

  Future<void> _initializeBackground() async {
    backgrounds.clear();

    final screenSize = gameRef.size;

    // 배경 초기화 (bg_ing1.jpg, bg_ing2.jpg)
    try {
      final bgSprite1 = await Sprite.load('screen/bg_ing1.jpg');
      final bgSprite2 = await Sprite.load('screen/bg_ing2.jpg');

      // 배경 크기를 화면 너비보다 1% 크게 설정
      final bgSize = Vector2(screenSize.x * 1.01, screenSize.y);

      // 첫 번째 배경: bg_ing1.jpg
      final bg1 = SpriteComponent(
        sprite: bgSprite1,
        size: bgSize,
        position: Vector2(0, 0),
        priority: -1,
      );
      // 두 번째 배경: bg_ing2.jpg
      final bg2 = SpriteComponent(
        sprite: bgSprite2,
        size: bgSize,
        position: Vector2(screenSize.x, 0),
        priority: -1,
      );

      backgrounds.add(bg1);
      backgrounds.add(bg2);
      add(bg1);
      add(bg2);
    } catch (e) {
      print('Error loading bg_ing1.jpg or bg_ing2.jpg: $e');
      final skyBackground = RectangleComponent(
        size: screenSize,
        position: Vector2.zero(),
        paint: Paint()
          ..shader = LinearGradient(
            colors: [Color(0xFFD9E7FF), Color(0xFFFFF0F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, screenSize.x, screenSize.y)),
      );
      add(skyBackground);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // 배경 재배치
    for (var i = 0; i < backgrounds.length; i++) {
      final bg = backgrounds[i];
      bg.size = Vector2(size.x * 1.01, size.y);
      bg.position = Vector2(size.x * i, 0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 배경 슬라이드
    for (final bg in backgrounds) {
      bg.position.x -= slideSpeed * dt;
    }

    // 배경 재배치 (15/16 지점에서 전환)
    for (var i = 0; i < backgrounds.length; i++) {
      final bg = backgrounds[i];
      // 15/16 지점 = 화면 너비의 1/16 남음
      final threshold = bg.size.x / 16;
      if (bg.position.x + bg.size.x <= threshold) {
        final prevIndex = (i - 1 + backgrounds.length) % backgrounds.length;
        final prevBg = backgrounds[prevIndex];
        bg.position.x = prevBg.position.x + prevBg.size.x;
        print('배경 전환: bg[$i] to x=${bg.position.x}');
      }
    }
  }
}