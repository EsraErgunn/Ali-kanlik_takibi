import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/habit.dart';
import '../../../data/models/habit_log.dart';
import '../../../domain/habit_stats.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class HabitCardItem extends ConsumerWidget {
  const HabitCardItem({
    super.key,
    required this.habit,
    required this.todayLog,
    required this.logs,
  });

  final Habit habit;
  final HabitLog? todayLog;
  final LogMap logs;

  void _onTap(BuildContext context) {
    context.push('/habit/${habit.id}');
  }

  void _markDone(WidgetRef ref, BuildContext context) {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    HapticFeedback.mediumImpact();
    ref.read(habitRepositoryProvider).markToday(uid, habit.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${habit.title}" sulandı! 💧'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () {
            ref.read(habitRepositoryProvider).unmarkToday(uid, habit.id);
          },
        ),
      ),
    );
  }

  void _incrementCount(WidgetRef ref) {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    HapticFeedback.lightImpact();
    ref.read(habitRepositoryProvider).incrementCount(
          uid,
          habit.id,
          habit.dailyTarget ?? 1,
        );
  }

  void _confirmRelapse(WidgetRef ref, BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydın mı?'),
        content: Text(
          'Dürüstlüğün için tebrikler. Bugünün kaydı "relapse" olarak işaretlenecek ve sayacın sıfırlanacak. Unutma, her an yeniden başlayabilirsin!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Kaydım'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        final uid = ref.read(uidProvider);
        if (uid != null) {
          ref.read(habitRepositoryProvider).recordRelapse(uid, habit.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompletedToday = todayLog?.status == 'done';
    final streak = currentStreak(logs, DateTime.now());

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.only(right: 20.w),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Alışkanlığı sil?'),
          content: Text('"${habit.title}" ve zinciri arşivlenecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sil'),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        final uid = ref.read(uidProvider);
        if (uid != null) {
          ref.read(habitRepositoryProvider).softDeleteHabit(uid, habit.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${habit.title}" silindi.'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Geri Al',
                onPressed: () {
                  ref.read(habitRepositoryProvider).restoreHabit(uid, habit.id);
                },
              ),
            ),
          );
        }
      },
      child: BloomCard(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        onTap: () => _onTap(context),
        child: switch (habit.type) {
          HabitType.quit => _buildQuitCard(context, ref, isDark, isCompletedToday, streak),
          HabitType.count => _buildCountCard(context, ref, isDark, isCompletedToday, streak),
          HabitType.build => _buildBuildCard(context, ref, isDark, isCompletedToday, streak),
        },
      ),
    );
  }

  Widget _buildBuildCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isCompletedToday,
    int streak,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: Color(habit.color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(habit.icon, style: TextStyle(fontSize: 22.sp)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      const StatusChip(
                        text: 'Kazanım 🌱',
                        tone: ChipTone.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    habit.targetLabel ??
                        (habit.reminderTime != null ? 'Saat: ${habit.reminderTime}' : 'Günlük Ritüel'),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            // Completion Check Button
            GestureDetector(
              onTap: isCompletedToday ? null : () => _markDone(ref, context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompletedToday ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: isCompletedToday
                    ? Icon(Icons.check_rounded, color: Colors.white, size: 22.r)
                    : null,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '⚡ $streak Gün Zincir ${streak >= 7 ? '(Harika Gidiyorsun!)' : ''}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (isCompletedToday)
              Text(
                'Tamamlandı ✓',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuitCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isCompletedToday,
    int streak,
  ) {
    final cleanDays = totalDone(logs);
    final stats = quitStats(
      cleanDays: cleanDays,
      unitsPerDay: habit.unitsPerDay ?? 1,
      unitPrice: habit.unitPrice ?? 0.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(habit.icon, style: TextStyle(fontSize: 22.sp)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      const StatusChip(
                        text: 'Bırakma',
                        tone: ChipTone.secondary,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '🔥 $streak Gün Zincir • ${stats.saved.toStringAsFixed(0)}₺ Tasarruf 💰',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutralVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // Live timer ticker container
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CANLI SAYAÇ:',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                ),
              ),
              ElapsedTicker(
                since: habit.lastRelapseAt ?? habit.startDate,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Actions: "Bugün Temizim" + "Kaydım"
        Row(
          children: [
            Expanded(
              flex: 3,
              child: PrimaryPillButton(
                text: isCompletedToday ? '✓ Bugün Temiz' : '✓ Bugün Temizim',
                height: 44.h,
                color: isCompletedToday ? AppColors.primaryDark : AppColors.primary,
                onPressed: isCompletedToday ? null : () => _markDone(ref, context),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 2,
              child: OutlinePillButton(
                text: '◇ Kaydım',
                height: 44.h,
                tone: AppColors.secondary,
                onPressed: () => _confirmRelapse(ref, context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isCompletedToday,
    int streak,
  ) {
    final currentCount = todayLog?.count ?? 0;
    final target = habit.dailyTarget ?? 1;
    final progress = (currentCount / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: Color(habit.color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(habit.icon, style: TextStyle(fontSize: 22.sp)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      const StatusChip(
                        text: 'Sayaçlı 🌱',
                        tone: ChipTone.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '$currentCount / $target ${habit.unit ?? 'Adet'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            StatusChip(
              text: isCompletedToday ? 'Hedef Tamamlandı ✓' : '+ 1 ${habit.unit ?? 'Adet'}',
              tone: isCompletedToday ? ChipTone.primary : ChipTone.neutral,
              onTap: isCompletedToday ? null : () => _incrementCount(ref),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        ProgressPill(
          value: progress,
          color: isCompletedToday ? AppColors.primary : AppColors.tertiary,
        ),
      ],
    );
  }
}
