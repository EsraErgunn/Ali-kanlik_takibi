import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_key.dart';
import '../../domain/habit_stats.dart';
import '../models/app_user.dart';
import '../services/local_storage_service.dart';
import 'auth_repository.dart';
import 'habit_repository.dart';

class UsernameTakenException implements Exception {
  final String message;
  const UsernameTakenException([this.message = 'Bu kullanıcı adı zaten alınmış.']);
  @override
  String toString() => message;
}

class UserRepository {
  UserRepository([FirebaseFirestore? db]) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore? get _safeDb {
    if (_db != null) return _db;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static final Map<String, StreamController<AppUser?>> _localControllers = {};

  StreamController<AppUser?> _controllerFor(String uid) {
    return _localControllers.putIfAbsent(
      uid,
      () => StreamController<AppUser?>.broadcast(),
    );
  }

  AppUser? _getLocalUser(String uid) {
    final data = LocalStorageService.instance.getUserProfile(uid);
    if (data == null) return null;
    return AppUser.fromMap(uid, data);
  }

  DocumentReference<Map<String, dynamic>>? _userRef(String uid) =>
      _safeDb?.collection('users').doc(uid);

  Stream<AppUser?> watchUser(String uid) {
    if (AuthRepository.isLocalUid(uid) || _safeDb == null) {
      final ctrl = _controllerFor(uid);
      final initial = _getLocalUser(uid);
      return () async* {
        yield initial;
        yield* ctrl.stream;
      }();
    }

    try {
      return _userRef(uid)!.snapshots().map((snap) {
        if (!snap.exists) return _getLocalUser(uid);
        return AppUser.fromDoc(snap);
      }).handleError((_) => _getLocalUser(uid));
    } catch (_) {
      return Stream.value(_getLocalUser(uid));
    }
  }

  Future<AppUser?> getUser(String uid) async {
    if (AuthRepository.isLocalUid(uid) || _safeDb == null) {
      return _getLocalUser(uid);
    }

    try {
      final ref = _userRef(uid);
      if (ref == null) return _getLocalUser(uid);
      final snap = await ref.get();
      if (!snap.exists) return _getLocalUser(uid);
      return AppUser.fromDoc(snap);
    } catch (_) {
      return _getLocalUser(uid);
    }
  }

  Future<void> createInitialUser({
    required String uid,
    String? characterId,
  }) async {
    final now = DateTime.now();
    final profileData = {
      'username': '',
      'usernameLower': '',
      'characterId': characterId ?? 'char_1',
      'gardenStartDate': now.toIso8601String(),
      'shields': 1,
      'lastShieldCheck': null,
      'themeMode': 'system',
      'createdAt': now.toIso8601String(),
    };

    if (AuthRepository.isLocalUid(uid)) {
      final existing = _getLocalUser(uid);
      if (existing == null) {
        await LocalStorageService.instance.saveUserProfile(uid, profileData);
        _controllerFor(uid).add(AppUser.fromMap(uid, profileData));
      }
      return;
    }

    try {
      final ref = _userRef(uid);
      if (ref != null) {
        final doc = await ref.get();
        if (!doc.exists) {
          await ref.set({
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
    } catch (e) {
      // Fallback to local profile on Firestore error
      final existing = _getLocalUser(uid);
      if (existing == null) {
        await LocalStorageService.instance.saveUserProfile(uid, profileData);
        _controllerFor(uid).add(AppUser.fromMap(uid, profileData));
      }
    }
  }

  Future<void> updateCharacter(String uid, String characterId) async {
    await LocalStorageService.instance.saveUserProfile(uid, {
      'characterId': characterId,
    });
    final updated = _getLocalUser(uid);
    _controllerFor(uid).add(updated);

    if (!AuthRepository.isLocalUid(uid)) {
      try {
        await _userRef(uid)?.set({
          'characterId': characterId,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> updateThemeMode(String uid, String themeMode) async {
    await LocalStorageService.instance.saveUserProfile(uid, {
      'themeMode': themeMode,
    });
    final updated = _getLocalUser(uid);
    _controllerFor(uid).add(updated);

    if (!AuthRepository.isLocalUid(uid)) {
      try {
        await _userRef(uid)?.set({
          'themeMode': themeMode,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> claimUsername(String uid, String username) async {
    final lower = username.trim().toLowerCase();

    await LocalStorageService.instance.saveUserProfile(uid, {
      'username': username.trim(),
      'usernameLower': lower,
    });
    final updated = _getLocalUser(uid);
    _controllerFor(uid).add(updated);

    final db = _safeDb;
    final userRef = _userRef(uid);
    if (!AuthRepository.isLocalUid(uid) && db != null && userRef != null) {
      try {
        await db.runTransaction((tx) async {
          final nameRef = db.doc('usernames/$lower');

          final snap = await tx.get(nameRef);
          if (snap.exists && snap.data()?['uid'] != uid) {
            throw const UsernameTakenException();
          }

          final userSnap = await tx.get(userRef);
          final old = userSnap.data()?['usernameLower'] as String?;
          if (old != null && old.isNotEmpty && old != lower) {
            tx.delete(db.doc('usernames/$old'));
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
      } catch (e) {
        if (e is UsernameTakenException) rethrow;
      }
    }
  }

  Future<void> deleteUserAccount(String uid) async {
    await LocalStorageService.instance.deleteUserProfile(uid);
    _controllerFor(uid).add(null);

    final db = _safeDb;
    final userRef = _userRef(uid);
    if (!AuthRepository.isLocalUid(uid) && db != null && userRef != null) {
      try {
        final userSnap = await userRef.get();
        final lower = userSnap.data()?['usernameLower'] as String?;
        if (lower != null && lower.isNotEmpty) {
          await db.doc('usernames/$lower').delete();
        }
        await userRef.delete();
      } catch (_) {}
    }
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
      await _saveShieldCheck(uid, todayKey, user.shields);
      return 0;
    }

    final habits = await habitRepo.fetchActiveHabits(uid);
    if (habits.isEmpty) {
      await _saveShieldCheck(uid, todayKey, user.shields);
      return 0;
    }

    final logsByHabit = <String, LogMap>{};
    for (final h in habits) {
      final logs = await habitRepo.fetchRecentLogs(uid, h.id, 10);
      logsByHabit[h.id] = logs;
    }

    final toFreeze = habitsToFreeze(logsByHabit, today, user.shields);
    if (toFreeze.isEmpty) {
      await _saveShieldCheck(uid, todayKey, user.shields);
      return 0;
    }

    final yesterday = DateKey.addDays(today, -1);
    final yesterdayKey = DateKey.of(yesterday);

    for (final habitId in toFreeze) {
      await habitRepo.setLogStatus(uid, habitId, yesterdayKey, 'frozen');
    }

    final remainingShields = (user.shields - toFreeze.length).clamp(0, 999);
    await _saveShieldCheck(uid, todayKey, remainingShields);

    return toFreeze.length;
  }

  Future<void> _saveShieldCheck(String uid, String todayKey, int shields) async {
    await LocalStorageService.instance.saveUserProfile(uid, {
      'shields': shields,
      'lastShieldCheck': todayKey,
    });
    final updated = _getLocalUser(uid);
    _controllerFor(uid).add(updated);

    if (!AuthRepository.isLocalUid(uid)) {
      try {
        await _userRef(uid)?.set({
          'shields': shields,
          'lastShieldCheck': todayKey,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }
}
