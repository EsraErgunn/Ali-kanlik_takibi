import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_key.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../data/models/support_message.dart';
import '../data/repositories/habit_repository.dart';
import '../data/sources/firebase_ai_support_message_source.dart';
import '../data/sources/support_message_source.dart';
import '../domain/habit_stats.dart';
import '../features/home/providers.dart';
import '../features/relapse/fallback_support.dart';

final supportMessageSourceProvider = Provider<SupportMessageSource>((ref) {
  return const FirebaseAiSupportMessageSource();
});

final relapseSupportServiceProvider = Provider<RelapseSupportService>((ref) {
  return RelapseSupportService(
    messageSource: ref.watch(supportMessageSourceProvider),
    habitRepository: ref.watch(habitRepositoryProvider),
  );
});

class RelapseSupportService {
  RelapseSupportService({
    required this.messageSource,
    required this.habitRepository,
  });

  final SupportMessageSource messageSource;
  final HabitRepository habitRepository;

  Future<SupportMessage> getSupportMessage({
    required String uid,
    required Habit habit,
    required LogMap logs,
    required HabitLog? todayLog,
    required DateTime now,
  }) async {
    final todayKey = DateKey.of(now);

    // 1. Önbellek kontrolü: Eğer bugünün logunda support zaten varsa, yeni istek atma
    if (todayLog?.support != null && SupportMessage.isValidMap(todayLog!.support)) {
      return SupportMessage.fromMap(todayLog.support!);
    }

    // 2. AI'a gidecek verileri domain üzerinden hesapla
    final cleanBefore = cleanStreakBeforeRelapse(logs, now);
    final totalClean = totalCleanDays(logs);
    final monthRelapses = relapsesThisMonth(logs, now);
    final timeOfDay = timeOfDaySegment(now);

    SupportMessage? result;
    try {
      result = await messageSource
          .generateMessage(
            habitTitle: habit.title,
            cleanDaysBeforeRelapse: cleanBefore,
            totalCleanDays: totalClean,
            relapsesThisMonth: monthRelapses,
            timeOfDay: timeOfDay,
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      result = null;
    }

    // 3. Yanıt gelmezse, hata olursa veya timeout olursa sessizce yedek listeye düş
    final finalMessage = result ?? getFallbackSupport(todayKey, habit.id);

    // 4. Üretilen mesajı o günün log dokümanına kaydet
    await habitRepository.saveRelapseSupport(
      uid,
      habit.id,
      todayKey,
      finalMessage.toMap(),
    );

    return finalMessage;
  }
}
