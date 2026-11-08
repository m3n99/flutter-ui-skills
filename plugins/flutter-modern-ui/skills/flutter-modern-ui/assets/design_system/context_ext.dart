import 'package:flutter/material.dart';

import 'app_density.dart';
import 'app_palette.dart';
import 'tokens.dart';

/// Short, explicit accessors for theme values inside build methods.
extension DesignSystemContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.fromScheme(colors);
  AppDensity get density =>
      Theme.of(this).extension<AppDensity>() ?? AppDensity.forPlatform(Theme.of(this).platform);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Window size class from the window width (not the parent's width).
  WindowSize get windowSize => WindowSize.of(MediaQuery.sizeOf(this).width);

  /// True when the platform asks for reduced motion.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// [duration], or zero when the platform asks for reduced motion.
  /// Wrap every animation duration in this.
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;
}
