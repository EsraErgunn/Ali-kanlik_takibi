import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  final String habitId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BloomAppBar(
        showBack: true,
        titleText: 'Alışkanlık Detayı',
        subtitle: 'Canlı Takip & İrade',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            // 1. Başlık ve Canlı Sayaç Kartı
            BloomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const EyebrowLabel('AKTİF İYİLEŞME ROTASI', color: AppColors.primary),
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
                      Text('🌱', style: TextStyle(fontSize: 28.sp)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Sigarayı Bırakma',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                          ),
                        ),
                      ),
                      const StatusChip(
                        text: 'Bırakma',
                        tone: ChipTone.secondary,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Elapsed Ticker boxes
                  Row(
                    children: [
                      _buildTimerBox('GÜN', '00', isDark: isDark),
                      SizedBox(width: 6.w),
                      _buildTimerBox('SAAT', '00', isDark: isDark),
                      SizedBox(width: 6.w),
                      _buildTimerBox('DK', '00', isDark: isDark),
                      SizedBox(width: 6.w),
                      _buildTimerBox('SN', '00', isDark: isDark, isSecondary: true),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // 3 mini StatTiles
                  Row(
                    children: const [
                      Expanded(
                        child: StatTile(
                          label: 'TASARRUF',
                          value: '0,00 ₺',
                          sub: '0 paket',
                          valueColor: AppColors.tertiary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          label: 'İÇİLMEYEN',
                          value: '0 adet',
                          sub: 'Temiz nefes',
                          valueColor: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
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
            ),
            SizedBox(height: 16.h),

            // 2. Güç Skoru İlerlemesi
            BloomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      EyebrowLabel('DİNAMİK İRADE GRAFİĞİ', color: AppColors.primary),
                      StatusChip(text: '🔥 Kararlı İrade', tone: ChipTone.secondary),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    height: 180.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: Text(
                        'İrade grafiği birkaç gün içinde oluşacaktır.',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.neutralVariant),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  const InfoBox(
                    text: 'Güç Skoru Algoritması: Her temiz gün +1 puan kazandırır, kaçırılan gün -1 puan eksiltir. Taban puan 0\'dır, asla negatife inmez.',
                    tone: ChipTone.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 3. Haftalık Tamamlama Barları
            BloomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      EyebrowLabel('SÜRDÜRÜLEBİLİRLİK', color: AppColors.primary),
                      Text('0/7 Gün · %0 Başarı', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: Text(
                        'Son 8 haftanın tamamlama barları',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.neutralVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 4. 30 Günlük Terrarium Matrisi
            BloomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      EyebrowLabel('30 GÜNLÜK TERRARIUM MATRİSİ', color: AppColors.primary),
                      Text('0 / 30 Gün', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Döngüdeki her günün durumunu renk yoğunluğuyla izle.',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.neutralVariant),
                  ),
                  SizedBox(height: 12.h),
                  // 6-column 1-30 matrix
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
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isDark ? AppColors.darkOutline : AppColors.outline,
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutralVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 5. Yıllık Zincir Takvimi
            BloomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const EyebrowLabel('YILLIK ZİNCİR', color: AppColors.primary),
                      Text(
                        '‹ 2026 ›',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Zinciri Kırma: Tamamlanan her gün kırmızı X ile bağlanır.',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.neutralVariant),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: Text(
                        '12 Aylık Zincir Takvimi',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.neutralVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 6. Alışkanlık Rutini & Bildirimler
            BloomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EyebrowLabel('RUTİN & BİLDİRİMLER', color: AppColors.primary),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hatırlatma Vakti', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                          Text('Her akşam düzenli kontrol', style: TextStyle(fontSize: 11.sp, color: AppColors.neutralVariant)),
                        ],
                      ),
                      const StatusChip(text: '20:00 (Her Gün)', tone: ChipTone.primary),
                    ],
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
                    onPressed: () {
                      // TODO(habit): Archive confirmation dialog
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
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
