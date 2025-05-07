// flutter_app/lib/game/game.dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

  // 타이머 관련 변수
  late TimerComponent gameTimer;
  int elapsedSeconds = 0; // 경과 시간(초)
  late ValueNotifier<int> elapsedSecondsNotifier; // ValueNotifier 추가

  // 카메라 관련 변수
  late CameraController cameraController;
  late Future<void> cameraInitialized;
  bool isCameraInitialized = false;

  // 채소 관련 변수
  final int targetVegetableCount; // 오늘 먹어야 할 채소 개수
  int eatenVegetableCount = 0; // 먹은 채소 개수

  // 생성자에서 targetVegetableCount를 받아옴
  BattleGame({required this.targetVegetableCount});

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

    // ValueNotifier 초기화
    elapsedSecondsNotifier = ValueNotifier<int>(elapsedSeconds);

    // 카메라 초기화
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(
        cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.low,
      );
      cameraInitialized = cameraController.initialize().then((_) {
        isCameraInitialized = true;
      }).catchError((e) {
        print('Camera initialization error: $e');
      });
    } else {
      print('No cameras available');
    }

    // 오버레이 빌더 등록
    overlays.addEntry('PauseOverlay', (context, game) => PauseOverlay(game: this));
    overlays.addEntry('PauseButton', (context, game) => PauseButton(game: this));
    overlays.addEntry('TimerOverlay', (context, game) => TimerOverlay(game: this));
    overlays.addEntry('CameraOverlay', (context, game) => CameraOverlay(game: this));
    overlays.addEntry('GameEndOverlay', (context, game) => GameEndOverlay(game: this));

    // PauseButton 오버레이 활성화
    overlays.add('PauseButton');
    // TimerOverlay 오버레이 활성화
    overlays.add('TimerOverlay');
    // CameraOverlay 오버레이 활성화
    overlays.add('CameraOverlay');

    // 타이머 컴포넌트 추가
    gameTimer = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: () {
        if (overlays.isActive('vegetableCameraView') || !isGamePaused) {
          elapsedSeconds++;
          elapsedSecondsNotifier.value = elapsedSeconds;
          print('Elapsed Seconds: $elapsedSeconds');
        }
      },
    );
    add(gameTimer);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isGamePaused) {
      gameWorld.update(dt);
    }
  }

  @override
  Future<void> onRemove() async {
    if (isCameraInitialized) {
      await cameraController.dispose();
    }
    await audioPlayer.stop();
    await audioPlayer.dispose();
    super.onRemove();
  }

  void showHeroSelectionOverlay() {
    overlays.add('HeroSelection');
    isGamePaused = true;
  }

  void hideHeroSelectionOverlay() {
    overlays.remove('HeroSelection');
    isGamePaused = false;
  }

  void showEatCameraOverlay() {
    overlays.add('eatCameraView');
    isGamePaused = true;
  }

  void hideEatCameraOverlay() {
    overlays.remove('eatCameraView');
    gameWorld.heroEnergy = gameWorld.maxHeroEnergy;

    if (gameWorld.heroes.isNotEmpty) {
      final heroEnergyBarPosition = gameWorld.heroEnergyBar.position;
      final flameEffectPosition = heroEnergyBarPosition + Vector2(200, 0);
      final flameEffect = FlameEffect(position: flameEffectPosition);
      add(flameEffect);
    }

    isGamePaused = false;
  }

  void showVegetableCameraOverlay() {
    overlays.add('vegetableCameraView');
    isGamePaused = true;
  }

  void hideVegetableCameraOverlay() {
    overlays.remove('vegetableCameraView');
    gameWorld.spawnUltraProjectile();
    gameWorld.removeVegetable();

    // 먹은 채소 개수 증가
    eatenVegetableCount++;
    print('Eaten Vegetables: $eatenVegetableCount / $targetVegetableCount');

    // 목표 채소 개수에 도달했는지 확인
    if (eatenVegetableCount >= targetVegetableCount) {
      overlays.add('GameEndOverlay');
      isGamePaused = true; // 게임 일시정지
    } else {
      isGamePaused = false; // 게임 재개
    }
  }

  void showPauseOverlay() {
    overlays.add('PauseOverlay');
    isGamePaused = true;
  }

  void hidePauseOverlay() {
    overlays.remove('PauseOverlay');
    isGamePaused = false;
  }

  void exitGame(BuildContext context) {
    onRemove();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  String getFormattedTime() {
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class PauseButton extends StatelessWidget {
  final BattleGame game;

  const PauseButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: IconButton(
        icon: const Icon(Icons.pause, size: 40, color: Colors.white),
        onPressed: () {
          game.showPauseOverlay();
        },
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  final BattleGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '일시정지됨',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                game.hidePauseOverlay();
              },
              child: const Text('재개', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                game.exitGame(context);
              },
              child: const Text('종료', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

class TimerOverlay extends StatelessWidget {
  final BattleGame game;

  const TimerOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      child: ValueListenableBuilder<int>(
        valueListenable: game.elapsedSecondsNotifier,
        builder: (context, elapsedSeconds, child) {
          return Text(
            game.getFormattedTime(),
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }
}

class CameraOverlay extends StatelessWidget {
  final BattleGame game;

  const CameraOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 1,
      child: SizedBox(
        width: 200,
        height: 150,
        child: FutureBuilder<void>(
          future: game.cameraInitialized,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && game.isCameraInitialized) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CameraPreview(game.cameraController),
              );
            } else if (snapshot.hasError) {
              return const Center(
                child: Text(
                  '카메라 오류',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

// 게임 종료 시 표시할 오버레이
class GameEndOverlay extends StatelessWidget {
  final BattleGame game;

  const GameEndOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // 현재 날짜 가져오기
    final now = DateTime.now();
    final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '게임 종료!',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '날짜: $formattedDate',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            Text(
              '플레이 시간: ${game.getFormattedTime()}',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            Text(
              '먹은 채소 개수: ${game.eatenVegetableCount}개',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                game.exitGame(context);
              },
              child: const Text('메인 화면으로로', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}