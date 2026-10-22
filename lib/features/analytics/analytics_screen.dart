import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: BloomAppBar(
        subtitle: 'Analiz & Gelişim',
        levelTitle: 'Seviye 1 Tohum',
        streakDays: 0,
        onAvatarTap: () => context.go('/profile'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            const SectionHeader(title: 'Genel İlerleme Özeti'),
            SizedBox(height: 12.h),
            Row(
              children: const [
                Expanded(
                  child: StatTile(
                    label: 'TOPLAM TAMAMLAMA',
                    value: '0 Gün',
                    sub: 'Tohum yeni ekildi',
                    icon: Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'AKTİF ZİNCİR',
                    value: '0 Gün',
                    sub: 'Ateşi yak',
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
                    'Birkaç gün sonra burada gelişim grafiğini göreceksin.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutralVariant,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  const InfoBox(
                    text: 'Güç Skoru Algoritması: Her başarılı gün +1 puan kazandırır, kaçırılan gün -1 puan eksiltir. Taban puan 0\'dır.',
                    tone: ChipTone.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
