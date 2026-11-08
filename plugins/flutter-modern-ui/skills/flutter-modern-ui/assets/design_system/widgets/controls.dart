import 'package:flutter/material.dart';

import '../tokens.dart';

/// A group of choice or filter chips, 8 px apart both ways, or one scrolling
/// row for a filter bar. Selected chips show a check and a fill (theme), so
/// selection never depends on color alone; all chips share one height.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
    this.multiple = false,
    this.scrollable = false,
    this.padding = EdgeInsets.zero,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T option) labelOf;

  /// Called with the tapped option; the caller updates [selected].
  final ValueChanged<T> onToggle;

  /// FilterChips (several can be on) instead of ChoiceChips (one at a time).
  final bool multiple;

  /// One horizontally scrolling row instead of a wrapping block.
  final bool scrollable;

  /// Padding of the scrolling row (usually the screen padding).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
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
    return Wrap(spacing: AppSpace.xs, runSpacing: AppSpace.xs, children: chips);
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
