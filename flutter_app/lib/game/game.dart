// flutter_app/lib/game/game.dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/camera.dart';
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
import 'dart:async';
import 'package:flutter_app/components/projectile.dart';
import 'package:flutter_app/game_ui/eat_detector_view.dart';


// 주요 게임 클래스
class BattleGame extends FlameGame {
  // 게임 월드
  final GameWorld gameWorld = GameWorld();

  // 게임 상태 관련 변수 초기화
  int level = 0; // 레벨
  int gold = 0; // 골드
  int powerLevel = 0; // 파워게이지
  bool isGamePaused = false; // 게임 일시정지 여부
  bool isGameEnded = false; // 게임 종료 여부
  late SlidingBackground slidingBackground; // 슬라이딩 배경
  late AudioPlayer audioPlayer; // 배경음악
  late EnemyGroup enemyGroup; // 적 그룹

  // 타이머 관련 변수 초기화
  late TimerComponent gameTimer;
  int elapsedSeconds = 0;
  late ValueNotifier<int> elapsedSecondsNotifier;

  // 카메라 관련 변수 초기화  
  CameraController? cameraController;
  Future<void>? cameraInitialized;
  bool isCameraInitialized = false;

  // 채소 관련 변수 초기화
  final int targetVegetableCount;
  int eatenVegetableCount = 0;

  // 게임 생성자
  BattleGame({required this.targetVegetableCount});

  // 게임 로드
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 화면 크기에 맞게 카메라 설정
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewport = FixedSizeViewport(size.x, size.y);
    
    // 슬라이딩 배경 - 화면 크기에 맞게 조정
    slidingBackground = SlidingBackground(size.y * 0.15); // 화면 높이의 15%로 설정
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
        }
      },
    );
    add(gameTimer);

    // 카메라 설정
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        cameraController = CameraController(
          cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          ),
          ResolutionPreset.medium, // 해상도를 medium으로 변경
        );
        cameraInitialized = cameraController!.initialize().then((_) {
          isCameraInitialized = true;
        }).catchError((e) {
          print('Camera initialization error: $e');
        });
      }
    } catch (e) {
      print('Camera setup error: $e');
    }

    // 오버레이 설정
    overlays.addEntry('PauseOverlay', (context, game) {
      final screenSize = MediaQuery.of(context).size;
      return Container(
        width: screenSize.width,
        height: screenSize.height,
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '일시정지',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenSize.height * 0.05),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.1,
                    vertical: screenSize.height * 0.02,
                  ),
                ),
                onPressed: () {
                  overlays.remove('PauseOverlay');
                  isGamePaused = false;
                },
                child: Text(
                  '계속하기',
                  style: TextStyle(fontSize: screenSize.width * 0.04),
                ),
              ),
            ],
          ),
        ),
      );
    });

    overlays.addEntry('PauseButton', (context, game) {
      final screenSize = MediaQuery.of(context).size;
      return Positioned(
        top: screenSize.height * 0.15,
        right: screenSize.width * 0.02,
        child: IconButton(
          icon: Icon(
            Icons.pause_circle_outline,
            size: screenSize.width * 0.1,
            color: Colors.white,
          ),
          onPressed: () {
            overlays.add('PauseOverlay');
            isGamePaused = true;
          },
        ),
      );
    });

    overlays.addEntry('TimerOverlay', (context, game) {
      final screenSize = MediaQuery.of(context).size;
      return Positioned(
        top: screenSize.height * 0.15,
        left: screenSize.width * 0.02,
        child: ValueListenableBuilder<int>(
          valueListenable: elapsedSecondsNotifier,
          builder: (context, seconds, child) {
            return Text(
              '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenSize.width * 0.05,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      );
    });

    overlays.addEntry(
      'camera_overlay',
      (context, game) => CameraOverlay(game: game as BattleGame),
    );

    // EatDetectorView 오버레이 등록
    overlays.addEntry(
      'eatCameraView',
      (context, game) => EatDetectorView(
        onFinished: () {
          hideEatCameraOverlay();
        },
      ),
    );

    overlays.add('PauseButton');
    overlays.add('TimerOverlay');
  }

  // 게임 업데이트
  @override
  void update(double dt) {
    if (!isGameEnded) {
      super.update(dt);
      if (!isGamePaused) {
        gameWorld.update(dt);
      }
    }
  }

  // 게임 종료 시 리소스 정리
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

  // 영웅 선택 오버레이 추가
  void showHeroSelectionOverlay() {
    overlays.add('HeroSelection');
    isGamePaused = true;
  }

  // 영웅 선택 오버레이 제거
  void hideHeroSelectionOverlay() {
    overlays.remove('HeroSelection');
    isGamePaused = false;
  }

  // 먹기 카메라 오버레이 추가
  void showEatCameraOverlay() {
    if (gameWorld.enemyGroup?.isBoss == true && gameWorld.enemyGroup?.isPhase2 == true) {
      // 보스 2페이즈일 때는 나중에 구현할 특별한 오버레이 표시
      // TODO: 보스 2페이즈용 오버레이 구현
      return;
    } else {
      // 일반 상황이나 1페이즈에서는 기존 먹기 인식 오버레이 표시
      overlays.add('eatCameraView');
      isGamePaused = true;
    }
  }

  // 먹기 카메라 오버레이 제거
  void hideEatCameraOverlay() {
    if (isGameEnded) return;
    
    overlays.remove('eatCameraView');
    
    // 식사 인식이 성공적으로 완료되었을 때만 에너지 회복
    if (gameWorld.heroes.isNotEmpty) {
      gameWorld.restoreEnergy(gameWorld.maxHeroEnergy * 0.9); // 90% 에너지 회복
      
      // 에너지 회복 시각 효과
      final heroEnergyBarPosition = gameWorld.heroEnergyBar.position;
      final flameEffectPosition = heroEnergyBarPosition + Vector2(200, 0);
      final flameEffect = FlameEffect(position: flameEffectPosition);
      add(flameEffect);
    }
    
    isGamePaused = false;
  }

  // 채소 카메라 오버레이 추가
  void showVegetableCameraOverlay() {
    // 이 메서드는 더 이상 직접 호출되지 않음
    showEatCameraOverlay();
  }

  // 채소 카메라 오버레이 제거
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

  // 게임 종료
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

  // 일시정지 오버레이 추가
  void showPauseOverlay() {
    overlays.add('PauseOverlay');
    isGamePaused = true;
  }

  // 일시정지 오버레이 제거
  void hidePauseOverlay() {
    overlays.remove('PauseOverlay');
    isGamePaused = false;
  }

  // 게임 종료 시 메인 화면으로 이동
  void exitGame(BuildContext context) {
    onRemove();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // 타이머 포맷 반환 (분:초)     
  String getFormattedTime() {
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// 일시정지 버튼
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

// 타이머 오버레이
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

// 카메라 오버레이
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

// 게임 종료 오버레이
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