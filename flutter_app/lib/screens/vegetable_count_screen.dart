// flutter_app/lib/screens/vegetable_count_screen.dart
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/screens/preferences.dart';

class VegetableCountScreen extends StatefulWidget {
  const VegetableCountScreen({super.key});

  @override
  State<VegetableCountScreen> createState() => _VegetableCountScreenState();
}

class _VegetableCountScreenState extends State<VegetableCountScreen> {
  int? broccoliCount;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // SharedPreferences에서 캐시된 값 로드
      final prefs = await SharedPreferences.getInstance();
      final cachedCount = prefs.getInt('broccoliCount');
      if (cachedCount != null) {
        setState(() {
          broccoliCount = cachedCount;
        });
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in, redirecting to login');
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      print('Fetching Firestore data for user: ${user.uid}');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final newCount = doc.data()!['broccoliCount'] ?? 0;
        print('Firestore broccoliCount: $newCount');
        await prefs.setInt('broccoliCount', newCount);
        setState(() {
          broccoliCount = newCount;
          isLoading = false;
        });
      } else {
        print('No Firestore document, creating with default values');
        final prefsData = await Preferences.getPreferences();
        final defaultCount = prefsData['broccoliCount']!;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'broccoliCount': defaultCount,
          'childAge': prefsData['childAge'],
          'dailyVegetableIntake': prefsData['dailyVegetableIntake'],
          'email': user.email,
          'uid': user.uid,
        }, SetOptions(merge: true));
        await prefs.setInt('broccoliCount', defaultCount);
        setState(() {
          broccoliCount = defaultCount;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Firestore error: $e');
      setState(() {
        isLoading = false;
        errorMessage = '하츄핑이 채소를 못 찾았어요: $e';
      });
    }
  }

  // 제목 텍스트 스타일
  static const titleTextStyle = TextStyle(
    fontSize: 40,
    color: Color(0xFFFF4081),
    shadows: [
      Shadow(color: Colors.white, offset: Offset(3, 3), blurRadius: 6),
      Shadow(color: Colors.black54, offset: Offset(-2, -2), blurRadius: 4),
    ],
  );

  // 채소 개수 텍스트 스타일
  static const countTextStyle = TextStyle(
    fontSize: 32,
    color: Color(0xFFFF80AB),
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
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFC1CC), Color(0xFFE6E6FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF4081),
            ).animate().fadeIn(),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFC1CC), Color(0xFFE6E6FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '하츄핑이 당황했어요!',
                  style: GoogleFonts.jua(fontSize: 24, color: Color(0xFFFF4081)),
                ),
                SizedBox(height: 10),
                Text(
                  errorMessage!,
                  style: GoogleFonts.jua(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadPreferences,
                  child: Text('다시 찾아봐요!', style: GoogleFonts.jua(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF80AB),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: GestureDetector(
        onTap: broccoliCount == null
            ? null
            : () {
                print('Starting game with broccoliCount: $broccoliCount');
                final myGame = BattleGame(targetVegetableCount: broccoliCount!);
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
                Color(0xFFFFC1CC),
                Color(0xFFE6E6FA),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: 20, left: 30, child: _buildStar()),
              Positioned(top: 80, right: 40, child: _buildHeart()),
              Positioned(bottom: 100, left: 50, child: _buildStar()),
              Positioned(bottom: 30, right: 60, child: _buildHeart()),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    Text(
                      '하츄핑과 먹을 채소!',
                      style: GoogleFonts.jua(textStyle: titleTextStyle),
                    ).animate().fadeIn(duration: 1.seconds),
                    SizedBox(height: 30),
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
                    SizedBox(height: 30),
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

  Widget _buildHeart() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
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

  Widget _buildStar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
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