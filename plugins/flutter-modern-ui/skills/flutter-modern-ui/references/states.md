# Loading, empty and error states

A screen is not finished until all four states are designed: **loading, empty, error, content** (plus *partial/refreshing* for lists). Most "unfinished" apps are missing three of these.

## Loading → skeletons
- Shape skeletons like the real content (same paddings, same row heights, same radii) so nothing jumps when data arrives.
- Use `Shimmer` + `SkeletonBox` from `widgets/skeleton.dart`. No package needed.
```dart
Shimmer(
  child: Column(
    spacing: AppSpace.sm,
    children: List.generate(5, (_) => const _RowSkeleton()),
  ),
)

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();
  @override
  Widget build(BuildContext context) => const Row(
        spacing: AppSpace.sm,
        children: [
          SkeletonBox.circle(size: 44),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [SkeletonBox(width: 160, height: 14), SkeletonBox(width: 96, height: 12)],
            ),
          ),
        ],
      );
}
```
- Centered `CircularProgressIndicator` is acceptable only for very short blocking operations (< 1 s) or inside buttons.
- Show the skeleton after a short delay (~150 ms) if loads are usually instant, to avoid flashing.
- Refreshing existing content: keep the content visible, show `RefreshIndicator` or a thin `LinearProgressIndicator` under the app bar. Never replace loaded content with a skeleton on refresh.

## Empty
Use `EmptyState` from `widgets/empty_state.dart`:
- Icon (48) inside a tinted circle (or a small illustration), title (titleLarge), one-sentence message (bodyMedium, muted), primary action if the user can fix it ("Add your first expense").
- Distinguish **first-use empty** (encouraging, with CTA) from **no-results empty** (search/filter: "No matches for 'x'", action "Clear filters").
- Place it in the visual center of the remaining space, slightly above true center (`Alignment(0, -0.2)`).

## Error
- Same layout as empty, with `errorContainer` tint, a human message ("Couldn't load your invoices"), and a **Retry** button. Never show raw exception text; log it instead.
- Inline errors (one failed card among many) show a compact row with retry, not a full-screen error.
- Offline: banner at the top (`MaterialBanner` or a slim custom bar using `palette.warningContainer`) while keeping cached content visible.

## Lists
- Pagination: loader row at the bottom (small skeleton row or 24px spinner), error row with retry, "end of list" spacing (no "No more items" text needed).
- Pull-to-refresh on every remotely-loaded list: `RefreshIndicator.adaptive`.

## Optimistic and success feedback
- Toggle likes, check items, reorder immediately; roll back with a snackbar if the request fails.
- After create/save: close the sheet, show a short snackbar (with Undo if destructive), and animate the new item in.

## Wiring with the project's state management
Map existing states to these widgets without changing the state layer, for example with BLoC:
```dart
BlocBuilder<InvoicesBloc, InvoicesState>(
  builder: (context, state) => AnimatedSwitcher(
    duration: AppDurations.medium,
    child: switch (state.status) {
      Status.loading => const InvoicesSkeleton(key: ValueKey('loading')),
      Status.failure => EmptyState.error(key: const ValueKey('error'), onRetry: () {/* dispatch the existing retry event */}),
      Status.success when state.items.isEmpty => EmptyState(key: const ValueKey('empty'), icon: Icons.receipt_long_rounded, title: 'No invoices yet', message: 'Invoices you create will show up here.'),
      _ => InvoicesList(key: const ValueKey('content'), items: state.items),
    },
  ),
)
```
Use whatever the project already uses to access blocs/controllers (service locator, providers, etc.). Adapt the status enum names to the project's.
