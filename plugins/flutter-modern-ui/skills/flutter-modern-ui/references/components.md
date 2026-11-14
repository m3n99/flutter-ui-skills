# Component patterns

Ready widgets: `assets/design_system/widgets/`. Snippets assume `context.colors`, `context.textStyles`, `context.palette` and the tokens. In a project with its own components, apply the same patterns to those.

## App bars

- Top-level screens: `SliverAppBar.large` or `.medium` (title collapses on scroll), or a greeting header (avatar 40 + "Good morning" in muted bodySmall + name in titleLarge + one icon button).
- Detail screens: `SliverAppBar.medium` or a plain `AppBar` with titleLarge.
- At most 2 action icons, each with a tooltip; the rest in a `MenuAnchor` overflow.
- Filter actions show the active count: `Badge(isLabelVisible: count > 0, label: Text('$count'), child: Icon(Icons.tune_rounded))`.

## Cards

`AppCard`: flat, tonal fill, hairline border, card radius, clips children. Tappable cards get ink (ripple, hover, focus, click cursor), a darker border on hover, and press scale.

```dart
AppCard(
  onTap: () => open(invoice),
  child: Row(
    spacing: AppSpace.sm,
    children: [
      IconBadge(icon: Icons.bolt_rounded),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.xxs,
          children: [
            Text('Electricity', style: context.textStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Due in 3 days', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
      Ltr(child: Text(formatMoney(8420), style: context.textStyles.titleMedium.tabular)),
    ],
  ),
)
```

- **Group card**: rows inside one card with 8 px padding; each row's ink radius is `AppRadius.concentric(AppRadius.card, 8)`.
- **ExpansionTile inside a card**: the theme sets `shape` / `collapsedShape` to `Border()` so it doesn't draw borders over the card's; keep `dividerColor` transparent if it shows lines.
- **Hero / summary card**: `primaryContainer` fill (or one primary → tertiary gradient in Bold Contrast), display-size number, sheet radius, 20–24 padding.
- **Raised tiles** (`AppCard(raised: true)`) only for dashboard KPIs.

## Badges

- `IconBadge`: icon in a 12 % tinted circle; the fastest way to make rows look designed.
- `EmojiBadge`: emoji on a tinted rounded square (36 px, 20 px emoji, `TextScaler.noScaling`). Only when the user asked for emoji (intake). Keep the text label; exclude the emoji from semantics.

## Lists

- Grouped list: one `AppCard(padding: EdgeInsets.zero)` with `ListTile`s separated by `Divider(height: 1, indent: 72)` (indent aligns with the text, not the icon), or a group card with inset rows.
- `ListTile`: leading `IconBadge`, title titleMedium, subtitle muted bodySmall, trailing chevron (`Icons.chevron_right_rounded`, mirrors in RTL) or a value.
- Animated lists: `AnimatedItems` (insert/remove animate, state kept by id). `flutter-motion` skill.
- Swipe actions: `Dismissible` with a rounded `errorContainer` background and an icon; destructive swipes go through the Undo flow (`messages.md`). Don't combine `Dismissible` with `AnimatedItems` removal for the same row (double animation): use a delete button or menu there.
- Section headers: `SectionHeader(title:, subtitle:, leading:, trailing:, actionLabel: 'See all', onAction:)`.

## Buttons

| Role | Widget | Notes |
|---|---|---|
| Primary (one per screen / sheet) | `FilledButton`, or `SubmitButton` for saves | full width in forms and sheets |
| Secondary | `FilledButton.tonal` or `OutlinedButton` | as wide as its label next to a primary |
| Tertiary / inline | `TextButton` | |
| Destructive | `FilledButton` with `backgroundColor: colors.error`, `foregroundColor: colors.onError` | after a confirm dialog |
| Icon-only | `IconButton` / `IconButton.filledTonal` | tooltip required |

- With icons: `FilledButton.icon(icon:, label:)`.
- Saving: `SubmitButton` keeps its width, shows a spinner, ignores a second press.
- Avoid `ElevatedButton` (shadowed, dated) unless the project standardized on it.
- Never two filled buttons side by side with equal weight.

## Chips

- **A few single-choice options (up to 4)**: `AppChoiceChips` wrapping, **never scrolling**, so every option stays visible on a 360 px phone. A scrolling row cut the second of two paper sizes off at 360 px. `SegmentedButton` works too when every label fits one row at text scale 1.3.
- **Inline label** ("Paper  [A4] [A5]"): `AppChoiceChips(label: 'Paper', …)` renders the label as the first child of the same `Wrap` (`WrapCrossAlignment.center`), so it stays with the first chip and later chips wrap under it. A label above the group is a section label instead (`SheetSection`, a field label).
- **Filters**: `AppChoiceChips(multiple: true)` in a wrapping block (8 / 8 spacing). Only a long filter list (5 or more) under a header may be one scrolling row (`scrollable: true`, screen padding), and the row must show part of the next chip so it reads as scrollable.
- **Selected = check + `primaryContainer` fill** (theme). Never selection by color alone.
- All chips in a group share one height: same label style and theme padding; no per-chip padding.
- Reference: payment terms in `assets/examples/record_form_screen.dart`; the filter sheet and the status filter row in `assets/examples/records_screen.dart`.

## Status

```dart
enum InvoiceStatus { draft, sent, dueSoon, overdue, paid }

extension InvoiceStatusUi on InvoiceStatus {
  String get label => switch (this) { /* … */ };
  IconData get icon => switch (this) { /* … */ };
  StatusTone get tone => switch (this) { /* … */ };
  StatusPill get pill => StatusPill(label: label, icon: icon, tone: tone);
}
```

- `StatusPill` requires an icon: status is never shown by color alone.
- One mapping per domain status, in one place; screens use `status.pill`.
- Business states use palette tones (add `overdue`, `paid`… to `AppPalette` if the domain needs distinct ones); `danger` / `error` is for failures.

## Navigation

- `AdaptiveShell`: NavigationBar < 600, rail 600–1199, extended rail ≥ 1200.
- 3–5 destinations, outlined icon + filled `selectedIcon`, one-word labels.
- Tabs inside a screen: `TabBar` (label-size indicator, no divider) or `SegmentedButton` for 2–3 views.
- **FABs on shell tabs need `heroTag: null`** (or a unique tag). An `IndexedStack` shell, and go_router's `StatefulShellRoute.indexedStack`, keep every tab mounted in one route, so two FABs with the default tag throw "There are multiple heroes that share the same tag within a subtree" as soon as any route is pushed. Rendering one page at a time never shows it; the harness's shell case does.

## Avatars and images

- `CircleAvatar(backgroundColor: colors.primaryContainer)` + initials in `onPrimaryContainer` as fallback.
- Network images: fixed aspect (`AspectRatio`), rounded with `ClipRRect`, `SkeletonBox` placeholder, fade in, an icon on `surfaceContainerHigh` on error. Use `cached_network_image` if the project has it.

## Search

- A filled `TextField` with a search prefix icon and a clear suffix button (tooltip "Clear search") at the top of the list, or `SearchAnchor` / `SearchBar` for suggestion-heavy search.
- Filter as the user types (debounce 250–300 ms when it hits a database); results animate with `AnimatedItems`.
- No-results state names the query and offers "Clear filters".

## Menus

- `MenuAnchor` + `MenuItemButton` (leading icon, shortcut on desktop). Destructive items last, in `error` color.
- Rows inside a menu sit 4 px in from its edge: radius `concentric(menuRadius, 4)`.

## Dialogs and confirmations

See `sheets-dialogs.md`. Short version: the title states the action ("Delete INV-1042?"), the body states the consequence in one sentence, actions are `TextButton('Cancel')` + a destructive `FilledButton`.

## Emoji (only when the user asked for them)

- Treat an emoji as an icon: fixed size, tinted badge, one emoji per meaning used consistently, never the only carrier of meaning, excluded from semantics.
- Good places: KPI tiles, section headers, empty states, success messages (as chosen in intake).
- Screenshots in `flutter_test` show emoji as boxes; devices render them in color.
