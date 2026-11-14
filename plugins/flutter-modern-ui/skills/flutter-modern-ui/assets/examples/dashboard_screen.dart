// Reference composition, Soft Minimal direction. Shows:
// - loading (skeleton shaped like the content), error (what failed + retry)
//   and content, switched with StateSwitcher;
// - greeting header, KPI tiles (emoji badges, raised tiles, equal heights,
//   values that shrink instead of overflowing, counters that tween);
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
    final outstanding = open.fold<int>(0, (sum, i) => sum + i.amountCents);
    final overdueAmount = overdue.fold<int>(0, (sum, i) => sum + i.amountCents);
    final collected = InvoiceRepository.collectedByMonth.last;

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = ContentWidth.horizontalPadding(box.maxWidth);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, 0),
                sliver: const SliverToBoxAdapter(child: _GreetingHeader()),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.lg, side, context.listEndPadding()),
                sliver: SliverList.list(
                  children: [
                    KpiGrid(
                      children: [
                        KpiTile(
                          emoji: '💰',
                          tone: StatusTone.info,
                          label: 'Outstanding',
                          value: AnimatedNumber(value: outstanding / 100, format: (v) => formatMoney((v * 100).round())),
                          caption: '${open.length} open invoices',
                          onTap: () {},
                        ),
                        KpiTile(
                          emoji: overdue.isEmpty ? '👌' : '🚨',
                          tone: overdue.isEmpty ? StatusTone.neutral : StatusTone.danger,
                          colorValue: overdue.isNotEmpty,
                          label: 'Overdue',
                          value: AnimatedNumber(value: overdueAmount / 100, format: (v) => formatMoney((v * 100).round())),
                          caption: '${overdue.length} invoices past due',
                          onTap: () {},
                        ),
                        KpiTile(
                          emoji: '✅',
                          tone: StatusTone.success,
                          colorValue: true,
                          label: 'Collected in November',
                          value: AnimatedNumber(value: collected / 100, format: (v) => formatMoney((v * 100).round())),
                          caption: '+20% vs October',
                        ),
                        KpiTile(
                          emoji: '📅',
                          tone: StatusTone.warning,
                          label: 'Due this week',
                          value: Text('${dueSoon.length}'),
                          caption: dueSoon.isEmpty ? null : 'Next: ${formatShortDate(dueSoon.last.due)}',
                        ),
                      ],
                    ),
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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Row(
      spacing: AppSpace.sm,
      children: [
        CircleAvatar(
          radius: AppSize.avatar / 2,
          backgroundColor: colors.primaryContainer,
          child: Text('MH', style: text.titleSmall?.copyWith(color: colors.onPrimaryContainer)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              Text('Maya Haddad', style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Badge(smallSize: 8, child: Icon(Icons.notifications_none_rounded)),
        ),
      ],
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
            final columns = box.maxWidth - 2 * side >= AppBreakpoints.expanded ? 4 : 2;
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    spacing: AppSpace.sm,
                    children: [
                      SkeletonBox.circle(size: AppSize.avatar),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.xs,
                        children: [SkeletonBox(width: 90, height: 12), SkeletonBox(width: 140, height: 18)],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  for (var row = 0; row < 4 ~/ columns; row++) ...[
                    Row(
                      spacing: AppSpace.sm,
                      children: [
                        for (var i = 0; i < columns; i++)
                          const Expanded(child: SkeletonBox(height: 112, borderRadius: AppRadius.cardAll)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                  ],
                  const SizedBox(height: AppSpace.sm),
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
