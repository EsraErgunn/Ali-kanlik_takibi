import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class ProgressPill extends StatelessWidget {
  const ProgressPill({
    super.key,
    required this.value,
    this.color,
    this.height,
    this.backgroundColor,
  });

  /// Progress value between 0.0 and 1.0
  final double value;
  final Color? color;
  final double? height;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final effectiveHeight = height ?? 6.h;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barColor = color ?? (isDark ? AppColors.darkPrimary : AppColors.primary);
    final bg = backgroundColor ?? (isDark ? const Color(0xFF2C2A27) : const Color(0xFFEBE5DF));

    return Container(
      height: effectiveHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * clamped,
              height: effectiveHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          );
        },
      ),
    );
  }
}
