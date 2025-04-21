import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/game.dart';
import 'package:flutter_app/game_ui/eat_detector_view.dart';
import 'package:flutter_app/game_ui/hero_selection_overlay.dart';
import 'package:flutter_app/game_ui/vegetable_detector_view.dart';
import 'package:flutter_app/screens/preferences.dart';
import 'package:flutter_app/screens/vegetable_count_screen.dart'; // VegetableCountScreen 임포트

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final double titleFontSize = 48;
  final double largeFontSize = 48 * 1.2;
  final double buttonFontSize = 24;
  final double spacing = 35;
  final double letterSpacing = 10;

  @override
  void initState() {
    super.initState();
    const String title = '냠냠쩝쩝팡팡';
    _controllers = List.generate(
      title.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        _controllers[i].repeat(reverse: true);
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/screen/bg_start.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: 50, left: 20, child: _buildHeart()),
            Positioned(top: 100, right: 30, child: _buildStar()),
            Positioned(top: 30, left: 100, child: _buildHeart()),
            Positioned(top: 60, right: 80, child: _buildStar()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildTitleText(),
                  ),
                  SizedBox(height: spacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // 게임 시작 버튼 클릭 시 VegetableCountScreen으로 이동
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const VegetableCountScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFA1CC), Color(0xFFFFC1CC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(2, 2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                '게임 시작',
                                style: GoogleFonts.jua(
                                  fontSize: buttonFontSize,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(1, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(top: -5, right: -5, child: _buildSmallHeart()),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: () {
                          Preferences.showSettingsDialog(context); // preferences.dart에서 다이얼로그 호출
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE6E6FA), Color(0xFFB3E5FC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(2, 2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                '환경 설정',
                                style: GoogleFonts.jua(
                                  fontSize: buttonFontSize,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(1, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(top: -5, right: -5, child: _buildSmallStar()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTitleText() {
    const String title = '냠냠쩝쩝팡팡';
    const List<Color> colors = [
      Color(0xFFFFA1CC),
      Color(0xFFE6E6FA),
      Color(0xFFFFC1CC),
      Color(0xFFE6E6FA),
      Color(0xFFFFA1CC),
      Color(0xFFE6E6FA),
    ];

    List<Widget> textWidgets = [];
    for (int i = 0; i < title.length; i++) {
      final double currentFontSize = (i == 0 || i == 2 || i == 4) ? largeFontSize : titleFontSize;

      textWidgets.add(
        AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Transform.scale(
              scale: _animations[i].value,
              child: Text(
                title[i],
                style: GoogleFonts.jua(
                  fontSize: currentFontSize,
                  color: colors[i],
                  shadows: const [
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
                ),
              ),
            );
          },
        ).animate().fadeIn(duration: 1.seconds, delay: (i * 0.2).seconds).shimmer(),
      );

      if (i < title.length - 1) {
        textWidgets.add(SizedBox(width: letterSpacing));
      }
    }
    return textWidgets;
  }

  Widget _buildHeart() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFFFA1CC),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: Offset(2, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        color: Colors.white,
        size: 24,
      ),
    ).animate().fadeIn().shimmer(duration: 2.seconds).moveY(
          begin: -5,
          end: 5,
          duration: 1.5.seconds,
          curve: Curves.easeInOut,
          delay: 0.5.seconds,
        );
  }

  Widget _buildStar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFFFC1CC),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: Offset(2, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.star,
        color: Colors.white,
        size: 24,
      ),
    ).animate().fadeIn().shimmer(duration: 2.seconds).moveY(
          begin: 5,
          end: -5,
          duration: 1.5.seconds,
          curve: Curves.easeInOut,
          delay: 0.5.seconds,
        );
  }

  Widget _buildSmallHeart() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFFFFA1CC),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.favorite,
        color: Colors.white,
        size: 12,
      ),
    ).animate().shimmer(duration: 2.seconds);
  }

  Widget _buildSmallStar() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFFE6E6FA),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.star,
        color: Colors.white,
        size: 12,
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}