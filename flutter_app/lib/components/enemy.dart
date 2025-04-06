import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame/effects.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'dart:math';

class Enemy extends SpriteComponent with HasGameRef {
  int enemyID;
  bool isDying = false;
  double idleTimer = 0.0;

  late Vector2 originalPosition; // originalPosition 저장
  bool isBoss;

  Enemy({required this.enemyID, this.isBoss = false}) : super(size: Vector2(60, 60));

  @override
  Future<void> onLoad() async {
    sprite = spriteManager.getEnemySpriteByHeroID(enemyID);
    if (sprite != null) {
      size = Vector2(sprite!.src.width.toDouble(), sprite!.src.height.toDouble());
      // 보스인 경우 size를 조정하지 않음
      if (!isBoss) {
        size = size * 0.5; // 보스가 아닐 경우만 크기 조정
      }
    }
    anchor = Anchor.bottomCenter;

    // originalPosition 초기화
    originalPosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    animateIdle(dt);
    adjustDynamicPosition(); // Y 위치를 동적으로 조정
  }

  void animateIdle(double dt) {
    idleTimer += dt;
    double scaleY = 1.0 + 0.05 * sin(idleTimer * 3); // 주기적 변화
    scale = Vector2(1.0, scaleY); // Y축 스케일 변화
  }

  // 화면 높이에 따라 동적 Y 위치를 설정하는 메서드
  void adjustDynamicPosition() {
    double screenHeight = gameRef.size.y;
    position.y = screenHeight * 0.7; // 화면 하단에서 30% 위에 위치
  }

  void takeDamage() {
    // 불꽃 효과 추가
    add(ColorEffect(
      const Color(0xFFFFFFFF), // 완전히 흰색으로 변경
      EffectController(duration: 0.3, reverseDuration: 0.3),
    ));

    // 뒤로 기울어지는 효과 추가
    add(RotateEffect.to(
      0.3, // 뒤로 기울어질 각도 (라디안, 음수 값은 반시계 방향)
      EffectController(duration: 0.2, reverseDuration: 0.2),
    ));

    // 이후 다시 원래 상태로 복원
    add(OpacityEffect.to(
      1.0, // 다시 불투명으로
      EffectController(duration: 0.1),
    ));
  }

  void addExplosionEffect() {
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 30,
        lifespan: 1.0,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 200),
          speed: Vector2.random() * 500,
          position: position.clone(),
          child: CircleParticle(
            radius: 5.0,
            paint: Paint()..color = const Color(0xFFFF0000),
          ),
        ),
      ),
      position: position.clone(),
      priority: 10,
    );

    gameRef.add(particleComponent);
  }

  void die() async {
    if (isDying) return;
    isDying = true;

    // 폭발 효과 추가
    addExplosionEffect();

    // 폭발 소리 재생
    final player = AudioPlayer();
    await player.play(AssetSource('audio/EXPLOSION_Distorted_01_Long_stereo.wav'));

    // 1초 후에 컴포넌트를 삭제
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
    });
  }
}