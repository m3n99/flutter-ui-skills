// The example app's signature, built once (references/identity.md › Find the
// signature): the lines of a ledger. What something is sits at the reading
// start, its figure in tabular numerals at the end, and a rule separates one
// line from the next.
//
// It appears in three places and nowhere else, as the brief in
// example_app.dart records:
// - the home screen's "To collect" card (dashboard_screen.dart);
// - an invoice's details (records_screen.dart);
// - the sign-in mark, its smallest form (sign_in_screen.dart).
//
// A project's signature is its own: take the pattern (one shared widget, from
// tokens, in one to three named places), not these lines.

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Ledger lines with a rule between them.
class Ledger extends StatelessWidget {
  const Ledger({super.key, required this.lines});

  final List<LedgerLine> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, line) in lines.indexed) ...[
          if (index > 0) const Divider(),
          line,
        ],
      ],
    );
  }
}

/// One line of a [Ledger]: [label] (and [detail] under it) at the start,
/// [value] at the end. A status is an [icon] in its [tone] plus the words,
/// never the color alone.
class LedgerLine extends StatelessWidget {
  const LedgerLine({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.icon,
    this.tone = StatusTone.neutral,
    this.ltrValue = true,
  });

  final String label;
  final String? detail;

  /// The figure: an amount, a date, a number.
  final String value;
  final IconData? icon;
  final StatusTone tone;

  /// Amounts, dates and numbers read left to right inside right-to-left
  /// text. False for a value that is words (a status).
  final bool ltrValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final icon = this.icon;
    final detail = this.detail;
    final figure = Text(value, style: text.titleMedium.tabular);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        spacing: AppSpace.sm,
        children: [
          if (icon != null) Icon(icon, size: context.iconSize(AppIconSize.dense), color: tone.strongOf(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (detail != null)
                  Text(
                    detail,
                    style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (ltrValue) Ltr(child: figure) else figure,
        ],
      ),
    );
  }
}

/// The brand mark: three ledger lines, the last one the total.
class LedgerMark extends StatelessWidget {
  const LedgerMark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppIconSize.hero,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.primary, borderRadius: AppRadius.controlAll),
          child: CustomPaint(painter: _LedgerMarkPainter(colors.onPrimary)),
        ),
      ),
    );
  }
}

class _LedgerMarkPainter extends CustomPainter {
  const _LedgerMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width / 16;
    final total = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width / 8;
    final start = size.width * 0.28;
    final end = size.width * 0.72;

    canvas.drawLine(Offset(start, size.height * 0.32), Offset(end, size.height * 0.32), line);
    canvas.drawLine(Offset(start, size.height * 0.48), Offset(end, size.height * 0.48), line);
    // The total: heavier, and only as wide as the amounts column.
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.68), Offset(end, size.height * 0.68), total);
  }

  @override
  bool shouldRepaint(_LedgerMarkPainter oldDelegate) => oldDelegate.color != color;
}
