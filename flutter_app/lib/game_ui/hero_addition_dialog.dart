import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/game/game.dart';

class HeroAdditionDialog extends StatelessWidget {
  final BattleGame game;

  const HeroAdditionDialog({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Center(
      child: Container(
        width: screenSize.width * 0.8,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.yellow.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '새로운 영웅 추가',
              style: GoogleFonts.jua(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '골드를 사용하여 새로운 영웅을 추가하시겠습니까?\n(비용: ${game.gameWorld.heroGoldCost} 골드)',
              style: GoogleFonts.jua(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    game.overlays.remove('HeroAdditionDialog');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    '다음에',
                    style: GoogleFonts.jua(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    game.overlays.remove('HeroAdditionDialog');
                    game.gameWorld.tryAddHero();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    '영웅 추가',
                    style: GoogleFonts.jua(fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 