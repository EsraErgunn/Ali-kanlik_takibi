import 'package:bloom_habit/data/models/habit.dart';
import 'package:bloom_habit/data/models/habit_log.dart';
import 'package:bloom_habit/data/models/support_message.dart';
import 'package:bloom_habit/data/repositories/habit_repository.dart';
import 'package:bloom_habit/data/sources/support_message_source.dart';
import 'package:bloom_habit/data/services/hive_service.dart';
import 'package:bloom_habit/features/relapse/fallback_support.dart';
import 'package:bloom_habit/services/relapse_support_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSupportMessageSource implements SupportMessageSource {
  FakeSupportMessageSource({this.response, this.shouldThrow = false});

  SupportMessage? response;
  bool shouldThrow;
  int callCount = 0;

  @override
  Future<SupportMessage?> generateMessage({
    required String habitTitle,
    required int cleanDaysBeforeRelapse,
    required int totalCleanDays,
    required int relapsesThisMonth,
    required String timeOfDay,
  }) async {
    callCount++;
    if (shouldThrow) throw Exception('AI service failure');
    return response;
  }
}

void main() {
  group('SupportMessage JSON Validation Tests', () {
    test('parses valid JSON with constraints', () {
      const validJson = '''
      {
        "message": "Bir gün tökezlemek yolun sonu değil. Çaban değerlidir.",
        "nextStep": "Hemen bir bardak ılık su iç ve 5 kez nefes al."
      }
      ''';

      final result = SupportMessage.tryParse(validJson);
      expect(result, isNotNull);
      expect(result!.message, contains('Bir gün tökezlemek'));
      expect(result.nextStep, contains('ılık su iç'));
    });

    test('rejects JSON when message is missing or empty', () {
      expect(SupportMessage.tryParse('{"nextStep": "Su iç"}'), isNull);
      expect(SupportMessage.tryParse('{"message": "", "nextStep": "Su iç"}'), isNull);
      expect(SupportMessage.tryParse('{"message": "   ", "nextStep": "Su iç"}'), isNull);
    });

    test('rejects JSON when nextStep is missing or empty', () {
      expect(SupportMessage.tryParse('{"message": "Güçlüsün"}'), isNull);
      expect(SupportMessage.tryParse('{"message": "Güçlüsün", "nextStep": ""}'), isNull);
    });

    test('rejects JSON when message exceeds 160 characters', () {
      final longMessage = 'A' * 161;
      final json = '{"message": "$longMessage", "nextStep": "Su iç"}';
      expect(SupportMessage.tryParse(json), isNull);
    });

    test('rejects JSON when nextStep exceeds 100 characters', () {
      final longStep = 'B' * 101;
      final json = '{"message": "Geri dönmek senin elinde", "nextStep": "$longStep"}';
      expect(SupportMessage.tryParse(json), isNull);
    });

    test('rejects non-JSON or corrupted strings', () {
      expect(SupportMessage.tryParse('invalid json'), isNull);
      expect(SupportMessage.tryParse(''), isNull);
      expect(SupportMessage.tryParse(null), isNull);
    });
  });

  group('RelapseSupportService Fallback and Cache Tests', () {
    setUp(() async {
      await HiveService.instance.init();
    });

    final habit = Habit(
      id: 'quit_habit_1',
      title: 'Sigarayı Bırak',
      type: HabitType.quit,
      category: 'smoking',
      icon: '🚭',
      color: 0xFFF07152,
      startDate: DateTime(2026, 10, 1),
      createdAt: DateTime(2026, 10, 1),
    );

    test('falls back to deterministic list when AI returns null or throws', () async {
      final fakeSource = FakeSupportMessageSource(shouldThrow: true);
      final repo = HabitRepository();
      final service = RelapseSupportService(
        messageSource: fakeSource,
        habitRepository: repo,
      );

      final now = DateTime(2026, 10, 23, 14, 0);
      final result = await service.getSupportMessage(
        uid: 'test_user_1',
        habit: habit,
        logs: {'2026-10-22': 'done', '2026-10-21': 'done'},
        todayLog: null,
        now: now,
      );

      final expectedFallback = getFallbackSupport('2026-10-23', habit.id);
      expect(result.message, equals(expectedFallback.message));
      expect(result.nextStep, equals(expectedFallback.nextStep));
      expect(fakeSource.callCount, equals(1));
    });

    test('uses cached support message from todayLog without invoking AI source', () async {
      final fakeSource = FakeSupportMessageSource(
        response: const SupportMessage(message: 'AI message', nextStep: 'AI step'),
      );
      final repo = HabitRepository();
      final service = RelapseSupportService(
        messageSource: fakeSource,
        habitRepository: repo,
      );

      final cachedLog = HabitLog(
        date: '2026-10-23',
        status: 'relapse',
        at: DateTime(2026, 10, 23, 10, 0),
        support: {
          'message': 'Önbellekteki kayıtlı mesaj',
          'nextStep': 'Kayıtlı küçük adım',
        },
      );

      final result = await service.getSupportMessage(
        uid: 'test_user_1',
        habit: habit,
        logs: {'2026-10-22': 'done'},
        todayLog: cachedLog,
        now: DateTime(2026, 10, 23, 16, 0),
      );

      expect(result.message, equals('Önbellekteki kayıtlı mesaj'));
      expect(result.nextStep, equals('Kayıtlı küçük adım'));
      expect(fakeSource.callCount, equals(0)); // 0 calls to AI
    });
  });
}
