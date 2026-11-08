import 'package:flutter/material.dart';

/// One semantic tone: a strong color for icons and text on surfaces, and a
/// container pair for pills, badges and tinted blocks.
@immutable
class ToneColors {
  const ToneColors({
    required this.color,
    required this.onColor,
    required this.container,
    required this.onContainer,
  });

  /// Derives a tone from a fixed hue so it harmonizes with the scheme and
  /// adapts to dark mode.
  factory ToneColors.fromSeed(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return ToneColors(
      color: scheme.primary,
      onColor: scheme.onPrimary,
      container: scheme.primaryContainer,
      onContainer: scheme.onPrimaryContainer,
    );
  }

  final Color color;
  final Color onColor;
  final Color container;
  final Color onContainer;

  static ToneColors lerp(ToneColors a, ToneColors b, double t) {
    return ToneColors(
      color: Color.lerp(a.color, b.color, t)!,
      onColor: Color.lerp(a.onColor, b.onColor, t)!,
      container: Color.lerp(a.container, b.container, t)!,
      onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
    );
  }
}

/// Colors Material's ColorScheme doesn't have, plus shadow presets.
/// Read it with `context.palette`.
///
/// Business states get their own tones. Add fields such as `overdue`,
/// `dueSoon` or `paid` next to [success] / [warning] / [info] instead of
/// reusing `colorScheme.error`, which belongs to failures and form errors.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.warning,
    required this.info,
    required this.softShadow,
    required this.hoverShadow,
  });

  factory AppPalette.fromScheme(ColorScheme scheme) {
    final brightness = scheme.brightness;
    final dark = brightness == Brightness.dark;
    // Light mode tints shadows with the text color so they stay warm or cool
    // with the palette; dark mode needs black at higher opacity to read.
    final tint = dark ? Colors.black : scheme.onSurface;

    return AppPalette(
      success: ToneColors.fromSeed(const Color(0xFF1E8E3E), brightness),
      warning: ToneColors.fromSeed(const Color(0xFFB26A00), brightness),
      info: ToneColors.fromSeed(const Color(0xFF0B6BCB), brightness),
      softShadow: [
        BoxShadow(color: tint.withValues(alpha: dark ? 0.35 : 0.10), blurRadius: 24, offset: const Offset(0, 8)),
        BoxShadow(color: tint.withValues(alpha: dark ? 0.20 : 0.06), blurRadius: 4, offset: const Offset(0, 1)),
      ],
      hoverShadow: [
        BoxShadow(color: tint.withValues(alpha: dark ? 0.45 : 0.14), blurRadius: 32, offset: const Offset(0, 12)),
        BoxShadow(color: tint.withValues(alpha: dark ? 0.25 : 0.08), blurRadius: 6, offset: const Offset(0, 2)),
      ],
    );
  }

  final ToneColors success;
  final ToneColors warning;
  final ToneColors info;

  /// For floating elements (FAB, sticky CTA bar) and raised dashboard tiles
  /// only. Regular cards stay flat with a hairline border.
  final List<BoxShadow> softShadow;

  /// [softShadow] while a pointer hovers a raised tile.
  final List<BoxShadow> hoverShadow;

  @override
  AppPalette copyWith({
    ToneColors? success,
    ToneColors? warning,
    ToneColors? info,
    List<BoxShadow>? softShadow,
    List<BoxShadow>? hoverShadow,
  }) {
    return AppPalette(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      softShadow: softShadow ?? this.softShadow,
      hoverShadow: hoverShadow ?? this.hoverShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      success: ToneColors.lerp(success, other.success, t),
      warning: ToneColors.lerp(warning, other.warning, t),
      info: ToneColors.lerp(info, other.info, t),
      softShadow: BoxShadow.lerpList(softShadow, other.softShadow, t) ?? other.softShadow,
      hoverShadow: BoxShadow.lerpList(hoverShadow, other.hoverShadow, t) ?? other.hoverShadow,
    );
  }
}
