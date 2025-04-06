import 'package:flame/game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'world.dart';
import 'package:flutter_app/screens/sliding_background.dart';
import 'package:flutter_app/components/enemyGroup.dart';
import 'package:flutter_app/utils/flame_effect.dart';

class BattleGame extends FlameGame {
  final GameWorld gameWorld = GameWorld();
  int level = 0;
  int gold = 0;
  int powerLevel = 0; // 파워게이지

  bool isGamePaused = false; // 게임 일시정지 여부
  late SlidingBackground slidingBackground; // SlidingBackground 추가

  late AudioPlayer audioPlayer; // AudioPlayer 인스턴스
  late EnemyGroup enemyGroup;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 슬라이딩 배경 추가
    slidingBackground = SlidingBackground(100); // 슬라이드 속도를 설정
    await add(slidingBackground); // `onLoad` 호출 및 추가

    // 게임 월드 추가
    add(gameWorld);

    // 배경음악 초기화 및 재생
    audioPlayer = AudioPlayer(); // AudioPlayer 생성
    await audioPlayer.setSource(AssetSource('audio/stranger-things-124008.mp3')); // 오디오 파일 설정
    await audioPlayer.setReleaseMode(ReleaseMode.loop); // 반복 재생 설정
    audioPlayer.play(AssetSource('audio/stranger-things-124008.mp3'), volume: 0.5); // 재생
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 게임이 일시 정지 상태가 아닐 때만 게임 월드 업데이트
    if (!isGamePaused) {
      gameWorld.update(dt); // 게임 월드 업데이트
    }
  }

  @override
  Future<void> onRemove() async {
    // 게임 종료 시 배경음악 정지 및 해제
    await audioPlayer.stop();
    await audioPlayer.dispose();
    super.onRemove();
  }

  void showHeroSelectionOverlay() {
    overlays.add('HeroSelection'); // 'HeroSelection' 오버레이 추가
    isGamePaused = true; // 게임 일시정지
  }

  void hideHeroSelectionOverlay() {
    overlays.remove('HeroSelection'); // 'HeroSelection' 오버레이 제거
    isGamePaused = false; // 게임 재개
  }

  void showEatCameraOverlay() {
    overlays.add('eatCameraView'); // 'EatCamera' 오버레이 추가
    isGamePaused = true; // 게임 일시정지
  }

  void hideEatCameraOverlay() {
    overlays.remove('eatCameraView'); // 'EatCamera' 오버레이 제거
    gameWorld.heroEnergy = gameWorld.maxHeroEnergy; // 히어로 에너지 풀충전

    // 히어로에 FlameEffect 파티클 효과 추가
    if (gameWorld.heroes.isNotEmpty) {
      // 에너지 바 위치를 기준으로 FlameEffect 생성
      final heroEnergyBarPosition = gameWorld.heroEnergyBar.position; // 에너지 바 위치
      final flameEffectPosition = heroEnergyBarPosition + Vector2(200, 0); // x 좌표를 200픽셀 오른쪽으로 이동
      final flameEffect = FlameEffect(position: flameEffectPosition);
      add(flameEffect);
    }

    isGamePaused = false; // 게임 재개
  }

  void showVegetableCameraOverlay() {
    overlays.add('vegetableCameraView'); // 'VegetableCamera' 오버레이 추가
    isGamePaused = true; // 게임 일시정지
  }
  void hideVegetableCameraOverlay() {
    overlays.remove('vegetableCameraView'); // 'VegetableCamera' 오버레이 제거
    gameWorld.spawnUltraProjectile();
    isGamePaused = false; // 게임 재개
  }

  // // 메시지 표시 메서드 추가
  // void showBossMessage(String message, {Duration duration = const Duration(seconds: 3)}) {
  //   final messageComponent = TextComponent(
  //     text: message,
  //     textRenderer: TextPaint(
  //       style: TextStyle(
  //         fontSize: 48.0,  // 크기를 좀 더 키워 강조
  //         color: Color.fromARGB(255, 0, 0, 0),
  //         fontWeight: FontWeight.bold,
  //       ),
  //     ),
  //     anchor: Anchor.center,
  //     position: size / 2, // 화면 중앙에 배치
  //   );

  //   add(messageComponent);

  //   // 일정 시간 후 메시지 제거
  //   Future.delayed(duration, () {
  //     messageComponent.removeFromParent();
  //   });
  // }
}
