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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class BattleGame extends FlameGame {
  final GameWorld gameWorld = GameWorld();
  int level = 0;
  int gold = 0;
  int powerLevel = 0; // 파워게이지
  bool isGamePaused = false; // 게임 일시정지 여부
  bool isGameEnded = false; // 게임 종료 여부
  late SlidingBackground slidingBackground;
  late AudioPlayer audioPlayer;
  late EnemyGroup enemyGroup;

  // 타이머 관련 변수
  late TimerComponent gameTimer;
  int elapsedSeconds = 0;
  late ValueNotifier<int> elapsedSecondsNotifier;

  // 카메라 관련 변수
  CameraController? cameraController;
  Future<void>? cameraInitialized;
  bool isCameraInitialized = false;

  // 채소 관련 변수
  final int targetVegetableCount;
  int eatenVegetableCount = 0;

  BattleGame({required this.targetVegetableCount});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 슬라이딩 배경
    slidingBackground = SlidingBackground(100);
    await add(slidingBackground);

    // 게임 월드
    add(gameWorld);

    // 배경음악
    audioPlayer = AudioPlayer();
    try {
      await audioPlayer.setSource(AssetSource('audio/stranger-things-124008.mp3'));
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.play(AssetSource('audio/stranger-things-124008.mp3'), volume: 0.5);
    } catch (e) {
      print('Audio initialization error: $e');
    }

    // 타이머
    elapsedSecondsNotifier = ValueNotifier<int>(elapsedSeconds);
    gameTimer = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: () {
        if (!isGameEnded && (overlays.isActive('vegetableCameraView') || !isGamePaused)) {
          elapsedSeconds++;
          elapsedSecondsNotifier.value = elapsedSeconds;
          print('Elapsed Seconds: $elapsedSeconds');
        }
      },
    );
    add(gameTimer);

    // 카메라
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        cameraController = CameraController(
          cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          ),
          ResolutionPreset.low,
        );
        cameraInitialized = cameraController!.initialize().then((_) {
          isCameraInitialized = true;
        }).catchError((e) {
          print('Camera initialization error: $e');
        });
      } else {
        print('No cameras available');
      }
    } catch (e) {
      print('Camera setup error: $e');
    }

    // 오버레이
    overlays.addEntry('PauseOverlay', (context, game) => PauseOverlay(game: this));
    overlays.addEntry('PauseButton', (context, game) => PauseButton(game: this));
    overlays.addEntry('TimerOverlay', (context, game) => TimerOverlay(game: this));
    overlays.addEntry('CameraOverlay', (context, game) => CameraOverlay(game: this));
    overlays.addEntry('GameEndOverlay', (context, game) => GameEndOverlay(game: this));
    overlays.add('PauseButton');
    overlays.add('TimerOverlay');
    overlays.add('CameraOverlay');
  }

  @override
  void update(double dt) {
    if (!isGameEnded) {
      super.update(dt);
      if (!isGamePaused) {
        gameWorld.update(dt);
      }
    }
  }

  @override
  Future<void> onRemove() async {
    try {
      if (isCameraInitialized && cameraController != null) {
        await cameraController!.dispose();
      }
      await audioPlayer.stop();
      await audioPlayer.dispose();
    } catch (e) {
      print('Resource cleanup error: $e');
    }
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
    eatenVegetableCount++;
    print('Eaten Vegetables: $eatenVegetableCount / $targetVegetableCount');

    if (eatenVegetableCount >= targetVegetableCount) {
      endGame();
    } else {
      isGamePaused = false;
    }
  }

  // 게임 종료 로직
  Future<void> endGame() async {
    if (isGameEnded) return;

    isGameEnded = true;
    isGamePaused = true;

    // 오버레이 정리
    overlays.remove('PauseButton');
    overlays.remove('TimerOverlay');

    // 컴포넌트 제거
    remove(gameWorld);
    remove(slidingBackground);
    remove(gameTimer);

    // 배경음악 중지
    try {
      await audioPlayer.stop();
    } catch (e) {
      print('Audio stop error: $e');
    }

    // Firestore 저장
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      try {
        await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('game_records')
          .add({
            'broccoliCount': eatenVegetableCount,
            'date': dateStr,
            'playTime': elapsedSeconds,
            'timestamp': FieldValue.serverTimestamp(),
          });
        print('Game record saved: $dateStr, $eatenVegetableCount, $elapsedSeconds');
      } catch (e) {
        print('Firestore save error: $e');
      }
    }

    // 게임 엔진 일시 중지
    pauseEngine();

    // 게임 종료 오버레이
    overlays.add('GameEndOverlay');
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
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6FA).withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '일시정지됨',
              style: GoogleFonts.jua(
                fontSize: 32,
                color: Color(0xFFFF4081),
                shadows: [Shadow(color: Colors.white, blurRadius: 2)],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                game.hidePauseOverlay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF80AB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('재개', style: GoogleFonts.jua(fontSize: 20, color: Colors.white)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                game.exitGame(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF80AB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('종료', style: GoogleFonts.jua(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 0.5.seconds);
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
            style: GoogleFonts.jua(
              fontSize: 24,
              color: Color(0xFFFF4081),
              shadows: [Shadow(color: Colors.white, blurRadius: 2)],
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
                child: CameraPreview(game.cameraController!),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  '카메라 오류',
                  style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4081)));
            }
          },
        ),
      ),
    );
  }
}

class GameEndOverlay extends StatelessWidget {
  final BattleGame game;

  const GameEndOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFC1CC), Color(0xFFE6E6FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/screen/Heartsping.png',
                width: 80,
                height: 80,
              ).animate().shimmer(duration: 2.seconds),
              const SizedBox(height: 10),
              Text(
                '하츄핑과 함께한 게임 종료!',
                style: GoogleFonts.jua(
                  fontSize: 32,
                  color: Color(0xFFFF4081),
                  shadows: [Shadow(color: Colors.white, blurRadius: 2)],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/heros/vegetable.png',
                    width: 40,
                    height: 40,
                  ).animate().shake(duration: 1.seconds),
                  const SizedBox(width: 10),
                  Text(
                    '먹은 채소: ${game.eatenVegetableCount}개',
                    style: GoogleFonts.jua(fontSize: 20, color: Colors.black),
                  ),
                ],
              ),
              Text(
                '날짜: $formattedDate',
                style: GoogleFonts.jua(fontSize: 20, color: Colors.black),
              ),
              Text(
                '플레이 시간: ${game.getFormattedTime()}',
                style: GoogleFonts.jua(fontSize: 20, color: Colors.black),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  game.exitGame(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF80AB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  '메인 화면으로',
                  style: GoogleFonts.jua(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 0.5.seconds);
  }
}