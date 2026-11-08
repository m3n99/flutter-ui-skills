import 'package:flutter/material.dart';

/// Script the type scale is tuned for.
enum AppScript {
  /// Latin, Cyrillic, Greek: tight tracking on large sizes.
  latin,

  /// Arabic and other connected scripts: zero letter-spacing (any tracking
  /// breaks the joins) and taller line heights.
  arabic,
}

/// Tuned type scale. Colors are applied by AppTheme.
abstract final class AppTypography {
  static TextTheme textTheme({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    AppScript script = AppScript.latin,
  }) {
    final arabic = script == AppScript.arabic;

    TextStyle style(double size, FontWeight weight, double latinHeight, double arabicHeight, double tracking) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: size,
        fontWeight: weight,
        height: arabic ? arabicHeight : latinHeight,
        letterSpacing: arabic ? 0 : tracking,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    //            size  weight            latin  arabic  tracking
    return TextTheme(
      displayLarge: style(44, FontWeight.w700, 1.10, 1.25, -1.0),
      displayMedium: style(36, FontWeight.w700, 1.12, 1.25, -0.8),
      displaySmall: style(30, FontWeight.w700, 1.15, 1.30, -0.5),
      headlineLarge: style(28, FontWeight.w700, 1.20, 1.35, -0.4),
      headlineMedium: style(24, FontWeight.w700, 1.25, 1.40, -0.3),
      headlineSmall: style(20, FontWeight.w600, 1.30, 1.45, -0.2),
      titleLarge: style(18, FontWeight.w600, 1.33, 1.45, -0.1),
      titleMedium: style(16, FontWeight.w600, 1.40, 1.50, 0),
      titleSmall: style(14, FontWeight.w600, 1.40, 1.50, 0),
      bodyLarge: style(16, FontWeight.w400, 1.50, 1.60, 0),
      bodyMedium: style(14, FontWeight.w400, 1.50, 1.60, 0),
      bodySmall: style(12, FontWeight.w400, 1.45, 1.55, 0.1),
      labelLarge: style(14, FontWeight.w600, 1.20, 1.35, 0.1),
      labelMedium: style(12, FontWeight.w600, 1.20, 1.35, 0.2),
      labelSmall: style(11, FontWeight.w600, 1.20, 1.35, 0.3),
    );
  }
}

/// Equal-width digits for amounts, dates, timers and table columns:
/// `context.textStyles.titleMedium.tabular`.
///
/// Check that the font supports `tnum`, or that its digits are already
/// monospaced; otherwise the feature does nothing.
extension TabularFigures on TextStyle? {
  TextStyle? get tabular => this?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
