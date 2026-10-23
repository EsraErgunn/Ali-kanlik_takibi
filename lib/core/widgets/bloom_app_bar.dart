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
    this.characterId,
  });

  final String? subtitle;
  final String levelTitle;
  final int streakDays;
  final VoidCallback? onAvatarTap;
  final bool showBack;
  final String? titleText;
  final String? characterId;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.darkOutline : AppColors.outline).withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText ?? 'BloomHabit',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
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
                      child: characterId != null
                          ? Image.asset(
                              'assets/characters/$characterId.png',
                              width: 22.r,
                              height: 22.r,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Text(
                                '🧑‍🌾',
                                style: TextStyle(fontSize: 18.sp),
                              ),
                            )
                          : Text(
                              '🧑‍🌾',
                              style: TextStyle(fontSize: 18.sp),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
