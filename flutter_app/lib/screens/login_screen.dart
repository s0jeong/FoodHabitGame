// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<String?> _authUser(LoginData data) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('forceLogin', false); // 로그인 성공 시 forceLogin 비활성화
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: data.name!,
        password: data.password!,
      );
      final user = userCredential.user!;
      final profile = UserProfile(uid: user.uid, email: data.name!, broccoliCount: 0);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profile.toMap());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('forceLogin', false); // 회원가입 성공 시 forceLogin 비활성화
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _recoverPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFC1CC), Color(0xFFE6E6FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FlutterLogin(
          title: '하츄핑과 함께!',
          logo: 'assets/images/screen/Heartsping.png',
          onLogin: _authUser,
          onSignup: _signupUser,
          onRecoverPassword: _recoverPassword,
          onSubmitAnimationCompleted: () {
            Navigator.of(context).pushReplacementNamed('/main_menu');
          },
          theme: LoginTheme(
            primaryColor: Color(0xFFFFA1CC),
            accentColor: Color(0xFFE6E6FA),
            titleStyle: GoogleFonts.jua(
              fontSize: 40,
              color: Color(0xFFFF4081),
              shadows: [
                Shadow(color: Colors.white, offset: Offset(3, 3), blurRadius: 6),
              ],
            ),
            buttonTheme: LoginButtonTheme(
              backgroundColor: Color(0xFFFF80AB),
            ),
          ),
          messages: LoginMessages(
            userHint: '이메일을 입력해요!',
            passwordHint: '비밀번호를 입력해요!',
            loginButton: '로그인',
            signupButton: '회원가입',
            recoverPasswordButton: '비밀번호 찾기',
            recoverPasswordIntro: '비밀번호를 잊으셨나요?',
            recoverPasswordDescription: '이메일을 입력하면 비밀번호 재설정 링크를 보내드릴게요!',
            recoverPasswordSuccess: '비밀번호 재설정 이메일을 보냈어요!',
          ),
        ).animate().fadeIn(duration: 1.seconds).shake(duration: 2.seconds),
      ),
    );
  }
}