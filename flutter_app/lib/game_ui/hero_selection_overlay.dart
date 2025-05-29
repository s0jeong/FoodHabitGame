// flutter_app/game_ui/hero_selection_overlay.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_app/main.dart';

class HeroSelectionOverlay extends StatelessWidget {
  final Function(int) onSelect;

  const HeroSelectionOverlay({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final Map<int, Uint8List?> heroes = {
      0: spriteManager.getHeroImageById(0), // apple
      1: spriteManager.getHeroImageById(1), // carrot
      2: spriteManager.getHeroImageById(2), // eggplant
      3: spriteManager.getHeroImageById(3), // banana
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE6F0), Color(0xFFD4E4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 30,
            child: _buildSparkle(Icons.star, Colors.yellow[200]!),
          ),
          Positioned(
            bottom: 20,
            right: 40,
            child: _buildSparkle(Icons.favorite, Colors.pink[200]!),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: heroes.entries.map((entry) {
                final heroId = entry.key;
                final imageData = entry.value;
                if (imageData == null) {
                  print('Image not loaded for hero ID: $heroId');
                  return const SizedBox(
                    width: 150,
                    height: 252,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return GestureDetector(
                  onTap: () => onSelect(heroId),
                  child: _buildTeeniepingCard(imageData, heroId),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeeniepingCard(Uint8List imageData, int heroId) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: 100 * 1.5,
        height: 168 * 1.5,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: _getPastelColor(heroId),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.memory(imageData, scale: 1),
                const SizedBox(height: 10),
                Text(
                  _getTeeniepingName(heroId),
                  style: const TextStyle(
                    fontFamily: 'Jua',
                    fontSize: 18,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTeeniepingName(int heroId) {
    const names = {
      0: '햐츄핑',
      1: '얌얌핑',
      2: '포실핑',
      3: '맛나핑',
    };
    return names[heroId] ?? '티니핑';
  }

  Color _getPastelColor(int heroId) {
    const colors = {
      0: Color(0xFFFFA1CC), // 애플핑: 핑크
      1: Color(0xFF98FB98), // 캐롯핑: 민트
      2: Color(0xFFE6E6FA), // 에그플랜트핑: 라벤더
      3: Color(0xFFFFFACD), // 바나나핑: 레몬
    };
    return colors[heroId] ?? Colors.grey[200]!;
  }

  Widget _buildSparkle(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(2, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}