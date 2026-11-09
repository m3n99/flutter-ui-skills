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
      └─ SliverToBoxAdapter(height: bottom inset + 24, or + FAB clearance)
bottomNavigationBar / NavigationRail: from the app shell (AdaptiveShell)
```

- Prefer `CustomScrollView` + slivers for anything longer than one viewport: collapsing headers, sticky headers and lazy lists in one scroll.
- Never a `ListView` inside a `Column` without `Expanded`; never `shrinkWrap: true` on long lists.
- Pull to refresh (`RefreshIndicator.adaptive`) on every remotely loaded list.

## Spacing rhythm

- Horizontal page padding `AppSpace.screen`. Full-bleed elements (carousels, images) break out deliberately; their content re-aligns to the screen padding.
- Section gap 24, item gap 12, text-group gap 4–8.
- Inside a card: padding 16; title → subtitle 4; text → actions 16.
- Everything aligns to the same start edge. Icons and text off by 2–4 px read as cheap immediately.
- The last item clears the home indicator and any FAB: `MediaQuery.paddingOf(context).bottom + AppSpace.lg` (more under a FAB).

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
- Test at text scale 1.0 and 1.3 (the layout test does). Don't clamp text scaling below 1.3; fix the layout instead.
- No fixed heights on containers that hold text; use padding and min constraints.
- Labels in other languages run 30–40 % longer than English (Arabic, German); leave room, never truncate primary labels.

## Keyboard and safe areas

- Long forms: the save bar is the **last child of the body `Column`** with an `Expanded` scroll view above it. In `Scaffold.bottomNavigationBar` it sits under the soft keyboard. Details in `forms.md`.
- An `Align` inside an unbounded-height bar expands to the full screen: give it `heightFactor: 1`.
- Dismiss the keyboard on scroll (`keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`) and on tap outside.
- `SafeArea` wraps content, not backgrounds; full-bleed headers pad their content by `MediaQuery.paddingOf(context).top`.
