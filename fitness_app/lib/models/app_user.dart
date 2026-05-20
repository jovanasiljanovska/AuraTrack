import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoBase64;
  final DateTime createdAt;
  final double? weightKg;
  final double? heightCm;
  final int? age;
  final String? gender;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoBase64,
    required this.createdAt,
    this.weightKg,
    this.heightCm,
    this.age,
    this.gender,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoBase64: map['photoBase64'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      age: map['age'] as int?,
      gender: map['gender'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'photoBase64': photoBase64,
    'createdAt': Timestamp.fromDate(createdAt),
    'weightKg': weightKg,
    'heightCm': heightCm,
    'age': age,
    'gender': gender,
  };

  AppUser copyWith({
    String? displayName,
    String? photoBase64,
    double? weightKg,
    double? heightCm,
    int? age,
    String? gender,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoBase64: photoBase64 ?? this.photoBase64,
      createdAt: createdAt,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      gender: gender ?? this.gender,
    );
  }
}