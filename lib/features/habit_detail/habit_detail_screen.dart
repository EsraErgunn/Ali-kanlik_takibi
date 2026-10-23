import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_key.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/habit.dart';
import '../../domain/habit_stats.dart';
import '../auth/providers.dart';
import '../home/providers.dart';
import 'widgets/annual_chain_calendar.dart';
import 'widgets/power_score_card.dart';
import 'widgets/weekly_bars_card.dart';
import '../../services/notification_service.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  final String habitId;

  Future<void> _updateReminderTime(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    final uid = ref.read(uidProvider);
    if (uid == null) return;

    final initialTime = habit.reminderTime != null
        ? TimeOfDay(
            hour: int.tryParse(habit.reminderTime!.split(':')[0]) ?? 20,
            minute: int.tryParse(habit.reminderTime!.split(':')[1]) ?? 0,
          )
        : const TimeOfDay(hour: 20, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final updated = habit.copyWith(reminderTime: formatted);
      await ref.read(habitRepositoryProvider).updateHabit(uid, updated);
      await NotificationService.instance.scheduleHabit(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hatırlatma saati $formatted olarak güncellendi.')),
        );
      }
    }
  }

  void _confirmArchive(BuildContext context, WidgetRef ref, Habit habit) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alışkanlığı Arşivle?'),
        content: Text('"${habit.title}" bahçeden kaldırılacak. 5 saniye içinde geri alabilirsin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Arşivle'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        final uid = ref.read(uidProvider);
        if (uid != null) {
          ref.read(habitRepositoryProvider).softDeleteHabit(uid, habit.id);
          NotificationService.instance.cancelHabit(habit.id);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${habit.title}" arşivlendi.'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Geri Al',
                  onPressed: () {
                    ref.read(habitRepositoryProvider).restoreHabit(uid, habit.id);
                    NotificationService.instance.scheduleHabit(habit);
                  },
                ),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitsAsync = ref.watch(habitsProvider);
    final logsAsync = ref.watch(habitLogsProvider(habitId));
    final user = ref.watch(appUserProvider).value;

    return habitsAsync.when(
      data: (habits) {
        final habit = habits.firstWhere(
          (h) => h.id == habitId,
          orElse: () => Habit(
            id: habitId,
            title: 'Alışkanlık',
            type: HabitType.build,
            icon: '🌱',
            color: AppColors.primary.toARGB32(),
            startDate: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );

        final logs = logsAsync.value ?? {};
        final now = DateTime.now();
        final streak = currentStreak(logs, now);
        final longest = longestStreak(logs);
        final totalCompleted = totalDone(logs);
        final monthlyPct = (monthlyRate(logs, habit.startDate, now) * 100).toInt();
        final weeklyPct = (weeklyRate(logs, habit.startDate, now) * 100).toInt();

        final habitColor = Color(habit.color);

        return Scaffold(
          appBar: BloomAppBar(
            showBack: true,
            titleText: habit.title,
            characterId: user?.characterId,
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              children: [
                // 1. Başlık & Canlı İzleme Sayaç Kartı
                _buildHeaderCard(context, habit, logs, now, streak, longest, totalCompleted, isDark),
                SizedBox(height: 16.h),

                // 2. Güç Skoru Çizgi Grafiği (LineChart)
                PowerScoreCard(
                  logs: logs,
                  startDate: habit.startDate,
                  now: now,
                  color: habitColor,
                ),
                SizedBox(height: 16.h),

                // 3. Haftalık Tamamlama Sütun Grafiği (BarChart)
                WeeklyBarsCard(
                  logs: logs,
                  now: now,
                  color: habitColor,
                ),
                SizedBox(height: 16.h),

                // 4. 30 Günlük Terrarium Matrisi
                _buildTerrariumMatrixCard(logs, habit.startDate, now, monthlyPct, weeklyPct, totalCompleted, isDark),
                SizedBox(height: 16.h),

                // 5. Yıllık Zincir Takvimi
                AnnualChainCalendar(
                  habit: habit,
                  habitLogs: logs,
                ),
                SizedBox(height: 16.h),

                // 6. Alışkanlık Rutini & Bildirimler
                BloomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('RUTİN & BİLDİRİMLER', color: AppColors.primary),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sulama & Hatırlatma Vakti',
                                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                habit.reminderTime != null
                                    ? '${habit.reminderTime} (Her Gün)'
                                    : 'Hatırlatma ayarlanmadı',
                                style: TextStyle(fontSize: 11.sp, color: AppColors.neutralVariant),
                              ),
                            ],
                          ),
                          StatusChip(
                            text: habit.reminderTime ?? 'Saat Seç',
                            tone: ChipTone.primary,
                            onTap: () => _updateReminderTime(context, ref, habit),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      InfoBox(
                        text: habit.type == HabitType.quit
                            ? 'Motivasyon: Bugün temiz kalarak ciğerlerini ve geleceğini korudun! 💪'
                            : 'Motivasyon: Zincirini bozma! Bir gün daha sulayarak tohumunu güçlendir. 🌱',
                        tone: ChipTone.neutral,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // 7. Tehlikeli Alan
                BloomCard(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                  borderColor: AppColors.secondary.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '⚠ Tehlikeli Alan',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                            ),
                          ),
                          StatusChip(text: 'Geri Alınabilir', tone: ChipTone.secondary),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Bu alışkanlığı arşivlediğinde verilerin korunur, 5 saniye içinde geri alabilirsin.',
                        style: TextStyle(fontSize: 11.sp, color: AppColors.neutralVariant),
                      ),
                      SizedBox(height: 12.h),
                      OutlinePillButton(
                        text: '🗑 Bu Alışkanlığı Arşivle / Kaldır',
                        tone: AppColors.secondary,
                        onPressed: () => _confirmArchive(context, ref, habit),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => Scaffold(
        body: SafeArea(child: Center(child: Text('Yüklenemedi: $e'))),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    Habit habit,
    LogMap logs,
    DateTime now,
    int streak,
    int longest,
    int totalCompleted,
    bool isDark,
  ) {
    final isQuit = habit.type == HabitType.quit;
    final elapsed = elapsedFor(habit, now);
    final days = elapsed.inDays;
    final hours = elapsed.inHours % 24;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    String two(int v) => v.toString().padLeft(2, '0');

    final stats = quitStats(
      cleanDays: totalCompleted,
      unitsPerDay: habit.unitsPerDay ?? 1,
      unitPrice: habit.unitPrice ?? 0.0,
    );

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(
                isQuit ? 'AKTİF İYİLEŞME ROTASI' : 'AKTİF BÜYÜME ROTASI',
                color: isQuit ? AppColors.secondary : AppColors.primary,
              ),
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Canlı İzleme',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(habit.icon, style: TextStyle(fontSize: 28.sp)),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  habit.title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                  ),
                ),
              ),
              StatusChip(
                text: isQuit ? 'Bırakma' : 'Kazanım',
                tone: isQuit ? ChipTone.secondary : ChipTone.primary,
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // 4 Box Elapsed Time
          Row(
            children: [
              _buildTimerBox('GÜN', two(days), isDark: isDark),
              SizedBox(width: 6.w),
              _buildTimerBox('SAAT', two(hours), isDark: isDark),
              SizedBox(width: 6.w),
              _buildTimerBox('DK', two(minutes), isDark: isDark),
              SizedBox(width: 6.w),
              _buildTimerBox('SN', two(seconds), isDark: isDark, isSecondary: true),
            ],
          ),
          SizedBox(height: 14.h),

          // 3 mini StatTiles
          if (isQuit)
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'TASARRUF',
                    value: '${stats.saved.toStringAsFixed(0)} ₺',
                    sub: '${habit.unitsPerDay ?? 1} paket/gün',
                    valueColor: AppColors.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'İÇİLMEYEN',
                    value: '${stats.avoided}',
                    sub: 'Temiz nefes',
                    valueColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: StatTile(
                    label: 'KALKAN',
                    value: '1 Hak',
                    sub: 'Zincir korur',
                    valueColor: AppColors.tertiary,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'TAMAMLAMA',
                    value: '$totalCompleted Gün',
                    sub: 'Tohum gücü',
                    valueColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'EN UZUN ZİNCİR',
                    value: '$longest Gün',
                    sub: 'Ateş disiplini',
                    valueColor: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: StatTile(
                    label: 'KALKAN',
                    value: '1 Hak',
                    sub: 'Zincir korur',
                    valueColor: AppColors.tertiary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }



  Widget _buildTerrariumMatrixCard(
    LogMap logs,
    DateTime start,
    DateTime now,
    int monthlyPct,
    int weeklyPct,
    int totalCompleted,
    bool isDark,
  ) {
    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const EyebrowLabel('30 GÜNLÜK TERRARIUM MATRİSİ', color: AppColors.primary),
              Text(
                '$totalCompleted / 30 Gün',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'AYLIK BAŞARI',
                  value: '%$monthlyPct',
                  sub: 'Verimli büyüme',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  label: 'HAFTALIK TAM',
                  value: '%$weeklyPct',
                  sub: 'Rutin dengesi',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 6-column 30-cell grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final dayNum = index + 1;
              final dayDate = DateKey.addDays(DateKey.dateOnly(start), index);
              final isFuture = dayDate.isAfter(DateKey.dateOnly(now));
              final status = logs[DateKey.of(dayDate)];

              Color cellColor;
              Color textColor = isDark ? AppColors.darkNeutral : AppColors.neutral;

              if (isFuture) {
                cellColor = isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted;
                textColor = (isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant).withValues(alpha: 0.5);
              } else if (status == 'done') {
                cellColor = AppColors.primary;
                textColor = Colors.white;
              } else if (status == 'frozen' || status == 'partial') {
                cellColor = AppColors.primaryContainer;
                textColor = AppColors.primaryDark;
              } else if (status == 'relapse') {
                cellColor = AppColors.secondaryContainer;
                textColor = AppColors.secondary;
              } else {
                cellColor = isDark ? const Color(0xFF332A26) : AppColors.secondaryContainer.withValues(alpha: 0.5);
                textColor = AppColors.secondary;
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 8.h),
          Center(
            child: Text(
              'Düşük Yoğunluk ●●●● Tam İrade (Bloom)',
              style: TextStyle(fontSize: 10.sp, color: AppColors.neutralVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBox(String unit, String val, {required bool isDark, bool isSecondary = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSecondary
              ? AppColors.secondaryContainer.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSecondary
                ? AppColors.secondary.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkOutline : AppColors.outline),
          ),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: isSecondary ? AppColors.secondary : (isDark ? AppColors.darkNeutral : AppColors.neutral),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: isSecondary ? AppColors.secondary : AppColors.neutralVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
