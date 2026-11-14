# {App name} — design system

The contract for every screen. Read it before changing UI; update it in the same change when you add a token, a pattern or a decision. Every rule here can be checked against a screen or the source.

Code: `{lib/core/design_system/}` (import `design_system.dart`). Widgets never use raw numbers or colors: every value below is a token.

## Brief

Who this app is, in five lines. Every later choice answers to them (`flutter-modern-ui` › identity).

- **Subject:** {what the app is, in its own world's words}
- **Audience and setting:** {who, where, for how long}
- **The job:** {the one thing it must make easy; the home screen shows it first}
- **Feeling:** {three words that rule something out}
- **Signature:** {the one element from the subject's world} — appears on {home card, record card, empty state} only
- **Palette:** {ink `#1F2A44` (seed, fidelity) · warm paper surfaces · check-green settled · stamp-red overdue · pencil-grey details}
- **Typeface:** {family, why; numerals tabular} · icons: {`Icons.*_rounded`}
- **Voice:** {plain and exact; buttons say what happens; one name per thing}

## Direction and decisions

- **Direction:** {Soft Minimal / Enterprise Dense / …}{, eye comfort}. {One sentence on the feel.}
- **Platforms:** {Android (touch), Windows (mouse, desktop density), …}
- **Languages / direction:** {Arabic only, RTL} · digits: {Western 0-9 / Arabic-Indic}
- **Look:** {cards / plain rows / rich} — {one card per record with status pill and end-aligned amount; KPI tiles on the dashboard}
- **Emoji:** {none / KPI tiles only / …}
- **Motion:** {none / soft / expressive} (`AppThemeConfig.motion`) on {cards and lists on load, list changes, numbers and charts, buttons, errors, pages, loading}
- **Derived from references:** {apps / screenshots, what was kept, what was left out} (optional)

### Deliberate deviations from the plugin defaults
- {e.g. warm hand-picked palette instead of fromSeed surfaces, checked ≥ 4.5:1}
- {e.g. 40 px controls on Windows}

## 1. Tokens

### Spacing — `{AppSpace}` (4-pt grid)

| Token | px | Use for |
|---|---|---|
| xxs | 4 | {title ↔ subtitle; icon ↔ label in pills} |
| xs | 8 | {chips both ways; buttons in a bar; group-card inset} |
| sm | 12 | {list cards; form grid gaps; row padding} |
| md | 16 | {card padding; form sections} |
| lg | 24 | {sections; sheet side padding} |
| xl | 32 | {empty-state side padding} |
| xxl | 48 | {empty-state vertical padding} |
| screen | {16/20/24} | horizontal page padding |

Rule: every padding, gap and `spacing:` is one of these.

### Radius — `{AppRadius}`

| Token | px | Use for |
|---|---|---|
| xs | 4 | {chart bar tops; rows inside group cards and menus} |
| sm | 8 | {inputs, buttons, menus, tooltips} |
| md | 12 | {cards} |
| xl | 24 | {sheet top corners, dialogs} |
| pill | 999 | {pills, chips, progress bars} |

### Elevation

| Token | Value | Use for |
|---|---|---|
| flat | 0 | cards, app bar, nav, rail (cards: 1 px `outlineVariant` border) |
| raised | 1 | FAB at rest |
| overlay | 3 | menus, autocomplete |

Raised tiles (`AppCard(raised: true)`, {dashboard KPIs only}): `palette.softShadow` {values}; light mode drops the border, dark keeps it.

### Typography — `context.textStyles`

| Role | Size / weight | Use for |
|---|---|---|
| headlineSmall | 20 / 600 | {sheet and dialog titles, KPI values} |
| titleLarge | 18 / 600 | {section headers, app bar} |
| titleMedium | 16 / 600 | {card titles, form section titles} |
| titleSmall | 14 / 600 | {row titles, field labels, amounts in rows} |
| bodyMedium | 14 / 400 | {body, inputs} |
| bodySmall | 12 / 400 | {dates, phones, helper text} |
| labelLarge | 14 / 600 | {buttons, chips, sheet section labels} |
| labelMedium | 12 / 600 | {pills, KPI labels, legends} |
| labelSmall | 11 / 600 | {chart axes} |

Font: {family} ({weights}). {Arabic: letter-spacing 0, body line height 1.6.} Amounts and dates: tabular, inside `Ltr`.

### Color roles

`ColorScheme` for surfaces / text / primary / error; `context.palette` for {success, warning, info, overdue, paid, …} (each: color, onColor, container, onContainer). Both modes defined; every text/background pair ≥ 4.5:1 (`contrast_test.dart`). No `Color(0x…)` / `Colors.*` in widgets.

### Sizes and density

- Touch target {48 × 48 on Android}; desktop controls {40 px}.
- Icons: 14 pill · 16 inline · 20 dense · 24 regular · 32 feature · 48 hero.
- Dialog widths: confirm 420 · sheet-as-dialog 560 · {large form 1000}. Content caps: forms 640 · pages {880 / 1440}.

## 2. Nested shapes and card types

1. Concentric corners while the gap < outer radius (`AppRadius.concentric`); otherwise the child keeps its own radius; a child filling its parent is clipped.
2. No card in a card; no double borders; no stacked shadows.

| Card type | Padding | Radius |
|---|---|---|
| {Content card} | 16 | {12} |
| {Group card} | 8, rows 12 × 8 | {12, rows 4} |
| {Row card} | 0, row 12 × 8 | {12, row 0 (clipped)} |
| {KPI tile (raised)} | 16 | {12, emoji badge 8} |

## 3. Sheets and dialogs

`showAppSheet` + `SheetScaffold`: bottom sheet < 600 px, 560 px dialog wider. Header (title + ✕) · scrolling body of `SheetSection`s 24 apart · sticky footer (hairline, safe area, 24 × 12). Footer: secondary at the start (label width), primary fills the rest; one filled button.

| Sheet | Secondary | Primary |
|---|---|---|
| {Filters} | {Clear all} | {Apply / Apply (n)} |
| {Payment} | {Cancel} | {Save (spinner)} |

Chips 8 / 8; selected = fill + check; equal heights.

## 4. Lists, status, KPIs

- Lists of cards are `AnimatedItems` keyed by {id}; gaps {12 records / 8 dense lists}.
- Status mapping (one place: `{status_ui.dart}`):

| Status | Label | Icon | Tone |
|---|---|---|---|
| {overdue} | {…} | {…} | {overdue} |

- KPI tiles: {emoji/icon per tile}, value headlineSmall tabular, shrinks to fit; 2 per row, 4 from {840/1200} px.

## 5. Motion

Level: **{soft}** (`MotionLevel.{soft}`), asked before the first screen. Places: {cards and lists on load, list changes, numbers, buttons, loading}. Places not listed don't move.

| What | Duration | Curve | {Soft} |
|---|---|---|---|
| Press / small state change | 150 ms | standard | {press 0.98} |
| Card entrance, insert, remove | 250 ms | enter / exit | {rise 4 %, no stagger} |
| Charts, progress, counters | 350 ms | standard | {tween from the old value} |
| Errors | 420 ms | — | {shake 4 px, with the message} |

Durations × {1.0 soft / 1.2 expressive}; reduced motion and `MotionLevel.none`: every duration 0 (`context.motion`), no entrance, no shimmer.

## 6. Messages

One component: `{AppMessenger / CustomToastMessage}`. Icon + text; success on inverse surface, errors on error container; 4 s plain, 6 s with an action (`persist: false`).

| Event | Message |
|---|---|
| {Add record} | {Added record {no} for {name}} |
| {Delete} | confirm → {Deleted record {no}} · action: Undo |
| {Error} | what failed + what to do |

Delete with Undo: hide at once → commit on close without Undo → release the key after reload; commit by explicit id.

## 7. Layout

- Breakpoints: compact < 600 (bottom nav, sheets, 1 column) · medium 600–{839/1199} (rail, dialogs, 2 columns) · {expanded/large} (extended rail, table + detail).
- Works from 360 px and text scale 1.3 and 1.6 with no overflow. Narrow (`context.isNarrow`: width ÷ text scale < 340): {the amount goes under the name, KPI tiles one per row, form fields one per row}.
- System bars: nothing touches the status bar, the camera cutout or Dynamic Island, the navigation bar or the home indicator. Headers without an app bar sit in `SafeArea` + {16} px; bottom bars are `SaveBar`s (safe area + 12 px); lists end with `context.listEndPadding()` (+ the FAB's 72 px).
- RTL: directional APIs only; numbers in `Ltr`.
- List-detail: the pane closes with a ✕ in its header, a second click on the open row, or Esc.
- A few single-choice options: wrapping chips with an inline label, never a scrolling row.

## 8. Printed documents (delete if the app doesn't print)

| Document | Page | Budgets (form caps) | Marked blocks |
|---|---|---|---|
| {Invoice} | {A5, 12.7 mm margins, one page} | {payments 4 rows (3 + summary) · notes 160 chars · names 2 lines} | {signatures, totals, stamp, issuedAt} |

- Font: {the app's family} via `pw.ThemeData.withFont`; text ≥ 8 pt, rules ≥ 0.5 pt, near-black ink.
- LTR runs (numbers, dates, phones, amounts) are separate `pw.Text`s in an LTR `pw.Directionality`.
- Stamps and seals sit inside their block, never at a fraction of the page.

## 9. Checking a change

```bash
flutter analyze
flutter test
flutter test test/ui                                                        # layout matrix, sheets, contrast
flutter test test/ui/visual_test.dart test/ui/sheets_test.dart --update-goldens --dart-define=VISUAL=true   # screenshots → test/ui/screenshots/
flutter test test/pdf                                                       # sample PDFs + block checks → test/pdf/out/
python3 <flutter-ui-verify>/scripts/rasterize_pdf.py test/pdf/out --text    # then open every page
```
