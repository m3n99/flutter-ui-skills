import 'package:flutter/material.dart';

import 'tokens.dart';

/// How much the app moves. Asked before building (references/intake.md ›
/// Motion), recorded in DESIGN.md, set once in `AppThemeConfig.motion`.
enum MotionLevel {
  /// Material's own motion only: ripples, page transitions, switches,
  /// sheets. The shared motion pieces show their end state at once.
  none,

  /// Calm (the default): fades and short rises, all at once, a light press,
  /// no overshoot.
  soft,

  /// Noticeable: longer rises staggered row by row, grids scaling in, a
  /// firmer press, a pop on success and a shake on errors. Still within the
  /// duration tokens (× 1.2).
  expressive,
}

/// The motion level's numbers, read by the shared motion pieces (Entrance,
/// AnimatedItems, StateSwitcher, PressScale, PopOnChange, ShakeOnChange)
/// through `context.appMotion`, and by `context.motion(duration)`, which
/// scales every duration token. Reduced motion still wins: durations become
/// zero at every level.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    required this.level,
    required this.durationScale,
    required this.entranceOffset,
    required this.stagger,
    required this.insertScale,
    required this.pressScale,
    required this.popScale,
    required this.shakeDistance,
  });

  static const AppMotion none = AppMotion(
    level: MotionLevel.none,
    durationScale: 0,
    entranceOffset: 0,
    stagger: Duration.zero,
    insertScale: 1,
    pressScale: 1,
    popScale: 1,
    shakeDistance: 0,
  );

  static const AppMotion soft = AppMotion(
    level: MotionLevel.soft,
    durationScale: 1,
    entranceOffset: 0.04,
    stagger: Duration.zero,
    insertScale: 0.98,
    pressScale: 0.98,
    popScale: 1.08,
    shakeDistance: 4,
  );

  static const AppMotion expressive = AppMotion(
    level: MotionLevel.expressive,
    durationScale: 1.2,
    entranceOffset: 0.12,
    stagger: AppDurations.stagger,
    insertScale: 0.92,
    pressScale: 0.96,
    popScale: 1.18,
    shakeDistance: 8,
  );

  static AppMotion of(MotionLevel level) => switch (level) {
        MotionLevel.none => none,
        MotionLevel.soft => soft,
        MotionLevel.expressive => expressive,
      };

  final MotionLevel level;

  /// Multiplies every duration token (0 at [MotionLevel.none]).
  final double durationScale;

  /// How far entrances rise, as a fraction of the item's height.
  final double entranceOffset;

  /// Delay between staggered siblings (the first AppDurations.staggerLimit).
  final Duration stagger;

  /// Grid items scale in from this.
  final double insertScale;

  /// Cards and tiles shrink to this while pressed.
  final double pressScale;

  /// PopOnChange's peak scale.
  final double popScale;

  /// ShakeOnChange's swing, in logical pixels.
  final double shakeDistance;

  /// False at [MotionLevel.none].
  bool get animates => level != MotionLevel.none;

  @override
  AppMotion copyWith({
    MotionLevel? level,
    double? durationScale,
    double? entranceOffset,
    Duration? stagger,
    double? insertScale,
    double? pressScale,
    double? popScale,
    double? shakeDistance,
  }) {
    return AppMotion(
      level: level ?? this.level,
      durationScale: durationScale ?? this.durationScale,
      entranceOffset: entranceOffset ?? this.entranceOffset,
      stagger: stagger ?? this.stagger,
      insertScale: insertScale ?? this.insertScale,
      pressScale: pressScale ?? this.pressScale,
      popScale: popScale ?? this.popScale,
      shakeDistance: shakeDistance ?? this.shakeDistance,
    );
  }

  /// Motion settings don't blend: the theme switches at the midpoint.
  @override
  AppMotion lerp(AppMotion? other, double t) => other == null || t < 0.5 ? this : other;
}
