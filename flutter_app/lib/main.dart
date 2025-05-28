// flutter_app/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/service/ai_manager.dart';
import 'package:flutter_app/utils/sprite_manager.dart';
import 'package:flutter_app/screens/main_menu.dart';
import 'package:flutter_app/screens/login_screen.dart';

final spriteManager = SpriteManager();
final AiManager aiManager = AiManager();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Firebase 초기화 시작');
  await Firebase.initializeApp();
  print('Firebase 초기화 완료');
  await spriteManager.preloadAll();
  await spriteManager.preloadHeroImages(); // 영웅 이미지 캐싱
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          print('Auth state: ${snapshot.data?.uid}');
          return snapshot.data != null ? const MainMenu() : const LoginScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}