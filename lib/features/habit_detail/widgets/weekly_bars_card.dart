import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/habit_stats.dart';

class WeeklyBarsCard extends StatelessWidget {
  const WeeklyBarsCard({
    super.key,
    required this.logs,
    required this.now,
    this.color = AppColors.primary,
    this.eyebrow = 'SÜRDÜRÜLEBİLİRLİK',
  });

  final LogMap logs;
  final DateTime now;
  final Color color;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completions = weeklyCompletions(logs, now); // length 8
    final thisWeekDone = completions.isNotEmpty ? completions.last : 0;
    final thisWeekPct = ((thisWeekDone / 7.0) * 100).toInt();

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(eyebrow, color: color),
              Text(
                '$thisWeekDone/7 Gün · %$thisWeekPct Başarı',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 140.h,
            child: BarChart(
              BarChartData(
                maxY: 7,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        final title = idx == 7 ? 'Bu' : 'H${idx + 1}';
                        return Text(
                          title,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(completions.length, (idx) {
                  final count = completions[idx];
                  final isCurrent = idx == completions.length - 1;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        width: 14.w,
                        borderRadius: BorderRadius.circular(6.r),
                        color: isCurrent
                            ? color
                            : color.withValues(alpha: count >= 5 ? 0.6 : 0.35),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
