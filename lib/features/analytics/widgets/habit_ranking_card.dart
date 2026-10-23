import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/habit.dart';
import '../../../domain/habit_stats.dart';

/// Performance ranking card displaying active habits sorted by streak and completion rate.
class HabitRankingCard extends StatelessWidget {
  const HabitRankingCard({
    super.key,
    required this.habits,
    required this.logsByHabit,
    required this.now,
    this.eyebrow = 'BİREYSEL PERFORMANS',
    this.title = 'Tohum Karnesi & İrade Sıralaması',
  });

  final List<Habit> habits;
  final Map<String, LogMap> logsByHabit;
  final DateTime now;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeHabits = habits.where((h) => !h.isDeleted).toList();

    // Map each habit with its stats and sort by streak descending, then total done
    final ranked = activeHabits.map((h) {
      final logs = logsByHabit[h.id] ?? {};
      final streak = currentStreak(logs, now);
      final total = totalDone(logs);
      final rate = completionRate(logs, h.startDate, now, h.startDate, now);
      return (
        habit: h,
        streak: streak,
        totalDone: total,
        rate: rate,
      );
    }).toList()
      ..sort((a, b) {
        final streakCmp = b.streak.compareTo(a.streak);
        if (streakCmp != 0) return streakCmp;
        return b.totalDone.compareTo(a.totalDone);
      });

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(eyebrow, color: AppColors.primary),
              StatusChip(
                text: '${activeHabits.length} Tohum Değerlendirildi',
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
          SizedBox(height: 12.h),
          if (ranked.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              alignment: Alignment.center,
              child: Text(
                'Değerlendirilecek aktif tohum bulunmuyor.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ranked.length,
              separatorBuilder: (context, index) => Divider(
                height: 16.h,
                color: isDark ? AppColors.darkOutline : AppColors.outline,
              ),
              itemBuilder: (context, index) {
                final item = ranked[index];
                final rank = index + 1;
                final habit = item.habit;
                final streak = item.streak;
                final ratePct = (item.rate * 100).toInt();

                // Medal or rank style
                final String rankLabel;
                final Color rankBg;
                final Color rankTextColor;

                if (rank == 1) {
                  rankLabel = '🥇';
                  rankBg = AppColors.tertiaryContainer;
                  rankTextColor = AppColors.tertiary;
                } else if (rank == 2) {
                  rankLabel = '🥈';
                  rankBg = isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted;
                  rankTextColor = isDark ? AppColors.darkNeutral : AppColors.neutral;
                } else if (rank == 3) {
                  rankLabel = '🥉';
                  rankBg = AppColors.secondaryContainer;
                  rankTextColor = AppColors.secondary;
                } else {
                  rankLabel = '#$rank';
                  rankBg = Colors.transparent;
                  rankTextColor = isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant;
                }

                return InkWell(
                  onTap: () => context.push('/habit/${habit.id}'),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Rank Badge
                            Container(
                              width: 28.r,
                              height: 28.r,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: rankBg,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                rankLabel,
                                style: TextStyle(
                                  fontSize: rank <= 3 ? 14.sp : 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: rankTextColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),

                            // Habit Icon
                            Container(
                              width: 32.r,
                              height: 32.r,
                              decoration: BoxDecoration(
                                color: Color(habit.color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Center(
                                child: Text(
                                  habit.icon,
                                  style: TextStyle(fontSize: 16.sp),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),

                            // Habit Name & Type
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit.title,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    habit.type == HabitType.quit
                                        ? 'Bırakma / Arınma 🛡'
                                        : (habit.type == HabitType.count
                                            ? 'Sayaçlı Hedef 💧'
                                            : 'Kazanım Tohumu 🌿'),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Streak Badge
                            StatusChip(
                              text: '🔥 $streak Gün',
                              tone: streak >= 7 ? ChipTone.secondary : ChipTone.neutral,
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),

                        // Progress Bar & Percentage
                        Row(
                          children: [
                            SizedBox(width: 38.w), // Indent past rank
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.r),
                                child: LinearProgressIndicator(
                                  value: item.rate.clamp(0.0, 1.0),
                                  minHeight: 5.h,
                                  backgroundColor: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ratePct >= 75
                                        ? AppColors.primary
                                        : (ratePct >= 50 ? AppColors.tertiary : AppColors.secondary),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '%$ratePct Verim · ${item.totalDone} Gün',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          SizedBox(height: 12.h),
          const InfoBox(
            text: 'Detaylı analiz, terrarium matrisi ve hatırlatma ayarlarına ulaşmak için herhangi bir tohuma dokunabilirsin.',
            tone: ChipTone.neutral,
          ),
        ],
      ),
    );
  }
}
