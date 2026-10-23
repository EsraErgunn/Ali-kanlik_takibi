import 'package:firebase_ai/firebase_ai.dart';
import '../models/support_message.dart';
import 'support_message_source.dart';

class FirebaseAiSupportMessageSource implements SupportMessageSource {
  const FirebaseAiSupportMessageSource();

  @override
  Future<SupportMessage?> generateMessage({
    required String habitTitle,
    required int cleanDaysBeforeRelapse,
    required int totalCleanDays,
    required int relapsesThisMonth,
    required String timeOfDay,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7,
        ),
      );

      final prompt = '''
Sen BloomHabit uygulamasında bırakma (quit) sürecindeki kullanıcılara destek olan şefkatli bir rehbersin.
Kullanıcı az önce kaydı (relapse kaydetti).
Veriler:
- Alışkanlık başlığı: $habitTitle
- Kayıttan önceki temiz gün sayısı: $cleanDaysBeforeRelapse
- Toplam temiz gün sayısı: $totalCleanDays
- Bu ay kaçıncı kayıt olduğu: $relapsesThisMonth
- Günün zaman dilimi: $timeOfDay

PROMPT KURALLARI:
- Tıbbi tavsiye, ilaç, tedavi, yoksunluk belirtisi veya sağlık istatistiği verme.
- Suçlama, utandırma, "yine mi" gibi ifadeler kullanma.
- Sayı uydurma; sadece sana verilen sayıları kullanabilirsin.
- Türkçe yaz, en fazla 1 emoji kullan.

Yanıtını YALNIZCA şu JSON formatında ver (başka hiçbir metin ekleme):
{
  "message": "en fazla 160 karakter, şefkatli, suçlamayan; ilerlemenin silinmediğini vurgulayan bir mesaj",
  "nextStep": "en fazla 100 karakter, hemen yapılabilecek tek bir küçük davranış"
}
''';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 6));

      final rawText = response.text;
      return SupportMessage.tryParse(rawText);
    } catch (_) {
      // Offline, timeout, or configuration error -> return null so fallback is used
      return null;
    }
  }
}
