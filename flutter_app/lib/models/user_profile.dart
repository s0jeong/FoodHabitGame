class UserProfile {
  final String uid;
  final String email;
  int broccoliCount;

  UserProfile({
    required this.uid,
    required this.email,
    this.broccoliCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'broccoliCount': broccoliCount,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
        return UserProfile(
          uid: map['uid'],
          email: map['email'],
          broccoliCount: map['broccoliCount'] ?? 0,
        );
      }
  }