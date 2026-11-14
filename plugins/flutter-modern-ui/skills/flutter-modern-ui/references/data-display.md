# KPI tiles, tables and charts

## KPI tiles (dashboards)

Widget: `KpiTile` + `KpiGrid`. Reference: `assets/examples/dashboard_screen.dart`.

- Raised tile (`AppCard(raised: true)`, the one shadow exception), tappable when it leads somewhere, padding 16.
- Top row: badge (36 px emoji badge on the tone's container, or an icon badge), 12 px gap, label in labelMedium / `onSurfaceVariant`, up to 2 lines.
- 12 px below: the value in headlineSmall + tabular figures, **shrinking to fit** (`FittedBox(fit: BoxFit.scaleDown)`) instead of overflowing: `12,500.50 ₪` doesn't fit a 160 px tile at headline size.
- Color the value only for states that need attention (overdue, paid); the rest stay `onSurface`.
- 4 px below: optional caption in bodySmall; no empty line when there's none.
- Tiles in a row have equal height (`KpiGrid` uses `IntrinsicHeight` rows). 2 per row; 4 per row from 840 px of available width; 12 px gaps.
- Values that change: `AnimatedNumber` (tweens from the shown value, never from zero after the first frame).
- An empty KPI shows its neutral form (👌 / "No overdue invoices") rather than a red zero.

## Tables

Use cards on phones; switch to a table on large widths (≥ 1200, or ≥ 840 for data-heavy apps) when users compare rows.

- `DataTable` (small sets) or `PaginatedDataTable`; `TableView` from `two_dimensional_scrollables` for large, scrollable both ways (ask before adding).
- Theme (template): heading row `surfaceContainerHigh`, heading text labelLarge / `onSurfaceVariant`, row height from density (40 desktop, 56 touch), hairline dividers, 16 px horizontal margin, 24 px column spacing.
- Numeric columns: `numeric: true` (end-aligned), tabular figures, the same decimals in every row, inside `Ltr` in RTL.
- Sorting: arrow on the sorted column (`sortColumnIndex`, `sortAscending`); sort by clicking the header.
- Row hover (desktop) and selection: `DataRow(selected:, onSelectChanged:)`; the selected row opens in a detail pane beside the table.
- Sticky header and horizontal scroll for wide tables; keep the first column (name) visible.
- Status column: `StatusPill` (icon + label), never colored text alone.
- Empty table: the empty state goes in the table area, not a blank grid.
- `DataTable` rows can't animate insert/remove individually; show changes through the detail pane, the message, and charts. For animated rows, render the table as `AnimatedItems` of row widgets.
- Records tables are wrapped in a card (radius `card`, clip) on dashboards; full-bleed on table-first screens.

## Charts

`MiniBarChart` (no package) demonstrates the rules; apply the same with `fl_chart` or any chart package.

### Colors

- Series colors come from scheme and palette roles, chosen by meaning: due → `palette.info`/upcoming, collected → `palette.success`, expected → `primary`. Never hard-coded hex.
- Gridlines: `outlineVariant`, 1 px. Axis labels: labelSmall / `onSurfaceVariant`, tabular figures.
- No more than 4–5 series; beyond that, use small multiples or a table.

### Axes and ticks

- **Nice ticks**: steps of 1, 2 or 5 × 10ⁿ (`NiceScale.forMax(max)`), so labels read 0 / 5k / 10k / 15k. A fixed `maxY * 1.15` with 4 intervals gives labels like "1.3 ألف".
- Format large ticks compactly (`5k`, `1.2M`, or the locale's compact format via `intl` `NumberFormat.compact`).
- **Narrow bars**: when there are fewer than ~44 px per bar, switch month names to numbers (`shortLabels`) instead of letting labels collide or rotate.

### RTL

- Most chart packages (fl_chart included) always lay out left to right. In RTL: **mirror the x index** (`x = count - 1 - i`) so time reads right to left, and **put the value axis on the reading-start side** (right).
- `MiniBarChart` is built from Rows, so it mirrors automatically.

### Motion

- Bars and lines move from the previous values to the new ones (fl_chart: `duration` + `curve`; implicit animations otherwise), never from zero on every update.
- In a hidden tab (`IndexedStack`, `TickerMode` off) keep showing the old values and switch when the tab becomes visible (`TickerMode.valuesOf(context).enabled`), so the change plays where the user can see it.
- First appearance: bars may grow from zero once (entrance), or appear static; pick one per app.

### States

- Loading: a skeleton block the chart's size. Empty: a short sentence inside the chart card ("No payments in this period"), not empty axes. Error: inline with retry.
- Every chart has a one-sentence semantic summary ("Collected per month, highest in November").
- Tooltips on hover/tap show the exact value (tabular, formatted), aligned away from the pointer.

## Amounts everywhere

- Minor units in data, `intl` formatting at the edge, tabular figures, `Ltr` in RTL, the same decimals in a column, negative values with a minus sign (and color only as a second signal).
- Totals in several currencies: one line per currency, never one summed number (`forms.md` › Money).
- A hero summary (this month's total) is one `AppCard` on `primaryContainer` with the amounts in `headlineMedium`; shares by category are pill `LinearProgressIndicator`s scaled to the largest category, with the amount as text beside each.
