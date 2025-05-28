// user_profile.dart
class UserProfile {
  final String uid;
  final String email;
  int broccoliCount;
  int? childAge;
  int? dailyVegetableIntake;

  UserProfile({
    required this.uid,
    required this.email,
    required this.broccoliCount,
    this.childAge,
    this.dailyVegetableIntake,
  });

  // Firestore 데이터를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'broccoliCount': broccoliCount,
      'childAge': childAge,
      'dailyVegetableIntake': dailyVegetableIntake,
    };
  }

  // Firestore에서 가져온 데이터를 UserProfile 객체로 변환
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      broccoliCount: map['broccoliCount'] ?? 0,
      childAge: map['childAge'],
      dailyVegetableIntake: map['dailyVegetableIntake'],
    );
  }
}