import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_log.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_stats.dart';
import '../auth/providers.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(FirebaseFirestore.instance);
});

final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchHabits(uid);
});

final habitLogsProvider = StreamProvider.family<LogMap, String>((ref, habitId) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchDoneDateKeys(uid, habitId);
});

final todayLogProvider = StreamProvider.family<HabitLog?, String>((ref, habitId) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchTodayLog(uid, habitId);
});

final yearLogsProvider = FutureProvider.family<Map<String, String>,
    ({String habitId, int year})>((ref, args) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Future.value({});
  return ref.watch(habitRepositoryProvider).fetchYearLogs(uid, args.habitId, args.year);
});
