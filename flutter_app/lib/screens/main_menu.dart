import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 추가
import 'package:flutter_animate/flutter_animate.dart'; // 애니메이션 패키지 추가
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
  final double titleFontSize = 50; // 기본 폰트 크기
  final double largeFontSize = 50 * 1.2; // "냠", "쩝", "팡"의 폰트 크기 (1.2배)
  final double buttonFontSize = 24; // 게임 시작과 환경 설정의 폰트 크기
  final double spacing = 35; // 냠냠쩝쩝팡팡과 버튼 사이의 간격
  final double letterSpacing = 10; // 글자 사이 간격

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
      return Tween<double>(begin: 0.9, end: 1.1).animate(
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
        // 배경 이미지를 설정
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/screen/bg_start.png'), // bg_start.png 경로
            fit: BoxFit.cover, // 이미지가 화면을 꽉 채우도록 설정
          ),
        ),
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
                    children: _buildTitleText(),
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), // 패딩 증가
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFA1CC), Color(0xFFFFC1CC)], // 그라데이션 추가
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
                            Positioned(
                              top: -5,
                              right: -5,
                              child: _buildSmallHeart(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30), // 버튼 간 간격 증가
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), // 패딩 증가
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE6E6FA), Color(0xFFB3E5FC)], // 그라데이션 추가
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
                            Positioned(
                              top: -5,
                              right: -5,
                              child: _buildSmallStar(),
                            ),
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

  // Build the "냠냠쩝쩝팡팡" title with colorful letters and scale effect
  List<Widget> _buildTitleText() {
    const String title = '냠냠쩝쩝팡팡';
    const List<Color> colors = [
      Color(0xFFFFA1CC), // 냠 (파스텔 핑크)
      Color(0xFFE6E6FA), // 냠 (파스텔 퍼플)
      Color(0xFFFFC1CC), // 쩝 (연한 핑크)
      Color(0xFFE6E6FA), // 쩝 (파스텔 퍼플)
      Color(0xFFFFA1CC), // 팡 (파스텔 핑크)
      Color(0xFFE6E6FA), // 팡 (파스텔 퍼플)
    ];

    List<Widget> textWidgets = [];
    for (int i = 0; i < title.length; i++) {
      // "냠", "쩝", "팡" (인덱스 0, 2, 4)의 크기를 더 크게 설정
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
                      blurRadius: 4, // 그림자 더 강하게
                    ),
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(-1, -1),
                      blurRadius: 2, // 외곽선 효과 추가
                    ),
                  ],
                ),
              ),
            );
          },
        ).animate().fadeIn(duration: 1.seconds, delay: (i * 0.2).seconds).shimmer(),
      );

      // 마지막 글자가 아니면 간격 추가
      if (i < title.length - 1) {
        textWidgets.add(SizedBox(width: letterSpacing));
      }
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
    ).animate().fadeIn().shimmer(duration: 2.seconds).moveY(
          begin: -5,
          end: 5,
          duration: 1.5.seconds,
          curve: Curves.easeInOut,
          delay: 0.5.seconds,
        );
  }

  // 별 장식 추가
  Widget _buildStar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFFFC1CC), // 연한 핑크 별
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

  // 작은 하트 장식 (버튼용)
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

  // 작은 별 장식 (버튼용)
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