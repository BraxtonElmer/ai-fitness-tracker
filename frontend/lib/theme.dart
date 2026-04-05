import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceRaised = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color primaryText = Color(0xFFF0F0F0);
  static const Color secondaryText = Color(0xFF888888);
  static const Color mutedText = Color(0xFF555555);
  static const Color accent = Color(0xFFC8F560);
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF4CAF7D);

  // Macro chart colors
  static const Color proteinColor = Color(0xFFF0F0F0);
  static const Color carbsColor = Color(0xFFC8F560);
  static const Color fatsColor = Color(0xFF888888);
}

class AppFontSizes {
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppSpacing {
  static const double x1 = 8;
  static const double x2 = 16;
  static const double x3 = 24;
  static const double x4 = 32;
  static const double x5 = 40;
  static const double x6 = 48;
  static const double x8 = 64;
}

class AppRadius {
  static const double standard = 8;
  static final BorderRadius borderRadius = BorderRadius.circular(standard);
}

class AppTextStyles {
  static const String _fontFamily = 'ClashGrotesk';

  // Regular (400)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSizes.xs,
    color: AppColors.primaryText,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSizes.sm,
    color: AppColors.primaryText,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSizes.md,
    color: AppColors.primaryText,
  );

  // Medium (500)
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSizes.sm,
    color: AppColors.primaryText,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSizes.md,
    color: AppColors.primaryText,
  );

  // Semibold (600)
  static const TextStyle headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSizes.lg,
    color: AppColors.primaryText,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSizes.xl,
    color: AppColors.primaryText,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSizes.xxl,
    color: AppColors.primaryText,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSizes.sm,
    letterSpacing: 1.2,
    color: AppColors.background,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'ClashGrotesk',
    colorScheme: const ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.accent,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 0,
    ),
  );
}
