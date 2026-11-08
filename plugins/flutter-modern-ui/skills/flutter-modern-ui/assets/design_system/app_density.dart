import 'package:flutter/material.dart';

/// Per-platform metrics carried in the theme: touch (Android, iOS) versus
/// pointer (Windows, macOS, Linux). Read it with `context.density`.
///
/// One app can ship both: a Windows build gets 40 px controls and visible
/// scrollbars, the Android build of the same code gets 48 px touch targets.
@immutable
class AppDensity extends ThemeExtension<AppDensity> {
  const AppDensity({
    required this.isPointer,
    required this.control,
    required this.row,
    required this.visualDensity,
    required this.tapTargetSize,
  });

  /// Touch: 48 px controls, 56 px list rows, padded tap targets.
  /// DIRECTION: Soft Minimal / Playful may raise [control] to 52–56.
  static const AppDensity touch = AppDensity(
    isPointer: false,
    control: 48,
    row: 56,
    visualDensity: VisualDensity.standard,
    tapTargetSize: MaterialTapTargetSize.padded,
  );

  /// Mouse-driven desktop: 40 px controls and rows.
  static const AppDensity desktop = AppDensity(
    isPointer: true,
    control: 40,
    row: 40,
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  static AppDensity forPlatform(TargetPlatform platform) => switch (platform) {
        TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia => touch,
        TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux => desktop,
      };

  /// True on mouse platforms: hover states, cursors, visible scrollbars,
  /// tooltips on hover and keyboard shortcuts matter here.
  final bool isPointer;

  /// Height of buttons, inputs and other single-line controls.
  final double control;

  /// Minimum height of list and table rows.
  final double row;

  final VisualDensity visualDensity;
  final MaterialTapTargetSize tapTargetSize;

  @override
  AppDensity copyWith({
    bool? isPointer,
    double? control,
    double? row,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
  }) {
    return AppDensity(
      isPointer: isPointer ?? this.isPointer,
      control: control ?? this.control,
      row: row ?? this.row,
      visualDensity: visualDensity ?? this.visualDensity,
      tapTargetSize: tapTargetSize ?? this.tapTargetSize,
    );
  }

  @override
  AppDensity lerp(ThemeExtension<AppDensity>? other, double t) {
    if (other is! AppDensity) return this;
    return t < 0.5 ? this : other;
  }
}
