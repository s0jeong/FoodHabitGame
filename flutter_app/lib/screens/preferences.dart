import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class Preferences {
  // 나이에 따른 하루 야채 섭취량 계산 (g 단위)
  static int calculateVegetableIntake(int age) {
    if (age == 1) return 36;
    if (age == 2) return 100;
    if (age <= 5) return 150;
    if (age <= 9) return 200;
    return 250;
  }

  // 하루 야채 섭취량을 브로콜리 개수로 변환 (한 입 크기: 18g)
  static int calculateBroccoliCount(int vegetableIntake) {
    const double broccoliPieceWeight = 18.0;
    return (vegetableIntake / broccoliPieceWeight).ceil();
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
      childAge = 1;
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
    print('환경 설정 다이얼로그 호출');
    final prefs = await SharedPreferences.getInstance();
    int initialAge = prefs.getInt('childAge') ?? 1;
    int? selectedAge = initialAge;

    await showDialog(
      context: context,
      barrierDismissible: false,
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print('채소 기록 보기 버튼 클릭');
                      Navigator.pop(dialogContext);
                      _showCalendarDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF80AB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      '채소 기록 보기',
                      style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('환경 설정 취소');
                Navigator.pop(dialogContext);
              },
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
                  print('사용자 미로그인, 로그인 화면으로 이동');
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
                  print('설정 저장 오류: $e');
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

  // 달력 다이얼로그 표시
  static Future<void> _showCalendarDialog(BuildContext context) async {
    print('달력 다이얼로그 호출, UID: ${FirebaseAuth.instance.currentUser?.uid}');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('사용자 미로그인, 로그인 화면으로 이동');
      await Navigator.of(context).pushNamed('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '하츄핑이 로그인해야 기록을 볼 수 있어요!',
            style: GoogleFonts.jua(fontSize: 16),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime selectedDay = DateTime.now();
    DateTime focusedDay = DateTime.now();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        print('달력 다이얼로그 빌더 실행');
        return AlertDialog(
          backgroundColor: const Color(0xFFE6E6FA).withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            '채소 기록 달력',
            style: TextStyle(fontSize: 24, color: Colors.black),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              minWidth: 300,
            ),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  print('달력 UI 렌더링');
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 350,
                        child: TableCalendar(
                          firstDay: DateTime.now().subtract(Duration(days: 365)),
                          lastDay: DateTime.now().add(Duration(days: 365)),
                          focusedDay: focusedDay,
                          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                          onDaySelected: (selected, focused) async {
                            print('날짜 선택: $selected');
                            setState(() {
                              selectedDay = selected;
                              focusedDay = focused;
                            });
                            Navigator.pop(dialogContext); // 다이얼로그 닫기
                            await _showRecordsForDate(context, selected); // 기록 표시
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Color(0xFFFF80AB),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Color(0xFFFF4081),
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            titleTextStyle: TextStyle(fontSize: 18, color: Colors.black),
                            formatButtonVisible: false,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('달력 다이얼로그 닫기');
                Navigator.pop(context);
              },
              child: Text('닫기', style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  // 선택한 날짜의 기록 표시
  static Future<void> _showRecordsForDate(BuildContext context, DateTime date) async {
    print('기록 호출: $date');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('사용자 미로그인, 로그인 화면으로 이동');
      await Navigator.of(context).pushNamed('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '하츄핑이 로그인해야 기록을 볼 수 있어요!',
            style: GoogleFonts.jua(fontSize: 16),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    List<Map<String, dynamic>> records = [];

    try {
      print('Firestore 쿼리: users/${user.uid}/game_records, date=$dateStr');
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('game_records')
          .where('date', isEqualTo: dateStr)
          .get(); // orderBy 제거하여 인덱스 문제 테스트

      records = snapshot.docs.map((doc) => doc.data()).toList();
      print('로드된 문서 수: ${snapshot.docs.length}');
      print('로드된 기록: $records');

      // 디버깅: 전체 문서 조회
      final allSnapshots = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('game_records')
          .get();
      print('모든 문서: ${allSnapshots.docs.map((doc) => doc.data()).toList()}');
    } catch (e, stackTrace) {
      print('Firestore 기록 로드 오류: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '기록을 불러오지 못했어요! 다시 시도해 주세요.',
            style: GoogleFonts.jua(fontSize: 16),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE6E6FA).withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            '${dateStr}의 채소 기록',
            style: GoogleFonts.jua(fontSize: 24, color: Color(0xFFFF4081)),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 300),
            child: records.isEmpty
                ? Center(
                    child: Text(
                      '하츄핑이 이 날의 기록을 못 찾았어요!',
                      style: GoogleFonts.jua(fontSize: 16, color: Colors.black),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final playTime = record['playTime'] ?? 0;
                      final minutes = (playTime / 60).floor();
                      final seconds = playTime % 60;
                      return Card(
                        color: Color(0xFFFFC1CC).withOpacity(0.8),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/images/heros/vegetable.png',
                            width: 40,
                            height: 40,
                          ).animate().shake(duration: 1.seconds),
                          title: Text(
                            '채소: ${record['broccoliCount']}개',
                            style: GoogleFonts.jua(fontSize: 16, color: Colors.black),
                          ),
                          subtitle: Text(
                            '플레이 시간: $minutes분 $seconds초',
                            style: GoogleFonts.jua(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 0.1).seconds);
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('기록 다이얼로그 닫기');
                Navigator.pop(dialogContext);
              },
              child: Text('닫기', style: GoogleFonts.jua(fontSize: 16, color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
}