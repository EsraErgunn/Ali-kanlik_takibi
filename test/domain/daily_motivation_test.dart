import 'package:bloom_habit/data/models/daily_motivation.dart';
import 'package:bloom_habit/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Daily Motivation Model and AI Service Tests', () {
    test('MotivationOption serialize and deserialize', () {
      final opt = MotivationOption.fromMap({
        'title': '🌱 Derin Kökler',
        'text': 'Sabırla yeşeren her alışkanlık sağlam bir orman kurar.',
        'tag': '#Direnç',
      });

      expect(opt.title, contains('Derin Kökler'));
      expect(opt.tag, '#Direnç');

      final map = opt.toMap();
      expect(map['title'], opt.title);
      expect(map['text'], opt.text);
      expect(map['tag'], opt.tag);
    });

    test('DailyMotivation selection state', () {
      const motivationUnselected = DailyMotivation(
        date: '2026-10-22',
        options: [
          MotivationOption(title: 'Kart 1', text: 'Söz 1', tag: '#1'),
          MotivationOption(title: 'Kart 2', text: 'Söz 2', tag: '#2'),
          MotivationOption(title: 'Kart 3', text: 'Söz 3', tag: '#3'),
        ],
        selectedIndex: null,
      );

      expect(motivationUnselected.isSelected, false);

      const motivationSelected = DailyMotivation(
        date: '2026-10-22',
        options: [
          MotivationOption(title: 'Kart 1', text: 'Söz 1', tag: '#1'),
          MotivationOption(title: 'Kart 2', text: 'Söz 2', tag: '#2'),
          MotivationOption(title: 'Kart 3', text: 'Söz 3', tag: '#3'),
        ],
        selectedIndex: 1,
      );

      expect(motivationSelected.isSelected, true);
    });

    test('AiService returns exactly 3 fallback options consistently', () {
      final ai = AiService();
      final options1 = ai.getFallbackOptions(dayKey: '2026-10-22');
      final options2 = ai.getFallbackOptions(dayKey: '2026-10-22');

      expect(options1.length, 3);
      expect(options2.length, 3);
      expect(options1.first.title, options2.first.title);
      expect(options1.first.text.isNotEmpty, true);
      expect(options1.first.tag.startsWith('#'), true);
    });
  });
}
