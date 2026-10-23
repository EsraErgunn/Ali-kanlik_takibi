import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/habit_stats.dart';
import '../habit_detail/widgets/annual_chain_calendar.dart';
import '../habit_detail/widgets/power_score_card.dart';
import '../habit_detail/widgets/weekly_bars_card.dart';
import '../home/providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final combinedLogs = ref.watch(combinedLogsProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final level = levelFor(totalXp(overallStats.totalCompletedDays * 10));

    return Scaffold(
      appBar: BloomAppBar(
        subtitle: 'Analiz & Gelişim',
        levelTitle: 'Seviye ${level.level} ${level.title}',
        streakDays: overallStats.longestStreak,
        onAvatarTap: () => context.go('/profile'),
      ),
      body: SafeArea(
        top: false,
        child: habitsAsync.when(
          data: (habits) {
            final activeHabits = habits.where((h) => !h.isDeleted).toList();

            if (activeHabits.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                  child: BloomCard(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64.r,
                          height: 64.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer.withValues(alpha: 0.7),
                          ),
                          child: Center(
                            child: Text('🌱', style: TextStyle(fontSize: 32.sp)),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        const StatusChip(
                          text: 'Yakında Filizlenecek',
                          tone: ChipTone.tertiary,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Analizler Yakında Burada',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Henüz dikilmiş bir tohumun yok. İlk alışkanlığını dikip düzenli suladıkça irade grafikleri ve yıllık zincir takvimin burada sergilenecek.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20.h),
                        PrimaryPillButton(
                          text: 'İlk Tohumunu Dik 🌱',
                          onPressed: () => context.push('/new-habit'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final earliestStart = activeHabits
                .map((h) => h.startDate)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            final now = DateTime.now();

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              children: [
                // 1. Özet İstatistik Kartları (2x2 Grid)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 1.25,
                  children: [
                    StatTile(
                      label: 'AKTİF TOHUMLAR',
                      value: '${activeHabits.length} Adet',
                      sub: 'Bahçede büyüyor',
                      icon: const Icon(Icons.eco_rounded, size: 16, color: AppColors.primary),
                    ),
                    StatTile(
                      label: 'GENEL BAŞARI',
                      value: '${(overallStats.successRate * 100).toInt()}%',
                      sub: overallStats.successRate >= 0.7 ? 'Yüksek verim' : 'İrade gelişiyor',
                      icon: const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                    ),
                    StatTile(
                      label: 'EN UZUN ZİNCİR',
                      value: '${overallStats.longestStreak} Gün',
                      sub: 'Tüm zamanların rekoru',
                      icon: const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.secondary),
                      valueColor: AppColors.secondary,
                    ),
                    StatTile(
                      label: 'TOPLAM SULAMA',
                      value: '${overallStats.totalCompletedDays} Gün',
                      sub: 'Başarılı ritüel',
                      icon: const Icon(Icons.water_drop_rounded, size: 16, color: AppColors.tertiary),
                      valueColor: AppColors.tertiary,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // 2. Birleşik Güç Skoru Çizgi Grafiği (Dinamik İrade)
                PowerScoreCard(
                  logs: combinedLogs,
                  startDate: earliestStart,
                  now: now,
                  eyebrow: 'BİRLEŞİK GÜÇ SKORU',
                  title: 'Tüm Alışkanlıkların İrade Eğrisi',
                  explanation: 'Tüm tohumlarının birleşik güç skoru: En az bir alışkanlığın tamamlandığı günler +1 puan, kaçırılan günler -1 puan olarak hesaplanır.',
                ),
                SizedBox(height: 16.h),

                // 3. Birleşik Haftalık Tamamlama Sütun Grafiği
                WeeklyBarsCard(
                  logs: combinedLogs,
                  now: now,
                  eyebrow: 'BİRLEŞİK HAFTALIK SÜRDÜRÜLEBİLİRLİK',
                ),
                SizedBox(height: 16.h),

                // 4. Genel Yıllık Zincir Takvimi (Reused AnnualChainCalendar)
                AnnualChainCalendar(
                  habitLogs: combinedLogs,
                  startDate: earliestStart,
                  title: 'Genel Bahçe Yıllık Zinciri',
                  eyebrow: 'GENEL YILLIK ZİNCİR',
                ),
                SizedBox(height: 24.h),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) => Center(
            child: Text('Veriler yüklenirken hata oluştu: $err'),
          ),
        ),
      ),
    );
  }
}
