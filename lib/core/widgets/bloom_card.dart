import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class BloomCard extends StatelessWidget {
  const BloomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.borderColor,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? 20.r;

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? (isDark ? AppColors.darkSurface : AppColors.surface)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: borderColor ?? (isDark ? AppColors.darkOutline : AppColors.outline),
          width: 0.8,
        ),
        boxShadow: isDark ? null : AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Padding(
          padding: padding ?? EdgeInsets.all(16.r),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(r),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
