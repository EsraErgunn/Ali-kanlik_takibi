import '../core/utils/date_key.dart';
import '../data/models/habit.dart';

/// Key: yyyy-MM-dd, Value: 'done' | 'relapse' | 'frozen' | 'partial'
typedef LogMap = Map<String, String>;

bool isDone(LogMap logs, DateTime d) => logs[DateKey.of(d)] == 'done';

/// Chain continuation day: 'done' or 'frozen' (protected by shield).
bool keepsChain(LogMap logs, DateTime d) {
  final s = logs[DateKey.of(d)];
  return s == 'done' || s == 'frozen';
}

/// Active streak count.
/// If today is not done yet, counts backwards from yesterday so the streak doesn't break until the day ends.
int currentStreak(LogMap logs, DateTime today) {
  var day = keepsChain(logs, today) ? today : DateKey.addDays(today, -1);
  var count = 0;
  while (keepsChain(logs, day)) {
    if (isDone(logs, day)) count++;
    day = DateKey.addDays(day, -1);
  }
  return count;
}

/// Longest historical streak of consecutive days.
int longestStreak(LogMap logs) {
  if (logs.isEmpty) return 0;
  final sortedDates = logs.keys
      .where((k) => logs[k] == 'done' || logs[k] == 'frozen')
      .map(DateKey.parse)
      .toList()
    ..sort();

  if (sortedDates.isEmpty) return 0;

  var maxStreak = 0;
  var currentRun = 0;
  DateTime? prev;

  for (final d in sortedDates) {
    if (prev == null) {
      currentRun = logs[DateKey.of(d)] == 'done' ? 1 : 0;
    } else {
      final diff = DateKey.daysBetween(prev, d);
      if (diff == 1) {
        if (logs[DateKey.of(d)] == 'done') currentRun++;
      } else if (diff > 1) {
        currentRun = logs[DateKey.of(d)] == 'done' ? 1 : 0;
      }
    }
    if (currentRun > maxStreak) maxStreak = currentRun;
    prev = d;
  }
  return maxStreak;
}

/// Total count of completed days.
int totalDone(LogMap logs) =>
    logs.values.where((status) => status == 'done').length;

/// Total XP earned from habits (10 XP per done day).
int totalXp(int totalDone) => totalDone * 10;

/// Level information derived from XP.
({int level, String title, double progress}) levelFor(int xp) {
  const thresholds = [0, 100, 300, 600, 1000, 1500, 2500];
  const titles = [
    'Tohum',
    'Filiz',
    'Bahçıvan',
    'Usta Bahçıvan',
    'Bahçe Bilgesi',
    'Orman Koruyucu',
    'Efsane Bahçıvan',
  ];
  var i = thresholds.lastIndexWhere((t) => xp >= t);
  if (i < 0) i = 0;
  final next = i + 1 < thresholds.length ? thresholds[i + 1] : thresholds[i];
  final p = next == thresholds[i] ? 1.0 : (xp - thresholds[i]) / (next - thresholds[i]);
  return (
    level: i + 1,
    title: titles[i],
    progress: p.clamp(0.0, 1.0),
  );
}

/// Completion percentage between two dates.
double completionRate(
  LogMap logs,
  DateTime from,
  DateTime to,
  DateTime start,
  DateTime today,
) {
  final s = [DateKey.dateOnly(from), DateKey.dateOnly(start)]
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final e = [DateKey.dateOnly(to), DateKey.dateOnly(today)]
      .reduce((a, b) => a.isBefore(b) ? a : b);

  if (s.isAfter(e)) return 0.0;
  var total = 0, done = 0;
  for (var d = s; !d.isAfter(e); d = DateKey.addDays(d, 1)) {
    total++;
    if (isDone(logs, d)) done++;
  }
  return total == 0 ? 0.0 : done / total;
}

/// Weekly completion rate (Monday to Sunday of the current week).
double weeklyRate(LogMap logs, DateTime start, DateTime today) {
  final from = DateKey.addDays(today, -(today.weekday - 1));
  final to = DateKey.addDays(from, 6);
  return completionRate(logs, from, to, start, today);
}

/// Monthly completion rate (Calendar month).
double monthlyRate(LogMap logs, DateTime start, DateTime today) {
  final from = DateTime(today.year, today.month, 1);
  final to = DateTime(today.year, today.month + 1, 0);
  return completionRate(logs, from, to, start, today);
}

/// Strength score series over time. +1 for done, -1 for missed, floor 0.
List<int> strengthSeries(LogMap logs, DateTime start, DateTime today) {
  final result = <int>[];
  var score = 0;
  final lastDay = isDone(logs, today) ? today : DateKey.addDays(today, -1);
  for (var d = DateKey.dateOnly(start); !d.isAfter(lastDay); d = DateKey.addDays(d, 1)) {
    score = isDone(logs, d) ? score + 1 : (score - 1).clamp(0, 1 << 30);
    result.add(score);
  }
  return result;
}

/// Last 8 weeks completion count (Monday to Sunday).
List<int> weeklyCompletions(LogMap logs, DateTime today) {
  final result = <int>[];
  final thisMonday = DateKey.addDays(DateKey.dateOnly(today), -(today.weekday - 1));

  for (var w = 7; w >= 0; w--) {
    final monday = DateKey.addDays(thisMonday, -(w * 7));
    final sunday = DateKey.addDays(monday, 6);
    var doneCount = 0;
    for (var d = monday; !d.isAfter(sunday); d = DateKey.addDays(d, 1)) {
      if (isDone(logs, d)) doneCount++;
    }
    result.add(doneCount);
  }
  return result;
}

/// Elapsed time duration for timer tickers.
Duration elapsedFor(Habit h, DateTime now) {
  final origin = h.type == HabitType.quit ? (h.lastRelapseAt ?? h.startDate) : h.startDate;
  final diff = now.difference(origin);
  return diff.isNegative ? Duration.zero : diff;
}

/// Financial and count savings for quit habits.
({double saved, int avoided}) quitStats({
  required int cleanDays,
  required int unitsPerDay,
  required double unitPrice,
}) {
  return (
    saved: cleanDays * unitsPerDay * unitPrice,
    avoided: cleanDays * unitsPerDay,
  );
}

/// Determines which habits should receive shield freeze if missed yesterday.
List<String> habitsToFreeze(
  Map<String, LogMap> logsByHabit,
  DateTime today,
  int shields,
) {
  if (shields <= 0) return const [];
  final yesterday = DateKey.addDays(today, -1);

  final candidateHabitIds = <({String id, int streak})>[];

  for (final entry in logsByHabit.entries) {
    final habitId = entry.key;
    final logs = entry.value;

    // Check if yesterday is not completed
    if (!keepsChain(logs, yesterday)) {
      // Calculate streak ending two days ago
      final twoDaysAgo = DateKey.addDays(yesterday, -1);
      final streak = currentStreak(logs, twoDaysAgo);
      if (streak >= 3) {
        candidateHabitIds.add((id: habitId, streak: streak));
      }
    }
  }

  candidateHabitIds.sort((a, b) => b.streak.compareTo(a.streak));
  return candidateHabitIds.take(shields).map((c) => c.id).toList();
}

/// Visual mark for calendar day cell.
enum DayMark { none, done, relapse, frozen, missed, future, beforeStart }

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.mark,
    this.linkLeft = false,
    this.linkRight = false,
    this.continuesNextRow = false,
    this.continuesPrevRow = false,
    this.isToday = false,
  });

  final DateTime date;
  final DayMark mark;
  final bool linkLeft;
  final bool linkRight;
  final bool continuesNextRow;
  final bool continuesPrevRow;
  final bool isToday;
}

/// Builds 1-month matrix for the Annual Chain Calendar with chain link flags.
List<CalendarDay> buildMonth(
  int year,
  int month,
  LogMap logs,
  DateTime start,
  DateTime today,
) {
  final result = <CalendarDay>[];
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final startDateOnly = DateKey.dateOnly(start);
  final todayDateOnly = DateKey.dateOnly(today);

  for (var day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    final status = logs[DateKey.of(date)];
    final isCurrentDay = date == todayDateOnly;

    DayMark mark;
    if (date.isBefore(startDateOnly)) {
      mark = DayMark.beforeStart;
    } else if (date.isAfter(todayDateOnly)) {
      mark = DayMark.future;
    } else if (status == 'done') {
      mark = DayMark.done;
    } else if (status == 'relapse') {
      mark = DayMark.relapse;
    } else if (status == 'frozen') {
      mark = DayMark.frozen;
    } else {
      mark = isCurrentDay ? DayMark.none : DayMark.missed;
    }

    final isDoneDay = mark == DayMark.done;
    final nextDate = DateKey.addDays(date, 1);
    final prevDate = DateKey.addDays(date, -1);
    final isNextDone = isDone(logs, nextDate);
    final isPrevDone = isDone(logs, prevDate);

    // Links: Monday is 1, Sunday is 7
    final linkRight = isDoneDay && isNextDone && date.weekday != 7;
    final linkLeft = isDoneDay && isPrevDone && date.weekday != 1;
    final continuesNextRow = isDoneDay && isNextDone && date.weekday == 7;
    final continuesPrevRow = isDoneDay && isPrevDone && date.weekday == 1;

    result.add(CalendarDay(
      date: date,
      mark: mark,
      linkLeft: linkLeft,
      linkRight: linkRight,
      continuesNextRow: continuesNextRow,
      continuesPrevRow: continuesPrevRow,
      isToday: isCurrentDay,
    ));
  }

  return result;
}

/// Unifies logs across all habits.
/// A day is marked 'done' if any habit was done on that day.
LogMap combineHabitLogs(Map<String, LogMap> logsByHabit) {
  final combined = <String, String>{};
  for (final logs in logsByHabit.values) {
    for (final entry in logs.entries) {
      if (entry.value == 'done') {
        combined[entry.key] = 'done';
      } else if (entry.value == 'frozen' && combined[entry.key] != 'done') {
        combined[entry.key] = 'frozen';
      } else if (entry.value == 'relapse' && combined[entry.key] == null) {
        combined[entry.key] = 'relapse';
      }
    }
  }
  return combined;
}

/// Computes overall completion rate across all habits.
double overallCompletionRate({
  required List<DateTime> startDates,
  required Map<String, LogMap> logsByHabit,
  required DateTime today,
}) {
  if (startDates.isEmpty) return 0.0;
  var totalPossible = 0;
  var totalCompleted = 0;

  var index = 0;
  for (final logs in logsByHabit.values) {
    final start = index < startDates.length ? startDates[index] : today;
    index++;
    final days = DateKey.daysBetween(DateKey.dateOnly(start), DateKey.dateOnly(today)) + 1;
    final eligibleDays = days < 1 ? 1 : days;
    totalPossible += eligibleDays;
    totalCompleted += totalDone(logs);
  }

  if (totalPossible == 0) return 0.0;
  return (totalCompleted / totalPossible).clamp(0.0, 1.0);
}

/// Finds the longest streak achieved across any habit.
int overallLongestStreak(Map<String, LogMap> logsByHabit) {
  var maxStreak = 0;
  for (final logs in logsByHabit.values) {
    final s = longestStreak(logs);
    if (s > maxStreak) maxStreak = s;
  }
  return maxStreak;
}

/// Calculates completion count per weekday (1=Monday ... 7=Sunday).
Map<int, int> weekdayDistribution(LogMap logs) {
  final counts = {for (var i = 1; i <= 7; i++) i: 0};
  for (final entry in logs.entries) {
    if (entry.value == 'done') {
      try {
        final d = DateKey.parse(entry.key);
        counts[d.weekday] = (counts[d.weekday] ?? 0) + 1;
      } catch (_) {}
    }
  }
  return counts;
}

/// Computes habit type counts: build, quit, count
({int build, int quit, int count}) habitTypeDistribution(List<Habit> habits) {
  var b = 0, q = 0, c = 0;
  for (final h in habits) {
    if (h.isDeleted) continue;
    switch (h.type) {
      case HabitType.build:
        b++;
        break;
      case HabitType.quit:
        q++;
        break;
      case HabitType.count:
        c++;
        break;
    }
  }
  return (build: b, quit: q, count: c);
}

/// Last 6 months completion counts
List<({String label, int count, int year, int month})> monthlyTrend(LogMap logs, DateTime now) {
  const monthNames = [
    '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];
  final result = <({String label, int count, int year, int month})>[];

  for (var i = 5; i >= 0; i--) {
    final targetMonth = DateTime(now.year, now.month - i, 1);
    final prefix = '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}-';
    var count = 0;
    for (final e in logs.entries) {
      if (e.key.startsWith(prefix) && e.value == 'done') {
        count++;
      }
    }
    result.add((
      label: monthNames[targetMonth.month],
      count: count,
      year: targetMonth.year,
      month: targetMonth.month,
    ));
  }
  return result;
}

