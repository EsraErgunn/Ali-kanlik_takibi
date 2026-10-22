import '../core/utils/date_key.dart';
import 'habit_stats.dart';

enum PlantStage { seed, sprout, stem, bud, flower }

extension PlantStageExtension on PlantStage {
  String get title {
    switch (this) {
      case PlantStage.seed:
        return 'Tohum Aşaması';
      case PlantStage.sprout:
        return 'Filiz Aşaması';
      case PlantStage.stem:
        return 'Sap Aşaması';
      case PlantStage.bud:
        return 'Tomurcuk Aşaması';
      case PlantStage.flower:
        return 'Çiçek Aşaması';
    }
  }

  String get emoji {
    switch (this) {
      case PlantStage.seed:
        return '🌱';
      case PlantStage.sprout:
        return '🌿';
      case PlantStage.stem:
        return '🪴';
      case PlantStage.bud:
        return '🌾';
      case PlantStage.flower:
        return '🌸';
    }
  }
}

/// Computes plant growth stage and completed 30-day cycles.
({PlantStage stage, int completedCycles, int dayInCycle, double cycleProgress}) plantFor(
  DateTime gardenStart,
  DateTime today,
) {
  final days = DateKey.daysBetween(DateKey.dateOnly(gardenStart), DateKey.dateOnly(today));
  final safeDays = days < 0 ? 0 : days;
  final inCycle = safeDays % 30;
  final stage = switch (inCycle) {
    0 => PlantStage.seed,
    <= 3 => PlantStage.sprout,
    <= 10 => PlantStage.stem,
    <= 20 => PlantStage.bud,
    _ => PlantStage.flower,
  };

  return (
    stage: stage,
    completedCycles: safeDays ~/ 30,
    dayInCycle: inCycle,
    cycleProgress: (inCycle / 30.0).clamp(0.0, 1.0),
  );
}

/// Checks if plant is wilted.
/// Wilted if yesterday had no 'done' in any habit (unless it's day 0).
bool checkWilted(Map<String, LogMap> logsByHabit, DateTime today) {
  if (logsByHabit.isEmpty) return false;
  final yesterday = DateKey.addDays(today, -1);
  for (final logs in logsByHabit.values) {
    if (isDone(logs, yesterday)) {
      return false;
    }
  }
  return true;
}
