import 'package:bloom_habit/core/utils/date_key.dart';
import 'package:bloom_habit/domain/habit_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateKey & DST tests', () {
    test('DateKey format and parse consistency', () {
      final date = DateTime(2026, 10, 22);
      final key = DateKey.of(date);
      expect(key, '2026-10-22');
      final parsed = DateKey.parse(key);
      expect(parsed.year, 2026);
      expect(parsed.month, 10);
      expect(parsed.day, 22);
    });

    test('DST boundary addition and daysBetween calculation', () {
      // European DST transition typically happens late October (e.g. Oct 25 2026)
      final beforeDst = DateTime(2026, 10, 24);
      final afterDst = DateKey.addDays(beforeDst, 2);
      expect(afterDst.day, 26);
      expect(DateKey.daysBetween(beforeDst, afterDst), 2);
    });
  });

  group('Habit Streak tests', () {
    test('Empty log returns 0 streak', () {
      final today = DateTime(2026, 10, 22);
      expect(currentStreak({}, today), 0);
    });

    test('Streak when today is done', () {
      final today = DateTime(2026, 10, 22);
      final logs = {
        '2026-10-22': 'done',
        '2026-10-21': 'done',
        '2026-10-20': 'done',
      };
      expect(currentStreak(logs, today), 3);
    });

    test('Streak when today is not yet done (counts from yesterday)', () {
      final today = DateTime(2026, 10, 22);
      final logs = {
        '2026-10-21': 'done',
        '2026-10-20': 'done',
      };
      expect(currentStreak(logs, today), 2);
    });

    test('Streak broken yesterday returns 0 if today not done', () {
      final today = DateTime(2026, 10, 22);
      final logs = {
        '2026-10-20': 'done',
      };
      expect(currentStreak(logs, today), 0);
    });

    test('Frozen day (shield) maintains chain without adding to done count', () {
      final today = DateTime(2026, 10, 22);
      final logs = {
        '2026-10-22': 'done',
        '2026-10-21': 'frozen',
        '2026-10-20': 'done',
      };
      expect(currentStreak(logs, today), 2);
    });

    test('Longest streak calculates correctly across breaks', () {
      final logs = {
        '2026-10-10': 'done',
        '2026-10-11': 'done',
        '2026-10-12': 'done', // 3 days
        '2026-10-15': 'done',
        '2026-10-16': 'done', // 2 days
      };
      expect(longestStreak(logs), 3);
    });
  });

  group('XP and Level tests', () {
    test('10 done days awards 100 XP and advances level', () {
      expect(totalXp(10), 100);
      final lvl = levelFor(100);
      expect(lvl.level, 2);
      expect(lvl.title, 'Filiz');
    });
  });

  group('Completion rate and Strength score tests', () {
    test('Haftalik % startDate hafta ortasındayken doğru payda', () {
      // Wednesday Oct 21
      final start = DateTime(2026, 10, 21);
      final today = DateTime(2026, 10, 23); // Friday
      final logs = {
        '2026-10-21': 'done',
        '2026-10-22': 'done',
        // Friday Oct 23 not done
      };
      // Week Monday Oct 19 to Sunday Oct 25.
      // Eligible days from start (Wednesday) to today (Friday) = 3 days (Wed, Thu, Fri).
      // 2 done out of 3 = 2/3 ≈ 0.6666
      final rate = weeklyRate(logs, start, today);
      expect(rate, closeTo(2 / 3, 0.01));
    });

    test('Strength score never drops below 0', () {
      final start = DateTime(2026, 10, 1);
      final today = DateTime(2026, 10, 5);
      // All days missed
      final series = strengthSeries({}, start, today);
      expect(series.every((s) => s >= 0), isTrue);
      expect(series.last, 0);
    });
  });

  group('Annual Chain Calendar buildMonth tests', () {
    test('buildMonth: pazar–pazartesi geçişinde linkRight false ve continuesNextRow true', () {
      // 2026 October: Oct 18 is Sunday, Oct 19 is Monday
      final start = DateTime(2026, 10, 1);
      final today = DateTime(2026, 10, 25);
      final logs = {
        '2026-10-18': 'done',
        '2026-10-19': 'done',
      };
      final days = buildMonth(2026, 10, logs, start, today);
      final sunday18 = days.firstWhere((d) => d.date.day == 18);
      final monday19 = days.firstWhere((d) => d.date.day == 19);

      expect(sunday18.linkRight, isFalse);
      expect(sunday18.continuesNextRow, isTrue);
      expect(monday19.linkLeft, isFalse);
      expect(monday19.continuesPrevRow, isTrue);
    });
  });

  group('Quit stats calculation', () {
    test('Calculates saved money and avoided units correctly', () {
      final stats = quitStats(
        cleanDays: 5,
        unitsPerDay: 2,
        unitPrice: 100.0,
      );
      expect(stats.saved, 1000.0);
      expect(stats.avoided, 10);
    });
  });

  group('Shield freeze candidates', () {
    test('Freezes habit missed yesterday if streak >= 3', () {
      final today = DateTime(2026, 10, 22);
      final logsByHabit = {
        'habit_1': {
          '2026-10-18': 'done',
          '2026-10-19': 'done',
          '2026-10-20': 'done',
          // 2026-10-21 missed (yesterday)
        },
        'habit_2': {
          '2026-10-20': 'done',
          // 2026-10-21 missed (streak was only 1)
        },
      };

      final toFreeze = habitsToFreeze(logsByHabit, today, 1);
      expect(toFreeze, ['habit_1']);
    });
  });
}
