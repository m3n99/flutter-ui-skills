// Reference composition, Soft Minimal direction, built from the example
// app's brief (example_app.dart). Shows:
// - a home that answers the owner's daily question, "what do I still have to
//   collect, and who do I chase today?", with the one action beside the
//   answer, instead of a greeting over a grid of numbers;
// - the app's signature: ledger lines (label at the start, tabular amount at
//   the end, ruled between), used in this card and as the sign-in mark only;
// - loading (skeleton shaped like the content), error (what failed + retry)
//   and content, switched with StateSwitcher;
// - KPI tiles for what's worth a glance (raised tiles, equal heights, values
//   that shrink instead of overflowing, counters that tween);
// - a chart card (value axis on the reading-start side, bars that move from
//   their previous values, held while the tab is hidden);
// - a grouped list whose rows use the concentric radius (card 16, inset 8 → 8);
// - pull to refresh, content width cap, bottom inset.
//
// Presentation only: swap the local state for the project's state management.

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'sample_data.dart';

enum _Load { loading, error, ready }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository});

  final InvoiceRepository repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Load _status = _Load.loading;
  List<Invoice> _invoices = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSkeleton = true}) async {
    if (showSkeleton && _status != _Load.loading) setState(() => _status = _Load.loading);
    try {
      final invoices = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _status = _Load.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _Load.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StateSwitcher(
          child: switch (_status) {
            _Load.loading => const _DashboardSkeleton(key: ValueKey('loading')),
            _Load.error => EmptyState.error(
                key: const ValueKey('error'),
                title: "Couldn't load your dashboard",
                message: 'Check your connection and try again.',
                onRetry: _load,
              ),
            _Load.ready => _DashboardContent(
                key: const ValueKey('ready'),
                invoices: _invoices,
                onRefresh: () => _load(showSkeleton: false),
              ),
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({super.key, required this.invoices, required this.onRefresh});

  final List<Invoice> invoices;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final open = invoices.where((i) => i.isOpen).toList();
    final overdue = invoices.where((i) => i.status == InvoiceStatus.overdue).toList();
    final dueSoon = invoices.where((i) => i.status == InvoiceStatus.dueSoon).toList();
    final later = invoices.where((i) => i.status == InvoiceStatus.sent).toList();
    final drafts = invoices.where((i) => i.status == InvoiceStatus.draft).length;
    final collected = InvoiceRepository.collectedByMonth.last;

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = ContentWidth.horizontalPadding(box.maxWidth);
          final wide = box.maxWidth - 2 * side >= AppBreakpoints.expanded;
          final toCollect = _ToCollectCard(
            overdue: overdue,
            dueSoon: dueSoon,
            later: later,
            // The message uses the button's words and names the thing.
            onRemind: () => AppMessenger.success(
              overdue.length == 1 ? 'Sent a reminder to ${overdue.single.customer}' : 'Sent ${overdue.length} reminders',
            ),
          );
          final tiles = KpiGrid(
            children: [
              KpiTile(
                icon: Icons.payments_outlined,
                tone: StatusTone.success,
                colorValue: true,
                label: 'Collected in November',
                value: AnimatedNumber(value: collected / 100, format: (v) => formatMoney((v * 100).round())),
                caption: '+20% vs October',
              ),
              KpiTile(
                icon: Icons.description_outlined,
                tone: StatusTone.info,
                label: 'Open invoices',
                value: Text('${open.length}'),
                caption: switch (drafts) {
                  0 => null,
                  1 => '1 draft not sent yet',
                  _ => '$drafts drafts not sent yet',
                },
                onTap: () {},
              ),
            ],
          );
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, 0),
                sliver: SliverToBoxAdapter(child: Text('Overview', style: context.textStyles.headlineSmall)),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, context.listEndPadding()),
                sliver: SliverList.list(
                  children: [
                    // Wide windows: the answer and the glance tiles side by
                    // side, so the ledger lines don't stretch across a monitor.
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.sm,
                        children: [Expanded(child: toCollect), Expanded(child: tiles)],
                      )
                    else ...[
                      toCollect,
                      const SizedBox(height: AppSpace.sm),
                      tiles,
                    ],
                    const SizedBox(height: AppSpace.lg),
                    const SectionHeader(title: 'Collected per month', subtitle: 'Last 6 months'),
                    const SizedBox(height: AppSpace.sm),
                    AppCard(
                      child: MiniBarChart(
                        values: [for (final c in InvoiceRepository.collectedByMonth) c / 100],
                        labels: InvoiceRepository.monthLabels,
                        shortLabels: InvoiceRepository.monthNumbers,
                        color: context.palette.success.color,
                        formatTick: (v) => v >= 1000 ? '${(v / 1000).round()}k' : v.round().toString(),
                        semanticLabel: 'Collected per month, June to November, highest in November.',
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    SectionHeader(title: 'Due soon', actionLabel: 'See all', onAction: () {}),
                    const SizedBox(height: AppSpace.sm),
                    _DueSoonGroup(invoices: [...dueSoon, ...overdue]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The home screen's answer: what is still to collect, and what needs
/// chasing today, with that one action beside it.
class _ToCollectCard extends StatelessWidget {
  const _ToCollectCard({required this.overdue, required this.dueSoon, required this.later, required this.onRemind});

  final List<Invoice> overdue;
  final List<Invoice> dueSoon;
  final List<Invoice> later;
  final VoidCallback onRemind;

  static int _sum(List<Invoice> invoices) => invoices.fold<int>(0, (sum, i) => sum + i.amountCents);

  static String _count(List<Invoice> invoices) => invoices.length == 1 ? '1 invoice' : '${invoices.length} invoices';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final total = _sum(overdue) + _sum(dueSoon) + _sum(later);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('To collect', style: text.titleSmall?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: AppSpace.xxs),
          // The one big number on the screen.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Ltr(
              child: AnimatedNumber(
                value: total / 100,
                format: (v) => formatMoney((v * 100).round()),
                style: text.displaySmall.tabular,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          _LedgerLine(
            icon: Icons.error_outline_rounded,
            tone: overdue.isEmpty ? StatusTone.neutral : StatusTone.danger,
            label: 'Overdue',
            detail: _count(overdue),
            amountCents: _sum(overdue),
          ),
          const Divider(),
          _LedgerLine(
            icon: Icons.schedule_rounded,
            tone: dueSoon.isEmpty ? StatusTone.neutral : StatusTone.warning,
            label: 'Due this week',
            detail: _count(dueSoon),
            amountCents: _sum(dueSoon),
          ),
          const Divider(),
          _LedgerLine(
            icon: Icons.event_outlined,
            tone: StatusTone.neutral,
            label: 'Later',
            detail: _count(later),
            amountCents: _sum(later),
          ),
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRemind,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  overdue.length == 1 ? 'Send 1 reminder' : 'Send ${overdue.length} reminders',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The app's signature, a line of a ledger: what it is at the start, its
/// amount in tabular figures at the end, a rule between lines. The status is
/// an icon and words, never the color alone.
class _LedgerLine extends StatelessWidget {
  const _LedgerLine({
    required this.icon,
    required this.tone,
    required this.label,
    required this.detail,
    required this.amountCents,
  });

  final IconData icon;
  final StatusTone tone;
  final String label;
  final String detail;
  final int amountCents;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        spacing: AppSpace.sm,
        children: [
          Icon(icon, size: context.iconSize(AppIconSize.dense), color: tone.strongOf(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  detail,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Ltr(child: Text(formatMoney(amountCents), style: text.titleMedium.tabular)),
        ],
      ),
    );
  }
}

/// Rows sit 8 px inside a 16 px card, so their ink radius is 16 − 8 = 8.
class _DueSoonGroup extends StatelessWidget {
  const _DueSoonGroup({required this.invoices});

  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.event_available_rounded,
          title: 'Nothing due this week',
          message: 'Invoices due in the next 7 days show up here.',
        ),
      );
    }

    const inset = AppSpace.xs;
    final rowRadius = BorderRadius.circular(AppRadius.concentric(AppRadius.card, inset));
    final text = context.textStyles;
    // Big fonts or a small phone: the amount and the pill move under the
    // details instead of squeezing the name.
    final narrow = context.isNarrow;

    return AppCard(
      padding: const EdgeInsets.all(inset),
      child: Column(
        spacing: AppSpace.xxs,
        children: [
          for (final invoice in invoices)
            InkWell(
              borderRadius: rowRadius,
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                child: Row(
                  spacing: AppSpace.sm,
                  children: [
                    IconBadge(icon: invoice.status.icon, color: invoice.status.tone.strongOf(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.xxs,
                        children: [
                          Text(
                            invoice.customer,
                            style: text.titleSmall,
                            maxLines: narrow ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.xxs,
                            children: [
                              MetaItem(icon: Icons.tag_rounded, text: invoice.number, ltr: true),
                              MetaItem(icon: Icons.event_outlined, text: 'Due ${formatShortDate(invoice.due)}'),
                            ],
                          ),
                          if (narrow) ...[
                            Ltr(child: Text(formatMoney(invoice.amountCents), style: text.titleSmall.tabular)),
                            invoice.status.pill,
                          ],
                        ],
                      ),
                    ),
                    if (!narrow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: AppSpace.xxs,
                        children: [
                          Ltr(child: Text(formatMoney(invoice.amountCents), style: text.titleSmall.tabular)),
                          invoice.status.pill,
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowAfter(
      child: Shimmer(
        child: LayoutBuilder(
          builder: (context, box) {
            final side = ContentWidth.horizontalPadding(box.maxWidth);
            final wide = box.maxWidth - 2 * side >= AppBreakpoints.expanded;
            const tiles = Row(
              spacing: AppSpace.sm,
              children: [
                Expanded(child: SkeletonBox(height: 112, borderRadius: AppRadius.cardAll)),
                Expanded(child: SkeletonBox(height: 112, borderRadius: AppRadius.cardAll)),
              ],
            );
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 140, height: 24),
                  const SizedBox(height: AppSpace.md),
                  // The same shape as the content: side by side when wide.
                  if (wide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.sm,
                      children: [
                        Expanded(child: SkeletonBox(height: 220, borderRadius: AppRadius.cardAll)),
                        Expanded(child: tiles),
                      ],
                    )
                  else ...[
                    const SkeletonBox(height: 300, borderRadius: AppRadius.cardAll),
                    const SizedBox(height: AppSpace.sm),
                    tiles,
                  ],
                  const SizedBox(height: AppSpace.lg),
                  const SkeletonBox(width: 180, height: 18),
                  const SizedBox(height: AppSpace.sm),
                  const SkeletonBox(height: 212, borderRadius: AppRadius.cardAll),
                  const SizedBox(height: AppSpace.lg),
                  const SkeletonBox(width: 120, height: 18),
                  const SizedBox(height: AppSpace.sm),
                  const SkeletonBox(height: 180, borderRadius: AppRadius.cardAll),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
