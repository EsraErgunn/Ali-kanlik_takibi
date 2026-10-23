import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.username,
    required this.usernameLower,
    this.characterId = 'char_1',
    required this.gardenStartDate,
    this.shields = 1,
    this.lastShieldCheck,
    this.themeMode = 'system',
    required this.createdAt,
  });

  final String uid;
  final String username;
  final String usernameLower;
  final String? characterId;
  final DateTime gardenStartDate;
  final int shields;
  final String? lastShieldCheck;
  final String themeMode;
  final DateTime createdAt;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.id, doc.data() ?? {});
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AppUser(
      uid: uid,
      username: data['username'] as String? ?? '',
      usernameLower: data['usernameLower'] as String? ?? '',
      characterId: data['characterId'] as String? ?? 'char_1',
      gardenStartDate: parseDate(data['gardenStartDate']),
      shields: (data['shields'] as num?)?.toInt() ?? 1,
      lastShieldCheck: data['lastShieldCheck'] as String?,
      themeMode: data['themeMode'] as String? ?? 'system',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'usernameLower': usernameLower,
      'characterId': characterId,
      'gardenStartDate': Timestamp.fromDate(gardenStartDate),
      'shields': shields,
      'lastShieldCheck': lastShieldCheck,
      'themeMode': themeMode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? username,
    String? usernameLower,
    String? characterId,
    DateTime? gardenStartDate,
    int? shields,
    String? lastShieldCheck,
    String? themeMode,
  }) {
    return AppUser(
      uid: uid,
      username: username ?? this.username,
      usernameLower: usernameLower ?? this.usernameLower,
      characterId: characterId ?? this.characterId,
      gardenStartDate: gardenStartDate ?? this.gardenStartDate,
      shields: shields ?? this.shields,
      lastShieldCheck: lastShieldCheck ?? this.lastShieldCheck,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt,
    );
  }
}
