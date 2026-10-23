import 'dart:async';
import '../../core/utils/date_key.dart';
import '../../domain/habit_stats.dart';
import '../models/app_user.dart';
import '../services/hive_service.dart';
import 'habit_repository.dart';

class UserRepository {
  UserRepository();

  AppUser? _getCurrentUser([String? uid]) {
    final box = HiveService.instance.profileBox;
    final data = box.get('current');
    if (data == null) return null;
    return AppUser.fromMap(uid ?? 'current', Map<String, dynamic>.from(data as Map));
  }

  Stream<AppUser?> watchUser([String? uid]) async* {
    yield _getCurrentUser(uid);
    yield* HiveService.instance.profileBox.watch(key: 'current').map((event) {
      if (event.value == null) return null;
      return AppUser.fromMap(
        uid ?? 'current',
        Map<String, dynamic>.from(event.value as Map),
      );
    });
  }

  Future<AppUser?> getUser([String? uid]) async {
    return _getCurrentUser(uid);
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

    final existing = _getCurrentUser(uid);
    if (existing == null) {
      await HiveService.instance.profileBox.put('current', profileData);
      await HiveService.instance.settingsBox.put('has_profile', true);
    }
  }

  Future<void> updateCharacter(String uid, String characterId) async {
    final current = _getCurrentUser(uid);
    final map = current?.toMap() ?? {
      'username': '',
      'usernameLower': '',
      'characterId': characterId,
      'gardenStartDate': DateTime.now().toIso8601String(),
      'shields': 1,
      'lastShieldCheck': null,
      'themeMode': 'system',
      'createdAt': DateTime.now().toIso8601String(),
    };
    map['characterId'] = characterId;
    await HiveService.instance.profileBox.put('current', map);
    await HiveService.instance.settingsBox.put('has_profile', true);
  }

  Future<void> updateThemeMode(String uid, String themeMode) async {
    final current = _getCurrentUser(uid);
    if (current != null) {
      final map = current.toMap();
      map['themeMode'] = themeMode;
      await HiveService.instance.profileBox.put('current', map);
    }
  }

  Future<void> claimUsername(String uid, String username) async {
    final trimmed = username.trim();
    final regex = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');
    if (!regex.hasMatch(trimmed)) {
      throw 'Kullanıcı adı 3-20 karakter olmalı ve yalnızca harf, rakam, alt çizgi veya nokta içermelidir.';
    }

    final current = _getCurrentUser(uid);
    final map = current?.toMap() ?? {
      'characterId': 'char_1',
      'gardenStartDate': DateTime.now().toIso8601String(),
      'shields': 1,
      'lastShieldCheck': null,
      'themeMode': 'system',
      'createdAt': DateTime.now().toIso8601String(),
    };
    map['username'] = trimmed;
    map['usernameLower'] = trimmed.toLowerCase();
    await HiveService.instance.profileBox.put('current', map);
    await HiveService.instance.settingsBox.put('has_profile', true);
  }

  Future<void> deleteUserAccount(String uid) async {
    await HiveService.instance.clearAll();
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
    final current = _getCurrentUser(uid);
    if (current != null) {
      final map = current.toMap();
      map['shields'] = shields;
      map['lastShieldCheck'] = todayKey;
      await HiveService.instance.profileBox.put('current', map);
    }
  }
}
