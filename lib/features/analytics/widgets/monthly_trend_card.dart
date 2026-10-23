import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/habit_stats.dart';

/// Smooth curved line chart showing the 6-month growth curve of habit completions.
class MonthlyTrendCard extends StatelessWidget {
  const MonthlyTrendCard({
    super.key,
    required this.logs,
    required this.now,
    this.eyebrow = 'UZUN VADELİ GELİŞİM',
    this.title = 'Aylık Sulama Trendi',
  });

  final LogMap logs;
  final DateTime now;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trend = monthlyTrend(logs, now); // 6 elements

    var maxCount = 0;
    var totalSixMonths = 0;
    for (final item in trend) {
      totalSixMonths += item.count;
      if (item.count > maxCount) {
        maxCount = item.count;
      }
    }

    final hasData = totalSixMonths > 0;
    final maxY = hasData ? (maxCount + 2).toDouble() : 5.0;
    final thisMonthCount = trend.isNotEmpty ? trend.last.count : 0;

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(eyebrow, color: AppColors.tertiary),
              StatusChip(
                text: 'Bu Ay: $thisMonthCount Sulama',
                tone: ChipTone.tertiary,
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
            height: 160.h,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
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
                        if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                        final isCurrent = idx == trend.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            trend[idx].label,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isCurrent
                                  ? AppColors.tertiary
                                  : (isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < trend.length; i++)
                        FlSpot(i.toDouble(), trend[i].count.toDouble()),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    curveSmoothness: 0.35,
                    barWidth: 3,
                    color: AppColors.tertiary,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isLast = index == trend.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 4.5 : 3.0,
                          color: isLast ? AppColors.tertiary : Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.tertiary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.tertiary.withValues(alpha: 0.28),
                          AppColors.tertiary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          InfoBox(
            text: hasData
                ? 'Son 6 ayda toplam $totalSixMonths kez tohumlarını suladın. Mevsimsel döngülerde disiplinini canlı tutuyorsun.'
                : 'Aylar ilerledikçe uzun vadeli alışkanlık birikiminin yükselen eğrisini burada izleyeceksin.',
            tone: ChipTone.tertiary,
          ),
        ],
      ),
    );
  }
}
