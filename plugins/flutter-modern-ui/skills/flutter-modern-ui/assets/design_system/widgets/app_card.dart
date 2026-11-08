import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';
import 'press_scale.dart';

/// Flat card: tonal fill, hairline border, clips its children.
///
/// Tappable cards get ink (ripple, hover and focus highlight, click cursor),
/// a border that darkens on hover, and a press scale.
///
/// [raised] is the one exception to flat cards, for dashboard tiles: a soft
/// two-layer shadow that grows on hover. Light mode drops the border (the
/// shadow replaces it); dark mode keeps it, because shadows barely read there.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = AppSpace.card,
    this.color,
    this.borderRadius = AppRadius.cardAll,
    this.border = true,
    this.raised = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius borderRadius;
  final bool border;
  final bool raised;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _onHover(bool hovered) {
    if (_hovered != hovered) setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = widget.color ?? Theme.of(context).cardTheme.color ?? colors.surfaceContainerLowest;
    final showBorder = widget.border && !(widget.raised && !context.isDark);
    final hovered = _hovered && _interactive;

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (_interactive) {
      content = InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onHover: _onHover,
        child: content,
      );
    }

    Widget card = Material(
      color: fill,
      clipBehavior: Clip.antiAlias,
      animationDuration: context.motion(AppDurations.fast),
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius,
        side: showBorder ? BorderSide(color: hovered ? colors.outline : colors.outlineVariant) : BorderSide.none,
      ),
      child: content,
    );

    if (widget.raised) {
      final palette = context.palette;
      card = AnimatedContainer(
        duration: context.motion(AppDurations.fast),
        curve: AppCurves.standard,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: hovered ? palette.hoverShadow : palette.softShadow,
        ),
        child: card,
      );
    }

    return _interactive ? PressScale(child: card) : card;
  }
}
