import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Hero Botanical Icon
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF133B27) : AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '🌱',
                    style: TextStyle(fontSize: 48.sp),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Title & Slogan
              Text(
                'BloomHabit',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Küçük tohumlar, büyük alışkanlıklar.',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Botanical Benefits Card
              BloomCard(
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: '🪴',
                      title: 'Canlı Bitki Bahçesi',
                      subtitle: 'Alışkanlıkların güçlendikçe bitkin yeşerir ve çiçek açar.',
                      isDark: isDark,
                    ),
                    Divider(height: 24.h, color: isDark ? AppColors.darkOutline : AppColors.outline),
                    _buildFeatureItem(
                      icon: '🔒',
                      title: '100% Cihazında & Gizli',
                      subtitle: 'Hesap veya şifre yok; verilerin sadece telefonunda saklanır.',
                      isDark: isDark,
                    ),
                    Divider(height: 24.h, color: isDark ? AppColors.darkOutline : AppColors.outline),
                    _buildFeatureItem(
                      icon: '✨',
                      title: 'Botanik Rehberlik',
                      subtitle: 'Günlük ilham kartları ve şefkatli destek mesajları.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Action Button
              PrimaryPillButton(
                text: 'Bahçeni Kur 🌱',
                onPressed: () => context.go('/onboarding/character'),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required String icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: TextStyle(fontSize: 22.sp)),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
