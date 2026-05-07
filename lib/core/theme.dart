import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Responsive {
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  /// Scale a size — tablets get 72% of the phone value.
  static double s(BuildContext context, double base) =>
      isTablet(context) ? (base * 0.72) : base;

  /// Status-bar-aware top inset for manual AppBars.
  static double topInset(BuildContext context) =>
      MediaQuery.of(context).padding.top + (isTablet(context) ? 8.0 : 12.0);
}

class AppColors {
  static const Color primary = Color(0xFF705D00);
  static const Color primaryContainer = Color(0xFFFFD700);
  static const Color onPrimaryContainer = Color(0xFF705E00);
  
  static const Color secondary = Color(0xFFA13470);
  static const Color secondaryContainer = Color(0xFFFC7EBD);
  static const Color onSecondaryContainer = Color(0xFF770C4E);
  
  static const Color tertiary = Color(0xFF00658D);
  static const Color tertiaryContainer = Color(0xFFB4E0FF);
  static const Color onTertiaryContainer = Color(0xFF00668E);
  
  static const Color background = Color(0xFFFCF9F8);
  static const Color surface = Color(0xFFFCF9F8);
  static const Color onBackground = Color(0xFF1B1C1C);
  static const Color onSurface = Color(0xFF1B1C1C);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  
  static const Color outline = Color(0xFF7E775F);
  static const Color surfaceVariant = Color(0xFFE4E2E1);
  static const Color onSurfaceVariant = Color(0xFF4D4732);
  
  static const Color shadow = Color(0xFF1B1C1C);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        outline: AppColors.outline,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.onBackground,
          height: 1.1,
          letterSpacing: -0.96,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.onBackground,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.onBackground,
        ),
        bodyLarge: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.onBackground,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.onBackground,
        ),
        labelLarge: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onBackground,
        ),
      ),
    );
  }

  // Neobrutalist border style
  static BoxBorder border({double width = 4}) => Border.all(
    color: AppColors.onBackground,
    width: width,
  );

  // Neobrutalist shadow
  static List<BoxShadow> shadow({double offset = 4}) => [
    BoxShadow(
      color: AppColors.shadow,
      offset: Offset(offset, offset),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static BorderRadius radiusSM = BorderRadius.circular(16); // DEFAULT 1rem
  static BorderRadius radiusMD = BorderRadius.circular(32); // lg 2rem
  static BorderRadius radiusLG = BorderRadius.circular(48); // xl 3rem
  static BorderRadius radiusFull = BorderRadius.circular(9999);
}
