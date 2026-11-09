import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// A group of choice or filter chips, 8 px apart both ways, optionally led
/// by an inline [label] ("Paper  [A4] [A5]"). Selected chips show a check
/// and a fill (theme), so selection never depends on color alone; all chips
/// share one height.
///
/// Wraps by default, so every option stays visible on a 360 px phone: the
/// label stays with the first chip and later chips wrap under it. Use
/// [scrollable] only for a long filter list under a header, never for a few
/// single-choice options (the last ones end up off-screen).
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
    this.label,
    this.multiple = false,
    this.scrollable = false,
    this.padding = EdgeInsets.zero,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T option) labelOf;

  /// Called with the tapped option; the caller updates [selected].
  final ValueChanged<T> onToggle;

  /// Inline label, the first child of the same wrap (or row), centered on
  /// the chips. For a label above the group, use a section label instead.
  final String? label;

  /// FilterChips (several can be on) instead of ChoiceChips (one at a time).
  final bool multiple;

  /// One horizontally scrolling row instead of a wrapping block: long filter
  /// lists only.
  final bool scrollable;

  /// Padding of the scrolling row (usually the screen padding).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (label case final text?) Text(text, style: context.textStyles.titleSmall),
      for (final option in options)
        multiple
            ? FilterChip(
                label: Text(labelOf(option)),
                selected: selected.contains(option),
                onSelected: (_) => onToggle(option),
              )
            : ChoiceChip(
                label: Text(labelOf(option)),
                selected: selected.contains(option),
                onSelected: (_) => onToggle(option),
              ),
    ];

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(spacing: AppSpace.xs, children: chips),
      );
    }
    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }
}

/// Small circular progress for buttons and inline loading.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = AppSize.spinner, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
