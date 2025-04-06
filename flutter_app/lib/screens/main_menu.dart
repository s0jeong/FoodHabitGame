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
  final double titleFontSize = 48; // 냠냠쩝쩝팡팡의 폰트 크기
  final double buttonFontSize = 24; // 게임 시작과 환경 설정의 폰트 크기
  final double spacing = 35; // 냠냠쩝쩝팡팡과 버튼 사이의 간격

  @override
  void initState() {
    super.initState();
    const String title = '냠냠쩝쩝팡팡';
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
        // 파스텔 핑크 배경 설정
        color: const Color(0xFFFFD1DC),
        child: Stack(
          children: [
            // 장식 요소: 하트와 별 추가
            Positioned(
              top: 50,
              left: 20,
              child: _buildHeart(),
            ),
            Positioned(
              top: 100,
              right: 30,
              child: _buildStar(),
            ),
            Positioned(
              top: 30,
              left: 100,
              child: _buildHeart(),
            ),
            Positioned(
              top: 60,
              right: 80,
              child: _buildStar(),
            ),
            // Center the main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title: 냠냠쩝쩝팡팡 with scale effect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildTitleText(titleFontSize),
                  ),
                  // Spacing set to 35
                  SizedBox(height: spacing),
                  // "게임 시작"과 "환경 설정" 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 게임 시작 버튼
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA1CC), // 파스텔 핑크 버튼
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
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20), // 버튼 간 간격
                      // 환경 설정 버튼
                      GestureDetector(
                        onTap: () {
                          // 환경 설정 화면으로 이동 (미구현 상태로 가정)
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                '환경 설정',
                                style: GoogleFonts.jua(fontSize: 24),
                              ),
                              content: const Text('환경 설정 화면은 준비 중입니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('닫기'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6E6FA), // 파스텔 퍼플 버튼
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
                            ),
                          ),
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

  // Build the "냠냠쩝쩝팡팡" title with colorful letters and scale effect
  List<Widget> _buildTitleText(double fontSize) {
    const String title = '냠냠쩝쩝팡팡';
    const List<Color> colors = [
      Color(0xFFFFA1CC), // 냠 (파스텔 핑크)
      Color(0xFFE6E6FA), // 냠 (파스텔 퍼플)
      Color(0xFFFFD700), // 쩝 (골드)
      Color(0xFFFFA1CC), // 쩝 (파스텔 핑크)
      Color(0xFFE6E6FA), // 팡 (파스텔 퍼플)
      Color(0xFFFFD700), // 팡 (골드)
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
                style: GoogleFonts.jua(
                  fontSize: fontSize,
                  color: colors[i],
                  shadows: const [
                    Shadow(
                      color: Colors.white, // 부드러운 흰색 그림자
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

  // 하트 장식 추가
  Widget _buildHeart() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFFFA1CC), // 파스텔 핑크 하트
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
    );
  }

  // 별 장식 추가
  Widget _buildStar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD700), // 골드 별
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
    );
  }
}