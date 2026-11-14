# Layout, spacing and hierarchy

## Screen anatomy

Most modern screens share one skeleton. Start from it and remove what you don't need.

```
Scaffold (bg: surface)
└─ SafeArea(bottom: false)
   └─ CustomScrollView
      ├─ SliverAppBar.large / .medium      ← title that collapses on scroll (or a greeting header)
      ├─ Search / filter chips             ← SliverToBoxAdapter, screen padding
      ├─ SliverPadding(horizontal: screen or ContentWidth.horizontalPadding(width))
      │   └─ SliverList / AnimatedItems / SliverGrid
      │       ├─ Hero / summary            gap 24
      │       ├─ SectionHeader             gap 12
      │       └─ Cards or a grouped card   gap 12 between items
      └─ SliverToBoxAdapter(height: context.listEndPadding(fab: …))   ← clears the navigation bar (and the FAB)
bottomNavigationBar / NavigationRail: from the app shell (AdaptiveShell)
```

- Prefer `CustomScrollView` + slivers for anything longer than one viewport: collapsing headers, sticky headers and lazy lists in one scroll.
- Never a `ListView` inside a `Column` without `Expanded`; never `shrinkWrap: true` on long lists.
- Pull to refresh (`RefreshIndicator.adaptive`) on every remotely loaded list. Live data (a local-first store, a stream) updates by itself: no pull to refresh.

### List screens

The usual anatomy, top to bottom: `SliverAppBar.medium` title (actions: sort, filter) · search field · status chips (wrapping when ≤ 4, `components.md` › Chips) · a count or summary line ("12 invoices · $48,210 open") · one `AppCard` per record, 12 px apart on the screen padding · `context.listEndPadding(fab: true)`.

A record card reads top to bottom:

1. leading `IconBadge` (the status tone, or neutral) or an initials avatar, when the list mixes kinds of records;
2. the title in `titleMedium`, the amount at the end in `titleMedium` with tabular figures (`Ltr` in RTL);
3. details as `MetaItem`s (icon + muted text: number, date, count) in a `Wrap`, so they flow onto a second line instead of truncating;
4. the status pill (or a status chip that changes it) last.

When the screen is narrow for its text (`context.isNarrow`), the amount moves under the title. Reference: `assets/examples/records_screen.dart`.

## Spacing rhythm

- Horizontal page padding `AppSpace.screen`. Full-bleed elements (carousels, images) break out deliberately; their content re-aligns to the screen padding.
- Section gap 24, item gap 12, text-group gap 4–8.
- Inside a card: padding 16; title → subtitle 4; text → actions 16.
- Everything aligns to the same start edge. Icons and text off by 2–4 px read as cheap immediately.
- The last item clears the navigation bar or home indicator and any FAB: `context.listEndPadding()` (the bottom inset + `AppSpace.lg`), `context.listEndPadding(fab: true)` under a FAB (+ 72).

## Hierarchy

Each screen answers "what's the one thing here?":

1. **Primary information**: largest type (headline/display), highest contrast, top-start.
2. **Primary action**: one `FilledButton` or FAB.
3. **Secondary information**: title/body roles, `onSurfaceVariant`.
4. **Tertiary**: bodySmall/labelSmall, timestamps, metadata.

Use several tools together: size, weight, color role, position, whitespace, container color. Group related items in one card or a grouped list instead of many small cards.

## Nested shapes

The rules in `tokens.md` › Nested shapes, summarized:

- Concentric radius while the gap is smaller than the outer radius (`AppRadius.concentric`); otherwise the child keeps its own radius; a child filling its parent is clipped (radius 0).
- No card inside a card; no double borders; no stacked shadows.
- Same card type, same padding / radius / border everywhere. Keep a table in DESIGN.md:

| Card type | Padding | Radius |
|---|---|---|
| Content card (record, chart, form section) | 16 | card |
| Group card (rows inside) | 8, rows pad 12 × 8 | card, rows `concentric(card, 8)` |
| Row card (ink fills the card) | 0, row pads 12 × 8 | card, row 0 (clipped) |
| KPI tile (raised) | 16 | card, emoji badge 8 |

## Window sizes

| Class | Width | Navigation | Content | Sheets |
|---|---|---|---|---|
| compact | < 600 | NavigationBar | 1 column, cards | bottom sheets |
| medium | 600–839 | NavigationRail (labels below) | 2-column grids | dialogs (560) |
| expanded | 840–1199 | NavigationRail | list-detail, 4 KPI tiles | dialogs |
| large | 1200–1599 | extended rail (labels beside) | table + detail pane | dialogs |
| extra-large | ≥ 1600 | extended rail | capped at 1440, centered | dialogs |

- `AdaptiveShell` switches the navigation; `context.windowSize` reads the class from the window width. Inside panes, decide from the available width (`LayoutBuilder`).
- Read sizes with `MediaQuery.sizeOf(context)` (not `MediaQuery.of`, which rebuilds on every metric change).
- Cap widths: forms 640, reading 720, dashboards and tables 1440 (`ContentWidth`, or `ContentWidth.horizontalPadding(width)` for slivers).

### List-detail

From expanded width: list on the start side (flex 5), hairline divider, detail pane (flex 4). Selecting a row shows it in the pane (cross-fade the pane with `StateSwitcher` keyed by id) and highlights the row (`secondaryContainer` fill + `Semantics(selected: true)`). On compact, the same tap pushes a detail page. The pane shows an empty state ("Select an invoice") when nothing is selected.

Getting back to that empty state must be obvious:

- **A visible close**: a ✕ `IconButton` with a tooltip ("Close details") at the end of the pane's header, in a header that stays put while the details scroll. Embedded pane only; a pushed detail page has the app bar's back button.
- **Clicking the open row again deselects it.**
- **Esc as a shortcut only**: `CallbackShortcuts` around the list and pane, whose `Focus` takes focus when a row is selected. Esc needs keyboard focus and nobody discovers it; a pane that only closes with Esc leaves users asking how to get back to the page as it first opened.
- Deleting the open record clears the selection too.

Reference: `assets/examples/records_screen.dart` (`initialSelectedId` opens it with a record selected, for deep links and the pane's screenshot).

## Grids and carousels

- Two-column grids: `SliverGrid` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: …)`. Fixed extents must survive text scale 1.3; prefer rows of `IntrinsicHeight` for small sets (`KpiGrid`).
- Horizontal carousels: `ListView.separated(scrollDirection: Axis.horizontal, padding: screen padding)` in a `SizedBox(height:)`; show ~15 % of the next item so it reads as scrollable.
- Homogeneous rows: one grouped card with dividers indented to the text (`Divider(indent: 72)`), or separated cards 8–12 apart. One style per app.

## Text resilience

- Every dynamic `Text` in a row: `Expanded`/`Flexible` + `maxLines` + `TextOverflow.ellipsis`.
- Big values in small tiles: `FittedBox(fit: BoxFit.scaleDown)` instead of overflowing.
- Test at text scale 1.0, 1.3 and 1.6 (the layout test does). Don't clamp text scaling; fix the layout instead.
- No fixed heights on containers that hold text; use padding and min constraints.
- Labels in other languages run 30–40 % longer than English (Arabic, German); leave room, never truncate primary labels.

## Big fonts and narrow screens

Big fonts (Android goes to 2.0 from Android 14, iOS further), a large display size and small phones all leave less room per character. Measure that, not the window: `context.textWidth` is the width ÷ the text scale, and `context.isNarrow` is true below 340 (360 px at 1.3 already is).

When narrow:

- **Rows that pair two things stack**: the amount under the name, the status chip under the details, the trailing button under the text. A side-by-side row at 1.6 leaves the name three letters wide.
- **One KPI tile per row** (`KpiGrid` does it from the width text sees), one form field per row.
- **Inline icons keep pace**: icons next to text (`MetaItem`, pills) use `context.iconSize(AppIconSize.inline)`, which grows with the text up to 1.4×. Icon buttons and badges keep their size.
- Pick-one choices stay wrapping chips: a `SegmentedButton` puts every option on one row and runs out of room (`components.md` › Chips).

## System bars and safe areas

Phones draw over the app: the status bar (with a camera cutout, or the Dynamic Island on iPhone) at the top, the navigation bar (Android's three buttons or gesture handle) or the home indicator at the bottom, and cutouts at the sides in landscape. Android 15+ draws apps edge to edge, under all of them. **Nothing the user reads or taps may sit under them or touch them**: keep it inside the safe area plus a little padding (at least 8 px; 12–16 px for bars and buttons).

| Where | How |
|---|---|
| App bar, `SliverAppBar`, `NavigationBar`, `NavigationRail` | they pad themselves: don't add `SafeArea` around them |
| A header without an app bar (greeting, search at the top) | `SafeArea(bottom: false)` around the scroll view, then ≥ `AppSpace.md` above the first row |
| Full-bleed header color or image | the background runs under the status bar; its content pads by `MediaQuery.paddingOf(context).top` + `AppSpace.md` |
| Bottom bar with a button (save, checkout, continue) | `SaveBar`: `SafeArea(top: false)` + `AppSpace.sm` all round, inside a surface with a hairline |
| A list that runs to the bottom of the screen | ends with `context.listEndPadding()`; `fab: true` under a FAB. A `ListView` with an explicit `padding` loses its automatic safe area: add the inset yourself |
| Sheets | `showAppSheet` (`useSafeArea: true`); the footer sits in `SafeArea(top: false)`; a sheet without a footer keeps its body in the safe area |
| Landscape | `SafeArea` keeps `left` / `right` on: cutouts move to the sides |

The UI tests render phones and tablets under these bars (Android: 32 px status bar, 48 px navigation bar; iOS: 59 px Dynamic Island, 34 px home indicator), draw them in the screenshots, and fail when text or a tap target sits under them or within 8 px, at rest or with a list scrolled to its end (`flutter-ui-verify` › harness).

## Keyboard

- Long forms: the save bar is the **last child of the body `Column`** with an `Expanded` scroll view above it. In `Scaffold.bottomNavigationBar` it sits under the soft keyboard. Details in `forms.md`.
- An `Align` inside an unbounded-height bar expands to the full screen: give it `heightFactor: 1`.
- Dismiss the keyboard on scroll (`keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`) and on tap outside.
- `SafeArea` wraps content, not backgrounds; full-bleed headers pad their content by `MediaQuery.paddingOf(context).top`.
