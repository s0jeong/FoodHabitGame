import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 추가
import '../game/game.dart';
import 'package:flutter_app/game_ui/eat_detector_view.dart';
import 'package:flutter_app/game_ui/hero_selection_overlay.dart';
import 'package:flutter_app/game_ui/vegetable_detector_view.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final double titleFontSize = 48; // FOOD HABIT GAME의 폰트 크기
  final double startTextFontSize = 24; // Press ENTER to start의 폰트 크기
  final double spacing = 40; // FOOD HABIT GAME과 Press ENTER to start 사이의 간격

  @override
  void initState() {
    super.initState();
    const String title = 'FOOD HABIT GAME';
    // 각 글자에 대해 AnimationController와 Animation 생성
    _controllers = List.generate(
      title.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1000), // 애니메이션 지속 시간
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut, // 부드러운 스케일 변화
        ),
      );
    }).toList();

    // 애니메이션 순차적으로 시작
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        _controllers[i].repeat(reverse: true); // 반복하며 커졌다 작아짐
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Set the background color to a bright blue, similar to the image
        color: const Color(0xFF5C94FC), // Blue background color
        child: Stack(
          children: [
            // Add some decorative elements like pipes and clouds
            Positioned(
              top: 50,
              left: 20,
              child: _buildPipe(),
            ),
            Positioned(
              top: 100,
              right: 30,
              child: _buildPipe(),
            ),
            Positioned(
              top: 30,
              left: 100,
              child: _buildCloud(),
            ),
            Positioned(
              top: 60,
              right: 80,
              child: _buildCloud(),
            ),
            // Center the main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title: FOOD HABIT GAME with scale effect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildTitleText(titleFontSize),
                  ),
                  // Spacing set to 35
                  SizedBox(height: spacing),
                  // "Press ENTER to start" text, now tappable
                  GestureDetector(
                    onTap: () {
                      final myGame = BattleGame();
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
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Press ',
                            style: GoogleFonts.pressStart2p(
                              fontSize: startTextFontSize,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'ENTER',
                            style: GoogleFonts.pressStart2p(
                              fontSize: startTextFontSize,
                              color: const Color(0xFFFFE082), // Pastel yellow
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: ' to start',
                            style: GoogleFonts.pressStart2p(
                              fontSize: startTextFontSize,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the "FOOD HABIT GAME" title with colorful letters and scale effect
  List<Widget> _buildTitleText(double fontSize) {
    const String title = 'FOOD HABIT GAME';
    const List<Color> colors = [
      Colors.red, // F
      Colors.green, // O
      Colors.yellow, // O
      Colors.blue, // D
      Colors.white, //  
      Colors.red, // H
      Colors.green, // A
      Colors.yellow, // B
      Colors.blue, // I
      Colors.red, // T
      Colors.white, //  
      Colors.green, // G
      Colors.yellow, // A
      Colors.blue, // M
      Colors.red, // E
    ];

    List<Widget> textWidgets = [];
    for (int i = 0; i < title.length; i++) {
      textWidgets.add(
        AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Transform.scale(
              scale: _animations[i].value, // 스케일 값에 따라 크기 변경
              child: Text(
                title[i],
                style: GoogleFonts.pressStart2p(
                  fontSize: fontSize,
                  color: colors[i],
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return textWidgets;
  }

  // Build a pipe widget (simplified as a rectangle for now)
  Widget _buildPipe() {
    return Container(
      width: 40,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF00C000), // Green pipe color
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
    );
  }

  // Build a cloud widget (simplified as an oval)
  Widget _buildCloud() {
    return Container(
      width: 60,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}