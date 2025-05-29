import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';
import 'dart:math';

class FlameEffect extends ParticleSystemComponent {
  FlameEffect({required Vector2 position}) : super(position: position);

  @override
  void onMount() {
    super.onMount();

    final particle = Particle.generate(
      count: 150,
      generator: (i) {
        final angle = Random().nextDouble() * 2 * pi; // 랜덤 각도
        final speed = Random().nextDouble() * 100 + 50; // 랜덤 속도
        final distance = Vector2(cos(angle) * speed, sin(angle) * speed); // 방향
        final colors = [0xFF00FF00, 0xFFFFFF00, 0xFF00FFFF, 0xFF006400]; // 색상 배열
        final baseColor = Color(colors[Random().nextInt(colors.length)]); // 랜덤 색상

        // Color.fromRGBO를 사용해 투명도 조정
        final adjustedColor = Color.fromRGBO(
          baseColor.red,
          baseColor.green,
          baseColor.blue,
          Random().nextDouble(), // 0.0 ~ 1.0 사이의 투명도
        );

        return AcceleratedParticle(
          position: Vector2.zero(),
          speed: distance,
          acceleration: Vector2(0, Random().nextDouble() * -25), // 중력 효과
          lifespan: Random().nextDouble() * 1.0 + 1.0, // 수명
          child: CircleParticle(
            radius: Random().nextDouble() * 3 + 3, // 더 큰 반지름
            paint: Paint()..color = adjustedColor, // 색상 적용
          ),
        );
      },
    );

    final glowEffect = ParticleSystemComponent(
      particle: Particle.generate(
        count: 50,
        generator: (i) => CircleParticle(
          radius: Random().nextDouble() * 5 + 5,
          paint: Paint()
            ..color = Color.fromRGBO(
              0, 255, 0, 0.2, // 연한 초록색, 낮은 투명도
            ),
        ),
      ),
    );

    add(ParticleSystemComponent(particle: particle)); // 기본 파티클
    add(glowEffect); // 글로우 파티클 추가
  }
}
