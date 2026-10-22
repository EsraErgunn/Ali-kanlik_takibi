import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_key.dart';
import '../../data/models/daily_motivation.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_log.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/motivation_repository.dart';
import '../../domain/habit_stats.dart';
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

