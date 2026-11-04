import 'package:flutter/material.dart';

/// Semantic colors Material's ColorScheme doesn't cover (success, warning,
/// info) plus shadow presets. Generated per brightness from fixed seed hues so
/// they harmonize with the main scheme and adapt to dark mode.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.softShadow,
  });

  factory AppPalette.forBrightness(Brightness brightness) {
    ColorScheme from(Color seed) => ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        );

    final success = from(const Color(0xFF16A34A));
    final warning = from(const Color(0xFFD97706));
    final info = from(const Color(0xFF0284C7));
    final isDark = brightness == Brightness.dark;

    return AppPalette(
      success: success.primary,
      onSuccess: success.onPrimary,
      successContainer: success.primaryContainer,
      onSuccessContainer: success.onPrimaryContainer,
      warning: warning.primary,
      onWarning: warning.onPrimary,
      warningContainer: warning.primaryContainer,
      onWarningContainer: warning.onPrimaryContainer,
      info: info.primary,
      onInfo: info.onPrimary,
      infoContainer: info.primaryContainer,
      onInfoContainer: info.onPrimaryContainer,
      softShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Soft, layered shadow for floating elements only (FAB, sticky CTA bar,
  /// floating nav). Cards should not use it by default.
  final List<BoxShadow> softShadow;

  @override
  AppPalette copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    List<BoxShadow>? softShadow,
  }) {
    return AppPalette(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      softShadow: softShadow ?? this.softShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      info: l(info, other.info),
      onInfo: l(onInfo, other.onInfo),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      softShadow: BoxShadow.lerpList(softShadow, other.softShadow, t) ?? softShadow,
    );
  }
}
