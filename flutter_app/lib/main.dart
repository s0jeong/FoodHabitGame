import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/game/game.dart';
import 'package:flutter_app/game_ui/eat_detector_view.dart';
import 'package:flutter_app/game_ui/hero_selection_overlay.dart';
import 'package:flutter_app/game_ui/vegetable_detector_view.dart';
import 'package:flutter_app/service/ai_manager.dart';
import 'package:flutter_app/utils/sprite_manager.dart';
import 'package:flutter_app/screens/main_menu.dart';

final spriteManager = SpriteManager();
final AiManager aiManager = AiManager();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 모든 스프라이트를 사전에 로드
  await spriteManager.preloadAll();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    aiManager.loadModel();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Habit Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainMenu(), // MainMenu를 첫 화면으로 설정
    );
  }
}
