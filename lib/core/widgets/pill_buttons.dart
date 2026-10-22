import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.height,
    this.color,
    this.textColor,
  });

  final String text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 52.h;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnColor = color ?? (isDark ? AppColors.darkPrimary : AppColors.primary);
    final txtColor = textColor ?? (isDark ? AppColors.darkBackground : Colors.white);

    return SizedBox(
      height: effectiveHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: txtColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: txtColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: txtColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton({
    super.key,
    required this.text,
    this.tone = AppColors.secondary,
    this.icon,
    this.onPressed,
    this.height,
  });

  final String text;
  final Color tone;
  final Widget? icon;
  final VoidCallback? onPressed;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 50.h,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: tone,
          side: BorderSide(color: tone, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              SizedBox(width: 6.w),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: tone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
