// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/service/ai_manager.dart';
import 'package:flutter_app/utils/sprite_manager.dart';
import 'package:flutter_app/screens/main_menu.dart';
import 'package:flutter_app/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final spriteManager = SpriteManager();
final AiManager aiManager = AiManager();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Firebase 초기화 시작');
  await Firebase.initializeApp();
  print('Firebase 초기화 완료');
  await spriteManager.preloadAll();
  await spriteManager.preloadHeroImages();
  print('Hero images preloaded');
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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
      routes: {
        '/main_menu': (context) => const MainMenu(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _shouldShowLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    // 세션 플래그 확인: 'forceLogin'이 true면 로그인 화면 표시
    return prefs.getBool('forceLogin') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowLoginScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true || FirebaseAuth.instance.currentUser == null) {
            return const LoginScreen();
          } else {
            return const MainMenu();
          }
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}