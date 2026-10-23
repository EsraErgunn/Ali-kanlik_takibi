import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_key.dart';
import '../../domain/habit_stats.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/local_storage_service.dart';
import 'auth_repository.dart';

class HabitRepository {
  HabitRepository([FirebaseFirestore? db]) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore? get _safeDb {
    if (_db != null) return _db;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static final Map<String, StreamController<List<Habit>>> _habitsControllers = {};
  static final Map<String, StreamController<LogMap>> _logsControllers = {};
  static final Map<String, StreamController<HabitLog?>> _todayLogControllers = {};

  CollectionReference<Map<String, dynamic>>? _habits(String uid) =>
      _safeDb?.collection('users').doc(uid).collection('habits');

  CollectionReference<Map<String, dynamic>>? _logs(String uid, String habitId) =>
      _habits(uid)?.doc(habitId).collection('logs');

  // --- Local helpers ---

  List<Habit> _getLocalHabits(String uid, {required bool isDeleted}) {
    final rawList = LocalStorageService.instance.getUserHabits(uid);
    final list = rawList
        .map((m) => Habit.fromMap(m['id'] as String? ?? '', m))
        .where((h) => h.isDeleted == isDeleted)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  LogMap _getLocalDoneDates(String uid, String habitId) {
    final map = LocalStorageService.instance.getHabitLogs(uid, habitId);
    return {
      for (final e in map.entries)
        e.key: (e.value['status'] as String? ?? 'done')
    };
  }

  HabitLog? _getLocalTodayLog(String uid, String habitId) {
    final today = DateKey.today();
    final map = LocalStorageService.instance.getHabitLogs(uid, habitId);
    final logData = map[today];
    if (logData == null) return null;
    return HabitLog.fromMap(logData, defaultDate: today);
  }

  void _notifyHabitsChanged(String uid) {
    final ctrl = _habitsControllers[uid];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(_getLocalHabits(uid, isDeleted: false));
    }
  }

  void _notifyLogsChanged(String uid, String habitId) {
    final logCtrl = _logsControllers['${uid}_$habitId'];
    if (logCtrl != null && !logCtrl.isClosed) {
      logCtrl.add(_getLocalDoneDates(uid, habitId));
    }
    final todayCtrl = _todayLogControllers['${uid}_$habitId'];
    if (todayCtrl != null && !todayCtrl.isClosed) {
      todayCtrl.add(_getLocalTodayLog(uid, habitId));
    }
  }

  // --- Streams & Queries ---

  Stream<List<Habit>> watchHabits(String uid) {
    if (AuthRepository.isLocalUid(uid) || _safeDb == null) {
      final ctrl = _habitsControllers.putIfAbsent(
        uid,
        () => StreamController<List<Habit>>.broadcast(),
      );
      final initial = _getLocalHabits(uid, isDeleted: false);
      return () async* {
        yield initial;
        yield* ctrl.stream;
      }();
    }

    try {
      final habitsRef = _habits(uid);
      if (habitsRef == null) {
        return Stream.value(_getLocalHabits(uid, isDeleted: false));
      }
      return habitsRef
          .where('isDeleted', isEqualTo: false)
          .snapshots()
          .map((snap) {
        final list = snap.docs.map(Habit.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }).handleError((_) => _getLocalHabits(uid, isDeleted: false));
    } catch (_) {
      return Stream.value(_getLocalHabits(uid, isDeleted: false));
    }
  }

  Stream<List<Habit>> watchArchivedHabits(String uid) {
    if (AuthRepository.isLocalUid(uid) || _safeDb == null) {
      return Stream.value(_getLocalHabits(uid, isDeleted: true));
    }

    try {
      final habitsRef = _habits(uid);
      if (habitsRef == null) {
        return Stream.value(_getLocalHabits(uid, isDeleted: true));
      }
      return habitsRef
          .where('isDeleted', isEqualTo: true)
          .snapshots()
          .map((snap) {
        final list = snap.docs.map(Habit.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }).handleError((_) => _getLocalHabits(uid, isDeleted: true));
    } catch (_) {
      return Stream.value(_getLocalHabits(uid, isDeleted: true));
    }
  }

  Future<Habit?> getHabit(String uid, String habitId) async {
    if (AuthRepository.isLocalUid(uid) || _safeDb == null) {
      final list = LocalStorageService.instance.getUserHabits(uid);
      final map = list.firstWhere((h) => h['id'] == habitId, orElse: () => {});
      if (map.isEmpty) return null;
      return Habit.fromMap(habitId, map);
    }

    try {
      final doc = await _habits(uid)?.doc(habitId).get();
      if (doc == null || !doc.exists) return null;
      return Habit.fromDoc(doc);
    } catch (_) {
      final list = LocalStorageService.instance.getUserHabits(uid);
      final map = list.firstWhere((h) => h['id'] == habitId, orElse: () => {});
      if (map.isEmpty) return null;
      return Habit.fromMap(habitId, map);
    }
  }

  Future<String> addHabit(String uid, Habit habit) async {
    final habitId = 'habit_${DateTime.now().millisecondsSinceEpoch}';
    final newHabit = habit.copyWith(id: habitId);

    // Save to local storage
    final map = newHabit.toMap();
    map['id'] = habitId;
    map['startDate'] = newHabit.startDate.toIso8601String();
    map['createdAt'] = newHabit.createdAt.toIso8601String();
    if (newHabit.lastRelapseAt != null) {
      map['lastRelapseAt'] = newHabit.lastRelapseAt!.toIso8601String();
    }
    await LocalStorageService.instance.saveUserHabit(uid, map);
    _notifyHabitsChanged(uid);

    final habitsRef = _habits(uid);
    if (!AuthRepository.isLocalUid(uid) && habitsRef != null) {
      try {
        final docRef = habitsRef.doc();
        await docRef.set(newHabit.toMap());
        return docRef.id;
      } catch (_) {}
    }

    return habitId;
  }

  Future<void> updateHabit(String uid, Habit habit) async {
    final map = habit.toMap();
    map['id'] = habit.id;
    map['startDate'] = habit.startDate.toIso8601String();
    map['createdAt'] = habit.createdAt.toIso8601String();
    if (habit.lastRelapseAt != null) {
      map['lastRelapseAt'] = habit.lastRelapseAt!.toIso8601String();
    }
    await LocalStorageService.instance.saveUserHabit(uid, map);
    _notifyHabitsChanged(uid);

    final habitsRef = _habits(uid);
    if (!AuthRepository.isLocalUid(uid) && habitsRef != null) {
      try {
        await habitsRef.doc(habit.id).update(habit.toMap());
      } catch (_) {}
    }
  }

  Future<void> markToday(String uid, String habitId) async {
    final today = DateKey.today();
    final logData = {
      'date': today,
      'status': 'done',
      'at': DateTime.now().toIso8601String(),
    };
    await LocalStorageService.instance.saveHabitLog(uid, habitId, today, logData);
    _notifyLogsChanged(uid, habitId);

    final logsRef = _logs(uid, habitId);
    if (!AuthRepository.isLocalUid(uid) && logsRef != null) {
      try {
        await logsRef.doc(today).set({
          'date': today,
          'status': 'done',
          'at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> unmarkToday(String uid, String habitId) async {
    final today = DateKey.today();
    await LocalStorageService.instance.deleteHabitLog(uid, habitId, today);
    _notifyLogsChanged(uid, habitId);

    final logsRef = _logs(uid, habitId);
    if (!AuthRepository.isLocalUid(uid) && logsRef != null) {
      try {
        await logsRef.doc(today).delete();
      } catch (_) {}
    }
  }

  Future<void> recordRelapse(String uid, String habitId) async {
    final today = DateKey.today();
    final now = DateTime.now();
    final logData = {
      'date': today,
      'status': 'relapse',
      'at': now.toIso8601String(),
    };
    await LocalStorageService.instance.saveHabitLog(uid, habitId, today, logData);

    final habit = await getHabit(uid, habitId);
    if (habit != null) {
      await updateHabit(uid, habit.copyWith(lastRelapseAt: now));
    }
    _notifyLogsChanged(uid, habitId);

    final db = _safeDb;
    final logsRef = _logs(uid, habitId);
    final habitsRef = _habits(uid);
    if (!AuthRepository.isLocalUid(uid) && db != null && logsRef != null && habitsRef != null) {
      try {
        final batch = db.batch();
        final logRef = logsRef.doc(today);
        batch.set(
          logRef,
          {
            'date': today,
            'status': 'relapse',
            'at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        final habitRef = habitsRef.doc(habitId);
        batch.update(habitRef, {
          'lastRelapseAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      } catch (_) {}
    }
  }

  Future<void> saveRelapseSupport(
    String uid,
    String habitId,
    String dateKey,
    Map<String, dynamic> support,
  ) async {
    final existingLogs = LocalStorageService.instance.getHabitLogs(uid, habitId);
    final logData = existingLogs[dateKey] != null
        ? Map<String, dynamic>.from(existingLogs[dateKey]!)
        : <String, dynamic>{
            'date': dateKey,
            'status': 'relapse',
            'at': DateTime.now().toIso8601String(),
          };
    logData['support'] = support;
    await LocalStorageService.instance.saveHabitLog(uid, habitId, dateKey, logData);
    _notifyLogsChanged(uid, habitId);

    final logsRef = _logs(uid, habitId);
    if (!AuthRepository.isLocalUid(uid) && logsRef != null) {
      try {
        await logsRef.doc(dateKey).set(
          {'support': support},
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  Future<void> incrementCount(String uid, String habitId, int dailyTarget) async {
    final today = DateKey.today();
    final logs = LocalStorageService.instance.getHabitLogs(uid, habitId);
    final cur = (logs[today]?['count'] as num?)?.toInt() ?? 0;
    final next = cur + 1;
    final isDone = next >= dailyTarget;

    final logData = {
      'date': today,
      'count': next,
      'status': isDone ? 'done' : 'partial',
      'at': DateTime.now().toIso8601String(),
    };
    await LocalStorageService.instance.saveHabitLog(uid, habitId, today, logData);
    _notifyLogsChanged(uid, habitId);

    final db = _safeDb;
    final logsRef = _logs(uid, habitId);
    if (!AuthRepository.isLocalUid(uid) && db != null && logsRef != null) {
      try {
        final logRef = logsRef.doc(today);
        await db.runTransaction((tx) async {
          final snap = await tx.get(logRef);
          final currentCount = (snap.data()?['count'] as num?)?.toInt() ?? 0;
          final newCount = currentCount + 1;
          final done = newCount >= dailyTarget;
          tx.set(
            logRef,
            {
              'date': today,
              'count': newCount,
              'status': done ? 'done' : 'partial',
              'at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        });
      } catch (_) {}
    }
  }

  Future<void> softDeleteHabit(String uid, String habitId) async {
    final habit = await getHabit(uid, habitId);
    if (habit != null) {
      await updateHabit(uid, habit.copyWith(isDeleted: true));
    }
  }

  Future<void> restoreHabit(String uid, String habitId) async {
    final habit = await getHabit(uid, habitId);
    if (habit != null) {
      await updateHabit(uid, habit.copyWith(isDeleted: false));
    }
  }

  Stream<LogMap> watchDoneDateKeys(String uid, String habitId) {
    if (AuthRepository.isLocalUid(uid) || _safeDb == null) {
      final ctrl = _logsControllers.putIfAbsent(
        '${uid}_$habitId',
        () => StreamController<LogMap>.broadcast(),
      );
      final initial = _getLocalDoneDates(uid, habitId);
      return () async* {
        yield initial;
        yield* ctrl.stream;
      }();
    }

    try {
      final logsRef = _logs(uid, habitId);
      if (logsRef == null) {
        return Stream.value(_getLocalDoneDates(uid, habitId));
      }
      return logsRef.snapshots().map((snap) {
        final map = <String, String>{};
        for (final doc in snap.docs) {
          final data = doc.data();
          final date = data['date'] as String? ?? doc.id;
          final status = data['status'] as String? ?? 'done';
          map[date] = status;
        }
        return map;
      }).handleError((_) => _getLocalDoneDates(uid, habitId));
    } catch (_) {
      return Stream.value(_getLocalDoneDates(uid, habitId));
    }
  }

  Stream<HabitLog?> watchTodayLog(String uid, String habitId) {
    final today = DateKey.today();
    if (AuthRepository.isLocalUid(uid) || _safeDb == null) {
      final ctrl = _todayLogControllers.putIfAbsent(
        '${uid}_$habitId',
        () => StreamController<HabitLog?>.broadcast(),
      );
      final initial = _getLocalTodayLog(uid, habitId);
      return () async* {
        yield initial;
        yield* ctrl.stream;
      }();
    }

    try {
      final logsRef = _logs(uid, habitId);
      if (logsRef == null) {
        return Stream.value(_getLocalTodayLog(uid, habitId));
      }
      return logsRef.doc(today).snapshots().map((doc) {
        if (!doc.exists) return _getLocalTodayLog(uid, habitId);
        return HabitLog.fromDoc(doc);
      }).handleError((_) => _getLocalTodayLog(uid, habitId));
    } catch (_) {
      return Stream.value(_getLocalTodayLog(uid, habitId));
    }
  }

  Future<Map<String, String>> fetchYearLogs(
    String uid,
    String habitId,
    int year,
  ) async {
    final allLogs = LocalStorageService.instance.getHabitLogs(uid, habitId);
    final prefix = '$year-';
    final localResult = <String, String>{};
    for (final e in allLogs.entries) {
      if (e.key.startsWith(prefix)) {
        localResult[e.key] = e.value['status'] as String? ?? 'done';
      }
    }

    final logsRef = _logs(uid, habitId);
    if (AuthRepository.isLocalUid(uid) || logsRef == null) {
      return localResult;
    }

    try {
      final snap = await logsRef
          .where('date', isGreaterThanOrEqualTo: '$year-01-01')
          .where('date', isLessThanOrEqualTo: '$year-12-31')
          .get();

      return {
        for (final doc in snap.docs)
          (doc.data()['date'] as String? ?? doc.id):
              (doc.data()['status'] as String? ?? 'done')
      };
    } catch (_) {
      return localResult;
    }
  }

  Future<List<Habit>> fetchActiveHabits(String uid) async {
    final habitsRef = _habits(uid);
    if (AuthRepository.isLocalUid(uid) || habitsRef == null) {
      return _getLocalHabits(uid, isDeleted: false);
    }

    try {
      final snap = await habitsRef.where('isDeleted', isEqualTo: false).get();
      return snap.docs.map(Habit.fromDoc).toList();
    } catch (_) {
      return _getLocalHabits(uid, isDeleted: false);
    }
  }

  Future<LogMap> fetchRecentLogs(String uid, String habitId, int limit) async {
    final allLogs = LocalStorageService.instance.getHabitLogs(uid, habitId);
    final sortedKeys = allLogs.keys.toList()..sort((a, b) => b.compareTo(a));
    final localResult = <String, String>{};
    for (final k in sortedKeys.take(limit)) {
      localResult[k] = allLogs[k]?['status'] as String? ?? 'done';
    }

    final logsRef = _logs(uid, habitId);
    if (AuthRepository.isLocalUid(uid) || logsRef == null) {
      return localResult;
    }

    try {
      final snap = await logsRef
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return {
        for (final doc in snap.docs)
          (doc.data()['date'] as String? ?? doc.id):
              (doc.data()['status'] as String? ?? 'done')
      };
    } catch (_) {
      return localResult;
    }
  }

  Future<void> setLogStatus(
    String uid,
    String habitId,
    String dateKey,
    String status,
  ) async {
    final logData = {
      'date': dateKey,
      'status': status,
      'at': DateTime.now().toIso8601String(),
    };
    await LocalStorageService.instance.saveHabitLog(uid, habitId, dateKey, logData);
    _notifyLogsChanged(uid, habitId);

    final logsRef = _logs(uid, habitId);
    if (!AuthRepository.isLocalUid(uid) && logsRef != null) {
      try {
        await logsRef.doc(dateKey).set({
          'date': dateKey,
          'status': status,
          'at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }
}
