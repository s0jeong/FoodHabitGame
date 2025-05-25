import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          broccoliCount = doc.data()!['broccoliCount'] ?? 0;
        });
      }
    }
  }

  Future<void> _updateBroccoliCount(int newCount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'broccoliCount': newCount});
      setState(() {
        broccoliCount = newCount;
      });
    }
  }

  // 제목 텍스트 스타일
  static const titleTextStyle = TextStyle(
    fontSize: 40,
    color: Color(0xFFFF4081), // 선명한 핑크
    shadows: [
      Shadow(color: Colors.white, offset: Offset(3, 3), blurRadius: 6),
      Shadow(color: Colors.black54, offset: Offset(-2, -2), blurRadius: 4),
    ],
  );

  // 채소 개수 텍스트 스타일
  static const countTextStyle = TextStyle(
    fontSize: 32,
    color: Color(0xFFFF80AB), // 연한 핑크
    shadows: [
      Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 4),
      Shadow(color: Colors.black54, offset: Offset(-1, -1), blurRadius: 2),
    ],
  );

  // 안내 텍스트 스타일
  static const guideTextStyle = TextStyle(
    fontSize: 24,
    color: Colors.black,
    shadows: [
      Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 2),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFC1CC), // 하츄핑 테마 핑크
                Color(0xFFE6E6FA), // 파스텔 라벤더
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // 배경 하트/별 장식
              Positioned(top: 20, left: 30, child: _buildStar()),
              Positioned(top: 80, right: 40, child: _buildHeart()),
              Positioned(bottom: 100, left: 50, child: _buildStar()),
              Positioned(bottom: 30, right: 60, child: _buildHeart()),
              // 메인 콘텐츠
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 하츄핑 미니 이미지
                    Image.asset(
                      'assets/images/screen/Heartsping.png',
                      width: 100,
                      height: 100,
                    ).animate().shimmer(duration: 2.seconds).scale(
                          begin: Offset(0.95, 0.95),
                          end: Offset(1.05, 1.05),
                          duration: 1.5.seconds,
                          curve: Curves.easeInOut,
                        ),
                    SizedBox(height: 20),
                    // 제목
                    Text(
                      '하츄핑과 먹을 채소!',
                      style: GoogleFonts.jua(textStyle: titleTextStyle),
                    ).animate().fadeIn(duration: 1.seconds),
                    SizedBox(height: 30),
                    // 채소 개수 표시
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/heros/vegetable.png',
                            width: 80,
                            height: 80,
                          ).animate().shake(duration: 1.5.seconds),
                          SizedBox(width: 10),
                          Text(
                            'X $broccoliCount',
                            style: GoogleFonts.jua(textStyle: countTextStyle),
                          ).animate().fadeIn(duration: 0.5.seconds),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // 채소 개수 선택 드롭다운
                    DropdownButton<int>(
                      value: broccoliCount,
                      items: List.generate(6, (index) => index).map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text('$count 개', style: GoogleFonts.jua(fontSize: 24)),
                        );
                      }).toList(),
                      onChanged: (newCount) {
                        if (newCount != null) {
                          _updateBroccoliCount(newCount);
                        }
                      },
                      dropdownColor: Color(0xFFFFC1CC),
                      style: GoogleFonts.jua(color: Colors.black),
                    ).animate().fadeIn(duration: 0.5.seconds),
                    SizedBox(height: 30),
                    // 터치 안내
                    Text(
                      '채소를 눌러서 하츄핑과 게임 시작!',
                      style: GoogleFonts.jua(textStyle: guideTextStyle),
                    ).animate().fadeIn(duration: 1.seconds).shimmer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 하트 장식
  Widget _buildHeart() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(0xFFFFA1CC),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 2),
        ],
      ),
      child: Icon(
        Icons.favorite,
        color: Colors.white,
        size: 24,
      ),
    ).animate().fadeIn().shimmer(duration: 2.seconds).moveY(
          begin: -5,
          end: 5,
          duration: 1.5.seconds,
          curve: Curves.easeInOut,
        );
  }

  // 별 장식
  Widget _buildStar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(0xFFFFC1CC),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 2),
        ],
      ),
      child: Icon(
        Icons.star,
        color: Colors.white,
        size: 24,
      ),
    ).animate().fadeIn().shimmer(duration: 2.seconds).moveY(
          begin: 5,
          end: -5,
          duration: 1.5.seconds,
          curve: Curves.easeInOut,
        );
  }
}