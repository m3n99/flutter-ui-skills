// Reference composition: a records list that scales from phone to desktop.
// Shows:
// - search + status filter chips + a filter sheet (SheetScaffold: sections,
//   chips with checks, "Clear all" in place, "Apply (n)");
// - sorting through a pick-one sheet (showAppPicker): one choice, so one tap
//   chooses and closes, with no Apply button;
// - AnimatedItems: filters and search animate rows out and in, new records
//   grow in at the top, a new sort replays the staggered entrance;
// - delete: in the row's ⋮ menu and at the foot of the details, never the
//   easiest thing to hit on a card (references/ux.md); then confirm dialog →
//   row hides at once → message with Undo → committed only when the message
//   closes without Undo;
// - the details as ledger lines, the app's signature (ledger.dart), and
//   "Mark as paid" as a button that does it and can't be pressed twice;
// - opening an invoice from another tab (`openRequest`): the pane on wide
//   windows, a pushed page on phones;
// - list-detail from 840 px (selected row + detail pane that cross-fades),
//   push to a detail page on phones; the pane always has a way back to the
//   empty state: a ✕ in its header, clicking the open row again, and Esc as
//   a shortcut only (it needs focus and nobody discovers it);
// - edit opens the same form pre-filled (RecordFormScreen(initial:));
// - the FAB has `heroTag: null`: screens in an IndexedStack shell (or
//   go_router's StatefulShellRoute.indexedStack) share one route, and two
//   FABs with the default tag throw when any route is pushed;
// - card rows: title and amount on one line (the amount under the title when
//   the screen is narrow: big fonts, small phones), details as MetaItems,
//   the status pill last;
// - the list ends with context.listEndPadding(fab: true), so its last row
//   scrolls clear of the navigation bar and the FAB;
// - loading skeleton, error with retry, first-use and no-results empty states.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/design_system.dart';
import 'ledger.dart';
import 'record_form_screen.dart';
import 'sample_data.dart';

enum InvoiceSort { dueDate, amount, customer }

extension InvoiceSortLabel on InvoiceSort {
  String get label => switch (this) {
        InvoiceSort.dueDate => 'Due date',
        InvoiceSort.amount => 'Amount',
        InvoiceSort.customer => 'Customer',
      };

  IconData get icon => switch (this) {
        InvoiceSort.dueDate => Icons.event_rounded,
        InvoiceSort.amount => Icons.payments_rounded,
        InvoiceSort.customer => Icons.sort_by_alpha_rounded,
      };
}

@immutable
class InvoiceFilters {
  const InvoiceFilters({this.statuses = const {}, this.sort = InvoiceSort.dueDate});

  final Set<InvoiceStatus> statuses;
  final InvoiceSort sort;

  /// Shown on the Apply button and the filter badge. The sort isn't a filter.
  int get activeCount => statuses.length;

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

/// One choice: a pick-one sheet, closed by the tap that chooses.
Future<InvoiceSort?> showInvoiceSort(BuildContext context, InvoiceSort current) {
  return showAppPicker<InvoiceSort>(
    context: context,
    title: 'Sort by',
    options: InvoiceSort.values,
    labelOf: (sort) => sort.label,
    iconOf: (sort) => sort.icon,
    selected: current,
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final InvoiceFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<InvoiceStatus> _statuses = {...widget.initial.statuses};

  InvoiceFilters get _draft => InvoiceFilters(statuses: _statuses, sort: widget.initial.sort);

  @override
  Widget build(BuildContext context) {
    final count = _draft.activeCount;

    return SheetScaffold(
      title: 'Filter invoices',
      // Clears the choices in the sheet; Apply makes it stick.
      secondaryAction: OutlinedButton(
        onPressed: count == 0
            ? null
            : () => setState(() => _statuses = {}),
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
      ],
    );
  }
}

enum _Load { loading, error, ready }

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.repository, this.initialSelectedId, this.openRequest});

  final InvoiceRepository repository;

  /// Opens with this record in the detail pane (wide windows): deep links,
  /// and the screenshot of the pane.
  final int? initialSelectedId;

  /// Lets another screen open an invoice here (the home screen's "Due soon"
  /// rows): set its value to the invoice's id. The detail pane shows it on
  /// wide windows, a pushed page on phones, and the value goes back to null.
  final ValueNotifier<int?>? openRequest;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final PendingDeletes<int> _pending = PendingDeletes<int>();
  final TextEditingController _search = TextEditingController();
  final FocusNode _listDetailFocus = FocusNode(debugLabel: 'invoices list-detail');
  _Load _status = _Load.loading;
  List<Invoice> _all = const [];
  InvoiceFilters _filters = const InvoiceFilters();
  late int? _selectedId = widget.initialSelectedId;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    widget.openRequest?.addListener(_handleOpenRequest);
    widget.repository.changes.addListener(_refresh);
    _load();
  }

  @override
  void didUpdateWidget(RecordsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openRequest != widget.openRequest) {
      oldWidget.openRequest?.removeListener(_handleOpenRequest);
      widget.openRequest?.addListener(_handleOpenRequest);
    }
  }

  @override
  void dispose() {
    widget.openRequest?.removeListener(_handleOpenRequest);
    widget.repository.changes.removeListener(_refresh);
    _pending.dispose();
    _search.dispose();
    _listDetailFocus.dispose();
    super.dispose();
  }

  /// An invoice changed, here or on another screen: reload quietly.
  void _refresh() {
    if (mounted && _status == _Load.ready) _load(quiet: true);
  }

  Future<void>? _quietLoad;

  /// Quiet reloads asked for while one is running share it: a change made
  /// here notifies [_refresh] and is usually followed by its own reload.
  Future<void> _load({bool quiet = false}) {
    if (!quiet) return _fetch(quiet: false);
    return _quietLoad ??= _fetch(quiet: true).whenComplete(() => _quietLoad = null);
  }

  Future<void> _fetch({required bool quiet}) async {
    if (!quiet && _status != _Load.loading) setState(() => _status = _Load.loading);
    try {
      final invoices = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _all = invoices;
        _status = _Load.ready;
      });
      // A request that arrived before the first load finished.
      _handleOpenRequest();
    } catch (failure) {
      if (!mounted) return;
      if (quiet) {
        AppMessenger.showFailure(failure, whatFailed: "Couldn't refresh the invoices. Pull down to try again.");
      } else {
        setState(() => _status = _Load.error);
      }
    }
  }

  /// Opens the invoice another screen asked for, once the list is loaded.
  void _handleOpenRequest() {
    final request = widget.openRequest;
    final id = request?.value;
    if (request == null || id == null || !mounted || _status != _Load.ready) return;
    request.value = null;
    for (final invoice in _all) {
      if (invoice.id != id) continue;
      if (context.windowSize.atLeast(WindowSize.expanded)) {
        setState(() => _selectedId = id);
      } else {
        _open(invoice, wide: false);
      }
      return;
    }
  }

  List<Invoice> get _visible => _filters.apply(_pending.visible(_all, (invoice) => invoice.id), _search.text);

  Future<void> _openFilters() async {
    final result = await showInvoiceFilters(context, _filters);
    if (result != null && mounted) setState(() => _filters = result);
  }

  Future<void> _pickSort() async {
    final sort = await showInvoiceSort(context, _filters.sort);
    if (sort != null && mounted) setState(() => _filters = InvoiceFilters(statuses: _filters.statuses, sort: sort));
  }

  Future<void> _edit(Invoice invoice, {bool popRoute = false}) async {
    final saved = await Navigator.of(context).push<Invoice>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RecordFormScreen(repository: widget.repository, initial: invoice),
      ),
    );
    if (saved == null || !mounted) return;
    // A pushed detail page still shows the old values: back to the list.
    if (popRoute) Navigator.of(context).pop();
    await _load(quiet: true);
  }

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<Invoice>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => RecordFormScreen(repository: widget.repository)),
    );
    if (created != null && mounted) await _load(quiet: true);
  }

  void _open(Invoice invoice, {required bool wide}) {
    if (wide) {
      // Clicking the open row again closes the pane. Selecting also moves
      // focus to the list-detail area, so Esc works right away.
      setState(() => _selectedId = _selectedId == invoice.id ? null : invoice.id);
      _listDetailFocus.requestFocus();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(invoice.number)),
          body: _DetailPane(
            invoice: invoice,
            onEdit: () => _edit(invoice, popRoute: true),
            onDelete: () => _delete(invoice, popRoute: true),
            onMarkPaid: () => _markPaid(invoice, popRoute: true),
          ),
        ),
      ),
    );
  }

  void _closeDetail() => setState(() => _selectedId = null);

  Future<void> _markPaid(Invoice invoice, {bool popRoute = false}) async {
    try {
      await widget.repository.markPaid(invoice.id);
    } catch (failure) {
      AppMessenger.showFailure(failure, whatFailed: "Couldn't mark ${invoice.number} as paid. Try again.");
      return;
    }
    if (!mounted) return;
    // A pushed detail page still shows the old status: back to the list.
    if (popRoute) Navigator.of(context).pop();
    AppMessenger.success('Marked ${invoice.number} as paid');
    await _load(quiet: true);
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
        // This screen is a tab of an IndexedStack shell: tabs share one
        // route, so default hero tags would clash as soon as a route opens.
        heroTag: null,
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
            // Esc closes the pane too, as a shortcut next to the visible ✕.
            return CallbackShortcuts(
              bindings: {
                if (selected != null) const SingleActivator(LogicalKeyboardKey.escape): _closeDetail,
              },
              child: Focus(
                focusNode: _listDetailFocus,
                child: Row(
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
                                onEdit: () => _edit(selected),
                                onDelete: () => _delete(selected),
                                onMarkPaid: () => _markPaid(selected),
                                onClose: _closeDetail,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
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
              tooltip: 'Sort: ${_filters.sort.label}',
              onPressed: _pickSort,
              icon: const Icon(Icons.swap_vert_rounded),
            ),
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
                    onEdit: () => _edit(invoice),
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
                            setState(() => _filters = InvoiceFilters(sort: _filters.sort));
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
        // Clears the navigation bar or home indicator, and the FAB.
        SliverToBoxAdapter(child: SizedBox(height: context.listEndPadding(fab: true))),
      ],
    );
  }
}

enum _CardAction { edit, delete }

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Invoice invoice;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final customer = Text(
      invoice.customer,
      style: text.titleMedium,
      maxLines: context.isNarrow ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );
    final amount = Ltr(child: Text(formatMoney(invoice.amountCents), style: text.titleMedium.tabular));

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
                  // Narrow (big fonts, small phones): the amount goes under
                  // the name instead of squeezing it to a few letters.
                  if (context.isNarrow) ...[
                    customer,
                    amount,
                  ] else
                    Row(
                      spacing: AppSpace.sm,
                      children: [Expanded(child: customer), amount],
                    ),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xxs,
                    children: [
                      MetaItem(icon: Icons.tag_rounded, text: invoice.number, ltr: true),
                      MetaItem(icon: Icons.event_outlined, text: 'Due ${formatShortDate(invoice.due)}'),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  invoice.status.pill,
                ],
              ),
            ),
            // Tapping the card opens it; what else can be done to it sits in
            // a menu. A trash can on every card would make the destructive
            // action the easiest one to hit.
            PopupMenuButton<_CardAction>(
              tooltip: 'More for ${invoice.number}',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) {
                switch (action) {
                  case _CardAction.edit:
                    onEdit();
                  case _CardAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _CardAction.edit,
                  child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
                ),
                PopupMenuItem(
                  value: _CardAction.delete,
                  child: _MenuRow(icon: Icons.delete_outline_rounded, label: 'Delete', color: colors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;

  /// The error color for a destructive item; the icon and the word carry
  /// the meaning, the color only underlines it.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpace.sm,
      children: [
        Icon(icon, size: AppIconSize.dense, color: color),
        Text(label, style: context.textStyles.bodyLarge?.copyWith(color: color)),
      ],
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane({
    super.key,
    required this.invoice,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkPaid,
    this.onClose,
  });

  final Invoice invoice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function() onMarkPaid;

  /// The embedded pane's ✕. A pushed detail page has the app bar's back
  /// button instead, so it passes nothing.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    // The header stays put while the details scroll, so the ✕ is always in
    // reach.
    final header = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        onClose == null ? AppSpace.lg : AppSpace.sm,
        onClose == null ? AppSpace.lg : AppSpace.xs,
        AppSpace.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.xs,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: onClose == null ? 0 : AppSpace.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.xxs,
                children: [
                  Text(invoice.customer, style: text.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(invoice.number, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          IconButton(tooltip: 'Edit invoice', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          if (onClose != null)
            IconButton(tooltip: 'Close details', onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: ListView(
            // An explicit padding turns off ListView's automatic safe area:
            // end with the bottom inset too.
            padding: EdgeInsetsDirectional.fromSTEB(AppSpace.lg, AppSpace.sm, AppSpace.lg, context.listEndPadding()),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Ltr(child: Text(formatMoney(invoice.amountCents), style: text.displaySmall.tabular)),
              ),
              const SizedBox(height: AppSpace.xs),
              Align(alignment: AlignmentDirectional.centerStart, child: invoice.status.pill),
              if (invoice.email.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xs),
                MetaItem(icon: Icons.mail_outline_rounded, text: invoice.email, ltr: true),
              ],
              const SizedBox(height: AppSpace.lg),
              // The signature again: the invoice's own lines. The status is
              // the pill above, so it isn't repeated here.
              AppCard(
                child: Ledger(
                  lines: [
                    LedgerLine(label: 'Number', value: invoice.number),
                    LedgerLine(label: 'Due date', value: formatShortDate(invoice.due)),
                  ],
                ),
              ),
              if (invoice.notes.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Text(invoice.notes, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              ],
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
                    child: SubmitButton(
                      label: 'Mark as paid',
                      icon: Icons.check_rounded,
                      onPressed: invoice.status == InvoiceStatus.paid ? null : onMarkPaid,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
