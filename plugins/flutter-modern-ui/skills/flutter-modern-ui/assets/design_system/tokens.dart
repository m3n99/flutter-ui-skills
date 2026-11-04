import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Spacing scale (4-pt grid). Use these instead of raw numbers.
abstract final class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Horizontal padding for screen content.
  static const double screen = 20;

  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: screen);
  static const EdgeInsets card = EdgeInsets.all(md);
}

/// Corner radius scale. One family per screen; nested radius = outer - padding.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Icon sizes.
abstract final class AppIconSize {
  static const double inline = 16;
  static const double dense = 20;
  static const double regular = 24;
  static const double feature = 32;
  static const double hero = 48;
}

/// Motion durations.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Motion curves.
abstract final class AppCurves {
  /// Default for elements entering or settling.
  static const Curve standard = Curves.easeOutCubic;

  /// Larger moves: sheets, expanding panels.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Elements leaving the screen.
  static const Curve exit = Curves.easeInCubic;
}
