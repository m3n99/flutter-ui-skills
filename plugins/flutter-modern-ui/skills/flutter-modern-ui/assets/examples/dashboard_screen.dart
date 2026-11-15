// Reference composition, Soft Minimal direction, built from the example
// app's brief (example_app.dart). Shows:
// - a home that answers the owner's daily question, "what do I still have to
//   collect, and who do I chase today?", with the one action beside the
//   answer, instead of a greeting over a grid of numbers;
// - the app's signature, ledger lines (ledger.dart), in the "To collect"
//   card;
// - real Arabic in right-to-left (home_strings.dart): plural forms, verbal
//   nouns on the button, month names, not English mirrored;
// - nothing tappable that does nothing: the tile, "See all" and the rows
//   call back to the shell, and are plain when no callback is given;
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
import 'home_strings.dart';
import 'ledger.dart';
import 'sample_data.dart';

enum _Load { loading, error, ready }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository, this.onSeeInvoices, this.onOpenInvoice});

  final InvoiceRepository repository;

  /// Opens the invoice list (the "Open invoices" tile, "See all"). Without
  /// it they are plain, not dead buttons.
  final VoidCallback? onSeeInvoices;

  /// Opens one invoice (a "Due soon" row).
  final ValueChanged<Invoice>? onOpenInvoice;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Load _status = _Load.loading;
  List<Invoice> _invoices = const [];

  @override
  void initState() {
    super.initState();
    widget.repository.changes.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    widget.repository.changes.removeListener(_refresh);
    super.dispose();
  }

  /// An invoice changed on another screen: reload quietly.
  void _refresh() {
    if (mounted && _status == _Load.ready) _load(showSkeleton: false);
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
    final strings = HomeStrings.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StateSwitcher(
          child: switch (_status) {
            _Load.loading => const _DashboardSkeleton(key: ValueKey('loading')),
            _Load.error => EmptyState.error(
                key: const ValueKey('error'),
                title: strings.loadFailedTitle,
                message: strings.loadFailedMessage,
                actionLabel: strings.retry,
                onRetry: _load,
              ),
            _Load.ready => _DashboardContent(
                key: const ValueKey('ready'),
                invoices: _invoices,
                onRefresh: () => _load(showSkeleton: false),
                onSeeInvoices: widget.onSeeInvoices,
                onOpenInvoice: widget.onOpenInvoice,
              ),
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    super.key,
    required this.invoices,
    required this.onRefresh,
    required this.onSeeInvoices,
    required this.onOpenInvoice,
  });

  final List<Invoice> invoices;
  final Future<void> Function() onRefresh;
  final VoidCallback? onSeeInvoices;
  final ValueChanged<Invoice>? onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final strings = HomeStrings.of(context);
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
              overdue.length == 1 ? strings.sentReminderTo(overdue.single.customer) : strings.sentReminders(overdue.length),
            ),
          );
          final tiles = KpiGrid(
            children: [
              KpiTile(
                icon: Icons.payments_outlined,
                tone: StatusTone.success,
                colorValue: true,
                label: strings.collectedThisMonth,
                value: AnimatedNumber(value: collected / 100, format: (v) => formatMoney((v * 100).round())),
                caption: strings.comparedWithLastMonth,
              ),
              KpiTile(
                icon: Icons.description_outlined,
                tone: StatusTone.info,
                label: strings.openInvoices,
                value: Text('${open.length}'),
                caption: strings.draftsNotSent(drafts),
                onTap: onSeeInvoices,
              ),
            ],
          );
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, 0),
                sliver: SliverToBoxAdapter(child: Text(strings.title, style: context.textStyles.headlineSmall)),
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
                    SectionHeader(title: strings.collectedPerMonth, subtitle: strings.lastSixMonths),
                    const SizedBox(height: AppSpace.sm),
                    AppCard(
                      child: MiniBarChart(
                        values: [for (final c in InvoiceRepository.collectedByMonth) c / 100],
                        labels: strings.chartMonths,
                        shortLabels: InvoiceRepository.monthNumbers,
                        color: context.palette.success.color,
                        formatTick: (v) => v >= 1000 ? '${(v / 1000).round()}k' : v.round().toString(),
                        semanticLabel: strings.chartDescription,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    SectionHeader(
                      title: strings.dueSoon,
                      actionLabel: onSeeInvoices == null ? null : strings.seeAll,
                      onAction: onSeeInvoices,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    _DueSoonGroup(invoices: [...dueSoon, ...overdue], onOpen: onOpenInvoice),
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

  @override
  Widget build(BuildContext context) {
    final strings = HomeStrings.of(context);
    final colors = context.colors;
    final text = context.textStyles;
    final total = _sum(overdue) + _sum(dueSoon) + _sum(later);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.toCollect, style: text.titleSmall?.copyWith(color: colors.onSurfaceVariant)),
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
          // The signature: what makes up the total, as ledger lines.
          Ledger(
            lines: [
              LedgerLine(
                icon: Icons.error_outline_rounded,
                tone: overdue.isEmpty ? StatusTone.neutral : StatusTone.danger,
                label: strings.overdue,
                detail: strings.invoices(overdue.length),
                value: formatMoney(_sum(overdue)),
              ),
              LedgerLine(
                icon: Icons.schedule_rounded,
                tone: dueSoon.isEmpty ? StatusTone.neutral : StatusTone.warning,
                label: strings.dueThisWeek,
                detail: strings.invoices(dueSoon.length),
                value: formatMoney(_sum(dueSoon)),
              ),
              LedgerLine(
                icon: Icons.event_outlined,
                label: strings.later,
                detail: strings.invoices(later.length),
                value: formatMoney(_sum(later)),
              ),
            ],
          ),
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRemind,
                icon: const Icon(Icons.send_rounded),
                label: Text(strings.sendReminders(overdue.length), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rows sit 8 px inside a 16 px card, so their ink radius is 16 − 8 = 8.
class _DueSoonGroup extends StatelessWidget {
  const _DueSoonGroup({required this.invoices, required this.onOpen});

  final List<Invoice> invoices;
  final ValueChanged<Invoice>? onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = HomeStrings.of(context);
    if (invoices.isEmpty) {
      return AppCard(
        child: EmptyState(
          icon: Icons.event_available_rounded,
          title: strings.nothingDueTitle,
          message: strings.nothingDueMessage,
        ),
      );
    }
    final onOpen = this.onOpen;

    const inset = AppSpace.xs;
    final rowRadius = BorderRadius.circular(AppRadius.concentric(AppRadius.card, inset));
    final text = context.textStyles;
    // Big fonts or a small phone: the amount and the pill move under the
    // details instead of squeezing the name.
    final narrow = context.isNarrow;

    // The status in the screen's language: one icon, one tone, one label.
    StatusPill pill(Invoice invoice) =>
        StatusPill(label: strings.status(invoice.status), icon: invoice.status.icon, tone: invoice.status.tone);

    return AppCard(
      padding: const EdgeInsets.all(inset),
      child: Column(
        spacing: AppSpace.xxs,
        children: [
          for (final invoice in invoices)
            InkWell(
              borderRadius: rowRadius,
              // No callback: a plain row, not a tap that does nothing.
              onTap: onOpen == null ? null : () => onOpen(invoice),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                child: Row(
                  spacing: AppSpace.sm,
                  children: [
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
                              MetaItem(icon: Icons.event_outlined, text: strings.due(invoice.due)),
                            ],
                          ),
                          if (narrow) ...[
                            Ltr(child: Text(formatMoney(invoice.amountCents), style: text.titleSmall.tabular)),
                            pill(invoice),
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
                          pill(invoice),
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
