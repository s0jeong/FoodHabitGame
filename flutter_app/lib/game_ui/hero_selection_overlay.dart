import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_app/main.dart';

class HeroSelectionOverlay extends StatelessWidget {
  final Function(int) onSelect;

  HeroSelectionOverlay({required this.onSelect});

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
      color: Colors.black.withOpacity(0.8),
      child: Center(
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
                    child: SizedBox(
                      width: 100 * 1.5,
                      height: 168 * 1.5,
                      child: Card(
                        color: const Color.fromARGB(125, 255, 255, 255),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.memory(snapshot.data!,scale: 1,),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
