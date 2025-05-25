import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core 추가
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 추가
import 'package:flutter_app/service/ai_manager.dart';
import 'package:flutter_app/utils/sprite_manager.dart';
import 'package:flutter_app/screens/main_menu.dart';
import 'package:flutter_app/screens/login_screen.dart'; // LoginScreen 추가

final spriteManager = SpriteManager();
final AiManager aiManager = AiManager();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  await spriteManager.preloadAll(); // 기존 스프라이트 로드 유지
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
    aiManager.loadModel(); // 기존 AI 모델 로드 유지
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
      home: const AuthWrapper(), // AuthWrapper로 첫 화면 설정
      routes: {
        '/main_menu': (context) => const MainMenu(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

// 인증 상태에 따라 화면을 전환하는 위젯
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          // 사용자가 로그인한 경우 MainMenu, 그렇지 않으면 LoginScreen
          return snapshot.data != null ? const MainMenu() : const LoginScreen();
        }
        // 초기화 중일 때 로딩 표시
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}