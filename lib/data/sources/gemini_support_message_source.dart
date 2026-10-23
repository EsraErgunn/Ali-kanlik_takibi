import '../../services/ai_service.dart';
import '../models/support_message.dart';
import 'support_message_source.dart';

class GeminiSupportMessageSource implements SupportMessageSource {
  const GeminiSupportMessageSource({this.aiService});

  final AiService? aiService;

  @override
  Future<SupportMessage?> generateMessage({
    required String habitTitle,
    required int cleanDaysBeforeRelapse,
    required int totalCleanDays,
    required int relapsesThisMonth,
    required String timeOfDay,
  }) async {
    final service = aiService ?? AiService();
    return service.generateRelapseSupportMessage(
      habitTitle: habitTitle,
      cleanDaysBeforeRelapse: cleanDaysBeforeRelapse,
      totalCleanDays: totalCleanDays,
      relapsesThisMonth: relapsesThisMonth,
      timeOfDay: timeOfDay,
    );
  }
}
