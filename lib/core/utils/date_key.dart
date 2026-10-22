import 'package:intl/intl.dart';

/// Helper for yyyy-MM-dd local date keys.
/// DST-safe and timezone-consistent.
class DateKey {
  const DateKey._();

  static final DateFormat _format = DateFormat('yyyy-MM-dd');

  /// Formats date to local yyyy-MM-dd.
  static String of(DateTime d) => _format.format(DateTime(d.year, d.month, d.day));

  /// Today's key in local time.
  static String today() => of(DateTime.now());

  /// Parses yyyy-MM-dd into local midnight.
  static DateTime parse(String k) {
    final parts = k.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Truncates time component.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// DST-safe day addition.
  static DateTime addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  /// Day difference between two dates using normalized UTC to avoid DST jumps.
  static int daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;
}
