import 'package:flutter/material.dart';

// Design tokens. Widgets use these names, never raw numbers.
//
// If the project already has tokens, map these names onto its own and add
// only what is missing to its existing file. When copying this file instead,
// retune every line marked DIRECTION to the chosen design direction
// (references/directions.md).

/// Spacing scale on a 4-pt grid.
abstract final class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Horizontal page padding.
  /// DIRECTION: 16 Enterprise Dense · 20 default · 24 Editorial.
  static const double screen = 20;

  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: screen);
  static const EdgeInsets card = EdgeInsets.all(md);
}

/// Corner radius scale and the roles that pick from it.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  /// Cards and grouped sections.
  /// DIRECTION: 16 Soft Minimal · 12 Enterprise Dense / Editorial · 24 Playful.
  static const double card = lg;

  /// Buttons, inputs, menus, tooltips.
  /// DIRECTION: 12 Soft Minimal · 8 Enterprise Dense · pill for Playful.
  static const double control = md;

  /// Bottom-sheet top corners and dialogs.
  static const double sheet = xl;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius controlAll = BorderRadius.all(Radius.circular(control));
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));

  /// Radius for a rounded shape sitting [gap] px inside a rounded parent of
  /// radius [outer], so the two corners stay concentric.
  ///
  /// Only applies while the gap is smaller than the outer radius. From there
  /// on the corners no longer read as nested and the child keeps its own
  /// component radius ([own]). A child that fills its parent (gap 0) is
  /// simply clipped by the parent.
  ///
  /// Example: rows inset 8 px in a 12 px card get `concentric(12, 8)` = 4.
  static double concentric(double outer, double gap, {double own = sm}) =>
      gap < outer ? outer - gap : own;
}

/// Elevation levels. Cards are flat and bordered; only overlays float.
abstract final class AppElevation {
  static const double flat = 0;
  static const double raised = 1;
  static const double overlay = 3;
}

/// Line widths.
abstract final class AppStroke {
  static const double hairline = 1;
  static const double focus = 1.5;
  static const double selected = 2;
}

/// Opacity steps. State layers follow Material 3.
abstract final class AppOpacity {
  static const double hover = 0.08;
  static const double focus = 0.10;
  static const double pressed = 0.10;
  static const double dragged = 0.16;
  static const double tint = 0.12;
  static const double disabled = 0.38;
  static const double muted = 0.6;
}

/// Icon sizes.
abstract final class AppIconSize {
  static const double pill = 14;
  static const double inline = 16;
  static const double dense = 20;
  static const double regular = 24;
  static const double feature = 32;

  /// The icon in an EmptyState's tinted circle.
  static const double emptyState = 40;
  static const double hero = 48;
}

/// Fixed component sizes and content widths.
abstract final class AppSize {
  static const double touchTarget = 48;
  static const double avatar = 40;
  static const double iconBadge = 40;
  static const double emojiBadge = 36;
  static const double progressBar = 8;
  static const double spinner = 18;

  /// Sheets shown as dialogs on wide windows.
  static const double sheetMaxWidth = 560;
  static const double confirmDialogWidth = 420;

  /// Floating SnackBar width on pointer (desktop) platforms.
  static const double messageWidth = 420;

  /// Empty states: title and message wrap at this width.
  static const double emptyStateWidth = 360;

  static const double formMaxWidth = 640;
  static const double readingMaxWidth = 720;

  /// Dashboards and tables stop growing here and center.
  static const double contentMaxWidth = 1440;
}

/// Window-width breakpoints (Material 3 window size classes).
abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;
  static const double extraLarge = 1600;
}

/// Window size class for the current width. Read it with `context.windowSize`.
enum WindowSize {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  static WindowSize of(double width) {
    if (width < AppBreakpoints.medium) return WindowSize.compact;
    if (width < AppBreakpoints.expanded) return WindowSize.medium;
    if (width < AppBreakpoints.large) return WindowSize.expanded;
    if (width < AppBreakpoints.extraLarge) return WindowSize.large;
    return WindowSize.extraLarge;
  }

  bool atLeast(WindowSize other) => index >= other.index;
}

/// Motion durations. Gate every duration with `context.motion(...)` so it
/// becomes zero when the platform asks for reduced motion.
abstract final class AppDurations {
  /// Press feedback, toggles, color and border changes.
  static const Duration fast = Duration(milliseconds: 150);

  /// State switches, list insert/remove, expand/collapse.
  static const Duration medium = Duration(milliseconds: 250);

  /// Charts, progress, counters, larger layout moves.
  static const Duration slow = Duration(milliseconds: 350);

  /// Route transitions (the Android default since Flutter 3.38 is 450 ms).
  static const Duration page = Duration(milliseconds: 450);

  /// Delay between siblings in a staggered entrance.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Only the first N siblings are staggered.
  static const int staggerLimit = 8;

  /// Messages: plain text, and with an action (Undo, Open, Print).
  static const Duration message = Duration(seconds: 4);
  static const Duration messageWithAction = Duration(seconds: 6);

  /// A failed submit's shake.
  static const Duration shake = Duration(milliseconds: 420);

  /// How long a success check stays before the button resets.
  static const Duration confirmation = Duration(milliseconds: 1200);

  /// One sweep of a skeleton's shimmer.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// Loads shorter than this show no skeleton at all (no flash).
  static const Duration skeletonDelay = Duration(milliseconds: 150);
}

/// Motion curves (Material 3 easing).
abstract final class AppCurves {
  /// Small, utilitarian moves.
  static const Curve standard = Easing.standard;

  /// Elements entering the screen or settling.
  static const Curve enter = Easing.emphasizedDecelerate;

  /// Elements leaving the screen.
  static const Curve exit = Easing.emphasizedAccelerate;

  /// Large moves that stay on screen (sheets, expanding panels).
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Celebratory pops (likes, success checks). Not for functional UI.
  static const Curve pop = Curves.easeOutBack;
}
