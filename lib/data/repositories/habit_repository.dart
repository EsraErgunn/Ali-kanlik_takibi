import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_key.dart';
import '../../domain/habit_stats.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class HabitRepository {
  HabitRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _habits(String uid) =>
      _db.collection('users').doc(uid).collection('habits');

  CollectionReference<Map<String, dynamic>> _logs(String uid, String habitId) =>
      _habits(uid).doc(habitId).collection('logs');

  Stream<List<Habit>> watchHabits(String uid) {
    return _habits(uid)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Habit.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Habit>> watchArchivedHabits(String uid) {
    return _habits(uid)
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Habit.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }


  Future<Habit?> getHabit(String uid, String habitId) async {
    final doc = await _habits(uid).doc(habitId).get();
    if (!doc.exists) return null;
    return Habit.fromDoc(doc);
  }

  Future<String> addHabit(String uid, Habit habit) async {
    final docRef = _habits(uid).doc();
    final newHabit = habit.copyWith();
    await docRef.set(newHabit.toMap());
    return docRef.id;
  }

  Future<void> updateHabit(String uid, Habit habit) async {
    await _habits(uid).doc(habit.id).update(habit.toMap());
  }

  Future<void> markToday(String uid, String habitId) async {
    final today = DateKey.today();
    await _logs(uid, habitId).doc(today).set({
      'date': today,
      'status': 'done',
      'at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unmarkToday(String uid, String habitId) async {
    final today = DateKey.today();
    await _logs(uid, habitId).doc(today).delete();
  }

  Future<void> recordRelapse(String uid, String habitId) async {
    final today = DateKey.today();
    final batch = _db.batch();

    final logRef = _logs(uid, habitId).doc(today);
    batch.set(
      logRef,
      {
        'date': today,
        'status': 'relapse',
        'at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final habitRef = _habits(uid).doc(habitId);
    batch.update(habitRef, {
      'lastRelapseAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> incrementCount(String uid, String habitId, int dailyTarget) async {
    final today = DateKey.today();
    final logRef = _logs(uid, habitId).doc(today);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(logRef);
      final currentCount = (snap.data()?['count'] as num?)?.toInt() ?? 0;
      final newCount = currentCount + 1;
      final isDone = newCount >= dailyTarget;

      tx.set(
        logRef,
        {
          'date': today,
          'count': newCount,
          'status': isDone ? 'done' : 'partial',
          'at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> softDeleteHabit(String uid, String habitId) async {
    await _habits(uid).doc(habitId).update({'isDeleted': true});
  }

  Future<void> restoreHabit(String uid, String habitId) async {
    await _habits(uid).doc(habitId).update({'isDeleted': false});
  }

  Stream<LogMap> watchDoneDateKeys(String uid, String habitId) {
    return _logs(uid, habitId).snapshots().map((snap) {
      final map = <String, String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final date = data['date'] as String? ?? doc.id;
        final status = data['status'] as String? ?? 'done';
        map[date] = status;
      }
      return map;
    });
  }

  Stream<HabitLog?> watchTodayLog(String uid, String habitId) {
    final today = DateKey.today();
    return _logs(uid, habitId).doc(today).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HabitLog.fromDoc(doc);
    });
  }

  Future<Map<String, String>> fetchYearLogs(
    String uid,
    String habitId,
    int year,
  ) async {
    final snap = await _logs(uid, habitId)
        .where('date', isGreaterThanOrEqualTo: '$year-01-01')
        .where('date', isLessThanOrEqualTo: '$year-12-31')
        .get();

    return {
      for (final doc in snap.docs)
        (doc.data()['date'] as String? ?? doc.id):
            (doc.data()['status'] as String? ?? 'done')
    };
  }
}
