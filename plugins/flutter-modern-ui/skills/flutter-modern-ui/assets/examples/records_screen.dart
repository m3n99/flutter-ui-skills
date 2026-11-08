// Reference composition: a records list that scales from phone to desktop.
// Shows:
// - search + status filter chips + a filter sheet (SheetScaffold: sections,
//   chips with checks, "Clear all" in place, "Apply (n)");
// - AnimatedItems: filters and search animate rows out and in, new records
//   grow in at the top, a new sort replays the staggered entrance;
// - delete: confirm dialog → row hides at once → message with Undo →
//   committed only when the message closes without Undo;
// - list-detail from 840 px (selected row + detail pane that cross-fades),
//   push to a detail page on phones;
// - loading skeleton, error with retry, first-use and no-results empty states.

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'record_form_screen.dart';
import 'sample_data.dart';

enum InvoiceSort { dueDate, amount, customer }

extension InvoiceSortLabel on InvoiceSort {
  String get label => switch (this) {
        InvoiceSort.dueDate => 'Due date',
        InvoiceSort.amount => 'Amount',
        InvoiceSort.customer => 'Customer',
      };
}

@immutable
class InvoiceFilters {
  const InvoiceFilters({this.statuses = const {}, this.sort = InvoiceSort.dueDate});

  final Set<InvoiceStatus> statuses;
  final InvoiceSort sort;

  /// Shown on the Apply button and the filter badge.
  int get activeCount => statuses.length + (sort == InvoiceSort.dueDate ? 0 : 1);

  InvoiceFilters toggle(InvoiceStatus status) {
    final next = {...statuses};
    if (!next.remove(status)) next.add(status);
    return InvoiceFilters(statuses: next, sort: sort);
  }

  List<Invoice> apply(Iterable<Invoice> invoices, String query) {
    final q = query.trim().toLowerCase();
    final result = [
      for (final invoice in invoices)
        if ((statuses.isEmpty || statuses.contains(invoice.status)) &&
            (q.isEmpty || invoice.customer.toLowerCase().contains(q) || invoice.number.toLowerCase().contains(q)))
          invoice,
    ];
    switch (sort) {
      case InvoiceSort.dueDate:
        result.sort((a, b) => a.due.compareTo(b.due));
      case InvoiceSort.amount:
        result.sort((a, b) => b.amountCents.compareTo(a.amountCents));
      case InvoiceSort.customer:
        result.sort((a, b) => a.customer.compareTo(b.customer));
    }
    return result;
  }
}

/// Opens the filter sheet (bottom sheet on phones, dialog from 600 px).
/// Returns the new filters, or null when dismissed.
Future<InvoiceFilters?> showInvoiceFilters(BuildContext context, InvoiceFilters current) {
  return showAppSheet<InvoiceFilters>(context: context, builder: (_) => _FilterSheet(initial: current));
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final InvoiceFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<InvoiceStatus> _statuses = {...widget.initial.statuses};
  late InvoiceSort _sort = widget.initial.sort;

  InvoiceFilters get _draft => InvoiceFilters(statuses: _statuses, sort: _sort);

  @override
  Widget build(BuildContext context) {
    final count = _draft.activeCount;

    return SheetScaffold(
      title: 'Filter invoices',
      // Clears the choices in the sheet; Apply makes it stick.
      secondaryAction: OutlinedButton(
        onPressed: count == 0
            ? null
            : () => setState(() {
                  _statuses = {};
                  _sort = InvoiceSort.dueDate;
                }),
        child: const Text('Clear all'),
      ),
      primaryAction: FilledButton(
        onPressed: () => Navigator.of(context).pop(_draft),
        child: Text(count == 0 ? 'Apply' : 'Apply ($count)'),
      ),
      children: [
        SheetSection(
          label: 'Status',
          child: AppChoiceChips<InvoiceStatus>(
            options: InvoiceStatus.values,
            selected: _statuses,
            labelOf: (status) => status.label,
            multiple: true,
            onToggle: (status) => setState(() {
              if (!_statuses.remove(status)) _statuses.add(status);
            }),
          ),
        ),
        SheetSection(
          label: 'Sort by',
          child: AppChoiceChips<InvoiceSort>(
            options: InvoiceSort.values,
            selected: {_sort},
            labelOf: (sort) => sort.label,
            onToggle: (sort) => setState(() => _sort = sort),
          ),
        ),
      ],
    );
  }
}

enum _Load { loading, error, ready }

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.repository});

  final InvoiceRepository repository;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final PendingDeletes<int> _pending = PendingDeletes<int>();
  final TextEditingController _search = TextEditingController();
  _Load _status = _Load.loading;
  List<Invoice> _all = const [];
  InvoiceFilters _filters = const InvoiceFilters();
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _pending.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet && _status != _Load.loading) setState(() => _status = _Load.loading);
    try {
      final invoices = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _all = invoices;
        _status = _Load.ready;
      });
    } catch (failure) {
      if (!mounted) return;
      if (quiet) {
        AppMessenger.showFailure(failure, whatFailed: "Couldn't refresh the invoices. Pull down to try again.");
      } else {
        setState(() => _status = _Load.error);
      }
    }
  }

  List<Invoice> get _visible => _filters.apply(_pending.visible(_all, (invoice) => invoice.id), _search.text);

  Future<void> _openFilters() async {
    final result = await showInvoiceFilters(context, _filters);
    if (result != null && mounted) setState(() => _filters = result);
  }

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<Invoice>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => RecordFormScreen(repository: widget.repository)),
    );
    if (created != null && mounted) await _load(quiet: true);
  }

  void _open(Invoice invoice, {required bool wide}) {
    if (wide) {
      setState(() => _selectedId = invoice.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(invoice.number)),
          body: _DetailPane(invoice: invoice, onDelete: () => _delete(invoice, popRoute: true)),
        ),
      ),
    );
  }

  Future<void> _delete(Invoice invoice, {bool popRoute = false}) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${invoice.number}?'),
        content: Text('The invoice for ${invoice.customer} will be removed. You can undo this for a few seconds.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (popRoute) Navigator.of(context).pop();
    if (_selectedId == invoice.id) setState(() => _selectedId = null);

    await AppMessenger.deleteWithUndo<int>(
      pending: _pending,
      key: invoice.id,
      message: 'Deleted ${invoice.number} for ${invoice.customer}',
      commit: () => widget.repository.delete(invoice.id),
      reload: () => _load(quiet: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.windowSize.atLeast(WindowSize.expanded);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New invoice'),
      ),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _pending,
          builder: (context, _) {
            final list = _buildList(context, wide: wide);
            if (!wide) return list;

            Invoice? match;
            for (final invoice in _all) {
              if (invoice.id == _selectedId && !_pending.contains(invoice.id)) match = invoice;
            }
            final selected = match;
            return Row(
              children: [
                Expanded(flex: 5, child: list),
                const VerticalDivider(width: AppStroke.hairline),
                Expanded(
                  flex: 4,
                  child: StateSwitcher(
                    child: selected == null
                        ? const EmptyState(
                            key: ValueKey('none'),
                            icon: Icons.receipt_long_rounded,
                            title: 'Select an invoice',
                            message: 'Its details show up here.',
                          )
                        : _DetailPane(
                            key: ValueKey(selected.id),
                            invoice: selected,
                            onDelete: () => _delete(selected),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, {required bool wide}) {
    final visible = _visible;
    final filtering = _filters.activeCount > 0 || _search.text.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverAppBar.medium(
          title: const Text('Invoices'),
          actions: [
            IconButton(
              tooltip: 'Filters',
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: _filters.activeCount > 0,
                label: Text('${_filters.activeCount}'),
                child: const Icon(Icons.tune_rounded),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.sm),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search customer or number',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(tooltip: 'Clear search', onPressed: _search.clear, icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: AppChoiceChips<InvoiceStatus>(
            options: InvoiceStatus.values,
            selected: _filters.statuses,
            labelOf: (status) => status.label,
            multiple: true,
            scrollable: true,
            padding: AppSpace.screenH,
            onToggle: (status) => setState(() => _filters = _filters.toggle(status)),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.md)),
        ...switch (_status) {
          _Load.loading => [const SliverToBoxAdapter(child: _ListSkeleton())],
          _Load.error => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState.error(
                  title: "Couldn't load your invoices",
                  message: 'Check your connection and try again.',
                  onRetry: _load,
                ),
              ),
            ],
          _Load.ready => [
              SliverPadding(
                padding: AppSpace.screenH,
                sliver: AnimatedItems<Invoice>(
                  items: visible,
                  keyOf: (invoice) => invoice.id,
                  spacing: AppSpace.sm,
                  itemBuilder: (context, invoice) => _InvoiceCard(
                    invoice: invoice,
                    selected: wide && invoice.id == _selectedId,
                    onTap: () => _open(invoice, wide: wide),
                    onDelete: () => _delete(invoice),
                  ),
                ),
              ),
              if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: filtering
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No invoices match',
                          message: 'Try another search or clear the filters.',
                          actionLabel: 'Clear filters',
                          onAction: () {
                            _search.clear();
                            setState(() => _filters = const InvoiceFilters());
                          },
                        )
                      : EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'No invoices yet',
                          message: 'Invoices you create show up here.',
                          actionLabel: 'New invoice',
                          onAction: _openForm,
                        ),
                ),
            ],
        },
        // Clears the floating button and the home indicator.
        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpace.xxl * 2)),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.selected, required this.onTap, required this.onDelete});

  final Invoice invoice;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Semantics(
      selected: selected,
      child: AppCard(
        onTap: onTap,
        color: selected ? colors.secondaryContainer : null,
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.md, AppSpace.md, AppSpace.xs, AppSpace.md),
        child: Row(
          spacing: AppSpace.xs,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.xxs,
                children: [
                  Row(
                    spacing: AppSpace.sm,
                    children: [
                      Expanded(
                        child: Text(invoice.customer, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Ltr(child: Text(formatMoney(invoice.amountCents), style: text.titleMedium.tabular)),
                    ],
                  ),
                  Text(
                    '${invoice.number} · due ${formatShortDate(invoice.due)}',
                    style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  invoice.status.pill,
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete ${invoice.number}',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane({super.key, required this.invoice, required this.onDelete});

  final Invoice invoice;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    Widget row(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Row(
            children: [
              Expanded(child: Text(label, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant))),
              value,
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        Text(invoice.customer, style: text.headlineSmall),
        const SizedBox(height: AppSpace.xxs),
        Text(invoice.number, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: AppSpace.lg),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Ltr(child: Text(formatMoney(invoice.amountCents), style: text.displaySmall.tabular)),
        ),
        const SizedBox(height: AppSpace.xs),
        Align(alignment: AlignmentDirectional.centerStart, child: invoice.status.pill),
        const SizedBox(height: AppSpace.lg),
        AppCard(
          child: Column(
            children: [
              row('Due date', Ltr(child: Text(formatShortDate(invoice.due), style: text.titleSmall.tabular))),
              const Divider(),
              row('Status', Text(invoice.status.label, style: text.titleSmall)),
              const Divider(),
              row('Number', Ltr(child: Text(invoice.number, style: text.titleSmall.tabular))),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          spacing: AppSpace.xs,
          children: [
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
            ),
            Expanded(
              child: FilledButton.icon(
                onPressed: invoice.status == InvoiceStatus.paid ? null : () {},
                icon: const Icon(Icons.check_rounded),
                label: const Text('Mark as paid'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShowAfter(
      child: Shimmer(
        child: Padding(
          padding: AppSpace.screenH,
          child: Column(
            spacing: AppSpace.sm,
            children: [
              for (var i = 0; i < 5; i++) const SkeletonBox(height: 104, borderRadius: AppRadius.cardAll),
            ],
          ),
        ),
      ),
    );
  }
}
