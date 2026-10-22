import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';
import '../home/providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: BloomAppBar(
        subtitle: 'Analiz & Gelişim',
        levelTitle: 'Genel Rapor',
        streakDays: 0,
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

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              children: [
                const SectionHeader(title: 'Genel İlerleme Özeti'),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'AKTİF TOHUMLAR',
                        value: '${activeHabits.length} Adet',
                        sub: 'Bahçede büyüyor',
                        icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: StatTile(
                        label: 'GENEL SAĞLIK',
                        value: '%100',
                        sub: 'Toprak nemli',
                        icon: Icon(Icons.local_fire_department, size: 16, color: AppColors.secondary),
                        valueColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                BloomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('DİNAMİK İRADE SKORU', color: AppColors.primary),
                      SizedBox(height: 8.h),
                      Text(
                        'Alışkanlıklarını her gün suladıkça güç skoru grafiğin ve yıllık zincirin şekillenecek.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      const InfoBox(
                        text: 'Güç Skoru Algoritması: Her sulanan gün +1 puan kazandırır, kaçırılan gün -1 puan eksiltir. Taban puan 0\'dır.',
                        tone: ChipTone.primary,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, stack) => Center(
            child: Text('Veriler yüklenirken hata oluştu: $err'),
          ),
        ),
      ),
    );
  }
}
