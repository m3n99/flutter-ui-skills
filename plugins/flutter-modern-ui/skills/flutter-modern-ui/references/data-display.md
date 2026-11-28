# KPI tiles, tables and charts

## KPI tiles (dashboards)

Widget: `KpiTile` + `KpiGrid`. Reference: `assets/examples/dashboard_screen.dart`.

- Tiles are for numbers worth a glance, after the screen's answer, not instead of it: a home that is only a grid of numbers gives the user nothing to do (`screens.md` › Home). Lead with the one figure the user came for, set large with its breakdown and its action; put two to four supporting tiles under it.

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

### Choosing the chart

Start from the question the chart answers, not from the chart types a package offers. In an app, most answers are a line, a bar or a single number.

| The question | Chart | Instead, when | Without the chart (screen readers, tiny widths) |
|---|---|---|---|
| How did it change over time? | line (area for one series) | ≤ 6 points: bars; one period vs the last: a number with its change | the latest value, the change and the high/low in a sentence |
| Which is biggest? How do they rank? | horizontal bars, sorted | categories with long names or more than ~7: still bars, never a pie | the sorted list with values |
| What share of the whole? | a single stacked bar or a donut, ≤ 5 parts | more parts or close values: sorted bars with percentages | the parts with their percentages |
| Are we on target? | a progress bar or bullet bar against a target mark | several targets: one row each | "72 % of the monthly target (3,600 of 5,000)" |
| How is it spread? Any outliers? | histogram; box plot for expert users | few values: a dot strip | median, range and the outliers named |
| Do two measures move together? | scatter | for a general audience: two lines on the same time axis, never a dual y-axis | the relationship in words |
| When is it busy? (hour × day) | a heat-map grid with a sequential ramp | few slots: a sorted bar list | the busiest and quietest slots |
| How does a total build up? | waterfall | two or three steps: a sentence with the numbers | the start, each step, the end |

- **One message per chart.** If the caption needs "and", it's two charts (small multiples share their axes).
- **Avoid by default:** pies with more than 5 slices, 3D anything, dual y-axes, radar charts for a general audience, gauges where a progress bar fits. Each reads as impressive and answers less.
- **Label directly** when there are ≤ 4 series or ≤ 12 bars: the value at the bar's end or the series name at the line's end, instead of a legend the eye has to travel to. A legend, when needed, sits next to the chart and in series order.
- **Show the time grain** ("by week", "by month") in the title or the axis, and keep it switchable where users compare periods.
- **Many points** (more than ~ 1 per 2 px of width): aggregate (per day → per week) or sample, and let the user drill into a range; never draw 5,000 points into 300 px.
- **A table view** for any chart that carries numbers the user may need: a "Show as table" toggle or the table below the chart on wide screens. It's the accessible form, the exportable form and the one people check numbers in.

### Colors

- Series colors come from scheme and palette roles, chosen by meaning: due → `palette.info`/upcoming, collected → `palette.success`, expected → `primary`. Never hard-coded hex.
- Gridlines: `outlineVariant`, 1 px. Axis labels: labelSmall / `onSurfaceVariant`, tabular figures.
- No more than 4–5 series; beyond that, use small multiples or a table.
- Data marks (lines, bars, points) ≥ 3:1 against the chart background, and data labels ≥ 4.5:1 (`accessibility.md`). Two series never differ by hue alone: add a dash pattern, a marker shape or a direct label, so the chart reads in grayscale and for color-blind users.
- Sequential data (low → high) uses one hue from light to dark; diverging data (below / above a midpoint) uses two hues meeting at a neutral; never a rainbow.

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
- Touch: tapping anywhere in a bar's column, or near a point (within 24 px), selects it; a 4 px dot is not a 48 px target. Selected values stay shown until another is tapped, rather than vanishing with the finger.
- Keyboard (desktop): the chart is focusable, and arrow keys move between points with the tooltip following.

## Amounts everywhere

- Minor units in data, `intl` formatting at the edge, tabular figures, `Ltr` in RTL, the same decimals in a column, negative values with a minus sign (and color only as a second signal).
- Totals in several currencies: one line per currency, never one summed number (`forms.md` › Money).
- A hero summary (this month's total) is one `AppCard` on `primaryContainer` with the amounts in `headlineMedium`; shares by category are pill `LinearProgressIndicator`s scaled to the largest category, with the amount as text beside each.
