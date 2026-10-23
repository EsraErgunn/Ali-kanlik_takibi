import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/habit.dart';
import '../../../domain/habit_stats.dart';

/// Donut chart showing distribution of habit types in the garden.
class HabitsBalanceCard extends StatelessWidget {
  const HabitsBalanceCard({
    super.key,
    required this.habits,
    this.eyebrow = 'TOHUM DENGESİ',
    this.title = 'Kategori & Tür Dağılımı',
  });

  final List<Habit> habits;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeHabits = habits.where((h) => !h.isDeleted).toList();
    final counts = habitTypeDistribution(activeHabits);
    final total = counts.build + counts.quit + counts.count;

    final buildPct = total > 0 ? ((counts.build / total) * 100).round() : 0;
    final quitPct = total > 0 ? ((counts.quit / total) * 100).round() : 0;
    final countPct = total > 0 ? ((counts.count / total) * 100).round() : 0;

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(eyebrow, color: AppColors.primary),
              StatusChip(
                text: '$total Tohum Dikili',
                tone: ChipTone.primary,
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
          SizedBox(height: 16.h),
          if (total == 0)
            Container(
              height: 140.h,
              alignment: Alignment.center,
              child: Text(
                'Henüz ekilmiş tohum bulunmuyor.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                ),
              ),
            )
          else
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: 130.r,
                  height: 130.r,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 38.r,
                          sections: [
                            if (counts.build > 0)
                              PieChartSectionData(
                                value: counts.build.toDouble(),
                                color: AppColors.primary,
                                radius: 20.r,
                                showTitle: false,
                              ),
                            if (counts.quit > 0)
                              PieChartSectionData(
                                value: counts.quit.toDouble(),
                                color: AppColors.secondary,
                                radius: 20.r,
                                showTitle: false,
                              ),
                            if (counts.count > 0)
                              PieChartSectionData(
                                value: counts.count.toDouble(),
                                color: AppColors.tertiary,
                                radius: 20.r,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🌱', style: TextStyle(fontSize: 18.sp)),
                          Text(
                            '$total',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                            ),
                          ),
                          Text(
                            'Tohum',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 18.w),

                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendItem(
                        color: AppColors.primary,
                        title: 'Kazanım Tohumu',
                        count: counts.build,
                        percentage: buildPct,
                        icon: '🌿',
                      ),
                      SizedBox(height: 10.h),
                      _LegendItem(
                        color: AppColors.secondary,
                        title: 'Bırakma / Arınma',
                        count: counts.quit,
                        percentage: quitPct,
                        icon: '🛡',
                      ),
                      SizedBox(height: 10.h),
                      _LegendItem(
                        color: AppColors.tertiary,
                        title: 'Sayaçlı Hedef',
                        count: counts.count,
                        percentage: countPct,
                        icon: '💧',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: 14.h),
          const InfoBox(
            text: 'Dengeli bir bahçe hem yeni erdemler yeşertmeyi (Kazanım) hem de zararlı alışkanlıkları budamayı (Bırakma) gerektirir.',
            tone: ChipTone.primary,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.title,
    required this.count,
    required this.percentage,
    required this.icon,
  });

  final Color color;
  final String title;
  final int count;
  final int percentage;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                ),
              ),
              Text(
                '$count adet (%$percentage)',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
