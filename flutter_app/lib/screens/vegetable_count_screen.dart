// flutter_app/lib/screens/vegetable_count_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/screens/preferences.dart';
import 'package:flame/game.dart';
import 'package:flutter_app/game/game.dart';
import 'package:flutter_app/game_ui/hero_selection_overlay.dart';
import 'package:flutter_app/game_ui/eat_detector_view.dart';
import 'package:flutter_app/game_ui/vegetable_detector_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VegetableCountScreen extends StatefulWidget {
  const VegetableCountScreen({super.key});

  @override
  State<VegetableCountScreen> createState() => _VegetableCountScreenState();
}

class _VegetableCountScreenState extends State<VegetableCountScreen> {
  int broccoliCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await Preferences.getPreferences();
    setState(() {
      broccoliCount = prefs['broccoliCount']!;
    });
  }

  // 제목에 사용할 텍스트 스타일 정의
  static const titleTextStyle = TextStyle(
    fontSize: 50,
    color: Colors.black,
    shadows: [
      Shadow(
        color: Colors.white,
        offset: Offset(2, 2),
        blurRadius: 4,
      ),
      Shadow(
        color: Colors.black54,
        offset: Offset(-1, -1),
        blurRadius: 2,
      ),
    ],
  );

  // 숫자에 사용할 텍스트 스타일 정의
  static const numberTextStyle = TextStyle(
    fontSize: 20, // 숫자는 작게 표시
    color: Colors.black,
    shadows: [
      Shadow(
        color: Colors.white,
        offset: Offset(1, 1),
        blurRadius: 2,
      ),
      Shadow(
        color: Colors.black54,
        offset: Offset(-0.5, -0.5),
        blurRadius: 1,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // 화면 터치 시 캐릭터 선택 창으로 이동
          // BattleGame 생성 시 broccoliCount를 targetVegetableCount로 전달
          final myGame = BattleGame(targetVegetableCount: broccoliCount);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GameWidget(
                game: myGame,
                overlayBuilderMap: {
                  'HeroSelection': (BuildContext context, BattleGame game) {
                    return HeroSelectionOverlay(
                      onSelect: (selectedHero) {
                        game.gameWorld.addHeroById(selectedHero);
                        game.hideHeroSelectionOverlay();
                      },
                    );
                  },
                  'eatCameraView': (BuildContext context, BattleGame game) {
                    return EatDetectorView(
                      onFinished: () {
                        game.hideEatCameraOverlay();
                      },
                    );
                  },
                  'vegetableCameraView': (BuildContext context, BattleGame game) {
                    return VegetableDetectorView(
                      onFinished: () {
                        game.hideVegetableCameraOverlay();
                      },
                    );
                  },
                },
              ),
            ),
          );
        },
        child: Container(
          color: const Color(0xFFE6E6FA).withOpacity(0.9), // 파스텔 퍼플 배경
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '오늘 먹어야 할 채소 개수',
                  style: GoogleFonts.jua(textStyle: titleTextStyle),
                ).animate().fadeIn(duration: 1.seconds),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: List.generate(
                    broccoliCount,
                    (index) => Column(
                      children: [
                        Image.asset(
                          'assets/images/heros/vegetable.png',
                          width: 60,
                          height: 60,
                        ).animate().fadeIn(
                              duration: 0.5.seconds,
                              delay: (index * 0.1).seconds,
                            ),
                        const SizedBox(height: 5),
                        Text(
                          (index + 1).toString(), // 1, 2, 3, ... 순서대로 표시
                          style: GoogleFonts.jua(textStyle: numberTextStyle),
                        ).animate().fadeIn(
                              duration: 0.5.seconds,
                              delay: (index * 0.1).seconds,
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Icon(
                  Icons.star,
                  size: 50,
                  color: Colors.black,
                ).animate().shimmer(duration: 1.5.seconds).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.1, 1.1),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                    ).rotate(
                      begin: 0,
                      end: 0.1,
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}