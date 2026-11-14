import 'package:flutter/material.dart';

import 'app_density.dart';
import 'app_motion.dart';
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

  /// How much the app moves (`AppThemeConfig.motion`).
  AppMotion get appMotion => Theme.of(this).extension<AppMotion>() ?? AppMotion.soft;

  /// True when the shared motion pieces must not animate: the platform asks
  /// for reduced motion, or the app's motion level is none.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this) || !appMotion.animates;

  /// [duration] scaled by the motion level, or zero under reduced motion and
  /// at MotionLevel.none. Wrap every animation duration in this.
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration * appMotion.durationScale;

  /// The text scale at body size (Android 14+ grows large text less than
  /// small text).
  double get textScale => MediaQuery.textScalerOf(this).scale(_bodySize) / _bodySize;

  /// The window width as text sees it: width ÷ text scale. Big fonts and
  /// Android's display size shrink it.
  double get textWidth => MediaQuery.sizeOf(this).width / textScale;

  /// A small phone, big fonts or a large display size: rows that pair two
  /// things stack (the amount under the name, the chip under the details),
  /// KPI tiles go one per row, forms one field per row.
  bool get isNarrow => textWidth < AppBreakpoints.narrow;

  /// [size] grown with the text, up to [AppIconSize.maxTextScale]: icons
  /// inline with text (MetaItem, pills) keep pace with big fonts.
  double iconSize(double size) {
    final scale = textScale;
    if (scale <= 1) return size;
    return size * (scale > AppIconSize.maxTextScale ? AppIconSize.maxTextScale : scale);
  }

  /// Space after the last row of a list that runs to the bottom of the
  /// screen: the navigation bar or home indicator, [AppSpace.lg], and room
  /// for a floating action button when the screen has one.
  double listEndPadding({bool fab = false}) =>
      MediaQuery.paddingOf(this).bottom + AppSpace.lg + (fab ? AppSize.fabClearance : 0);
}

const double _bodySize = 14;
