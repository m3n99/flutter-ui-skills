import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// Section title with an optional leading badge (emoji or icon), subtitle and
/// trailing action ("See all"). The action keeps the theme's control height,
/// so it stays a 48 px touch target on phones.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Shown before the action, e.g. a StatusPill with a count.
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final colors = context.colors;
    final label = actionLabel;
    final action = onAction;

    return Row(
      spacing: AppSpace.sm,
      children: [
        if (leading != null) leading!,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.xxs,
            children: [
              Text(title, style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (label != null && action != null) TextButton(onPressed: action, child: Text(label)),
      ],
    );
  }
}
