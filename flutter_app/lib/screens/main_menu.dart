import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/game.dart';
import 'package:flutter_app/game_ui/eat_detector_view.dart';
import 'package:flutter_app/game_ui/hero_selection_overlay.dart';
import 'package:flutter_app/game_ui/vegetable_detector_view.dart';
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
  late AnimationController _gameStartButtonController; // late로 변경, null 제거
  late AnimationController _settingsButtonController; // late로 변경, null 제거
  final double titleFontSize = 40;
  final double buttonFontSize = 24;
  final double spacing = 20;

  @override
  void initState() {
    super.initState();
    // 하츄핑 캐릭터 애니메이션 컨트롤러
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

    // 버튼 컨트롤러 초기화
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
    _gameStartButtonController.dispose(); // 명시적 dispose
    _settingsButtonController.dispose(); // 명시적 dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/screen/start_bg.png'),
            fit: BoxFit.cover,
          ),
          color: Colors.black.withOpacity(0.3), // 반투명 오버레이
        ),
        child: Stack(
          children: [
            // 배경에 반짝이는 별과 하트
            Positioned(top: 50, left: 20, child: _buildStar()),
            Positioned(top: 100, right: 30, child: _buildHeart()),
            Positioned(bottom: 50, left: 80, child: _buildStar()),
            Positioned(bottom: 30, right: 60, child: _buildHeart()),
            // 메인 콘텐츠
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 왼쪽 하츄핑 캐릭터
                Expanded(
                  flex: 1,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _hachupingAnimation,
                      builder: (context, child) {
                        return Container(
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
                              width: 400,
                              height: 400,
                            ).animate().shimmer(duration: 2.seconds),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 오른쪽 제목과 버튼
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
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
                          SizedBox(height: spacing),
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
                              ),
                              SizedBox(width: 20),
                              _buildButton(
                                text: '환경 설정',
                                colors: [Color(0xFFE6E6FA), Color(0xFFB3E5FC)],
                                controller: _settingsButtonController,
                                onTap: () {
                                  Preferences.showSettingsDialog(context);
                                },
                              ),
                            ],
                          ),
                        ],
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
      Color(0xFFFFA1CC), // 핑크
      Color(0xFFE6E6FA), // 라벤더
      Color(0xFFFFC1CC), // 연한 핑크
    ];

    return Column(
      children: List.generate(3, (index) {
        return Text(
          titleLines[index],
          style: GoogleFonts.jua(
            fontSize: titleFontSize,
            color: colors[index],
            shadows: const [
              Shadow(
                color: Colors.white,
                offset: Offset(3, 3),
                blurRadius: 6,
              ),
              Shadow(
                color: Colors.black54,
                offset: Offset(-2, -2),
                blurRadius: 4,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 1.seconds, delay: (index * 0.2).seconds).shimmer();
      }),
    );
  }

  Widget _buildButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onTap,
    required AnimationController controller, // null 허용 제거
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
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
                    text,
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
              );
            },
          ),
          Positioned(top: -5, right: -5, child: _buildSmallHeart()),
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