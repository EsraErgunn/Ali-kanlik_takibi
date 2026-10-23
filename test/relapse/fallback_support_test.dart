import 'package:bloom_habit/features/relapse/fallback_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fallback Support Tests', () {
    test('fallback list has at least 15 items', () {
      expect(fallbackSupportList.length, greaterThanOrEqualTo(15));
    });

    test('all fallback messages respect length constraints', () {
      for (var i = 0; i < fallbackSupportList.length; i++) {
        final item = fallbackSupportList[i];
        expect(
          item.message.trim().length,
          lessThanOrEqualTo(160),
          reason: 'Item $i message exceeds 160 chars',
        );
        expect(
          item.message.trim().isNotEmpty,
          isTrue,
          reason: 'Item $i message should not be empty',
        );
        expect(
          item.nextStep.trim().length,
          lessThanOrEqualTo(100),
          reason: 'Item $i nextStep exceeds 100 chars',
        );
        expect(
          item.nextStep.trim().isNotEmpty,
          isTrue,
          reason: 'Item $i nextStep should not be empty',
        );
      }
    });

    test('fallback selection is deterministic for same dateKey and habitId', () {
      const dateKey = '2026-10-23';
      const habitId = 'habit_quit_smoking_1';

      final firstChoice = getFallbackSupport(dateKey, habitId);
      final secondChoice = getFallbackSupport(dateKey, habitId);
      final thirdChoice = getFallbackSupport(dateKey, habitId);

      expect(firstChoice.message, equals(secondChoice.message));
      expect(firstChoice.nextStep, equals(secondChoice.nextStep));
      expect(firstChoice.message, equals(thirdChoice.message));
      expect(firstChoice.nextStep, equals(thirdChoice.nextStep));
    });

    test('different dates or habits provide consistent seeded choices', () {
      final choiceA = getFallbackSupport('2026-10-23', 'habit_1');
      final choiceB = getFallbackSupport('2026-10-24', 'habit_1');
      // Running choiceA again should match exactly choiceA
      expect(getFallbackSupport('2026-10-23', 'habit_1').message, equals(choiceA.message));
      expect(getFallbackSupport('2026-10-24', 'habit_1').message, equals(choiceB.message));
    });
  });
}
