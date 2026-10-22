import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import 'status_chip.dart';

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.text,
    this.tone = ChipTone.primary,
    this.icon,
  });

  final String text;
  final ChipTone tone;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor;
    final Color textColor;
    final Color borderColor;
    final IconData defaultIcon;

    switch (tone) {
      case ChipTone.primary:
        bgColor = isDark ? const Color(0xFF133B27) : AppColors.primaryContainer;
        textColor = isDark ? AppColors.darkPrimary : AppColors.primaryDark;
        borderColor = isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2);
        defaultIcon = Icons.eco_outlined;
        break;
      case ChipTone.secondary:
        bgColor = isDark ? const Color(0xFF4C2117) : AppColors.secondaryContainer;
        textColor = AppColors.secondary;
        borderColor = AppColors.secondary.withValues(alpha: 0.3);
        defaultIcon = Icons.info_outline;
        break;
      case ChipTone.tertiary:
        bgColor = isDark ? const Color(0xFF4A3412) : AppColors.tertiaryContainer;
        textColor = isDark ? AppColors.tertiary : const Color(0xFF9E6508);
        borderColor = AppColors.tertiary.withValues(alpha: 0.3);
        defaultIcon = Icons.shield_outlined;
        break;
      case ChipTone.neutral:
        bgColor = isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted;
        textColor = isDark ? AppColors.darkNeutral : AppColors.neutral;
        borderColor = isDark ? AppColors.darkOutline : AppColors.outline;
        defaultIcon = Icons.info_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon ??
              Icon(
                defaultIcon,
                size: 18.r,
                color: textColor,
              ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
