import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/habit.dart';
import '../../../domain/habit_stats.dart';
import '../../home/providers.dart';
import 'chain_day_painter.dart';

class AnnualChainCalendar extends ConsumerStatefulWidget {
  const AnnualChainCalendar({
    super.key,
    this.habit,
    required this.habitLogs,
    this.startDate,
    this.title = 'Zinciri Kırma',
    this.eyebrow = 'YILLIK ZİNCİR',
  });

  final Habit? habit;
  final LogMap habitLogs;
  final DateTime? startDate;
  final String title;
  final String eyebrow;

  @override
  ConsumerState<AnnualChainCalendar> createState() => _AnnualChainCalendarState();
}

class _AnnualChainCalendarState extends ConsumerState<AnnualChainCalendar> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  DateTime get _effectiveStartDate =>
      widget.startDate ?? widget.habit?.startDate ?? DateTime(DateTime.now().year, 1, 1);


  void _showDayDetails(BuildContext context, CalendarDay day) {
    final dateStr = DateFormat('d MMMM yyyy EEEE', 'tr_TR').format(day.date);
    final statusText = switch (day.mark) {
      DayMark.done => 'Tamamlandı ✓ (Zincir halkası eklendi)',
      DayMark.relapse => 'Kaydın günü ⚠ (Alev sıfırlandı)',
      DayMark.frozen => 'Kalkanla Korundu 🛡 (Zincir kurtarıldı)',
      DayMark.missed => 'Kaçırıldı ✗',
      DayMark.beforeStart => 'Başlangıç tarihinden önce',
      DayMark.future => 'Gelecek gün',
      DayMark.none => 'Bugün henüz sulanmadı',
    };

    final statusTone = switch (day.mark) {
      DayMark.done => ChipTone.primary,
      DayMark.relapse => ChipTone.secondary,
      DayMark.frozen => ChipTone.tertiary,
      _ => ChipTone.neutral,
    };

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                    ),
                    StatusChip(
                      text: day.mark.name.toUpperCase(),
                      tone: statusTone,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.neutralVariant),
                ),
                SizedBox(height: 16.h),
                PrimaryPillButton(
                  text: 'Kapat',
                  height: 44.h,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final startYear = _effectiveStartDate.year;
    final canGoNext = _selectedYear < now.year;
    final canGoPrev = _selectedYear > startYear;

    final habit = widget.habit;
    final yearLogsAsync = habit != null
        ? ref.watch(
            yearLogsProvider((habitId: habit.id, year: _selectedYear)),
          )
        : null;

    final mergedLogs = <String, String>{
      ...widget.habitLogs,
      ...?yearLogsAsync?.value,
    };

    // Calculate annual statistics
    final yearEnd = DateTime(_selectedYear, 12, 31);
    final eligibleEnd = now.isBefore(yearEnd) ? now : yearEnd;
    final startOfCheck = _effectiveStartDate.isAfter(DateTime(_selectedYear, 1, 1))
        ? _effectiveStartDate
        : DateTime(_selectedYear, 1, 1);


    var eligibleDays = DateKey.daysBetween(DateKey.dateOnly(startOfCheck), DateKey.dateOnly(eligibleEnd)) + 1;
    if (eligibleDays < 1) eligibleDays = 1;

    final doneThisYear = mergedLogs.entries.where((e) {
      if (e.value != 'done') return false;
      final d = DateKey.parse(e.key);
      return d.year == _selectedYear;
    }).length;

    final percent = ((doneThisYear / eligibleDays) * 100).toInt().clamp(0, 100);
    final longestChain = longestStreak(mergedLogs);
    final activeChain = currentStreak(mergedLogs, now);

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(widget.eyebrow, color: AppColors.primary),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: canGoPrev
                        ? () => setState(() => _selectedYear--)
                        : null,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$_selectedYear',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: canGoNext
                        ? () => setState(() => _selectedYear++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkNeutral : AppColors.neutral,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Bu yıl $doneThisYear gün (%$percent) · En uzun $longestChain · Aktif $activeChain 🔥',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralVariant,
            ),
          ),
          SizedBox(height: 16.h),

          // 12 months grid
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w < 340 ? 1 : (w < 580 ? 2 : 3);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.95,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  return _buildMonthWidget(
                    year: _selectedYear,
                    month: month,
                    logs: mergedLogs,
                    start: _effectiveStartDate,
                    today: now,
                    isDark: isDark,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthWidget({
    required int year,
    required int month,
    required LogMap logs,
    required DateTime start,
    required DateTime today,
    required bool isDark,
  }) {
    final monthName = DateFormat('MMMM', 'tr_TR').format(DateTime(year, month, 1));
    final days = buildMonth(year, month, logs, start, today);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon ... 7=Sun
    final blankCells = firstWeekday - 1;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.outline,
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkNeutral : AppColors.neutral,
              ),
            ),
            SizedBox(height: 4.h),
            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'].map((d) {
                return Text(
                  d,
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemCount: blankCells + days.length,
                itemBuilder: (context, idx) {
                  if (idx < blankCells) {
                    return const SizedBox();
                  }
                  final day = days[idx - blankCells];
                  return GestureDetector(
                    onTap: () => _showDayDetails(context, day),
                    child: CustomPaint(
                      painter: ChainDayPainter(
                        day: day,
                        color: widget.habit != null ? Color(widget.habit?.color ?? 0xFF1B6B48) : AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
