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

  late Vector2 originalPosition;
  bool isBoss;

  Enemy({required this.enemyID, this.isBoss = false}) : super(size: Vector2(60, 60));

  @override
  Future<void> onLoad() async {
    sprite = spriteManager.getEnemySpriteByHeroID(enemyID);
    if (sprite != null) {
      // 화면 크기에 따른 적군 크기 계산
      double screenWidth = gameRef.size.x;
      double baseSize = screenWidth * (isBoss ? 0.2 : 0.1); // 보스는 화면 너비의 20%, 일반 적군은 10%
      size = Vector2(baseSize, baseSize);
    }
    anchor = Anchor.bottomCenter;
    originalPosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    animateIdle(dt);
    adjustDynamicPosition();
  }

  void animateIdle(double dt) {
    idleTimer += dt;
    double screenHeight = gameRef.size.y;
    double scaleY = 1.0 + (screenHeight * 0.0001) * sin(idleTimer * 3); // 화면 크기에 비례한 애니메이션
    scale = Vector2(1.0, scaleY);
  }

  void adjustDynamicPosition() {
    double screenHeight = gameRef.size.y;
    position.y = screenHeight * 0.85; // 화면 하단에서 15% 위에 위치 (기존 25%에서 수정)
  }

  void takeDamage() {
    // 화면 크기에 따른 효과 조정
    double screenWidth = gameRef.size.x;
    
    add(ColorEffect(
      const Color(0xFFFFFFFF),
      EffectController(duration: 0.3, reverseDuration: 0.3),
    ));

    // 회전 각도를 화면 크기에 비례하게 설정
    double rotationAngle = (screenWidth / 1000) * 0.3; // 기준 화면 너비 1000px
    add(RotateEffect.to(
      rotationAngle,
      EffectController(duration: 0.2, reverseDuration: 0.2),
    ));

    add(OpacityEffect.to(
      1.0,
      EffectController(duration: 0.1),
    ));
  }

  void addExplosionEffect() {
    double screenWidth = gameRef.size.x;
    double screenHeight = gameRef.size.y;
    double particleSize = screenWidth * 0.005; // 화면 너비의 0.5%
    double particleSpeed = screenWidth * 0.5; // 화면 너비의 50%
    
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 30,
        lifespan: 1.0,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, screenHeight * 0.2), // 화면 높이의 20%만큼 가속
          speed: Vector2.random() * particleSpeed,
          position: position.clone(),
          child: CircleParticle(
            radius: particleSize,
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

    addExplosionEffect();

    final player = AudioPlayer();
    await player.play(AssetSource('audio/EXPLOSION_Distorted_01_Long_stereo.wav'));

    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
    });
  }
}