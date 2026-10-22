import 'package:bloom_habit/domain/plant_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlantStage tests', () {
    test('plantFor calculates correct stages for days 0, 3, 4, 29, 30, 61', () {
      final start = DateTime(2026, 1, 1);

      // Day 0: Seed (cycle 0)
      final day0 = plantFor(start, DateTime(2026, 1, 1));
      expect(day0.stage, PlantStage.seed);
      expect(day0.completedCycles, 0);

      // Day 3: Sprout (cycle 0)
      final day3 = plantFor(start, DateTime(2026, 1, 4));
      expect(day3.stage, PlantStage.sprout);
      expect(day3.completedCycles, 0);

      // Day 4: Stem (cycle 0)
      final day4 = plantFor(start, DateTime(2026, 1, 5));
      expect(day4.stage, PlantStage.stem);
      expect(day4.completedCycles, 0);

      // Day 29: Flower (cycle 0)
      final day29 = plantFor(start, DateTime(2026, 1, 30));
      expect(day29.stage, PlantStage.flower);
      expect(day29.completedCycles, 0);

      // Day 30: Seed (cycle 1, first completed 30-day garden cycle!)
      final day30 = plantFor(start, DateTime(2026, 1, 31));
      expect(day30.stage, PlantStage.seed);
      expect(day30.completedCycles, 1);

      // Day 61: Sprout (cycle 2: 61 % 30 = 1 => sprout)
      final day61 = plantFor(start, DateTime(2026, 3, 3));
      expect(day61.stage, PlantStage.sprout);
      expect(day61.completedCycles, 2);
    });

    test('Wilted plant check: false if at least one habit was done yesterday', () {
      final today = DateTime(2026, 10, 22);
      final logs = {
        'habit_1': {'2026-10-21': 'done'},
        'habit_2': {'2026-10-21': 'relapse'},
      };
      expect(checkWilted(logs, today), isFalse);
    });

    test('Wilted plant check: true if no habit was done yesterday', () {
      final today = DateTime(2026, 10, 22);
      final logs = {
        'habit_1': {'2026-10-20': 'done'}, // 2 days ago
        'habit_2': {'2026-10-21': 'relapse'},
      };
      expect(checkWilted(logs, today), isTrue);
    });
  });
}
