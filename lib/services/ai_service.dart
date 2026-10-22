import 'dart:convert';
import 'dart:math';
import 'package:firebase_ai/firebase_ai.dart';
import '../data/models/daily_motivation.dart';

class AiService {
  AiService();

  static const List<List<MotivationOption>> _fallbackTriplets = [
    [
      MotivationOption(
        title: '🌱 Derin Kökler Kartı',
        text: 'En güçlü fırtınalara sessizce toprağa tutunan tohumlar dayanır. Bugün sabırla devam et.',
        tag: '#Direnç',
      ),
      MotivationOption(
        title: '☀️ Güneş Işığı Kartı',
        text: 'Işığa doğru uzanan bir filiz gibi, hedefine odaklan. Küçük adımlar büyük ormanlar yaratır.',
        tag: '#Odaklanma',
      ),
      MotivationOption(
        title: '🌧️ Yağmurun Gücü Kartı',
        text: 'Her zorlu an tohumu çatlatıp büyüten bir yağmur damlasıdır. Zorlukları kucakla.',
        tag: '#Dönüşüm',
      ),
    ],
    [
      MotivationOption(
        title: '🌿 Sessiz Büyüme Kartı',
        text: 'Bambu yıllarca kök salar, sonra birden gökyüzüne ulaşır. Gelişimin gözle görülmese de devam ediyor.',
        tag: '#Sabır',
      ),
      MotivationOption(
        title: '💧 Berrak Su Kartı',
        text: 'Damla taşı deler; gücünden değil, sürekliliğinden. Bugün de zincirini kırma.',
        tag: '#Süreklilik',
      ),
      MotivationOption(
        title: '🍃 Taze Filiz Kartı',
        text: 'Eski yapraklar dökülmeden yenileri yeşermez. Kötü alışkanlıkları geride bırakma zamanı.',
        tag: '#Yenilenme',
      ),
    ],
    [
      MotivationOption(
        title: '🌳 Ulu Çınar Kartı',
        text: 'Bugün gölgesinde dinlendiğin çınar, bir zamanlar toprağa bırakılmış küçücük bir tohumdu.',
        tag: '#Gelecek',
      ),
      MotivationOption(
        title: '🌸 Bahar Müjdesi Kartı',
        text: 'Kış ne kadar sert geçerse geçsin, bahar mutlaka gelir. İrade gücüne güven.',
        tag: '#Umut',
      ),
      MotivationOption(
        title: '🌾 Esnek Başak Kartı',
        text: 'Rüzgarda kırılmayan başak, eğilmeyi bilendir. Esnek ol ama yönünü asla kaybetme.',
        tag: '#Denge',
      ),
    ],
  ];

  Future<List<MotivationOption>> generateDailyOptions({
    List<String>? habitTitles,
    String? dayKey,
  }) async {
    try {
      final habitsContext = (habitTitles != null && habitTitles.isNotEmpty)
          ? 'Kullanıcının aktif alışkanlıkları: ${habitTitles.join(", ")}.'
          : '';

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7,
        ),
      );

      final prompt = '''
Sen BloomHabit isimli botanik metaforlu alışkanlık takip uygulamasının yapay zeka rehberisin.
Kullanıcıya bugünün rehberliği için TAM 3 FARKLI motivasyon kartı hazırla.
$habitsContext
Kartlar botanik, doğa ve büyüme metaforları içermeli. İlham verici, Türkçe, samimi ve güçlü olmalı.
Yanıtını YALNIZCA şu JSON formatında ver (başka metin ekleme):
[
  {
    "title": "🌱 Başlık (örn: Derin Kökler Kartı)",
    "text": "1-2 cümlelik vurucu motivasyon sözü",
    "tag": "#Etiket"
  },
  {
    "title": "☀️ İkinci Başlık",
    "text": "1-2 cümlelik vurucu motivasyon sözü",
    "tag": "#Etiket"
  },
  {
    "title": "🌧️ Üçüncü Başlık",
    "text": "1-2 cümlelik vurucu motivasyon sözü",
    "tag": "#Etiket"
  }
]
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text?.trim();

      if (rawText != null && rawText.isNotEmpty) {
        final decoded = jsonDecode(rawText);
        if (decoded is List && decoded.length == 3) {
          final options = <MotivationOption>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              options.add(MotivationOption.fromMap(item));
            }
          }
          if (options.length == 3) {
            return options;
          }
        }
      }
    } catch (_) {
      // Offline, AI not configured, or network error: gracefully fall back to curated options
    }

    return getFallbackOptions(dayKey: dayKey);
  }

  List<MotivationOption> getFallbackOptions({String? dayKey}) {
    if (dayKey != null) {
      final hash = dayKey.hashCode.abs();
      return _fallbackTriplets[hash % _fallbackTriplets.length];
    }
    final randomIndex = Random().nextInt(_fallbackTriplets.length);
    return _fallbackTriplets[randomIndex];
  }
}
