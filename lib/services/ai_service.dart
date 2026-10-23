import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../data/models/daily_motivation.dart';
import '../data/models/support_message.dart';

class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _geminiModel = 'gemini-1.5-flash';

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

  Future<String?> _callGeminiRest(String prompt) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$apiKey',
      );

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.7,
        },
      });

      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is Map) {
        final candidates = body['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final first = candidates.first as Map;
          final content = first['content'] as Map?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final part = parts.first as Map;
            return part['text'] as String?;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<MotivationOption>> generateDailyOptions({
    List<String>? habitTitles,
    String? dayKey,
  }) async {
    try {
      final habitsContext = (habitTitles != null && habitTitles.isNotEmpty)
          ? 'Kullanıcının aktif alışkanlıkları: ${habitTitles.join(", ")}.'
          : '';

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

      final rawText = await _callGeminiRest(prompt);

      if (rawText != null && rawText.isNotEmpty) {
        final decoded = jsonDecode(rawText);
        if (decoded is List && decoded.length == 3) {
          final options = <MotivationOption>[];
          for (final item in decoded) {
            if (item is Map) {
              options.add(MotivationOption.fromMap(Map<String, dynamic>.from(item)));
            }
          }
          if (options.length == 3) {
            return options;
          }
        }
      }
    } catch (_) {
      // Offline, AI not configured, or network error: gracefully fall back
    }

    return getFallbackOptions(dayKey: dayKey);
  }

  Future<SupportMessage?> generateRelapseSupportMessage({
    required String habitTitle,
    required int cleanDaysBeforeRelapse,
    required int totalCleanDays,
    required int relapsesThisMonth,
    required String timeOfDay,
  }) async {
    try {
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

      final rawText = await _callGeminiRest(prompt);
      return SupportMessage.tryParse(rawText);
    } catch (_) {
      return null;
    }
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
