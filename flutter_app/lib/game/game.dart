// flutter_app/lib/game/game.dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // 카메라 패키지 추가
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
          (camera) => camera.lensDirection == CameraLensDirection.front, // 전면 카메라 선택
          orElse: () => cameras.first, // 전면 카메라가 없으면 첫 번째 카메라 사용
        ),
        ResolutionPreset.low, // 낮은 해상도로 설정하여 성능 최적화
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

    // PauseButton 오버레이 활성화
    overlays.add('PauseButton');
    // TimerOverlay 오버레이 활성화
    overlays.add('TimerOverlay');
    // CameraOverlay 오버레이 활성화
    overlays.add('CameraOverlay');

    // 타이머 컴포넌트 추가
    gameTimer = TimerComponent(
      period: 1.0, // 1초마다 업데이트
      repeat: true,
      onTick: () {
        // vegetableCameraView가 활성화되어 있거나, 게임이 일시정지 상태가 아닐 때 타이머 증가
        if (overlays.isActive('vegetableCameraView') || !isGamePaused) {
          elapsedSeconds++; // 경과 시간 증가
          elapsedSecondsNotifier.value = elapsedSeconds; // ValueNotifier 갱신
          print('Elapsed Seconds: $elapsedSeconds'); // 디버깅 로그
        }
      },
    );
    add(gameTimer);
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
    // 카메라 리소스 해제
    if (isCameraInitialized) {
      await cameraController.dispose();
    }
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
    gameWorld.removeVegetable(); // 채소 이미지 하나 제거
    isGamePaused = false; // 게임 재개
  }

  // 일시정지 오버레이 표시
  void showPauseOverlay() {
    overlays.add('PauseOverlay');
    isGamePaused = true;
  }

  // 일시정지 오버레이 닫기
  void hidePauseOverlay() {
    overlays.remove('PauseOverlay');
    isGamePaused = false;
  }

  // 게임 종료 및 MainMenu로 돌아가기
  void exitGame(BuildContext context) {
    onRemove();
    // 스택의 첫 번째 화면(MainMenu)으로 이동
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // 경과 시간을 분:초 형식으로 변환
  String getFormattedTime() {
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// 일시정지 버튼 오버레이
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

// 일시정지 오버레이
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

// 실행 시간을 표시하는 오버레이
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

// 카메라 피드를 표시하는 오버레이
class CameraOverlay extends StatelessWidget {
  final BattleGame game;

  const CameraOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80, // TimerOverlay 아래에 배치
      left: 1,
      child: SizedBox(
        width: 200, // 작은 크기
        height: 150,
        child: FutureBuilder<void>(
          future: game.cameraInitialized,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && game.isCameraInitialized) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10), // 모서리 둥글게
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