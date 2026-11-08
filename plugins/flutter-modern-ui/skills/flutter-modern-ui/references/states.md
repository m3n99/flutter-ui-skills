# Loading, empty, error and refresh states

A screen is not finished until all of them are designed: **loading, empty, error, content**, plus **refreshing** for lists. Most "unfinished-looking" apps miss three of these.

Switch between them with `StateSwitcher` (cross-fade + slight settle, top-aligned) and give each state a key.

```dart
StateSwitcher(
  child: switch (state.status) {
    Status.loading => const InvoicesSkeleton(key: ValueKey('loading')),
    Status.failure => EmptyState.error(
        key: const ValueKey('error'),
        title: "Couldn't load your invoices",
        message: 'Check your connection and try again.',
        onRetry: () => bloc.add(const InvoicesRequested()),
      ),
    Status.success when state.items.isEmpty => const EmptyState(
        key: ValueKey('empty'),
        icon: Icons.receipt_long_rounded,
        title: 'No invoices yet',
        message: 'Invoices you create show up here.',
      ),
    _ => InvoicesList(key: const ValueKey('content'), items: state.items),
  },
)
```

Map the project's own status enums and state classes (per-field `BaseStatus`, `AsyncValue`, sealed states) onto these widgets; never change the state layer for it. Access blocs the way the project does (service locator or providers).

## Loading → skeletons

- Shape skeletons like the content: same paddings, row heights, radii and count that fits the screen, so nothing jumps when data arrives (`Shimmer` + `SkeletonBox`, no package).
- Delay the skeleton ~150 ms (`ShowAfter`) so fast loads never flash it.
- A centered spinner is fine only for short blocking actions (< 1 s) and inside buttons.
- Use skeletons on every data screen, including secondary ones (alerts, history, settings sections that load). A single screen left with a centered spinner reads as unfinished next to the rest.
- Tests: the shimmer repeats forever, so pump with durations, not `pumpAndSettle`.

## Refresh

- Keep content visible while refreshing: `RefreshIndicator.adaptive` on lists, or a thin `LinearProgressIndicator` under the app bar. Never replace loaded content with a skeleton on refresh.
- A failed refresh keeps the old data and shows a message ("Couldn't refresh the invoices. Pull down to try again.").
- Lists update in place with `AnimatedItems` (new rows grow in, removed rows shrink out).

## Empty

`EmptyState`: tinted icon (or a small illustration / emoji if chosen in intake), title, one sentence, and an action when the user can fix it.

- **First use**: encouraging, with the primary action ("Add your first invoice").
- **No results** (search/filter): name what was searched, offer "Clear filters".
- **Nothing to do** (all paid, no alerts): positive and calm ("Nothing due this week").
- Inside cards or panes, keep it compact; full-screen empty states sit slightly above center.

## Error

- Say **what failed and what to do**: "Couldn't load your invoices. Check your connection and try again." Never raw exception text, never a generic "Something went wrong". Log the failure separately.
- Full-screen error only when the whole screen depends on the failed load; otherwise an inline row with Retry in the affected card.
- Offline: a slim banner (`palette.warning` container) while keeping cached content visible.
- Validation failures from the backend pass through as written (`AppMessenger.userMessageOf`).

## Pagination

- Loader row at the end (small skeleton row or a 24 px spinner); an error row with Retry; extra bottom space at the end of the list (no "No more items" text needed).

## Optimistic updates

- Toggle, check, reorder and favourite immediately; roll back with a message if the request fails.
- After create/save: close the form, show a message naming the thing, and animate the new row in.
- Deletes: hide at once, Undo in the message, commit when it closes (`messages.md`).
