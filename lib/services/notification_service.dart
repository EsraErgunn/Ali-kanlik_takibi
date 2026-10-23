import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/habit.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Fallback if local timezone lookup fails
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted = await androidImpl?.requestNotificationsPermission();

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (androidGranted ?? iosGranted) ?? true;
    } catch (_) {
      return false;
    }
  }

  int notifId(String habitId, int weekday) =>
      (habitId.hashCode & 0x7ffffff) * 10 + weekday;

  Future<void> scheduleHabit(Habit habit) async {
    await cancelHabit(habit.id);
    if (habit.reminderTime == null || habit.reminderDays.isEmpty) return;

    final parts = habit.reminderTime!.split(':');
    if (parts.length != 2) return;
    final hh = int.tryParse(parts[0]) ?? 20;
    final mm = int.tryParse(parts[1]) ?? 0;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminders',
        'Sulama Hatırlatıcıları',
        channelDescription: 'Sulama saati gelen tohumlar için bildirimler',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (final wd in habit.reminderDays) {
      try {
        await _plugin.zonedSchedule(
          id: notifId(habit.id, wd),
          title: '🌱 Sulama Vakti: ${habit.title}',
          body: habit.type == HabitType.quit
              ? 'Özgürlük yolunda bugün de kararlı kal! 💪'
              : 'Bugün tohumunu sulamayı unutma, zinciri büyüt! 🔥',
          scheduledDate: _nextInstanceOfWeekday(wd, hh, mm),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (_) {
        // Notification scheduling skipped on failure
      }
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelHabit(String habitId) async {
    for (var wd = 1; wd <= 7; wd++) {
      try {
        await _plugin.cancel(id: notifId(habitId, wd));
      } catch (_) {}
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
