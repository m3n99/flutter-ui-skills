# Anti-patterns → fixes

Things that make Flutter UI look default, dated, inconsistent or machine-generated. Scan every diff for these.

## Identity, flow and words

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 1 | No brief: tokens chosen before anyone wrote what the app is, for whom, and what it must make easy | every choice falls back to a default | five lines in DESIGN.md first (identity.md) |
| 2 | The template's seed and font left as shipped, or `Colors.deepPurple` / indigo and Inter / Roboto with no reason | the app looks like every generated app | seed and typeface from the brand or the subject; the sameness check |
| 3 | A greeting, an avatar and a bell over a 2 × 2 grid of numbers, whatever the app is | a home that answers nothing and leads nowhere | home shows the answer to the user's daily question with the action beside it (ux.md, screens.md) |
| 4 | No signature, or decoration everywhere (gradients, tints and icons on every row) | nothing is memorable when everything is dressed up | one signature from the subject's world in one to three places; the rest quiet |
| 5 | The most frequent task three or more taps deep, or its action in the app bar | daily friction | a shortcut on the home screen or the row; the primary action in the thumb zone |
| 6 | Asking for what the app knows or could default (the date, the last customer, the currency), or losing typed input after a failed save | retyping; abandoned forms | defaults, remembered choices, the form stays filled with the error beside the action |
| 7 | Sign-in errors in a SnackBar; social buttons louder than the main path; no show-password button | the failure disappears; the wrong path is taken; typos | the error inside the form by the button; one primary action; a visibility toggle (`assets/examples/sign_in_screen.dart`) |
| 8 | Settings as one long list; a toggle that needs Save; a pick-one that hides its current value | nothing can be found or trusted | grouped cards, changes apply at once, the value in the row (`assets/examples/settings_screen.dart`) |
| 9 | "Submit", "OK", "Yes" on buttons; "Success", "No data", "Something went wrong" in messages | the interface says nothing; it reads as a template | verb + object on buttons; messages name the thing; errors say what to do (writing.md) |
| 10 | Two names for one thing ("Delete" here, "Remove" there; "bill" and "invoice") | the user wonders whether they differ | one name per thing, one verb per action, through the whole flow |
| 11 | Arabic strings translated word for word, gendered imperatives on buttons, two plural forms | reads as foreign; wrong for half the users; wrong counts | plain Modern Standard Arabic, verbal nouns on buttons («حفظ»), all six plural forms (writing.md) |

## System

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 12 | A second design system or `theme/` folder next to the project's own | two sources of truth, drift | extend the existing system (discovery.md) |
| 13 | `Colors.blue`, `Colors.grey[200]`, `Color(0xFF…)` in widgets | off-brand, breaks dark mode | scheme roles / palette tones |
| 14 | `fontSize: 15`, `fontSize: 22` scattered | no type system | text theme roles |
| 15 | `SizedBox(height: 10)`, `EdgeInsets.all(15)` | off-grid rhythm | `AppSpace` tokens, `Column(spacing:)` |
| 16 | New colors or styles invented per screen | drift | add once to theme/tokens, reuse, record in DESIGN.md |
| 17 | Unchanged `ThemeData()` / default purple seed | instantly reads as unstyled | seed + direction in `AppThemeConfig` |
| 18 | M3 surface tint on app bars, cards, sheets | grey-purple wash | `surfaceTintColor: Colors.transparent` |
| 19 | Theme contradicting its own direction (Enterprise Dense with 52 px buttons and 16 px cards) | screens fight the theme | direction values in tokens/config, not per widget |
| 20 | Bare `ListTile` rows because the spec said "keep it basic" | reads as unstyled; a redesign round later | ask the look question (intake); cards per record unless the user picks rows |
| 21 | Template widgets re-created by hand after copying only part of the kit | lookalikes drift from the originals | copy the core kit; add kits with `copy_design_system.py` |
| 22 | Token arithmetic (`AppSpace.xs + 2`), raw `0.55` opacities, `maxWidth: 132` | off-grid values the tokens exist to prevent | the next token step, or a new named token; `lint_ui.py` |
| 23 | "Soft" containers as strong as their seed (fidelity `primaryContainer`, hand-picked tones) | solid red / amber blocks, glare in dark mode; contrast still passes | containers from tonalSpot (`ToneColors.fromSeed`, `AppTheme`); soft-container check |

## Visual hierarchy and shapes

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 24 | Same spacing between everything | no grouping, flat page | small gaps inside groups, large between |
| 25 | `Card(elevation: 4)`, `BoxShadow(blurRadius: 4, color: Colors.black26)` | 2015 look, muddy in dark | flat card + hairline border; soft shadow only for floating UI and raised KPI tiles |
| 26 | Every item its own shadowed card | busy, heavy | one grouped card or a plain list |
| 27 | Card inside a card, double borders, stacked shadows | cluttered, amateur | one container level; ExpansionTile without its own borders |
| 28 | Same radius on nested shapes (12 px row inside a 12 px card with 8 px padding) | corners don't nest | `AppRadius.concentric(outer, gap)` |
| 29 | Concentric rule applied blindly (an input 16 px inside a 12 px card gets radius 0) | sharp controls | concentric only while gap < outer radius |
| 30 | Several filled buttons side by side | no action hierarchy | one primary; others tonal / outlined / text |
| 31 | Gradients everywhere, random accent colors | noisy | one accent; a gradient on one hero element at most |
| 32 | Pure `#FFFFFF` page background or `#000000` text; pure white surfaces in long-session apps | harsh, tiring | `surface` roles; eye-comfort surfaces for ledgers/admin/reading |
| 33 | Mixed icon styles (filled + outlined + sharp) | visual noise | one family; filled only for the selected state |

## Components

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 34 | Status shown by color alone (red text for overdue) | inaccessible, ambiguous | `StatusPill` with icon + label from one status mapping |
| 35 | Selected chips only tinted | invisible to color-blind users | check mark + fill (theme) |
| 36 | `colorScheme.error` for business states (overdue, unpaid) | errors and states blur | domain tones in `AppPalette` |
| 37 | Floating labels + underline inputs | dated | label above, filled or outlined fields |
| 38 | Filled inputs on low-contrast warm surfaces | field edges vanish | `InputStyle.outlined` with `outline` at rest |
| 39 | Each sheet with its own layout, buttons in random order | inconsistent | `SheetScaffold`: header, scroll body, sticky footer; secondary start, primary end |
| 40 | Footer buttons split 1 : 2 or 1 : 1 | long labels truncate (esp. Arabic) | secondary as wide as its label, primary fills |
| 41 | KPI value at headline size overflowing a 160 px tile | broken tiles | `FittedBox(scaleDown)`, label `maxLines` |
| 42 | Emoji as the only carrier of meaning, scaling with text | inconsistent, inaccessible | emoji as a fixed-size icon next to a label |
| 43 | A scrolling chip row for a few single-choice options | the last options end up off-screen on a phone | wrap; an inline label is the first `Wrap` child (`AppChoiceChips(label:)`); scroll only long filter lists |
| 44 | A pick-one sheet with an Apply button, or a sort hidden in a form-like sheet | two taps for one choice | `showAppPicker`: the tap chooses and closes |
| 45 | Two FABs with the default hero tag in an IndexedStack / `StatefulShellRoute.indexedStack` shell | crash on the first pushed route | `heroTag: null` (or unique tags); a shell case in the harness |
| 46 | `SegmentedButton` for a choice in a form or a sheet | its segments share one row: they truncate or overflow at text scale 1.6 and in longer languages | wrapping `AppChoiceChips` |

## States and messages

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 47 | Centered spinner for content loads (or on just one screen) | blank, jumpy, unfinished | skeletons shaped like the content, on every data screen |
| 48 | Missing empty and error states | looks broken without data | `EmptyState` / `EmptyState.error` with what failed and Retry |
| 49 | Generic "Something went wrong" / raw exception text | useless to the user | what failed + what to do; validation passes through |
| 50 | "Success" messages | says nothing | name the thing ("Created INV-1043 for …") |
| 51 | SnackBar with an action that never closes (Flutter ≥ 3.38) | stuck messages | `persist: false` in the message component |
| 52 | `fluttertoast` on desktop | no Windows support | SnackBar via a global `ScaffoldMessengerKey` |
| 53 | Delete without confirmation or Undo | data loss | confirm → hide → Undo message → commit on close |
| 54 | Undo that releases the key before reload / keeps keys forever / deletes "the open record" | flashing rows, hidden new rows, wrong deletes | release after reload, always release, commit by explicit id |
| 55 | Save button that can be pressed twice | duplicate records | `SubmitButton` (busy, ignores presses) |
| 56 | A SnackBar for an error from a sheet's or dialog's action | it opens on the page behind the modal sheet, where nobody sees it | `SheetScaffold(error:)` above the footer; the sheet stays open |
| 57 | Amounts in several currencies added into one total | the number is wrong for every currency in it | one line per currency, each formatted on its own |

## Layout, platforms, RTL

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 58 | Text overflow stripes / unbounded `Row` text | broken at runtime | `Expanded` + `maxLines` + ellipsis; layout test at 360 × 1.3 |
| 59 | Save bar in `Scaffold.bottomNavigationBar` on a form | hidden under the keyboard | last child of the body `Column` |
| 60 | `controller.text = …` inside `build` (or a BlocBuilder) to pre-fill a form | "setState() called during build": only edit mode crashes | fill in the controller's initializer or `initState`; later data in a listener; test create and edit cases |
| 61 | `Align` without `heightFactor` inside a bar | bar fills the screen | `heightFactor: 1` |
| 62 | Touch metrics on desktop / desktop metrics on touch | cramped or oversized | `AppDensity` by platform |
| 63 | No hover, cursor, visible scrollbar or tooltips on desktop | feels like a stretched phone app | `adaptive.md` pointer affordances |
| 64 | Breakpoints that stop at tablet; stretched forms on 1920 px | wasted space or unreadable lines | list-detail, rails, content caps (640 / 720 / 1440) |
| 65 | List-detail pane that closes only with Esc, or not at all | needs focus and nobody finds it; no way back to the first view | ✕ with a tooltip in the pane header, a second click on the open row deselects, Esc as a shortcut |
| 66 | `EdgeInsets.only(left:)`, `Alignment.centerLeft`, `TextAlign.left` | breaks RTL | directional APIs |
| 67 | Letter-spacing on Arabic | broken joins | `AppScript.arabic` (tracking 0) |
| 68 | Numbers/phones without LTR isolation in RTL | `123456-0599` | `Ltr` / `ltr()`; separate `pw.Text` runs in PDFs |
| 69 | An LTR amount field left at `TextAlign.start` in RTL | digits glued to a currency suffix (`₪2500`) or far from a prefix | `TextAlign.end` on RTL screens (the reading start) |
| 70 | Swapping `chevron_left` / `chevron_right` by direction | Material directional icons already mirror: the arrow flips twice | the LTR meaning everywhere; let `matchTextDirection` mirror it |
| 71 | A font that lacks a symbol the UI shows (Tajawal has no `₪`, `٫`, `✓`) | boxes or a mismatched system glyph | `check_glyphs.py`; a `fontFamilyFallback` that has them |
| 72 | Charts left-to-right in an RTL app | time reads backwards | mirror x index, value axis on the reading start |
| 73 | Autocomplete overlay spanning the screen / querying on programmatic fills | ugly, slow | start-aligned, max width, guard with `focusNode.hasFocus` |
| 74 | A header, search bar, bottom bar or button touching the system bars, or under them (no `SafeArea`, or a safe area with no padding) | hidden by the Dynamic Island or the navigation bar, or cramped against them | `SafeArea` + ≥ 8 px (`SaveBar` for bottom bars); the harness's system-bar check |
| 75 | A list whose last row ends under the navigation bar or behind the FAB (an explicit `ListView(padding:)` drops the automatic safe area) | the last row can't be read or tapped | end with `context.listEndPadding(fab: …)` |
| 76 | A name and an amount side by side at big font sizes | the name shrinks to a few letters | `context.isNarrow` → the amount under the name |

## Motion and performance

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 77 | `AnimatedList` losing item state when rows shift | expanded tiles jump to other rows | `AnimatedItems` (keyed by id, `findChildIndexCallback`) |
| 78 | Charts and progress animating from 0 on every update, or while hidden | noisy, the change is missed | animate from previous values; hold while `TickerMode` is off |
| 79 | Long, bouncy, decorative animations; no reduced-motion support | sluggish, inaccessible | tokens (150–350 ms), `context.motion`, `AppCurves.pop` only for celebrations |
| 80 | `shrinkWrap: true` long lists inside `Column` / `SingleChildScrollView` | jank, no laziness | slivers |
| 81 | `MediaQuery.of(context).size` everywhere | extra rebuilds | `MediaQuery.sizeOf(context)` |
| 82 | Placeholder data ("Item 1", lorem) in screens and screenshots | can't judge the design | realistic names, lengths and amounts |
| 83 | Motion added without asking how much (none, soft, expressive) and where | too much or too little: a redo, or an app that feels off to its owner | intake › Motion with its examples; `AppThemeConfig.motion` |

## Printed documents (PDF)

| # | Anti-pattern | Why it hurts | Fix |
|---|---|---|---|
| 84 | One fixed `pw.Page` holding content that grows, with no line budget | `pdf` drops what doesn't fit without an error: the signatures vanish and the tests stay green | a line budget the form enforces, or `pw.MultiPage`; a longest-case sample with block checks |
| 85 | A stamp or seal placed at a fraction of the page (`pw.Alignment(0.6, 0.7)`) | lands on text as soon as the content above changes height | anchor it inside its block (`pw.Stack` in the signature slot) |
| 86 | PDF layouts reviewed in code only, or only with typical data | clipping, collisions and `null` reach paper | typical, empty-optional and longest samples → rasterize → open every page |

## Smell test

If a screenshot could be any app, it's not done. Look for at least one **signature element** of the chosen direction: an expressive header, a hero or KPI row, a distinctive shape language, tinted icon badges, confident typography.
