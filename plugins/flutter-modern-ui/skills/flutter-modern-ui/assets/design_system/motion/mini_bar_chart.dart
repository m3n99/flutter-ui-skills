import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_typography.dart';
import '../context_ext.dart';
import '../tokens.dart';

/// "Nice" axis bounds: ticks every 1, 2 or 5 × 10ⁿ, so labels read 0, 500,
/// 1000, 1500 instead of 0, 433, 866, 1300.
@immutable
class NiceScale {
  const NiceScale._(this.max, this.step);

  factory NiceScale.forMax(double value, {int ticks = 4}) {
    if (value <= 0) return const NiceScale._(4, 1);
    final raw = value / ticks;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final residual = raw / magnitude;
    final nice = residual <= 1
        ? 1
        : residual <= 2
            ? 2
            : residual <= 5
                ? 5
                : 10;
    final step = nice * magnitude;
    return NiceScale._((value / step).ceil() * step, step);
  }

  final double max;
  final double step;

  List<double> get ticks => [for (var i = 0; i * step <= max + step / 2; i++) i * step];
}

/// Small bar chart with no chart package: gridlines, a value axis on the
/// reading-start side (right in RTL), labels under the bars, and bars that
/// move from their previous heights to new ones.
///
/// While it sits in a hidden tab (TickerMode off) it keeps showing the last
/// values, so the change animates when the tab is opened instead of
/// finishing off-screen.
///
/// The same rules apply to fl_chart: see references/data-display.md.
class MiniBarChart extends StatefulWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.shortLabels,
    this.color,
    this.height = 180,
    this.formatTick,
    this.semanticLabel,
  }) : assert(values.length == labels.length);

  final List<double> values;
  final List<String> labels;

  /// Used when bars get narrower than 44 px (e.g. month numbers for names).
  final List<String>? shortLabels;

  /// Series color from the scheme or palette (never a hard-coded hex).
  final Color? color;
  final double height;
  final String Function(double value)? formatTick;

  /// One-sentence summary for screen readers ("Collected per month, highest in June").
  final String? semanticLabel;

  @override
  State<MiniBarChart> createState() => _MiniBarChartState();
}

class _MiniBarChartState extends State<MiniBarChart> {
  List<double> _shown = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(MiniBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (TickerMode.valuesOf(context).enabled) _shown = widget.values;
  }

  String _format(double value) => widget.formatTick?.call(value) ?? value.round().toString();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final values = _shown.length == widget.values.length ? _shown : List<double>.filled(widget.values.length, 0);
    final scale = NiceScale.forMax(values.fold<double>(0, math.max));
    final tickStyle = context.textStyles.labelSmall?.copyWith(color: colors.onSurfaceVariant).tabular;
    final textScaler = MediaQuery.textScalerOf(context);
    final tickLabels = [for (final tick in scale.ticks) _format(tick)];
    final lineHeight = textScaler.scale(tickStyle?.fontSize ?? 11) * (tickStyle?.height ?? 1.2);

    var axisWidth = 0.0;
    for (final label in tickLabels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: tickStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      axisWidth = math.max(axisWidth, painter.width);
      painter.dispose();
    }

    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Value axis on the reading-start side.
              SizedBox(
                width: axisWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var i = 0; i < scale.ticks.length; i++)
                              PositionedDirectional(
                                end: 0,
                                top: box.maxHeight * (1 - scale.ticks[i] / scale.max) - lineHeight / 2,
                                child: Text(tickLabels[i], style: tickStyle, maxLines: 1),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpace.xxs + lineHeight),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final narrow = widget.shortLabels != null && box.maxWidth / math.max(1, values.length) < 44;
                    final labels = narrow ? widget.shortLabels! : widget.labels;
                    return Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(child: _Gridlines(ticks: scale.ticks, max: scale.max)),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final value in values)
                                    Expanded(
                                      child: _Bar(
                                        fraction: value / scale.max,
                                        color: widget.color ?? colors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        SizedBox(
                          height: lineHeight,
                          child: Row(
                            children: [
                              for (final label in labels)
                                Expanded(
                                  child: Text(
                                    label,
                                    style: tickStyle,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gridlines extends StatelessWidget {
  const _Gridlines({required this.ticks, required this.max});

  final List<double> ticks;
  final double max;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.outlineVariant;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          for (final tick in ticks)
            Positioned(
              left: 0,
              right: 0,
              top: (box.maxHeight * (1 - tick / max) - AppStroke.hairline / 2).clamp(0.0, box.maxHeight - AppStroke.hairline),
              child: Container(height: AppStroke.hairline, color: color),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedFractionallySizedBox(
        duration: context.motion(AppDurations.slow),
        curve: AppCurves.standard,
        alignment: Alignment.bottomCenter,
        widthFactor: 0.56,
        heightFactor: fraction.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xs)),
          ),
        ),
      ),
    );
  }
}
