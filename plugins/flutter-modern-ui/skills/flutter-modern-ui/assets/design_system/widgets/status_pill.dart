import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// Tone of a status, badge or tile. Business states map onto these (or onto
/// extra tones added to AppPalette); `danger` is for failures, not for
/// ordinary states like "overdue" if the app has many of them.
enum StatusTone { neutral, primary, success, warning, info, danger }

extension StatusToneColors on StatusTone {
  /// Container fill and its content color.
  ({Color container, Color onContainer}) colorsOf(BuildContext context) {
    final c = context.colors;
    final p = context.palette;
    return switch (this) {
      StatusTone.neutral => (container: c.surfaceContainerHighest, onContainer: c.onSurfaceVariant),
      StatusTone.primary => (container: c.primaryContainer, onContainer: c.onPrimaryContainer),
      StatusTone.success => (container: p.success.container, onContainer: p.success.onContainer),
      StatusTone.warning => (container: p.warning.container, onContainer: p.warning.onContainer),
      StatusTone.info => (container: p.info.container, onContainer: p.info.onContainer),
      StatusTone.danger => (container: c.errorContainer, onContainer: c.onErrorContainer),
    };
  }

  /// Strong color for text or icons drawn directly on a surface.
  Color strongOf(BuildContext context) {
    final c = context.colors;
    final p = context.palette;
    return switch (this) {
      StatusTone.neutral => c.onSurfaceVariant,
      StatusTone.primary => c.primary,
      StatusTone.success => p.success.color,
      StatusTone.warning => p.warning.color,
      StatusTone.info => p.info.color,
      StatusTone.danger => c.error,
    };
  }
}

/// Small rounded status label ("Paid", "Due in 3 days", "Overdue").
///
/// The icon is required: status is never shown by color alone. Map each
/// domain status to one label, one icon and one tone in a single place
/// (an enum extension) and build pills only from that.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.icon, this.tone = StatusTone.neutral});

  final String label;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = tone.colorsOf(context);

    // One rich text (icon as a WidgetSpan) instead of a Row with Flexible:
    // works in unbounded slots (trailing columns, horizontal lists) and
    // still ellipsizes when space is tight.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: AppSpace.xxs),
      decoration: BoxDecoration(color: colors.container, borderRadius: AppRadius.pillAll),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.xxs),
                child: Icon(icon, size: AppIconSize.pill, color: colors.onContainer),
              ),
            ),
            TextSpan(text: label),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.labelMedium?.copyWith(color: colors.onContainer),
      ),
    );
  }
}

/// Icon inside a softly tinted circle: the quickest way to make list rows
/// look designed.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.color, this.size = AppSize.iconBadge});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint.withValues(alpha: AppOpacity.tint), shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: tint),
    );
  }
}

/// Emoji on a tinted rounded square. An emoji is treated as an icon: fixed
/// size (it does not grow with the text scale), one emoji per meaning, and
/// never the only carrier of meaning, so keep the text label next to it.
///
/// `flutter_test` has no emoji font: emoji render as boxes in screenshots
/// but in color on devices.
class EmojiBadge extends StatelessWidget {
  const EmojiBadge(this.emoji, {super.key, this.color, this.size = AppSize.emojiBadge});

  final String emoji;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color ?? context.colors.secondaryContainer,
          borderRadius: AppRadius.smAll,
        ),
        child: Text(
          emoji,
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontSize: size * 0.55, height: 1),
        ),
      ),
    );
  }
}
