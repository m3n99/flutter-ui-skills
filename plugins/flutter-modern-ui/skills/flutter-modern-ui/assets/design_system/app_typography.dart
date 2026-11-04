import 'package:flutter/material.dart';

/// Tuned type scale: tighter tracking on large sizes, comfortable line heights
/// on body text, semibold titles. Colors are applied by AppTheme.
abstract final class AppTypography {
  static TextTheme textTheme({String? fontFamily, List<String>? fontFamilyFallback}) {
    TextStyle s(double size, double height, FontWeight weight, double tracking) => TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          fontSize: size,
          height: height,
          fontWeight: weight,
          letterSpacing: tracking,
          leadingDistribution: TextLeadingDistribution.even,
        );

    return TextTheme(
      displayLarge: s(44, 1.10, FontWeight.w700, -1.0),
      displayMedium: s(36, 1.12, FontWeight.w700, -0.8),
      displaySmall: s(30, 1.15, FontWeight.w700, -0.5),
      headlineLarge: s(28, 1.20, FontWeight.w700, -0.4),
      headlineMedium: s(24, 1.25, FontWeight.w700, -0.3),
      headlineSmall: s(20, 1.30, FontWeight.w600, -0.2),
      titleLarge: s(18, 1.33, FontWeight.w600, -0.1),
      titleMedium: s(16, 1.40, FontWeight.w600, 0),
      titleSmall: s(14, 1.40, FontWeight.w600, 0),
      bodyLarge: s(16, 1.50, FontWeight.w400, 0),
      bodyMedium: s(14, 1.50, FontWeight.w400, 0),
      bodySmall: s(12, 1.45, FontWeight.w400, 0.1),
      labelLarge: s(14, 1.20, FontWeight.w600, 0.1),
      labelMedium: s(12, 1.20, FontWeight.w600, 0.2),
      labelSmall: s(11, 1.20, FontWeight.w600, 0.3),
    );
  }
}
