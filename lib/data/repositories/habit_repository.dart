import 'dart:async';
import '../../core/utils/date_key.dart';
import '../../domain/habit_stats.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/hive_service.dart';

class HabitRepository {
  HabitRepository();

  // --- Internal Hive Helpers ---

  List<Habit> _getHabitsList({required bool isDeleted}) {
    final box = HiveService.instance.habitsBox;
    final list = <Habit>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final habit = Habit.fromMap(key.toString(), Map<String, dynamic>.from(raw));
        if (habit.isDeleted == isDeleted) {
          list.add(habit);
        }
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  LogMap _getDoneDates(String habitId) {
    final box = HiveService.instance.logsBox;
    final prefix = '$habitId|';
    final result = <String, String>{};
    for (final key in box.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith(prefix)) {
        final dateKey = keyStr.substring(prefix.length);
        final raw = box.get(key);
        if (raw is Map) {
          result[dateKey] = (raw['status'] as String? ?? 'done');
        }
      }
    }
    return result;
  }

  HabitLog? _getLog(String habitId, String dateKey) {
    final box = HiveService.instance.logsBox;
    final key = '$habitId|$dateKey';
    final raw = box.get(key);
    if (raw == null || raw is! Map) return null;
    return HabitLog.fromMap(Map<String, dynamic>.from(raw), defaultDate: dateKey);
  }

  // --- Streams & Queries ---

  Stream<List<Habit>> watchHabits([String? uid]) async* {
    yield _getHabitsList(isDeleted: false);
    yield* HiveService.instance.habitsBox.watch().map((_) => _getHabitsList(isDeleted: false));
  }

  Stream<List<Habit>> watchArchivedHabits([String? uid]) async* {
    yield _getHabitsList(isDeleted: true);
    yield* HiveService.instance.habitsBox.watch().map((_) => _getHabitsList(isDeleted: true));
  }

  Future<Habit?> getHabit(String uid, String habitId) async {
    final raw = HiveService.instance.habitsBox.get(habitId);
    if (raw == null || raw is! Map) return null;
    return Habit.fromMap(habitId, Map<String, dynamic>.from(raw));
  }

  Future<List<Habit>> fetchActiveHabits(String uid) async {
    return _getHabitsList(isDeleted: false);
  }

  Future<String> addHabit(String uid, Habit habit) async {
    final habitId = habit.id.isNotEmpty
        ? habit.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final toSave = habit.copyWith(id: habitId);
    final map = toSave.toMap();
    map['id'] = habitId;
    await HiveService.instance.habitsBox.put(habitId, map);
    return habitId;
  }

  Future<void> updateHabit(String uid, Habit habit) async {
    final map = habit.toMap();
    map['id'] = habit.id;
    await HiveService.instance.habitsBox.put(habit.id, map);
  }

  Future<void> markToday(
    String uid,
    String habitId, {
    String status = 'done',
    int? count,
    Map<String, dynamic>? support,
  }) async {
    final today = DateKey.today();
    final logKey = '$habitId|$today';
    final logData = {
      'date': today,
      'status': status,
      'count': count,
      'at': DateTime.now().toIso8601String(),
      'support':? support,
    };
    await HiveService.instance.logsBox.put(logKey, logData);
  }

  Future<void> unmarkToday(String uid, String habitId) async {
    final today = DateKey.today();
    await HiveService.instance.logsBox.delete('$habitId|$today');
  }

  Future<void> setLogStatus(
    String uid,
    String habitId,
    String dateKey,
    String status,
  ) async {
    final logKey = '$habitId|$dateKey';
    final existing = _getLog(habitId, dateKey);
    final logData = {
      'date': dateKey,
      'status': status,
      'count': existing?.count,
      'at': DateTime.now().toIso8601String(),
      'support':? existing?.support,
    };
    await HiveService.instance.logsBox.put(logKey, logData);
  }

  Future<void> saveRelapseSupport(
    String uid,
    String habitId,
    String dateKey,
    Map<String, dynamic> supportData,
  ) async {
    final logKey = '$habitId|$dateKey';
    final existing = _getLog(habitId, dateKey);
    final logData = {
      'date': dateKey,
      'status': existing?.status ?? 'relapse',
      'count': existing?.count,
      'at': existing?.at.toIso8601String() ?? DateTime.now().toIso8601String(),
      'support': supportData,
    };
    await HiveService.instance.logsBox.put(logKey, logData);
  }

  Stream<LogMap> watchDoneDates(String uid, String habitId) async* {
    yield _getDoneDates(habitId);
    yield* HiveService.instance.logsBox.watch().where((event) {
      final key = event.key?.toString() ?? '';
      return key.startsWith('$habitId|');
    }).map((_) => _getDoneDates(habitId));
  }

  Stream<HabitLog?> watchTodayLog(String uid, String habitId) async* {
    final today = DateKey.today();
    final logKey = '$habitId|$today';
    yield _getLog(habitId, today);
    yield* HiveService.instance.logsBox.watch(key: logKey).map((_) => _getLog(habitId, today));
  }

  Future<LogMap> fetchRecentLogs(
    String uid,
    String habitId,
    int count,
  ) async {
    final all = _getDoneDates(habitId);
    final sortedKeys = all.keys.toList()..sort((a, b) => b.compareTo(a));
    final takeKeys = sortedKeys.take(count);
    return {for (final k in takeKeys) k: all[k]!};
  }

  Future<LogMap> fetchYearLogs(String uid, String habitId, int year) async {
    final prefix = '$habitId|$year-';
    final box = HiveService.instance.logsBox;
    final result = <String, String>{};
    for (final key in box.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith(prefix)) {
        final dateKey = keyStr.substring('$habitId|'.length);
        final raw = box.get(key);
        if (raw is Map) {
          result[dateKey] = (raw['status'] as String? ?? 'done');
        }
      }
    }
    return result;
  }

  Stream<LogMap> watchYearLogs(String uid, String habitId, int year) async* {
    yield await fetchYearLogs(uid, habitId, year);
    final prefix = '$habitId|$year-';
    yield* HiveService.instance.logsBox.watch().where((event) {
      final keyStr = event.key?.toString() ?? '';
      return keyStr.startsWith(prefix);
    }).asyncMap((_) => fetchYearLogs(uid, habitId, year));
  }

  Future<void> softDeleteHabit(String uid, String habitId) =>
      deleteHabit(uid, habitId);

  Stream<Set<String>> watchDoneDateKeys(String uid, String habitId) {
    return watchDoneDates(uid, habitId).map((m) => m.keys.toSet());
  }

  Future<void> incrementCount(
    String uid,
    String habitId,
    int dailyTarget, {
    int delta = 1,
  }) async {
    final today = DateKey.today();
    final current = _getLog(habitId, today);
    final cur = current?.count ?? 0;
    final next = cur + delta;
    final isDone = next >= dailyTarget;

    final logData = {
      'date': today,
      'status': isDone ? 'done' : 'partial',
      'count': next,
      'at': DateTime.now().toIso8601String(),
      'support':? current?.support,
    };
    await HiveService.instance.logsBox.put('$habitId|$today', logData);
  }

  Future<void> recordRelapse(
    String uid,
    String habitId, {
    DateTime? at,
  }) async {
    final relapseAt = at ?? DateTime.now();
    final today = DateKey.of(relapseAt);
    final existing = _getLog(habitId, today);
    final logData = {
      'date': today,
      'status': 'relapse',
      'count': existing?.count,
      'at': relapseAt.toIso8601String(),
      if (existing?.support != null) 'support': existing!.support,
    };
    await HiveService.instance.logsBox.put('$habitId|$today', logData);

    final habit = await getHabit(uid, habitId);
    if (habit != null) {
      await updateHabit(uid, habit.copyWith(lastRelapseAt: relapseAt));
    }
  }

  Future<void> deleteHabit(String uid, String habitId) async {
    final existing = await getHabit(uid, habitId);
    if (existing != null) {
      final updated = existing.copyWith(isDeleted: true);
      await updateHabit(uid, updated);
    }
  }

  Future<void> restoreHabit(String uid, String habitId) async {
    final existing = await getHabit(uid, habitId);
    if (existing != null) {
      final updated = existing.copyWith(isDeleted: false);
      await updateHabit(uid, updated);
    }
  }

  Future<void> permanentlyDeleteHabit(String uid, String habitId) async {
    await HiveService.instance.habitsBox.delete(habitId);

    // Delete all logs for this habit
    final prefix = '$habitId|';
    final box = HiveService.instance.logsBox;
    final keysToDelete = box.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    for (final k in keysToDelete) {
      await box.delete(k);
    }
  }

  Future<void> deleteLog(String uid, String habitId, String dateKey) async {
    await HiveService.instance.logsBox.delete('$habitId|$dateKey');
  }
}
