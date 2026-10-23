import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/habit_stats.dart';

/// Card showing habit completion distribution by day of the week (Monday to Sunday).
class DayOfWeekCard extends StatelessWidget {
  const DayOfWeekCard({
    super.key,
    required this.logs,
    this.eyebrow = 'GÜN RİTMİ & PERFORMANS',
    this.title = 'Haftalık Gün Dağılımı',
  });

  final LogMap logs;
  final String eyebrow;
  final String title;

  static const _dayNames = [
    'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'
  ];

  static const _fullDayNames = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distribution = weekdayDistribution(logs); // Map<int, int> 1..7

    var maxCount = 0;
    var bestDayIndex = 0;
    var totalCompletions = 0;

    for (var i = 1; i <= 7; i++) {
      final count = distribution[i] ?? 0;
      totalCompletions += count;
      if (count > maxCount) {
        maxCount = count;
        bestDayIndex = i - 1;
      }
    }

    final hasData = totalCompletions > 0;
    final maxY = hasData ? (maxCount + 2).toDouble() : 5.0;

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(eyebrow, color: AppColors.primary),
              if (hasData)
                StatusChip(
                  text: '👑 En Verimli: ${_fullDayNames[bestDayIndex]}',
                  tone: ChipTone.primary,
                )
              else
                const StatusChip(
                  text: 'Ritim Bekleniyor',
                  tone: ChipTone.neutral,
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkNeutral : AppColors.neutral,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 150.h,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 5 ? (maxY / 4).roundToDouble().clamp(1.0, 50.0) : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (isDark ? AppColors.darkOutline : AppColors.outline).withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24.w,
                      interval: maxY > 5 ? (maxY / 4).roundToDouble().clamp(1.0, 50.0) : 1,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          val.toInt().toString(),
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= _dayNames.length) return const SizedBox.shrink();
                        final isBest = hasData && idx == bestDayIndex;
                        return Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            _dayNames[idx],
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: isBest ? FontWeight.w800 : FontWeight.w600,
                              color: isBest
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (idx) {
                  final dayNumber = idx + 1;
                  final count = distribution[dayNumber] ?? 0;
                  final isBest = hasData && idx == bestDayIndex;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        width: 16.w,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
                        color: isBest
                            ? AppColors.primary
                            : (count > 0
                                ? AppColors.primary.withValues(alpha: 0.55)
                                : (isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          InfoBox(
            text: hasData
                ? 'Haftalık ritminde en istikrarlı olduğun gün ${_fullDayNames[bestDayIndex]} ($maxCount sulama). Bu ivmeyi haftanın geneline yaymaya odaklanabilirsin.'
                : 'Alışkanlıklarını tamamladıkça hangi günlerde daha üretken olduğunu burada keşfedeceksin.',
            tone: ChipTone.primary,
          ),
        ],
      ),
    );
  }
}
