import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';  // Color 클래스를 사용하기 위해 import

class SlidingBackground extends Component with HasGameRef<FlameGame> {
  final List<SpriteComponent> topBackgrounds = [];
  final List<SpriteComponent> bottomBackgrounds = [];
  final double slideSpeed;
  final double overlapRatio;

  SlidingBackground(this.slideSpeed, {this.overlapRatio = 0.9});

  @override
  Future<void> onLoad() async {
    await _initializeBackgrounds();
  }

  Future<void> _initializeBackgrounds() async {
    topBackgrounds.clear();
    bottomBackgrounds.clear();

    final screenSize = gameRef.size;

    // 공백 부분을 연한 하늘색으로 채우는 배경을 추가
    final skyBackground = RectangleComponent(
      size: screenSize,
      position: Vector2(0, 0), // 화면의 왼쪽 상단에 배치
      paint: Paint()..color = Color.fromARGB(255, 199, 233, 249), // 연한 하늘색으로 채우기
    );
    add(skyBackground); // 하늘색 배경을 맨 뒤에 추가

    // 하단 배경 (bg4) 초기화
    for (int i = 0; i < 2; i++) {
      final sprite = await Sprite.load('screen/bg4.png');
      final bottomBackground = SpriteComponent(
        sprite: sprite,
        size: Vector2(screenSize.x, screenSize.y), // 화면 크기로 설정
        position: Vector2(
          screenSize.x * i * (1 - overlapRatio),
          screenSize.y - screenSize.y, // 화면 하단에 위치
        ),
      );
      bottomBackgrounds.add(bottomBackground);
      add(bottomBackground); // 하단 배경을 하늘색 배경 위에 추가
    }

    // 상단 배경 (bg1, bg2, bg3) 초기화
    for (int i = 0; i < 3; i++) {
      final sprite = await Sprite.load('screen/bg${i + 1}.png');
      final topBackground = SpriteComponent(
        sprite: sprite,
        size: Vector2(screenSize.x, screenSize.y), // 화면 크기로 설정
        position: Vector2(
          screenSize.x * i * (1 - overlapRatio),
          screenSize.y * 0.4, // 화면의 중앙에서 조금 위쪽에 위치
        ),
      );
      topBackgrounds.add(topBackground);
      add(topBackground); // 상단 배경을 하늘색 배경 위에 추가
    }
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);

    final screenSize = newSize;

    // 하단 배경 재배치
    for (int i = 0; i < bottomBackgrounds.length; i++) {
      final background = bottomBackgrounds[i];
      background.size = Vector2(screenSize.x, screenSize.y); // 화면을 꽉 채우도록 수정
      background.position = Vector2(
        screenSize.x * i * (1 - overlapRatio),
        screenSize.y - screenSize.y, // 하단 배경을 화면 맨 아래로 설정
      );
    }

    // 상단 배경 재배치
    for (int i = 0; i < topBackgrounds.length; i++) {
      final background = topBackgrounds[i];
      background.size = Vector2(screenSize.x, screenSize.y); // 화면을 꽉 채우도록 수정
      background.position = Vector2(
        screenSize.x * i * (1 - overlapRatio),
        screenSize.y * -0.5, // 상단 배경을 화면의 중앙에서 조금 위쪽에 배치
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 상단 배경 슬라이드
    for (final bg in topBackgrounds) {
      bg.position.x -= slideSpeed * dt;
      if (bg.position.x + bg.size.x * (1 - overlapRatio) < 0) {
        bg.position.x += bg.size.x * topBackgrounds.length * (1 - overlapRatio);
      }
    }

    // 하단 배경 슬라이드
    for (final bg in bottomBackgrounds) {
      bg.position.x -= slideSpeed * dt;
      if (bg.position.x + bg.size.x * (1 - overlapRatio) < 0) {
        bg.position.x += bg.size.x * bottomBackgrounds.length * (1 - overlapRatio);
      }
    }
  }
}
