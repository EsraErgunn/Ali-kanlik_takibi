import '../models/support_message.dart';

abstract class SupportMessageSource {
  Future<SupportMessage?> generateMessage({
    required String habitTitle,
    required int cleanDaysBeforeRelapse,
    required int totalCleanDays,
    required int relapsesThisMonth,
    required String timeOfDay,
  });
}
