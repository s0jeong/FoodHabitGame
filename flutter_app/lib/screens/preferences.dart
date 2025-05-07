// flutter_app/lib/preferences.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    
    if (childAge == null || dailyVegetableIntake == null) {
      childAge = 1; // 기본값 만 1세로 설정 (테스트 용이성)
      dailyVegetableIntake = calculateVegetableIntake(childAge);
      await prefs.setInt('childAge', childAge);
      await prefs.setInt('dailyVegetableIntake', dailyVegetableIntake);
    }

    int broccoliCount = calculateBroccoliCount(dailyVegetableIntake);
    return {
      'childAge': childAge,
      'dailyVegetableIntake': dailyVegetableIntake,
      'broccoliCount': broccoliCount,
    };
  }

  // 환경 설정 다이얼로그 표시
  static Future<void> showSettingsDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    int? initialAge = prefs.getInt('childAge');
    int? selectedAge = initialAge;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE6E6FA).withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            '환경 설정',
            style: GoogleFonts.jua(fontSize: 24, color: Colors.black),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '아이의 나이를 선택하세요:',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<int>(
                    value: selectedAge,
                    hint: const Text('나이를 선택하세요', style: TextStyle(color: Colors.black)),
                    dropdownColor: const Color(0xFFFFA1CC),
                    items: List.generate(9, (index) => index + 1)
                        .map((age) => DropdownMenuItem(
                              value: age,
                              child: Text('만 $age세', style: const TextStyle(color: Colors.black)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAge = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                if (selectedAge != null) {
                  int vegetableIntake = calculateVegetableIntake(selectedAge!);
                  int broccoliCount = calculateBroccoliCount(vegetableIntake);
                  await prefs.setInt('childAge', selectedAge!);
                  await prefs.setInt('dailyVegetableIntake', vegetableIntake);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '설정이 완료되었습니다! 먹어야 할 채소 수: $broccoliCount개',
                          style: const TextStyle(color: Colors.black),
                        ),
                        backgroundColor: const Color(0xFFFFA1CC),
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('확인', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
}