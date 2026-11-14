import 'package:flutter/material.dart';

import '../app_typography.dart';
import '../context_ext.dart';
import '../tokens.dart';
import 'app_card.dart';
import 'status_pill.dart';

/// Dashboard KPI tile: badge (emoji or icon) and label on top, the value
/// below (tabular, shrinks to fit instead of overflowing), optional caption.
///
/// [value] is a widget so it can be a plain Text or an AnimatedNumber; it is
/// styled headlineSmall + tabular figures. Color the value only for states
/// that need attention ([colorValue]).
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.emoji,
    this.icon,
    this.tone = StatusTone.neutral,
    this.caption,
    this.colorValue = false,
    this.onTap,
  });

  final String label;
  final Widget value;
  final String? emoji;
  final IconData? icon;
  final StatusTone tone;
  final String? caption;
  final bool colorValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final toneColors = tone.colorsOf(context);
    final badgeEmoji = emoji;
    final badgeIcon = icon;
    final note = caption;

    return AppCard(
      raised: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: AppSpace.sm,
            children: [
              if (badgeEmoji != null)
                EmojiBadge(badgeEmoji, color: toneColors.container)
              else if (badgeIcon != null)
                IconBadge(icon: badgeIcon, color: tone.strongOf(context), size: AppSize.emojiBadge),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: DefaultTextStyle.merge(
              style: text.headlineSmall.tabular?.copyWith(color: colorValue ? tone.strongOf(context) : null),
              maxLines: 1,
              child: value,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpace.xxs),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lays out KPI tiles in rows of equal height: 4 per row from 840 px of
/// available width, 2 per row, and 1 per row when the width text sees
/// (width ÷ text scale) is under two tiles' worth: small phones, big fonts.
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.children, this.spacing = AppSpace.sm});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = constraints.maxWidth / context.textScale;
        final columns = textWidth >= AppBreakpoints.expanded
            ? 4
            : textWidth >= AppSize.kpiTileMinWidth * 2
                ? 2
                : 1;
        return Column(
          spacing: spacing,
          children: [
            for (var start = 0; start < children.length; start += columns)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: spacing,
                  children: [
                    for (var i = start; i < start + columns; i++)
                      Expanded(child: i < children.length ? children[i] : const SizedBox.shrink()),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
