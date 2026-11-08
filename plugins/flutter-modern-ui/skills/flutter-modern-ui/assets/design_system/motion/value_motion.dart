import 'package:flutter/material.dart';

import '../app_typography.dart';
import '../context_ext.dart';
import '../tokens.dart';

/// A number that tweens to each new value from the value currently shown,
/// never from zero (unless [fromZero] on first appearance). Tabular figures,
/// so digits don't jiggle. Screen readers get the final value only.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    this.format,
    this.style,
    this.duration = AppDurations.slow,
    this.fromZero = false,
  });

  final double value;

  /// E.g. `(v) => NumberFormat.currency(locale: 'en', symbol: '\$').format(v)`.
  final String Function(double value)? format;
  final TextStyle? style;
  final Duration duration;

  /// Count up from zero the first time it appears (playful dashboards).
  final bool fromZero;

  String _text(double v) => format?.call(v) ?? v.round().toString();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: _text(value),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: fromZero ? 0 : value, end: value),
          duration: context.motion(duration),
          curve: AppCurves.standard,
          builder: (context, v, _) => Text(_text(v), style: (style ?? DefaultTextStyle.of(context).style).tabular),
        ),
      ),
    );
  }
}

/// Rounded progress bar that tweens from the previous value, never from 0.
/// Fills from the reading start (right in RTL).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.trackColor,
    this.height = AppSize.progressBar,
    this.semanticLabel,
  });

  /// 0 to 1.
  final double value;
  final Color? color;
  final Color? trackColor;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final fill = color ?? context.colors.primary;
    final track = trackColor ?? context.colors.surfaceContainerHighest;

    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: track,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: v, end: v),
              duration: context.motion(AppDurations.slow),
              curve: AppCurves.standard,
              builder: (context, t, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: t,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: fill, borderRadius: AppRadius.pillAll),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
