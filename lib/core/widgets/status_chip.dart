import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

enum ChipTone { primary, secondary, tertiary, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.text,
    this.tone = ChipTone.primary,
    this.icon,
    this.onTap,
    this.isSelected,
  });

  final String text;
  final ChipTone tone;
  final Widget? icon;
  final VoidCallback? onTap;
  final bool? isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor;
    final Color textColor;
    final Color borderColor;

    if (isSelected == true) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
      borderColor = AppColors.primary;
    } else {
      switch (tone) {
        case ChipTone.primary:
          bgColor = isDark ? const Color(0xFF133B27) : AppColors.primaryContainer;
          textColor = isDark ? AppColors.darkPrimary : AppColors.primaryDark;
          borderColor = isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2);
          break;
        case ChipTone.secondary:
          bgColor = isDark ? const Color(0xFF4C2117) : AppColors.secondaryContainer;
          textColor = AppColors.secondary;
          borderColor = AppColors.secondary.withValues(alpha: 0.3);
          break;
        case ChipTone.tertiary:
          bgColor = isDark ? const Color(0xFF4A3412) : AppColors.tertiaryContainer;
          textColor = isDark ? AppColors.tertiary : const Color(0xFF9E6508);
          borderColor = AppColors.tertiary.withValues(alpha: 0.3);
          break;
        case ChipTone.neutral:
          bgColor = isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted;
          textColor = isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant;
          borderColor = isDark ? AppColors.darkOutline : AppColors.outline;
          break;
      }
    }

    Widget chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: 4.w),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999.r),
          onTap: onTap,
          child: chip,
        ),
      );
    }

    return chip;
  }
}
