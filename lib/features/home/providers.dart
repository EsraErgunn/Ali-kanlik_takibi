import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_key.dart';
import '../../data/models/daily_motivation.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_log.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/motivation_repository.dart';
import '../../domain/habit_stats.dart';
import '../../domain/plant_stage.dart';
import '../../services/ai_service.dart';
import '../auth/providers.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(FirebaseFirestore.instance);
});

final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchHabits(uid);
});

final archivedHabitsProvider = StreamProvider<List<Habit>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchArchivedHabits(uid);
});


final habitLogsProvider = StreamProvider.family<LogMap, String>((ref, habitId) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(habitRepositoryProvider).watchDoneDateKeys(uid, habitId);
});

final allHabitLogsProvider = Provider<Map<String, LogMap>>((ref) {
  final habits = ref.watch(habitsProvider).value ?? [];
  final map = <String, LogMap>{};
  for (final habit in habits) {
    final logs = ref.watch(habitLogsProvider(habit.id)).value ?? {};
    map[habit.id] = logs;
  }
  return map;
});

final combinedLogsProvider = Provider<LogMap>((ref) {
  final logsMap = ref.watch(allHabitLogsProvider);
  return combineHabitLogs(logsMap);
});

final isPlantWiltedProvider = Provider<bool>((ref) {
  final logsMap = ref.watch(allHabitLogsProvider);
  return checkWilted(logsMap, DateTime.now());
});

final overallStatsProvider = Provider<({double successRate, int longestStreak, int totalCompletedDays})>((ref) {
  final habits = ref.watch(habitsProvider).value ?? [];
  final logsMap = ref.watch(allHabitLogsProvider);
  final today = DateTime.now();

  final rate = overallCompletionRate(
    startDates: habits.map((h) => h.startDate).toList(),
    logsByHabit: logsMap,
    today: today,
  );
  final longest = overallLongestStreak(logsMap);
  final combined = ref.watch(combinedLogsProvider);
  final totalDoneDays = totalDone(combined);

  return (
    successRate: rate,
    longestStreak: longest,
    totalCompletedDays: totalDoneDays,
  );
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

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});


final motivationRepositoryProvider = Provider<MotivationRepository>((ref) {
  return MotivationRepository(firestore: FirebaseFirestore.instance);
});

final todayMotivationProvider = StreamProvider<DailyMotivation?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  final todayKey = DateKey.today();
  final repo = ref.watch(motivationRepositoryProvider);
  final ai = ref.watch(aiServiceProvider);

  // Trigger getOrCreate if document does not exist yet
  repo.getTodayMotivation(uid, todayKey).then((existing) {
    if (existing == null) {
      final habits = ref.read(habitsProvider).value;
      final titles = habits?.map((h) => h.title).toList();
      repo.getOrCreateTodayMotivation(
        uid: uid,
        dateKey: todayKey,
        optionGenerator: () => ai.generateDailyOptions(
          habitTitles: titles,
          dayKey: todayKey,
        ),
      );
    }
  });

  return repo.watchTodayMotivation(uid, todayKey);
});

