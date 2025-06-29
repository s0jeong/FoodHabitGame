import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/screens/preferences.dart';
import 'package:flutter_app/screens/vegetable_count_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late AnimationController _hachupingController;
  late Animation<double> _hachupingAnimation;
  late AnimationController _gameStartButtonController;
  late AnimationController _settingsButtonController;
  final double titleFontSize = 48;
  final double buttonFontSize = 24;
  final double spacing = 20;

  @override
  void initState() {
    super.initState();
    _hachupingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _hachupingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _hachupingController,
        curve: Curves.easeInOut,
      ),
    );

    _gameStartButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _settingsButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hachupingController.dispose();
    _gameStartButtonController.dispose();
    _settingsButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonWidth = screenSize.width * 0.15; // 화면 너비의 20%로 감소 (기존 25%에서 감소)
    final buttonHeight = screenSize.height * 0.07; // 화면 높이의 5%로 감소 (기존 6%에서 감소)
    final buttonSpacing = screenSize.width * 0.02; // 화면 너비의 2%로 감소 (기존 3%에서 감소)

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/screen/start_bg.png'),
            fit: BoxFit.cover,
          ),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Stack(
          children: [
            Positioned(top: 50, left: 20, child: _buildStar()),
            Positioned(top: 100, right: 30, child: _buildHeart()),
            Positioned(bottom: 50, left: 80, child: _buildStar()),
            Positioned(bottom: 30, right: 60, child: _buildHeart()),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _hachupingAnimation,
                      builder: (context, child) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const VegetableCountScreen(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  offset: Offset(2, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Transform.scale(
                              scale: _hachupingAnimation.value,
                              child: Image.asset(
                                'assets/images/screen/Heartsping.png',
                                width: screenSize.width * 0.35, // 화면 너비의 35%로 감소 (기존 40%에서 감소)
                                height: screenSize.width * 0.35, // 화면 너비의 35%로 감소 (기존 40%에서 감소)
                              ).animate().shimmer(duration: 2.seconds),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: screenSize.width * 0.05),
                      child: ClipPath(
                        clipper: SpeechBubbleClipper(),
                        child: Container(
                          width: screenSize.width * 0.75, // 화면 너비의 75%로 감소 (기존 80%에서 감소)
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.04,
                            vertical: screenSize.height * 0.02,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTitleText(),
                              SizedBox(height: screenSize.height * 0.02),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildButton(
                                    text: '게임 시작',
                                    colors: [Color(0xFFFFA1CC), Color(0xFFFFC1CC)],
                                    controller: _gameStartButtonController,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const VegetableCountScreen(),
                                        ),
                                      );
                                    },
                                    width: buttonWidth,
                                    height: buttonHeight,
                                  ),
                                  SizedBox(width: buttonSpacing),
                                  _buildButton(
                                    text: '환경 설정',
                                    colors: [Color(0xFFE6E6FA), Color(0xFFB3E5FC)],
                                    controller: _settingsButtonController,
                                    onTap: () async {
                                      print('환경 설정 버튼 클릭');
                                      await Preferences.showSettingsDialog(context);
                                      print('환경 설정 다이얼로그 닫힘');
                                    },
                                    width: buttonWidth,
                                    height: buttonHeight,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleText() {
    const List<String> titleLines = ['냠냠', '쩝쩝', '팡팡'];
    const List<Color> colors = [
      Color(0xFFFFA1CC),
      Color(0xFFE6E6FA),
      Color(0xFFFFC1CC),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        // 각 글씨의 위치와 회전 각도 설정
        final alignment = [
          Alignment(-0.3, 0), // 냠냠: 왼쪽 쯤
          Alignment(0.3, 0),  // 쩝쩝: 오른쪽 쯤
          Alignment.center,   // 팡팡: 중앙
        ][index];
        final rotationAngle = [
          -10 * (3.14159 / 180), // 냠냠: 왼쪽으로 10도 기울임
          10 * (3.14159 / 180),  // 쩝쩝: 오른쪽으로 10도 기울임
          0.0,                   // 팡팡: 기울임 없음
        ][index];

        return Align(
          alignment: alignment,
          child: Transform.rotate(
            angle: rotationAngle,
            child: Text(
              titleLines[index],
              style: GoogleFonts.jua(
                fontSize: 80,
                color: colors[index],
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    offset: Offset(5, 5),
                    blurRadius: 10,
                  ),
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 1.seconds, delay: (index * 0.2).seconds).shimmer(),
          ),
        );
      }),
    );
  }

  Widget _buildButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onTap,
    required AnimationController controller,
    required double width,
    required double height,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        controller.forward();
      },
      onTapUp: (_) {
        controller.reverse();
        onTap();
      },
      onTapCancel: () {
        controller.reverse();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Transform.scale(
                scale: controller.isAnimating ? 1.05 : 1.0,
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(height * 0.2), // 버튼 높이의 20%
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(2, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      text,
                      style: GoogleFonts.jua(
                        fontSize: height * 0.4, // 버튼 높이의 40%
                        color: Colors.black,
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
                ),
              );
            },
          ),
          Positioned(
            top: -height * 0.1,
            right: -height * 0.1,
            child: Transform.scale(
              scale: height * 0.001, // 버튼 높이에 비례하여 하트 크기 조정
              child: _buildSmallHeart(),
            ),
          ),
        ],
      ),
    );
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
}

class SpeechBubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final cornerRadius = 20.0;
    final tailHeight = 20.0;
    final tailWidth = 40.0; // 꼬리 너비 증가

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tailWidth, 0, size.width - tailWidth, size.height),
        Radius.circular(cornerRadius),
      ),
    );

    final tailStartY = size.height / 2 - tailHeight / 2;
    path.moveTo(tailWidth, tailStartY);
    path.lineTo(0, size.height / 2);
    path.lineTo(tailWidth, tailStartY + tailHeight);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}