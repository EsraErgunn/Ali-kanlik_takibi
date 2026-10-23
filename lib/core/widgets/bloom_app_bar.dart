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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final effectiveTitle = titleText ?? (showBack ? '' : 'BloomHabit');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.6),
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
                      color: colorScheme.onSurface,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(width: 8.w),
                ] else ...[
                  Text(
                    '🌱',
                    style: TextStyle(fontSize: 20.sp),
                  ),
                  SizedBox(width: 8.w),
                ],
                Expanded(
                  child: subtitle != null && subtitle!.isNotEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              effectiveTitle,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? colorScheme.primary : AppColors.primary,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Text(
                          effectiveTitle,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? colorScheme.primary : AppColors.primary,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      color: colorScheme.primaryContainer,
                      border: Border.all(
                        color: colorScheme.primary,
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
