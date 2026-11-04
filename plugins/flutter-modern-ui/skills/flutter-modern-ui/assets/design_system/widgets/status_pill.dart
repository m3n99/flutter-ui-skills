import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

enum StatusTone { neutral, primary, success, warning, info, error }

/// Small rounded label for states ("Paid", "Pending", "Overdue").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = StatusTone.neutral, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = context.palette;
    final (Color bg, Color fg) = switch (tone) {
      StatusTone.neutral => (c.surfaceContainerHighest, c.onSurfaceVariant),
      StatusTone.primary => (c.primaryContainer, c.onPrimaryContainer),
      StatusTone.success => (p.successContainer, p.onSuccessContainer),
      StatusTone.warning => (p.warningContainer, p.onWarningContainer),
      StatusTone.info => (p.infoContainer, p.onInfoContainer),
      StatusTone.error => (c.errorContainer, c.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs + 2, vertical: AppSpace.xxs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.xxs,
        children: [
          if (icon != null) Icon(icon, size: 14, color: fg),
          Text(label, style: context.textStyles.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Icon inside a softly tinted circle. The quickest way to make rows look designed.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.color, this.size = 44});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: tint),
    );
  }
}
