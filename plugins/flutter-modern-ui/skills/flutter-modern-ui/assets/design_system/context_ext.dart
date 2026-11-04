import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Short, explicit accessors for theme values inside build methods.
extension DesignSystemContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
