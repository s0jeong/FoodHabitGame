import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_app/main.dart';

class HeroSelectionOverlay extends StatelessWidget {
  final Function(int) onSelect;

  const HeroSelectionOverlay({required this.onSelect});

  Future<Uint8List> _spriteToBytes(Sprite sprite) async {
    final ui.Image image = await sprite.toImage();
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, Sprite> heroes = {
      0: spriteManager.getSpriteByHeroID(0)!,
      1: spriteManager.getSpriteByHeroID(1)!,
      2: spriteManager.getSpriteByHeroID(2)!,
      3: spriteManager.getSpriteByHeroID(3)!,
    };

    return Container(
      // 티니핑스러운 그라데이션 배경
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE6F0), Color(0xFFD4E4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // 반짝이는 장식 요소 (별과 하트)
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
                final sprite = entry.value;
                return FutureBuilder<Uint8List>(
                  future: _spriteToBytes(sprite),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                      return GestureDetector(
                        onTap: () => onSelect(heroId),
                        child: _buildTeeniepingCard(snapshot.data!, heroId),
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 티니핑 카드 위젯 (애니메이션 포함)
  Widget _buildTeeniepingCard(Uint8List imageData, int heroId) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: 100 * 1.5,
        height: 168 * 1.5,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 둥근 모서리
          ),
          color: _getPastelColor(heroId), // 각 티니핑마다 다른 파스텔 색상
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.memory(imageData, scale: 1),
                const SizedBox(height: 10),
                Text(
                  _getTeeniepingName(heroId), // 티니핑 이름 추가
                  style: const TextStyle(
                    fontFamily: 'Jua', // GoogleFonts.jua 대신 직접 지정 (필요 시 패키지 추가)
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

  // 티니핑 이름 매핑 (예시)
  String _getTeeniepingName(int heroId) {
    const names = {
      0: '하츄핑', // 사랑의 티니핑
      1: '차차핑', // 용기의 티니핑
      2: '라라핑', // 희망의 티니핑
      3: '해핑',   // 행복의 티니핑
    };
    return names[heroId] ?? '티니핑';
  }

  // 파스텔 색상 매핑
  Color _getPastelColor(int heroId) {
    const colors = {
      0: Color(0xFFFFA1CC), // 하츄핑: 핑크
      1: Color(0xFF98FB98), // 차차핑: 민트
      2: Color(0xFFE6E6FA), // 라라핑: 라벤더
      3: Color(0xFFFFFACD), // 해핑: 레몬
    };
    return colors[heroId] ?? Colors.grey[200]!;
  }

  // 반짝이는 장식 요소
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