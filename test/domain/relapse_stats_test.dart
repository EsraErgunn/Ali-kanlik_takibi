import 'package:bloom_habit/core/utils/date_key.dart';
import 'package:bloom_habit/domain/habit_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Relapse Stats Domain Tests', () {
    final today = DateTime(2026, 10, 23);

    test('cleanStreakBeforeRelapse calculates consecutive clean days ending yesterday', () {
      final logs = <String, String>{
        DateKey.of(today): 'relapse',
        DateKey.of(DateKey.addDays(today, -1)): 'done',
        DateKey.of(DateKey.addDays(today, -2)): 'done',
        DateKey.of(DateKey.addDays(today, -3)): 'done',
        DateKey.of(DateKey.addDays(today, -4)): 'relapse',
      };

      expect(cleanStreakBeforeRelapse(logs, today), equals(3));
    });

    test('cleanStreakBeforeRelapse returns 0 if yesterday was not done', () {
      final logs = <String, String>{
        DateKey.of(today): 'relapse',
        DateKey.of(DateKey.addDays(today, -1)): 'relapse',
        DateKey.of(DateKey.addDays(today, -2)): 'done',
      };

      expect(cleanStreakBeforeRelapse(logs, today), equals(0));
    });

    test('cleanStreakBeforeRelapse returns 0 for empty logs', () {
      expect(cleanStreakBeforeRelapse({}, today), equals(0));
    });

    test('cleanStreakBeforeRelapse honors frozen days in chain', () {
      final logs = <String, String>{
        DateKey.of(today): 'relapse',
        DateKey.of(DateKey.addDays(today, -1)): 'done',
        DateKey.of(DateKey.addDays(today, -2)): 'frozen',
        DateKey.of(DateKey.addDays(today, -3)): 'done',
      };

      // 2 done days + 1 frozen day maintaining chain -> 2 done count
      expect(cleanStreakBeforeRelapse(logs, today), equals(2));
    });

    test('totalCleanDays counts all days with done status', () {
      final logs = <String, String>{
        '2026-10-01': 'done',
        '2026-10-02': 'done',
        '2026-10-03': 'relapse',
        '2026-10-04': 'done',
        '2026-10-05': 'partial',
      };

      expect(totalCleanDays(logs), equals(3));
    });

    test('relapsesThisMonth counts only relapses in target month', () {
      final logs = <String, String>{
        '2026-09-28': 'relapse', // previous month
        '2026-10-05': 'relapse', // this month
        '2026-10-12': 'done',
        '2026-10-23': 'relapse', // this month
        '2026-11-01': 'relapse', // next month
      };

      expect(relapsesThisMonth(logs, today), equals(2));
    });

    test('timeOfDaySegment returns accurate time descriptions', () {
      expect(timeOfDaySegment(DateTime(2026, 10, 23, 7, 30)), equals('sabah'));
      expect(timeOfDaySegment(DateTime(2026, 10, 23, 14, 0)), equals('öğle'));
      expect(timeOfDaySegment(DateTime(2026, 10, 23, 20, 15)), equals('akşam'));
      expect(timeOfDaySegment(DateTime(2026, 10, 23, 23, 30)), equals('gece'));
      expect(timeOfDaySegment(DateTime(2026, 10, 23, 3, 0)), equals('gece'));
    });
  });
}
