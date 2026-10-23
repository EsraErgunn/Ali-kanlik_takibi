import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/habit_stats.dart';

class PowerScoreCard extends StatelessWidget {
  const PowerScoreCard({
    super.key,
    required this.logs,
    required this.startDate,
    required this.now,
    this.color = AppColors.primary,
    this.eyebrow = 'DİNAMİK İRADE GRAFİĞİ',
    this.title = 'Güç Skoru İlerlemesi',
    this.explanation = 'Güç Skoru Algoritması: Her temiz gün +1 puan kazandırır, kaçırılan gün -1 puan eksiltir. Taban puan 0\'dır, asla negatife inmez.',
  });

  final LogMap logs;
  final DateTime startDate;
  final DateTime now;
  final Color color;
  final String eyebrow;
  final String title;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final series = strengthSeries(logs, startDate, now);
    // Take last 30 points
    final spotsData = series.length > 30 ? series.sublist(series.length - 30) : series;
    final currentScore = spotsData.isNotEmpty ? spotsData.last : 0;
    final peakScore = spotsData.isNotEmpty ? spotsData.reduce((a, b) => a > b ? a : b) : 0;

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(eyebrow, color: color),
              StatusChip(text: '🔥 Kararlı İrade ($currentScore)', tone: ChipTone.secondary),
            ],
          ),
          SizedBox(height: 6.h),
          StatusChip(text: '🚩 Tepe: $peakScore Puan', tone: ChipTone.primary),
          SizedBox(height: 12.h),
          if (spotsData.length < 2)
            Container(
              height: 180.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: Text(
                  'Birkaç gün sonra burada gelişimini göreceksin.',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.neutralVariant),
                ),
              ),
            )
          else
            SizedBox(
              height: 200.h,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < spotsData.length; i++)
                          FlSpot(i.toDouble(), spotsData[i].toDouble()),
                      ],
                      isCurved: true,
                      preventCurveOverShooting: true,
                      barWidth: 3,
                      color: color,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 10.h),
          InfoBox(
            text: explanation,
            tone: ChipTone.primary,
          ),
        ],
      ),
    );
  }
}
