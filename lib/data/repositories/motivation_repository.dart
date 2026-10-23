import 'dart:async';
import '../models/daily_motivation.dart';
import '../services/hive_service.dart';

class MotivationRepository {
  MotivationRepository();

  DailyMotivation? _getMotivation(String dateKey) {
    final raw = HiveService.instance.motivationBox.get(dateKey);
    if (raw == null || raw is! Map) return null;
    return DailyMotivation.fromMap(Map<String, dynamic>.from(raw), defaultDate: dateKey);
  }

  Stream<DailyMotivation?> watchTodayMotivation(String uid, String dateKey) async* {
    yield _getMotivation(dateKey);
    yield* HiveService.instance.motivationBox.watch(key: dateKey).map((event) {
      if (event.value == null || event.value is! Map) return null;
      return DailyMotivation.fromMap(
        Map<String, dynamic>.from(event.value as Map),
        defaultDate: dateKey,
      );
    });
  }

  Future<DailyMotivation?> getTodayMotivation(String uid, String dateKey) async {
    return _getMotivation(dateKey);
  }

  Future<DailyMotivation> getOrCreateTodayMotivation({
    required String uid,
    required String dateKey,
    required Future<List<MotivationOption>> Function() optionGenerator,
  }) async {
    final existing = _getMotivation(dateKey);
    if (existing != null) return existing;

    final options = await optionGenerator();
    final created = DailyMotivation(
      date: dateKey,
      options: options,
      selectedIndex: null,
      selectedAt: null,
    );

    await HiveService.instance.motivationBox.put(dateKey, created.toMap());
    return created;
  }

  Future<void> selectOption({
    required String uid,
    required String dateKey,
    required int optionIndex,
  }) async {
    final current = _getMotivation(dateKey);
    if (current != null && current.selectedIndex == null) {
      final updated = DailyMotivation(
        date: current.date,
        options: current.options,
        selectedIndex: optionIndex,
        selectedAt: DateTime.now(),
      );
      await HiveService.instance.motivationBox.put(dateKey, updated.toMap());
    }
  }
}
