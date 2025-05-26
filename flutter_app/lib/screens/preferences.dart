// flutter_app/lib/preferences.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Preferences {
  // 나이에 따른 하루 야채 섭취량 계산 (g 단위)
  static int calculateVegetableIntake(int age) {
    if (age == 1) return 36; // 만 1세: 36g (브로콜리 2개, 18g * 2)
    if (age == 2) return 100; // 만 2세: 100g
    if (age <= 5) return 150; // 만 3~5세: 150g
    if (age <= 9) return 200; // 만 6~9세: 200g
    return 250; // 만 10세 이상: 250g
  }

  // 하루 야채 섭취량을 브로콜리 개수로 변환 (한 입 크기: 18g)
  static int calculateBroccoliCount(int vegetableIntake) {
    const double broccoliPieceWeight = 18.0; // 한 입 크기 브로콜리 무게 (g)
    return (vegetableIntake / broccoliPieceWeight).ceil(); // 올림 처리
  }

  // 저장된 나이와 야채 섭취량, 브로콜리 개수 불러오기
  static Future<Map<String, int>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    int? childAge = prefs.getInt('childAge');
    int? dailyVegetableIntake = prefs.getInt('dailyVegetableIntake');
    int? broccoliCount = prefs.getInt('broccoliCount');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          childAge = doc.data()!['childAge'] ?? childAge;
          dailyVegetableIntake = doc.data()!['dailyVegetableIntake'] ?? dailyVegetableIntake;
          broccoliCount = doc.data()!['broccoliCount'] ?? broccoliCount;
        }
      } catch (e) {
        print('Firestore 로드 오류: $e');
      }
    }

    if (childAge == null || dailyVegetableIntake == null || broccoliCount == null) {
      childAge = 1; // 기본값 만 1세
      dailyVegetableIntake = calculateVegetableIntake(childAge);
      broccoliCount = calculateBroccoliCount(dailyVegetableIntake);
      await prefs.setInt('childAge', childAge);
      await prefs.setInt('dailyVegetableIntake', dailyVegetableIntake);
      await prefs.setInt('broccoliCount', broccoliCount);
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'childAge': childAge,
            'dailyVegetableIntake': dailyVegetableIntake,
            'broccoliCount': broccoliCount,
            'email': user.email,
            'uid': user.uid,
          }, SetOptions(merge: true));
        } catch (e) {
          print('Firestore 저장 오류: $e');
        }
      }
    }

    return {
      'childAge': childAge,
      'dailyVegetableIntake': dailyVegetableIntake,
      'broccoliCount': broccoliCount,
    };
  }

  // 환경 설정 다이얼로그 표시
  static Future<void> showSettingsDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    int initialAge = prefs.getInt('childAge') ?? 1; // 초기값 1세
    int? selectedAge = initialAge; // 초기 선택값 설정

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE6E6FA).withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            '하츄핑과 채소 설정',
            style: GoogleFonts.jua(fontSize: 24, color: Color(0xFFFF4081)),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '아이의 나이를 선택해요!',
                    style: GoogleFonts.jua(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<int>(
                    value: selectedAge,
                    hint: Text('나이를 선택해요', style: GoogleFonts.jua(color: Colors.black)),
                    dropdownColor: const Color(0xFFFFA1CC),
                    items: List.generate(9, (index) => index + 1)
                        .map((age) => DropdownMenuItem(
                              value: age,
                              child: Text('만 $age세', style: GoogleFonts.jua(fontSize: 16)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAge = value;
                      });
                    },
                    style: GoogleFonts.jua(color: Colors.black),
                  ).animate().fadeIn(duration: 0.5.seconds),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('취소', style: GoogleFonts.jua(fontSize: 16, color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                if (selectedAge == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '나이를 선택해 주세요!',
                        style: GoogleFonts.jua(fontSize: 16),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  Navigator.pop(dialogContext);
                  Navigator.of(context).pushReplacementNamed('/login');
                  return;
                }

                try {
                  int vegetableIntake = calculateVegetableIntake(selectedAge!);
                  int broccoliCount = calculateBroccoliCount(vegetableIntake);
                  await prefs.setInt('childAge', selectedAge!);
                  await prefs.setInt('dailyVegetableIntake', vegetableIntake);
                  await prefs.setInt('broccoliCount', broccoliCount);

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({
                    'childAge': selectedAge,
                    'dailyVegetableIntake': vegetableIntake,
                    'broccoliCount': broccoliCount,
                    'email': user.email,
                    'uid': user.uid,
                  }, SetOptions(merge: true));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '하츄핑과 함께 채소 $broccoliCount개로 설정했어요!',
                        style: GoogleFonts.jua(fontSize: 16, color: Colors.black),
                      ),
                      backgroundColor: const Color(0xFFFF80AB),
                    ),
                  );
                  Navigator.pop(dialogContext);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '설정 저장에 실패했어요: $e',
                        style: GoogleFonts.jua(fontSize: 16),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('확인', style: GoogleFonts.jua(fontSize: 16, color: Color(0xFFFF4081))),
            ),
          ],
        );
      },
    );
  }
}