import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: BloomAppBar(
        subtitle: 'Alışkanlıklar',
        levelTitle: 'Seviye 1 Tohum',
        streakDays: 0,
        onAvatarTap: () => context.go('/profile'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(title: 'Aktif Ritüeller'),
                StatusChip(
                  text: '+ Yeni Tohum',
                  tone: ChipTone.primary,
                  onTap: () => context.push('/new-habit'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            BloomCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
              child: Column(
                children: [
                  Text('🌿', style: TextStyle(fontSize: 44.sp)),
                  SizedBox(height: 12.h),
                  Text(
                    'Henüz Takip Edilen Alışkanlık Yok',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Geliştirmek veya bırakmak istediğin bir alışkanlık ekle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.neutralVariant,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  PrimaryPillButton(
                    text: 'Tohum Ek 🌱',
                    onPressed: () => context.push('/new-habit'),
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
