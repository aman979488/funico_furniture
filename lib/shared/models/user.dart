class UserProfile {
  final String uid;
  final String name;
  final String nickname;
  final String email;
  final String dateOfBirth;
  final String phoneNumber;
  final String gender;
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.name,
    this.nickname = '',
    this.email = '',
    this.dateOfBirth = '',
    this.phoneNumber = '',
    this.gender = '',
    this.photoUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, {String uid = ''}) {
    return UserProfile(
      uid: (map['uid'] as String?) ?? uid,
      name: (map['name'] as String?) ?? (map['displayName'] as String?) ?? '',
      nickname: (map['nickname'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      dateOfBirth: (map['dateOfBirth'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? '',
      photoUrl: (map['photoUrl'] as String?) ?? (map['photoURL'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'nickname': nickname,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'photoUrl': photoUrl,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? nickname,
    String? email,
    String? dateOfBirth,
    String? phoneNumber,
    String? gender,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      photoUrl: clearPhotoUrl ? null : photoUrl ?? this.photoUrl,
    );
  }
}
