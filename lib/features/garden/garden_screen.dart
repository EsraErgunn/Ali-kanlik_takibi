import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/plant_stage.dart';
import '../auth/providers.dart';
import '../home/widgets/swaying_plant.dart';

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final user = userAsync.value;
    final gardenStart = user?.gardenStartDate ?? DateTime.now();
    final plantInfo = plantFor(gardenStart, DateTime.now());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: BloomAppBar(
        showBack: true,
        titleText: 'Çiçek Bahçem',
        characterId: user?.characterId,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            // Header Hero
            BloomCard(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        colorScheme.surface,
                        colorScheme.primaryContainer.withValues(alpha: 0.5),
                      ]
                    : [
                        colorScheme.primaryContainer.withValues(alpha: 0.6),
                        colorScheme.surface,
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      EyebrowLabel('30 GÜNLÜK DÖNGÜLER', color: colorScheme.primary),
                      StatusChip(
                        text: '🌸 ${plantInfo.completedCycles} Çiçek',
                        tone: ChipTone.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    plantInfo.completedCycles > 0
                        ? 'Her 30 günde bir açan kalıcı çiçeklerin bahçende rüzgarla dans ediyor.'
                        : 'İlk çiçeğin tohumdan yeşeriyor. 30 günü tamamladığında bahçene eklenecek!',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            if (plantInfo.completedCycles > 0) ...[
              const SectionHeader(
                title: 'Açan Çiçekler',
                icon: Text('🌸'),
              ),
              SizedBox(height: 10.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width < 360 ? 2 : 3,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.85,
                ),
                itemCount: plantInfo.completedCycles,
                itemBuilder: (context, index) {
                  return BloomCard(
                    padding: EdgeInsets.all(8.r),
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 70.h,
                          child: Center(
                            child: SwayingPlant(
                              stage: PlantStage.flower,
                              height: 65.h,
                              phaseOffset: index * 0.7,
                              duration: Duration(milliseconds: 2600 + (index % 4) * 400),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '${index + 1}. Ay Çiçeği',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        const StatusChip(
                          text: '30 Gün ✓',
                          tone: ChipTone.primary,
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),
            ],

            // Active Cycle in Progress
            const SectionHeader(
              title: 'Gelişmekte Olan Çiçek',
              icon: Text('🌱'),
            ),
            SizedBox(height: 8.h),
            BloomCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 110.h,
                    child: Center(
                      child: SwayingPlant(
                        stage: plantInfo.stage,
                        height: 100.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Şimdiki Aşama: ${plantInfo.stage.title}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? colorScheme.primary : AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        '${30 - plantInfo.dayInCycle} Gün Kaldı',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ProgressPill(value: plantInfo.cycleProgress),
                  SizedBox(height: 12.h),
                  InfoBox(
                    text: 'Her gün tek dokunuşla alışkanlıklarını sula. Döngü bittiğinde bahçene yeni bir kalıcı çiçek açacak!',
                    tone: ChipTone.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
