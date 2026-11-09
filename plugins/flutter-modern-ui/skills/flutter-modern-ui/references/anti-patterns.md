# Anti-patterns → fixes

Things that make Flutter UI look default, dated, inconsistent or machine-generated. Scan every diff for these.

## System

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 1 | A second design system or `theme/` folder next to the project's own | two sources of truth, drift | extend the existing system (discovery.md) |
| 2 | `Colors.blue`, `Colors.grey[200]`, `Color(0xFF…)` in widgets | off-brand, breaks dark mode | scheme roles / palette tones |
| 3 | `fontSize: 15`, `fontSize: 22` scattered | no type system | text theme roles |
| 4 | `SizedBox(height: 10)`, `EdgeInsets.all(15)` | off-grid rhythm | `AppSpace` tokens, `Column(spacing:)` |
| 5 | New colors or styles invented per screen | drift | add once to theme/tokens, reuse, record in DESIGN.md |
| 6 | Unchanged `ThemeData()` / default purple seed | instantly reads as unstyled | seed + direction in `AppThemeConfig` |
| 7 | M3 surface tint on app bars, cards, sheets | grey-purple wash | `surfaceTintColor: Colors.transparent` |
| 8 | Theme contradicting its own direction (Enterprise Dense with 52 px buttons and 16 px cards) | screens fight the theme | direction values in tokens/config, not per widget |

## Visual hierarchy and shapes

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 9 | Same spacing between everything | no grouping, flat page | small gaps inside groups, large between |
| 10 | `Card(elevation: 4)`, `BoxShadow(blurRadius: 4, color: Colors.black26)` | 2015 look, muddy in dark | flat card + hairline border; soft shadow only for floating UI and raised KPI tiles |
| 11 | Every item its own shadowed card | busy, heavy | one grouped card or a plain list |
| 12 | Card inside a card, double borders, stacked shadows | cluttered, amateur | one container level; ExpansionTile without its own borders |
| 13 | Same radius on nested shapes (12 px row inside a 12 px card with 8 px padding) | corners don't nest | `AppRadius.concentric(outer, gap)` |
| 14 | Concentric rule applied blindly (an input 16 px inside a 12 px card gets radius 0) | sharp controls | concentric only while gap < outer radius |
| 15 | Several filled buttons side by side | no action hierarchy | one primary; others tonal / outlined / text |
| 16 | Gradients everywhere, random accent colors | noisy | one accent; a gradient on one hero element at most |
| 17 | Pure `#FFFFFF` page background or `#000000` text; pure white surfaces in long-session apps | harsh, tiring | `surface` roles; eye-comfort surfaces for ledgers/admin/reading |
| 18 | Mixed icon styles (filled + outlined + sharp) | visual noise | one family; filled only for the selected state |

## Components

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 19 | Status shown by color alone (red text for overdue) | inaccessible, ambiguous | `StatusPill` with icon + label from one status mapping |
| 20 | Selected chips only tinted | invisible to color-blind users | check mark + fill (theme) |
| 21 | `colorScheme.error` for business states (overdue, unpaid) | errors and states blur | domain tones in `AppPalette` |
| 22 | Floating labels + underline inputs | dated | label above, filled or outlined fields |
| 23 | Filled inputs on low-contrast warm surfaces | field edges vanish | `InputStyle.outlined` with `outline` at rest |
| 24 | Each sheet with its own layout, buttons in random order | inconsistent | `SheetScaffold`: header, scroll body, sticky footer; secondary start, primary end |
| 25 | Footer buttons split 1 : 2 or 1 : 1 | long labels truncate (esp. Arabic) | secondary as wide as its label, primary fills |
| 26 | KPI value at headline size overflowing a 160 px tile | broken tiles | `FittedBox(scaleDown)`, label `maxLines` |
| 27 | Emoji as the only carrier of meaning, scaling with text | inconsistent, inaccessible | emoji as a fixed-size icon next to a label |
| 28 | A scrolling chip row for a few single-choice options | the last options end up off-screen on a phone | wrap; an inline label is the first `Wrap` child (`AppChoiceChips(label:)`); scroll only long filter lists |

## States and messages

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 29 | Centered spinner for content loads (or on just one screen) | blank, jumpy, unfinished | skeletons shaped like the content, on every data screen |
| 30 | Missing empty and error states | looks broken without data | `EmptyState` / `EmptyState.error` with what failed and Retry |
| 31 | Generic "Something went wrong" / raw exception text | useless to the user | what failed + what to do; validation passes through |
| 32 | "Success" messages | says nothing | name the thing ("Created INV-1043 for …") |
| 33 | SnackBar with an action that never closes (Flutter ≥ 3.38) | stuck messages | `persist: false` in the message component |
| 34 | `fluttertoast` on desktop | no Windows support | SnackBar via a global `ScaffoldMessengerKey` |
| 35 | Delete without confirmation or Undo | data loss | confirm → hide → Undo message → commit on close |
| 36 | Undo that releases the key before reload / keeps keys forever / deletes "the open record" | flashing rows, hidden new rows, wrong deletes | release after reload, always release, commit by explicit id |
| 37 | Save button that can be pressed twice | duplicate records | `SubmitButton` (busy, ignores presses) |

## Layout, platforms, RTL

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 38 | Text overflow stripes / unbounded `Row` text | broken at runtime | `Expanded` + `maxLines` + ellipsis; layout test at 360 × 1.3 |
| 39 | Save bar in `Scaffold.bottomNavigationBar` on a form | hidden under the keyboard | last child of the body `Column` |
| 40 | `Align` without `heightFactor` inside a bar | bar fills the screen | `heightFactor: 1` |
| 41 | Touch metrics on desktop / desktop metrics on touch | cramped or oversized | `AppDensity` by platform |
| 42 | No hover, cursor, visible scrollbar or tooltips on desktop | feels like a stretched phone app | `adaptive.md` pointer affordances |
| 43 | Breakpoints that stop at tablet; stretched forms on 1920 px | wasted space or unreadable lines | list-detail, rails, content caps (640 / 720 / 1440) |
| 44 | List-detail pane that closes only with Esc, or not at all | needs focus and nobody finds it; no way back to the first view | ✕ with a tooltip in the pane header, a second click on the open row deselects, Esc as a shortcut |
| 45 | `EdgeInsets.only(left:)`, `Alignment.centerLeft`, `TextAlign.left` | breaks RTL | directional APIs |
| 46 | Letter-spacing on Arabic | broken joins | `AppScript.arabic` (tracking 0) |
| 47 | Numbers/phones without LTR isolation in RTL | `123456-0599` | `Ltr` / `ltr()`; separate `pw.Text` runs in PDFs |
| 48 | Charts left-to-right in an RTL app | time reads backwards | mirror x index, value axis on the reading start |
| 49 | Autocomplete overlay spanning the screen / querying on programmatic fills | ugly, slow | start-aligned, max width, guard with `focusNode.hasFocus` |

## Motion and performance

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 50 | `AnimatedList` losing item state when rows shift | expanded tiles jump to other rows | `AnimatedItems` (keyed by id, `findChildIndexCallback`) |
| 51 | Charts and progress animating from 0 on every update, or while hidden | noisy, the change is missed | animate from previous values; hold while `TickerMode` is off |
| 52 | Long, bouncy, decorative animations; no reduced-motion support | sluggish, inaccessible | tokens (150–350 ms), `context.motion`, `AppCurves.pop` only for celebrations |
| 53 | `shrinkWrap: true` long lists inside `Column` / `SingleChildScrollView` | jank, no laziness | slivers |
| 54 | `MediaQuery.of(context).size` everywhere | extra rebuilds | `MediaQuery.sizeOf(context)` |
| 55 | Placeholder data ("Item 1", lorem) in screens and screenshots | can't judge the design | realistic names, lengths and amounts |

## Printed documents (PDF)

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 56 | One fixed `pw.Page` holding content that grows, with no line budget | `pdf` drops what doesn't fit without an error: the signatures vanish and the tests stay green | a line budget the form enforces, or `pw.MultiPage`; a longest-case sample with block checks |
| 57 | A stamp or seal placed at a fraction of the page (`pw.Alignment(0.6, 0.7)`) | lands on text as soon as the content above changes height | anchor it inside its block (`pw.Stack` in the signature slot) |
| 58 | PDF layouts reviewed in code only, or only with typical data | clipping, collisions and `null` reach paper | typical, empty-optional and longest samples → rasterize → open every page |

## Smell test

If a screenshot could be any app, it's not done. Look for at least one **signature element** of the chosen direction: an expressive header, a hero or KPI row, a distinctive shape language, tinted icon badges, confident typography.
