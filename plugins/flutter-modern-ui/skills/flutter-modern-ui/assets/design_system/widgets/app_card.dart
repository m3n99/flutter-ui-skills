import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';
import 'pressable.dart';

/// Flat, tonal card with a hairline border. Tappable cards scale on press.
/// Set [floating] only for elements that sit above content.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpace.card,
    this.color,
    this.borderRadius = AppRadius.lgAll,
    this.showBorder = true,
    this.floating = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius borderRadius;
  final bool showBorder;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = color ?? Theme.of(context).cardTheme.color ?? colors.surfaceContainerLowest;

    // A Material (not a DecoratedBox) so ink ripples of children like ListTile
    // render on top of the card fill instead of underneath it.
    Widget card = Material(
      color: fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: showBorder
            ? BorderSide(color: colors.outlineVariant.withValues(alpha: context.isDark ? 0.4 : 0.6))
            : BorderSide.none,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (floating) {
      card = DecoratedBox(
        decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: context.palette.softShadow),
        child: card,
      );
    }

    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}
