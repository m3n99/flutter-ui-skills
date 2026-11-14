import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';
import 'ltr.dart';

/// One detail of a card row: a small icon and muted text ("INV-1041",
/// "Due Nov 22", "3 checks"). The icon grows with big fonts (up to 1.4×)
/// and never carries the meaning alone.
///
/// Put several in a `Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.xxs)`
/// so they flow onto a second line instead of truncating.
class MetaItem extends StatelessWidget {
  const MetaItem({super.key, required this.icon, required this.text, this.ltr = false, this.maxLines = 1});

  final IconData icon;
  final String text;

  /// Codes, numbers, dates and phone numbers inside right-to-left text.
  final bool ltr;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurfaceVariant;
    final label = Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: context.textStyles.bodySmall?.copyWith(color: color),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.xxs,
      children: [
        Icon(icon, size: context.iconSize(AppIconSize.inline), color: color),
        Flexible(child: ltr ? Ltr(child: label) : label),
      ],
    );
  }
}
