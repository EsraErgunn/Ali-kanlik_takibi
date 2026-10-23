import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _prefs;

  // In-memory fallback caches
  final Map<String, Map<String, dynamic>> _registeredUsers = {};
  String? _sessionUid;
  final Map<String, Map<String, dynamic>> _userProfiles = {};
  final Map<String, List<Map<String, dynamic>>> _userHabits = {};
  final Map<String, Map<String, Map<String, dynamic>>> _userLogs = {};

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadFromPrefs();
    } catch (e) {
      debugPrint('SharedPreferences init fallback: $e');
    }
  }

  void _loadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) return;

    // Load registered users
    final usersRaw = prefs.getString('bloom_local_registered_users');
    if (usersRaw != null) {
      try {
        final decoded = jsonDecode(usersRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map) {
            _registeredUsers[entry.key] = Map<String, dynamic>.from(entry.value as Map);
          }
        }
      } catch (_) {}
    }

    // Load active session
    _sessionUid = prefs.getString('bloom_local_session_uid');

    // Load profiles
    final profilesRaw = prefs.getString('bloom_local_user_profiles');
    if (profilesRaw != null) {
      try {
        final decoded = jsonDecode(profilesRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map) {
            _userProfiles[entry.key] = Map<String, dynamic>.from(entry.value as Map);
          }
        }
      } catch (_) {}
    }

    // Load habits
    final habitsRaw = prefs.getString('bloom_local_user_habits');
    if (habitsRaw != null) {
      try {
        final decoded = jsonDecode(habitsRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is List) {
            _userHabits[entry.key] = (entry.value as List)
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList();
          }
        }
      } catch (_) {}
    }

    // Load logs
    final logsRaw = prefs.getString('bloom_local_user_logs');
    if (logsRaw != null) {
      try {
        final decoded = jsonDecode(logsRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map) {
            final inner = <String, Map<String, dynamic>>{};
            for (final sub in (entry.value as Map).entries) {
              if (sub.value is Map) {
                inner[sub.key.toString()] = Map<String, dynamic>.from(sub.value as Map);
              }
            }
            _userLogs[entry.key] = inner;
          }
        }
      } catch (_) {}
    }
  }

  // --- Auth Session ---

  String? getSessionUid() => _sessionUid;

  Future<void> saveSessionUid(String? uid) async {
    _sessionUid = uid;
    final prefs = _prefs;
    if (prefs == null) return;
    if (uid == null) {
      await prefs.remove('bloom_local_session_uid');
    } else {
      await prefs.setString('bloom_local_session_uid', uid);
    }
  }

  // --- Registered Users ---

  Map<String, dynamic>? getRegisteredUser(String email) {
    return _registeredUsers[email.trim().toLowerCase()];
  }

  bool isEmailRegistered(String email) {
    return _registeredUsers.containsKey(email.trim().toLowerCase());
  }

  Future<void> saveRegisteredUser({
    required String uid,
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    _registeredUsers[key] = {
      'uid': uid,
      'email': email.trim(),
      'password': password.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(
        'bloom_local_registered_users',
        jsonEncode(_registeredUsers),
      );
    }
  }

  // --- User Profiles ---

  Map<String, dynamic>? getUserProfile(String uid) {
    return _userProfiles[uid];
  }

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    final existing = _userProfiles[uid] ?? {};
    existing.addAll(data);
    _userProfiles[uid] = existing;

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(
        'bloom_local_user_profiles',
        jsonEncode(_userProfiles),
      );
    }
  }

  Future<void> deleteUserProfile(String uid) async {
    _userProfiles.remove(uid);
    _userHabits.remove(uid);
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(
        'bloom_local_user_profiles',
        jsonEncode(_userProfiles),
      );
    }
  }

  // --- Habits ---

  List<Map<String, dynamic>> getUserHabits(String uid) {
    return List<Map<String, dynamic>>.from(_userHabits[uid] ?? []);
  }

  Future<void> saveUserHabit(String uid, Map<String, dynamic> habit) async {
    final list = _userHabits[uid] ?? [];
    final id = habit['id'];
    final idx = list.indexWhere((h) => h['id'] == id);
    if (idx >= 0) {
      list[idx] = habit;
    } else {
      list.add(habit);
    }
    _userHabits[uid] = list;

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(
        'bloom_local_user_habits',
        jsonEncode(_userHabits),
      );
    }
  }

  // --- Logs ---

  Map<String, Map<String, dynamic>> getHabitLogs(String uid, String habitId) {
    final key = '${uid}_$habitId';
    return Map<String, Map<String, dynamic>>.from(_userLogs[key] ?? {});
  }

  Future<void> saveHabitLog(
    String uid,
    String habitId,
    String dateKey,
    Map<String, dynamic> logData,
  ) async {
    final key = '${uid}_$habitId';
    final map = _userLogs[key] ?? {};
    map[dateKey] = logData;
    _userLogs[key] = map;

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(
        'bloom_local_user_logs',
        jsonEncode(_userLogs),
      );
    }
  }

  Future<void> deleteHabitLog(
    String uid,
    String habitId,
    String dateKey,
  ) async {
    final key = '${uid}_$habitId';
    final map = _userLogs[key];
    if (map != null) {
      map.remove(dateKey);
      _userLogs[key] = map;

      final prefs = _prefs;
      if (prefs != null) {
        await prefs.setString(
          'bloom_local_user_logs',
          jsonEncode(_userLogs),
        );
      }
    }
  }
}
