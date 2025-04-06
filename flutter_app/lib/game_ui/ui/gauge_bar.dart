import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum GaugeDirection { leftToRight, rightToLeft }
enum AlignType { left, right, center }
class GaugeBar extends PositionComponent {
  final GaugeDirection direction;
  Color mainColor;
  Color backgroundColor;
  Color decreaseMarginColor;
  final double animationDuration;

  // 테두리 속성 추가
  double borderWidth;
  Color borderColor;

  double currentValue = 1.0;
  double previousValue = 1.0;
  double animationProgress = 1.0;
  double elapsedTime = 0.0;

  GaugeBar({
    required this.direction,
    required this.mainColor,
    required this.backgroundColor,
    required this.decreaseMarginColor,
    this.animationDuration = 0.3,
    required Vector2 position,
    required Vector2 size,
    this.borderWidth = 4.0, // 기본 테두리 두께
    this.borderColor = Colors.black, // 기본 테두리 색상
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = backgroundColor,
    );

    // Draw main gauge bar (red bar)
    double barWidth = size.x * currentValue;
    double barStart = direction == GaugeDirection.leftToRight ? 0 : size.x - barWidth;
    canvas.drawRect(
      Rect.fromLTWH(barStart, 0, barWidth, size.y),
      Paint()..color = mainColor,
    );

    // Draw decrease margin (yellow area)
    if (previousValue > currentValue) {
      double decreaseWidth = size.x * (previousValue - currentValue) * (1 - animationProgress);
      double decreaseStart = direction == GaugeDirection.leftToRight
          ? barStart + barWidth
          : barStart - decreaseWidth;

      canvas.drawRect(
        Rect.fromLTWH(decreaseStart, 0, decreaseWidth, size.y),
        Paint()..color = decreaseMarginColor,
      );
    }

    // Draw border
    if (borderWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
  }
  void setPosition(AlignType align, double gameWidth) {
    //gameWidth = gameref.size.x
    //자신의 크기를 고려하여 위치 설정
    switch (align) {
      case AlignType.left:
        this.position = Vector2(0, this.position.y);
        break;
      case AlignType.right:
        this.position = Vector2(gameWidth - this.size.x, this.position.y);
        break;
      case AlignType.center:
        this.position = Vector2((gameWidth - this.size.x) / 2, this.position.y);
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update animation progress
    if (animationProgress < 1.0) {
      elapsedTime += dt;
      animationProgress = (elapsedTime / animationDuration).clamp(0.0, 1.0);

      if (animationProgress >= 1.0) {
        animationProgress = 1.0;
        previousValue = currentValue; // Reset previous value after animation
      }
    }
  }

  void setValue(double newValue) {
    if (newValue < currentValue) {
      // Trigger yellow margin animation when HP decreases
      previousValue = currentValue;
      elapsedTime = 0.0;
      animationProgress = 0.0;
    }
    currentValue = newValue.clamp(0.0, 1.0);
  }
}
