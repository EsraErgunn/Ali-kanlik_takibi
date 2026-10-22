import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import 'status_chip.dart';

class BloomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BloomAppBar({
    super.key,
    this.subtitle,
    this.levelTitle = 'Seviye 1 Tohum',
    this.streakDays = 0,
    this.onAvatarTap,
    this.showBack = false,
    this.titleText,
  });

  final String? subtitle;
  final String levelTitle;
  final int streakDays;
  final VoidCallback? onAvatarTap;
  final bool showBack;
  final String? titleText;

  @override
  Size get preferredSize => Size.fromHeight(68.h);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SafeArea(
      bottom: false,
      child: Container(
        constraints: BoxConstraints(minHeight: 56.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          border: Border(
            bottom: BorderSide(
              color: (isDark ? AppColors.darkOutline : AppColors.outline).withValues(alpha: 0.6),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: back button or logo + title
            Expanded(
              child: Row(
                children: [
                  if (showBack) ...[
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20.r,
                        color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    '🌱',
                    style: TextStyle(fontSize: 20.sp),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText ?? 'BloomHabit',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // Middle & Right: Status chips & Avatar
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!showBack) ...[
                  if (screenWidth >= 420) ...[
                    StatusChip(
                      text: levelTitle,
                      tone: ChipTone.primary,
                    ),
                    SizedBox(width: 6.w),
                  ],
                  StatusChip(
                    text: '🔥 $streakDays Gün',
                    tone: ChipTone.secondary,
                  ),
                  SizedBox(width: 8.w),
                ],
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '🧑‍🌾',
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
