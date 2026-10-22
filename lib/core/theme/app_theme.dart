import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final baseText = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: Color(0xFF9E381C),
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: Color(0xFF8B570A),
        surface: AppColors.surface,
        onSurface: AppColors.neutral,
        surfaceContainerHighest: AppColors.surfaceMuted,
        onSurfaceVariant: AppColors.neutralVariant,
        outline: AppColors.outline,
        error: AppColors.secondary,
        onError: Colors.white,
      ),
      textTheme: baseText.copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 26.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.neutral,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.neutralVariant,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.neutralVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: const BorderSide(color: AppColors.outline, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.neutralVariant,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkBackground,
        primaryContainer: Color(0xFF133B27),
        onPrimaryContainer: AppColors.darkPrimary,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF4C2117),
        onSecondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: Colors.black,
        tertiaryContainer: Color(0xFF4A3412),
        onTertiaryContainer: AppColors.tertiaryContainer,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkNeutral,
        surfaceContainerHighest: AppColors.darkSurfaceMuted,
        onSurfaceVariant: AppColors.darkNeutralVariant,
        outline: AppColors.darkOutline,
        error: AppColors.secondary,
        onError: Colors.white,
      ),
      textTheme: baseText.copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 26.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.darkNeutral,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.darkNeutral,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.darkNeutral,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.darkNeutral,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.darkNeutralVariant,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.darkNeutralVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: const BorderSide(color: AppColors.darkOutline, width: 0.5),
        ),
      ),
    );
  }
}
