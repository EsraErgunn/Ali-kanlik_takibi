import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_key.dart';
import '../../domain/habit_stats.dart';
import '../models/app_user.dart';
import 'habit_repository.dart';

class UsernameTakenException implements Exception {
  final String message;
  const UsernameTakenException([this.message = 'Bu kullanıcı adı zaten alınmış.']);
  @override
  String toString() => message;
}

class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  Stream<AppUser?> watchUser(String uid) {
    return _userRef(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromDoc(snap);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final snap = await _userRef(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromDoc(snap);
  }

  Future<void> createInitialUser({
    required String uid,
    String? characterId,
  }) async {
    final doc = await _userRef(uid).get();
    if (!doc.exists) {
      final now = DateTime.now();
      await _userRef(uid).set({
        'username': '',
        'usernameLower': '',
        'characterId': characterId ?? 'char_1',
        'gardenStartDate': Timestamp.fromDate(now),
        'shields': 1,
        'lastShieldCheck': null,
        'themeMode': 'system',
        'createdAt': Timestamp.fromDate(now),
      });
    }
  }

  Future<void> updateCharacter(String uid, String characterId) async {
    await _userRef(uid).set({
      'characterId': characterId,
    }, SetOptions(merge: true));
  }

  Future<void> updateThemeMode(String uid, String themeMode) async {
    await _userRef(uid).set({
      'themeMode': themeMode,
    }, SetOptions(merge: true));
  }


  Future<void> claimUsername(String uid, String username) async {
    final lower = username.trim().toLowerCase();
    await _db.runTransaction((tx) async {
      final nameRef = _db.doc('usernames/$lower');
      final userRef = _userRef(uid);

      final snap = await tx.get(nameRef);
      if (snap.exists && snap.data()?['uid'] != uid) {
        throw const UsernameTakenException();
      }

      final userSnap = await tx.get(userRef);
      final old = userSnap.data()?['usernameLower'] as String?;
      if (old != null && old.isNotEmpty && old != lower) {
        tx.delete(_db.doc('usernames/$old'));
      }

      tx.set(nameRef, {'uid': uid});
      tx.set(
        userRef,
        {
          'username': username.trim(),
          'usernameLower': lower,
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> deleteUserAccount(String uid) async {
    final userSnap = await _userRef(uid).get();
    final lower = userSnap.data()?['usernameLower'] as String?;
    if (lower != null && lower.isNotEmpty) {
      await _db.doc('usernames/$lower').delete();
    }
    await _userRef(uid).delete();
  }

  Future<int> checkAndApplyShields({
    required String uid,
    required DateTime today,
    required HabitRepository habitRepo,
  }) async {
    final user = await getUser(uid);
    if (user == null) return 0;

    final todayKey = DateKey.of(today);
    if (user.lastShieldCheck == todayKey) {
      return 0; // Already checked today
    }

    if (user.shields <= 0) {
      await _userRef(uid).set({'lastShieldCheck': todayKey}, SetOptions(merge: true));
      return 0;
    }

    final habits = await habitRepo.fetchActiveHabits(uid);
    if (habits.isEmpty) {
      await _userRef(uid).set({'lastShieldCheck': todayKey}, SetOptions(merge: true));
      return 0;
    }

    final logsByHabit = <String, LogMap>{};
    for (final h in habits) {
      final logs = await habitRepo.fetchRecentLogs(uid, h.id, 10);
      logsByHabit[h.id] = logs;
    }

    final toFreeze = habitsToFreeze(logsByHabit, today, user.shields);
    if (toFreeze.isEmpty) {
      await _userRef(uid).set({'lastShieldCheck': todayKey}, SetOptions(merge: true));
      return 0;
    }

    final yesterday = DateKey.addDays(today, -1);
    final yesterdayKey = DateKey.of(yesterday);

    for (final habitId in toFreeze) {
      await habitRepo.setLogStatus(uid, habitId, yesterdayKey, 'frozen');
    }

    final remainingShields = (user.shields - toFreeze.length).clamp(0, 999);
    await _userRef(uid).set({
      'shields': remainingShields,
      'lastShieldCheck': todayKey,
    }, SetOptions(merge: true));

    return toFreeze.length;
  }
}

