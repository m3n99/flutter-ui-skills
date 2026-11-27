# Changelog

## 1.8.0

Advanced rules adapted from a review of [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) (MIT), a web-first UI/UX rule set. Only what this plugin lacked was taken, rewritten for Flutter and tied to its tokens, widgets and tests; its style catalog, palettes and search tool were left out (`color.md` and the brief already cover that ground for Flutter).

### Verify: accessibility measured on the rendered screens
- **`a11y_test.dart`** (new, copied with the harness): every case, rendered once per platform, theme and direction at the smallest size, against flutter_test's guidelines: tap targets ≥ 48 px (44 on iOS), a label on every tappable, and **text contrast measured on the pixels behind the text**. `contrast_test.dart` checks the theme's pairs; this one catches text on a photo or a gradient, a one-off color, a faded caption. It uses flutter_test's square glyphs so the measured color is the text's own, and ignores layout errors (the matrix's job).
- `screenA11yProblems()` and `UiConfig.a11yMatrix` in `ui_harness.dart`; failures read as one line each (`text contrast: "Due soon" is 3.12:1, needs 4.5:1 (font size 12.0)`), grouped by variant.
- `harness.md`: the new check's limits (merged rows, icons, desktop pointer targets) and three rows in the fix table.
- CI: the check catches low-contrast text, a small and an unlabeled target, and passes a clean screen.

### Accessibility (`accessibility.md`)
- The WCAG 2.2 criteria apps miss, each with its Flutter form and a check: focus not obscured, dragging alternatives, 24 px pointer targets, consistent help, redundant entry, accessible sign-in, pause for moving content, status messages.
- An icon's semantics follow its use (decoration, meaning or control); toggles expose their state (`isSelected`, `toggled`, `expanded`); announcements are whole phrases, once.

### Forms (`forms.md`)
- Forgiving input: trim, ignore spaces and hyphens in phones and codes, Arabic-Indic digits in every numeric field, names in any script.
- Paste works in every field; one-time codes take the whole pasted code; sign-in in an `AutofillGroup` with `finishAutofillContext()`.
- An error summary for three or more errors; errors clear as soon as the field is valid; a failed submit keeps every value.
- Submit stays enabled until pressed; a create carries its own id so a retry or a double tap makes one record.
- `dirty` compares with the opening values; the focused field clears the save bar (`scrollPadding`); values given earlier are carried forward; a custom Enter shortcut waits for the input method to finish composing.

### Motion (`flutter-motion`)
- `principles.md` › Interruption: retarget from the current value, never put state changes in completion callbacks, input stays live, no half-faded remains, gestures track the finger and release with velocity.
- `testing.md` › Interruption: a double-tap and mid-animation test, also under reduced motion.

### Charts (`data-display.md`)
- Choosing the chart by the question it answers, with what to use instead and the text form for screen readers.
- What to avoid by default (9-slice pies, dual axes, 3D, gauges), direct labels for small sets, the time grain, aggregation, a table view; data marks ≥ 3:1 and series that differ by more than hue; sequential and diverging ramps; touch and keyboard selection.

### Directions and components
- `directions.md`: an RTL fit row for every direction and the elements that carry a reading direction whatever the direction (tickers, steppers, peeking carousels, time axes, pointing icons).
- `components.md`: chips that don't fit end with an operable `+n` chip; long unbroken values (IDs, emails, URLs) ellipsize with a copy action or break after separators.
- `review-checklist.md`: lines for all of the above.

### Evals
- Two cases (18 → 20): `chart-fits-question` (9 categories get sorted, labelled bars, not a pie) and `submit-stays-enabled`.

## 1.7.0

From design feedback (21 entries) on an Arabic, RTL app that prints onto pre-printed forms. Entries 1–3 had already been fixed (1.2–1.5: the printed-documents loop, `AppChoiceChips(label:)` and wrapping, the list-detail close and deselect). This release takes the other 18.

### Values on pre-printed forms (entries 6, 7, 9, 10, 11, 14, 15, 19, 21)
- **`flutter-ui-verify/references/preprinted-forms.md`**, covering:
  - positions as cm constants from the paper's corner, with page = paper and zero margins;
  - text with its baseline on the printed line and tails under it, not the deepest glyph above it, which left words floating 0.17–0.20 cm high;
  - shrink-to-fit that keeps the baseline still (`Alignment(±1, 2·d/(a+d) − 1)`; the pdf package's y points up);
  - start room inside a `FittedBox`, because the pdf package measures some Arabic narrower than it draws it and a leading «ا» was clipped («ثنا عشر»);
  - at least 0.2 cm from printed text, and amounts anchored away from a printed currency label;
  - one function returning the document and its paper format, since a `directPrintPdf` without `format:` printed A4 with every test green;
  - feed direction with `rotateBox(unconstrained: true)`;
  - system fonts such as Calibri: loaded at run time, never in assets; checked for Arabic (5.x has none); its seat measured (Calibri's Arabic rests 0.078 em high); tashkeel checked, since GPOS marks aren't applied;
  - on paper: a 10 cm ruler proves the scale first (a queue set to Letter scales A4 to 92%), each field measured against its nearest printed line, hand-cut paper is ±1 mm, a test print, and a per-printer offset for the values only.
- **`examples/cheque_pdf.dart`**, which puts all of that in one place:
  - `ChequeLayout`, the positions in cm;
  - `FormFont.fromBytes`, metrics from the font's `hhea` table;
  - `ChequePrint(document, format)`;
  - `forPrinter`, `lift` and `ChequeLayout.printerLift`;
  - the grey-guides preview and `buildChequeTestSheet` with its ruler.
- **`scripts/measure_pdf.py`**: rasterizes at 600 dpi and measures each value's ink in cm: its baseline (the bottom of the densest band, not the ink box), its start and its end. It checks them against `*.measure.json` files the PDF test writes from the same layout constants (`writePdfWithMeasures`, `MeasuredField` in the PDF harness), or measures ad hoc with `--window`.
- **`check_glyphs.py --metrics`**: per font, it prints:
  - ascent and descent as the pdf package reads them;
  - the deepest glyph of any text, contextual forms included («ي» 0.44 em in IBM Plex Sans Arabic);
  - where Arabic rests;
  - whether the font has the Arabic forms and relies on GPOS marks;
  - with `--size`, the values in cm.
- CI renders the cheque samples (typical, longest, leading «ا», lifted, turned, test sheet) and measures them, and asserts the print job's format and the per-printer lift.

### Forms, RTL, states, sheets (entries 4, 5, 12, 18)
- **`forms.md`**: an error that stops a live preview or calculation shows as soon as it's true, not after submit. *Mode switches in forms*: the switch sits next to what it reveals, turning it on prefills the field from the current result, and the derived outcome is the helper text.
- **`rtl-arabic.md`**: isolates fix the order, not where a line breaks. **`keepTogether()`** (in `ltr.dart`) puts no-break spaces and word joiners in values like «4–6 × 1,200 ₪». A list of such values goes in a `Wrap` of LTR `Text`s.
- **`EmptyState.inline` / `.inlineError`** for a list that is a section of a page that already scrolls: no nested scroll view, a plain icon, one sentence. `states.md` says which size goes where.
- **Checklist**: a sheet's failed action shows where it's always in view (above the footer or at the top of the body), never only at the end of a scrolling body.

### Harness (entries 8, 17)
- **`harness.md`**: widgets that call a plugin while building get one injectable function, swapped before the first pump, because an `IndexedStack` shell builds every tab and one plugin call breaks every screenshot. Widgets that read files get an injectable loader, or a future completed in `tester.runAsync` and passed in.

### Scripts on Windows (entries 13, 16, 20)
- **Every script prints UTF-8** whatever the console, and reads `git` and poppler output as UTF-8. `lint_ui.py --diff` crashed on any Arabic in a change (`stdout` came back `None`), and `rasterize_pdf.py --text` stopped at the first Arabic page with `UnicodeEncodeError`.
- **`raw-duration`** only applies to presentation code: files that import Flutter's widgets, outside `test/`, `data/`, `domain/`, `repos/`, `use_cases/`, `services/` and similar. A sync interval or a debounce is timing, not motion.
- **CI runs the scripts on Windows**, with Arabic in a git diff, in printed text and in font metrics (`ci/scripts_unicode_test.py`).

## 1.6.0

Color when the user gives none. The skills took a seed from the subject or from a direction's table, which in practice meant a color picked from memory. Now they find the app's own color, or search real palettes and let the user choose.

### Finding a palette (`references/color.md`)
- **The app's own color first**: the launcher icon and splash config, `colors.xml`, `manifest.json`, `Assets.xcassets`, existing constants, the business's website. A brand color found there is the primary; the search is then only for its companions, with it locked.
- **Otherwise, search real sources** with the brief's subject and feeling words: Color Hunt (by tag), Coolors (trending), Figma's palette pages, Realtime Colors, Adobe Color, Huemint, Happy Hues, and real products in the same field (structure only, never a competitor's color). Six to ten candidates from at least two sources, each with its URL. The reference says which sites can be fetched and which need a browser.
- **Show three**, on a preview sheet with light and dark mock-ups, one recommended, as the intake's color question. An unattended run takes the recommendation and records it as a default to confirm.
- Hooked into the hub, intake (a new *Color* default), identity, directions (its seeds are now hue families, not answers), theming, the design-system skill and the DESIGN.md template (*Palette source*).

### `scripts/palette.py`
- Reads Coolors, Color Hunt and Realtime Colors palettes from their URLs (no network), hex codes from any page text (Figma's palette pages), or `--file`.
- Gives each color a UI role (ink, paper, primary, secondary, accent), or takes them from a Realtime Colors link or `--roles`; makes a missing ink or paper from the primary's hue.
- Checks contrast the way the UI uses each role. A primary or accent too light for its job is darkened in the same hue, and the report says from what to what.
- Warns about the generated-app purple and indigo, a red primary, neon, poster palettes and an accent that won't stand out.
- Ranks palettes from real sources before the fallback library.
- `--preview` draws the top three as light and approximate dark mock-ups (PNG with Pillow, SVG without). `--dart` writes the `AppThemeConfig` seeds; `--design-md` writes the DESIGN.md block with the source URL; every candidate gets a Realtime Colors link.
- **A curated fallback library** (`assets/palettes/curated.json`): 22 palettes written for this plugin, tagged by subject and feeling, for when the sites can't be reached. `--curated <tags>`, `--tags`.

### Theme
- `AppThemeConfig` takes `secondarySeed`, `tertiarySeed` (the accent) and `neutralSeed` (the background: surfaces, text and outlines tinted toward its hue). Each role gets its own tonal palette: dark mode and the on-colors are derived, the strong color keeps its hue and the container stays soft.

### Tests and evals
- `ci/palette_selftest.py`: every URL format, the contrast math, role choice, fixes and warnings.
- `palette.py --check-curated` in CI: every curated palette passes with no adjustment.
- `ci/palettes_test.dart`: every curated palette, applied with the seeds `--dart` writes, builds a Flutter theme that passes the harness's contrast and soft-container checks in light and dark and keeps its hues.
- New eval case `palette-without-brand-color` (18 in all): a bakery with no brand colors must get three checked palettes from named sources, not a seed from memory. Not run yet.

## 1.5.0

From an outside assessment of 1.4.0 (2026-11-15). It rated the harness and the Flutter knowledge highly and named three weaknesses: a process with no small size, a design layer its own example didn't live up to, and checks that claimed more than they covered. This release takes its eight recommendations in order.

### A process sized to the request
- **The hub opens with "Size the work first"**: a question gets an answer from the relevant reference; one widget gets a build, a lint of the diff and a render of its screen; a screen gets the plan and the full check; only a first pass gets every step. Step 0 is no longer "never skip" for a wording question, and the baseline run is for screen-sized changes.
- **Motion is asked unless it is answered.** DESIGN.md › Motion, or a request that states the level and the places, is an answer and isn't asked again. A hint ("basic", "lively") still isn't. An unattended run takes soft, says so and records it as a default to confirm, instead of asking nobody.
- **The hub's description** names what the skill is for and what it is not for (Flutter work with no interface), in place of "ANY … however small".
- **A quick run**: `--dart-define=QUICK=true` renders the five shot variants per case instead of the whole matrix; `UiConfig.only` drops combinations the app never meets. `flutter-ui-verify` has a *Size the run* table.

### Template defects
- **`MoneyInputFormatter`** treated the first comma as the decimal separator: pasting `12,480.50`, the format the app displays, gave `12.48`. It now keeps the value of pasted amounts (`12,480.50`, `1.234,56`, `1,234,567`) and still takes `12,5` as 12.5.
- **`Shimmer`** kept its ticker running under reduced motion and at `MotionLevel.none`; it stops now.
- **Sign-in**: Done on the keyboard called the auth function outside `SubmitButton`'s guard, so the button and the keyboard could each start an attempt. One guard covers both.
- **`SubmitButton`** lost its name for screen readers while busy (opacity 0 drops semantics); it keeps it.
- **`deleteWithUndo`**: a failed refresh after a successful delete was reported as a failed delete; it has its own message. `PendingDeletes` is safe to use after the screen that owned it has closed.
- **`LabeledField`** (core kit): a label above its field, tied to it for screen readers. The examples used a sibling `Text`.
- `ShakeOnChange` and `PopOnChange` take their durations through `context.motion` like everything else.
- Two raw values the linter had been missing in the templates (`EmptyState`'s 88 px circle, a `Positioned(left:, right:)`).

### Checks that say what they cover
- **`lint_ui.py`** reads a call whole, so a raw value on its own line is found; skips token files by exact name, so `theme_picker_screen.dart` is linted; catches token arithmetic on a project's own classes (`Gaps.s8 + 3`, `--tokens`); `--skip` for other token files. Its docstring lists what it can't see. `ci/lint_selftest.py` tests it.
- **System bars**: under a bar is a defect; inside the safe area but closer than the gap is the house rule, and the failure line now says so (`systemBarGap: 0` reports overlap only). Cupertino bars are exempt like Material ones. An endless list is skipped, not asserted on; reverse lists are skipped; long lazy lists get 20 jumps.
- **Dark variants** set the device brightness as well as the theme. **Sheets** are checked in every direction, and the checks moved into the harness (`sheetProblems`) so they can be tested.
- **`harness.md` › What the checks do not see** lists the gaps of the system-bar check, the matrix, the sheet test and the contrast test.
- **Repo tests** (`ci/harness_test.dart`) show the harness failing on an overflow (with its source line), a stuck picker, a missing primary action and a button under the keyboard.

### The example earns its claims
- **The signature is one shared widget** (`examples/ledger.dart`: `Ledger`, `LedgerLine`, `LedgerMark`) in three named places: the home card, an invoice's details, the sign-in mark.
- **Real Arabic on the home screen** (`home_strings.dart`): the dual and the other plural forms, verbal nouns on the button, Levantine month names, and the Arabic type scale in right-to-left. The RTL screenshots were English mirrored.
- **Delete moved off the cards** into a row menu; it was the most prominent control on every card.
- **Nothing tappable does nothing**: "Mark as paid" marks the invoice; the "Open invoices" tile, "See all" and the due-soon rows open the Invoices tab; the form saves the email and the notes it validates; settings names the real number of invoices and its "Delete all" deletes them; a change on one tab reaches the others.
- The due-soon rows lost their icon badges (a tinted circle in front of rows of one kind is on `identity.md`'s list of defaults).

### Drift and taste
- `recipes.md` gave entrance values no motion level has; the numbers now live in `AppMotion` only.
- The smell test, the reviewer and `components.md` no longer recommend what `identity.md` lists as tells (KPI rows and icon badges as a "signature", badges on every row). `identity.md`'s example radius is on the token scale.
- The hub's rules mark three **house defaults** (flat cards, the 8 px on top of the safe area, the brief's form); `DESIGN.md` overrides them. Floating labels and `ElevatedButton` are described as defaults, not as "dated".
- The reviewer agent and `visual-review.md` list the same fourteen checks; CI compares them.

### Evals
- Eight new cases (17 in all): two that must load no skill (a React question, a build failure), a one-line question that must not start the intake, a stated motion level that must not be asked again, one each for the verify, motion and audit skills, and one that writes a screen into a fixture project and grades the file.
- Each `skill-fired` grader names the skill the request should load, where it used to accept any of the five. Two order-dependent regexes are order-independent.
- **Not done here:** the new cases have not been run (a run bills Claude sessions), and no with-and-without baseline is published yet. `CONTRIBUTING.md` says how to run and record one.

### Copies that can be updated
- `copy_design_system.py` records the plugin version and a hash per file (`.flutter-modern-ui.json`). `--status` tells your edits from the plugin's changes, `--diff` shows a file against the current template, `--update` takes the fixes to files you haven't edited. The harness copy records its version too.

### CI
- Flutter is pinned (3.50.0) and the fonts come from a pinned commit of google/fonts (`scripts/fetch_fonts.sh`). New steps: the lint self-test, the copy script's status and update, matching versions in the two manifests and the changelog, the two review lists in step.

## 1.4.0

A review of the whole plugin against Anthropic's own design and skill-authoring guidance. The engineering side was strong; the design side started every app from the same presets, and there was little on flows, screen types or wording.

### A look that belongs to the app
- **`references/identity.md`**: before any token, a five-line **brief** (subject, audience and setting, the one job, three feeling words, a signature element from the subject's world), proposed by Claude and corrected by the user. The seed, the typeface, the shapes and what the home screen shows come from it; a **sameness check** redoes every line of the plan that would fit any other app; a list of the defaults that mark generated Flutter apps; "take one thing away" after the screenshots.
- **directions.md**: a direction is the chassis (density, depth, roundness), not the identity; its seeds and fonts are fallbacks. The template's seed is marked as a placeholder (and is no longer indigo).
- Intake proposes the brief; DESIGN.md opens with it; the design-system skill builds the signature once as a shared widget; the reviewer agent and the visual review ask "whose app is this?" first.

### UX, screen types and words
- **`references/ux.md`**: the task per screen and its tap count, a home that answers the user's question, navigation models, defaults and remembered choices, feedback by waiting time, undo over confirm, never losing input, first run, search and filters, gestures with visible twins.
- **`references/screens.md`**: what each screen type is for, its anatomy and how it goes wrong: home, detail, sign-in, onboarding, settings, profile, search, notifications, paywall and checkout, reading and media.
- **`references/writing.md`**: buttons that say what happens, one name per thing through the flow, wording per element (titles, labels, validation, empty, error, confirmation), and Arabic conventions (verbal nouns on buttons, the six plural forms, punctuation).
- The hub's Step 3 plans the task, the screen type and the words; two new non-negotiables (a brief exists; no placeholder copy); eleven new anti-patterns (75 → 86); a new first section in the review checklist.

### Examples: one app, built from its brief
- The example app has a brief (`example_app.dart`): a studio's invoice book, ink blue-black, ledger lines as its signature.
- **Home** no longer opens with a greeting over four tiles: it answers "what is there to collect, and who do I chase?" with the total, a ledger breakdown (overdue, due this week, later) and one action, then two tiles and the chart.
- **`sign_in_screen.dart`**: one capped, scrolling column; a brand mark made from the signature; autofill, show-password, Next and Done; the failed attempt reported inside the form with the fields kept (a harness case of its own).
- **`settings_screen.dart`**: grouped cards, switches that apply at once, pick-one rows that show their value and open a pick-one sheet, each language in its own script, a destructive action apart with typed confirmation. It is the shell's third tab.

### Evals
- **`plugins/flutter-modern-ui/evals/`**: nine cases for `claude plugin eval`, one per behaviour the skills must cause, graded by regexes, short rubrics and "was a skill loaded". The first run showed a pasted-widget review answered without loading any skill, so the hub and audit descriptions now claim small requests too.

### Also
- `AppSize.columnMaxWidth` (420) for sign-in and other single-column pages.

## 1.3.0

Two rules from the maintainer, and design feedback on 1.2.

### Nothing touches the system bars
- **The rule** (hub non-negotiable 12, layout.md › System bars and safe areas): whatever sits near the top or bottom edge (a header, a search bar, a bottom bar, a button, the last list row) is inside `SafeArea` plus at least 8 px, clear of the status bar, the camera cutout or Dynamic Island, the navigation bar and the home indicator. App bars and navigation bars pad themselves.
- **`SaveBar`** (core kit): a form's primary action pinned under the fields, inside the safe area plus 12 px. **`context.listEndPadding(fab:)`**: the bottom inset + 24, + 72 under a FAB. The examples use both; the detail pane's list now ends with the inset too.
- **The harness renders phones and tablets under their bars** (`UiConfig.systemBars`: Android's 32 px status bar and 48 px navigation bar, iOS's Dynamic Island and home indicator), as `MediaQuery` padding like a device, and draws them in the screenshots. The keyboard now covers the navigation bar, as on a device.
- **System-bar check** in the layout and sheet tests (`systemBarProblems`): text, icons, fields and tap targets under a bar or within `systemBarGap` (8 px) of it, for what stays put, scroll views at their start, and every list scrolled to its end (whose last row must also clear the FAB). One line per problem across variants, with the source line; a repo test proves it catches each case and passes the safe versions.
- Source lines now skip widgets from packages too, so they point at the project's code in `material_ui` apps.

### Ask how much motion, and where
- **intake.md › Motion** is asked before the first screen, even when the spec or the customer hinted at it (the hint becomes the recommendation): the level, **none** (Material's own motion), **soft** or **expressive**, each with a small example, then the places, each with its soft and expressive version.
- **`AppThemeConfig.motion`** (`MotionLevel`) → the `AppMotion` theme extension: `context.motion(d)` scales durations (0 at none, × 1.2 at expressive), and `Entrance`, `AnimatedItems`, `StateSwitcher`, `PressScale`, `PopOnChange`, `ShakeOnChange` and `SubmitButton` take their rise, stagger, press, pop and shake from the level. Default: soft (a 4 % rise, all at once).
- DESIGN.md records the level and the places; the flutter-motion skill asks first and documents the levels (principles.md › Motion levels); the review checklist and an anti-pattern check that it was asked.

### From that app's design contract
- **Big fonts**: the layout matrix adds text scale 1.6 (and a 1.6 screenshot). `context.isNarrow` (width ÷ text scale < 340) stacks rows that pair two things; the examples put the amount under the name; `KpiGrid` goes one tile per row; `context.iconSize` grows inline icons with the text up to 1.4×.
- **`MetaItem`** (core kit): a small icon and muted detail text, for card rows; layout.md › List screens describes the list-screen and record-card anatomy.
- **Errors inside sheets**: `SheetScaffold(error:)` shows a failed action above the footer; a SnackBar would open behind the modal sheet. Several entries in one sheet ("Add another" copies the last one).
- **Not `SegmentedButton`** for choices in forms and sheets: it can't wrap at big font sizes; chips can.
- Optional fields say "(optional)" in the label (example form); totals in several currencies show one line per currency; live data needs no pull to refresh (sync status instead); hero summary and category shares in data-display.md.

### Also
- Anti-patterns 68 → 75; review checklist, reviewer agent, visual review and the UI_PASS template cover the bars, 1.6 and the motion level.

## 1.2.0

From design feedback on 1.1.0 (problems 1–11).

### Intake asks about the look (1)
- **intake.md**: a new question, *the look*: cards, plain rows or rich, with sketches for question tools that show previews. It's asked even when the spec says "basic" or "simple" (those usually mean uncluttered, not unstyled). With nobody to answer, the first list screen is built with cards and its screenshot shown before the rest. DESIGN.md records it (*Look*), and the reviewer checks screens against it.

### Soft containers that stay soft (2)
- **Fixed**: `ToneColors.fromSeed` took the container from `fidelity`, which puts it at the seed's own tone, so a saturated seed turned "soft" tiles into solid red and amber blocks. It now takes the strong color from `fidelity` and the container from `tonalSpot`.
- **Fixed**: `AppTheme` with `variant: fidelity` or `content` had the same problem in the scheme's primary and tertiary containers; they now come from `tonalSpot` too.
- **contrast_test.dart**: containers must read as tints (light: tone ≥ 80 and chroma ≤ 50; dark: tone ≤ 40), a check contrast alone can't make. `UiConfig.softContainers` lists extra tones; the design-system test runs saturated seeds through `ToneColors`.

### Pick-one sheets (3)
- **`showAppPicker`**: one tap chooses and closes, the current option shows a check; `SheetScaffold.primaryAction` is optional, so read-only and pick-one sheets have no footer. Example: the records screen's sort sheet.
- **sheets_test.dart**: `SheetCase.picker(...)` checks that options are on screen with real tap targets and that a tap closes the sheet, instead of requiring a primary button. The sheets' screenshots moved into the sheet test, so `visual_test.dart` no longer needs `sheetCases` and an empty list works.

### Shell and edit-mode cases (4)
- **The shell case**: `UiCase(act:)` drives a case after it renders. The example shell mounts every tab in an `IndexedStack`, switches tab and pushes a route; with two default FAB hero tags that push throws, which a page rendered on its own never shows. components.md: FABs on shell tabs need `heroTag: null`. A repo test proves both sides.
- **Every form twice**: `record_form_screen.dart` creates and edits (`initial`), and the harness cases cover both. forms.md › Create and edit: fill controllers where they're created or in a listener, never in `build`; a new anti-pattern says the same.

### Core and extras kits (5)
- **`scripts/copy_design_system.py`**: `--kit core` (default: tokens, theme, palette, cards, pills, empty states, skeletons, sheets, chips, messages, `Ltr`) or `--kit extras` (motion, `AdaptiveShell`, `KpiTile`), one line each. It keeps files you changed and writes the barrel for what's there.
- **`flutter-ui-verify/scripts/copy_harness.py`**: copies the harness (and `--pdf`, `--design-system-test`) without overwriting your cases.

### Flutter 3.50 and `material_ui` (6)
- Both copy scripts rewrite `package:flutter/material.dart` / `cupertino.dart` to `material_ui` / `cupertino_ui` when the project's pubspec lists `material_ui`. Step 0 checks which library the project uses; theming.md covers the `GlobalMaterialLocalizations` clash with `flutter_localizations`.
- CI builds and tests the sandbox both ways (a `material_ui` app and a `package:flutter/material.dart` app).

### RTL traps (7)
- **rtl-arabic.md is required reading** whenever the app has a right-to-left language.
- **Glyph coverage**: `flutter-ui-verify/scripts/check_glyphs.py` lists every character in the app's strings (Dart literals, ARB files, `--chars` for what `intl` adds) that the fonts lack. Tajawal, for one, has no `₪`, `٫`, `٬` or `✓`.
- **Amount fields**: an LTR field's start is the left, so in RTL the digits sit away from the prefix or glue to the suffix; align them with `TextAlign.end` in RTL (example form, forms.md › Money).
- **Mirrored icons**: `Icons.chevron_left` / `chevron_right` already flip in RTL; swapping them by direction flips twice.

### Lint the diff (8)
- **`scripts/lint_ui.py`**: raw colors, font sizes, spacing, sizes, radii, opacities and durations, token arithmetic (`AppSpace.xs + 2`) and left/right APIs, on the whole of `lib/` or only the lines a branch changed (`--diff`). Step 7 runs it before the anti-pattern scan; CI runs it on the templates, which gained the tokens they were missing (`AppDurations.shake`, `.shimmer`, `AppSize.emptyStateWidth`, …).

### Faking dependencies (9)
- **harness.md › Faking dependencies**: register fakes in the service locator in `UiConfig.setUp` (runs once before the first case), stub platform plugins that call native code on start (connectivity, auth), and treat a screen that can't render in a test as one that needs something injected.

### Contact sheets (10)
- The screenshot run writes a contact sheet per case (`visual_test.dart`) and per sheet (`sheets_test.dart`) to `screenshots/contact_sheets/`: every variant side by side, labeled. Review starts there.

### Reviewer by default (11)
- The `flutter-ui-reviewer` agent is the default whenever a pass touches more than three screens, or it's the first pass on an app, and it checks the agreed look.

### Also
- Anti-patterns 58 → 68; the review checklist covers the look, pickers, the shell, edit mode and glyphs.
- `scripts/sandbox.sh --material-ui | --framework-material` builds the sandbox through the same copy scripts users run.

## 1.1.0

From design feedback on 1.0.0 (entries 1–3).

### Printed documents (entry 1)
- **flutter-ui-verify › Printed documents**: sample PDFs (typical, every optional field empty, the longest content the forms allow) → block checks → rasterize → open every page. New `references/printed-documents.md`.
- **PDF harness** (`assets/pdf/` → `test/pdf/`): documents mark the blocks that must survive on paper; a case fails when one isn't painted (a fixed `pw.Page` drops what doesn't fit without an error), sticks out of the margins, overlaps a block it must not cover (a stamp on the date line), or the document runs past its page count.
- **`scripts/rasterize_pdf.py`**: PNG per page with PyMuPDF or poppler's `pdftoppm` (`Printing.raster` needs pdfium, which `flutter test` doesn't load); `--text` flags `null`, `NaN` and other leftovers of empty fields.
- **rtl-arabic.md › Printing**: line budgets or `pw.MultiPage`, the longest sample case, overlays anchored to their block instead of a page fraction, `maxLines` truncating without an ellipsis, empty fields leaving out the whole row.
- **Example**: `invoice_pdf.dart`, an A5 invoice in Arabic (RTL) and English with LTR runs, a payment-row budget, a stamp anchored in its signature slot and the `mark` seam; the form's notes field shares its length cap.

### Chips (entry 2)
- `AppChoiceChips(label:)`: an inline label as the first child of the same `Wrap`, centered on the chips.
- components.md: a few single-choice options (up to 4) wrap and never scroll, so every option stays visible on a phone; scrolling is for long filter lists. Example: payment terms in the long form.

### List-detail (entry 3)
- layout.md: the detail pane always has a visible ✕ with a tooltip, a second click on the open row deselects it, Esc is a shortcut only.
- `records_screen.dart` shows all three, plus `initialSelectedId` for deep links and the pane's screenshot.

### Fixed
- Screenshots of screens that load data showed the loading or empty state: `pumpUi` moved the clock in one jump, so a fake load finished inside it and the entrances and cross-fades it started were still at their first frame. It now advances in 100 ms frames.

### Also
- Anti-patterns 53 → 58; review checklist covers chips, list-detail and printed documents; the reviewer agent reviews printed pages.
- Feedback template: a status per entry (open / sent → #N / fixed in x.y.z) and how to send entries upstream.
- CI: repo tests for the examples' promised behaviour and for the PDF checks themselves, sample PDFs rendered and rasterized, pages uploaded with the screenshots; every check runs even after an earlier one fails.

## 1.0.0

A rebuild driven by design feedback from using 0.1.0 on an Arabic RTL app, and by one goal: a skill set that understands design systems, studies the existing app, keeps screens consistent and verifies its own work visually.

### New skills and agent
- **flutter-design-system**: create, extend, repair or document a design system; study existing code (`scripts/ui_inventory.sh`) or reference screenshots; `DESIGN.md` contract and `UI_PASS.md` progress templates.
- **flutter-motion**: principles, 17 recipes, testing (filmstrips), packages; shared motion widgets.
- **flutter-ui-verify**: `flutter_test` harness with a layout matrix (size × text scale × theme × platform × direction) that reports the source line, sheet / keyboard / tap-target checks, contrast test, screenshots, visual review rubric, golden pitfalls.
- **flutter-ui-reviewer** agent: independent visual QA against DESIGN.md.

### flutter-modern-ui
- Step 0 "read first": find, read and extend the project's design system; map names; follow existing flows; respect deliberate deviations; audit and baseline before changing.
- Intake questions asked once: platforms, RTL, emoji, motion, direction.
- New references: discovery, intake, adaptive (desktop: hover, cursors, focus, shortcuts, scrollbars, tooltips, window), forms (long forms, money, dates, warnings, autocomplete in RTL, editable rows, settings), sheets-dialogs (shared anatomy, footer order, filter sheets, keyboard), data-display (KPI tiles, tables, charts incl. RTL and nice ticks), messages (one component, `persist: false`, copy rules, delete with Undo), rtl-arabic (layout, numbers, Arabic typography, plurals, PDF), accessibility.
- Directions now state every token (radius roles, control height, density, inputs, surfaces) and gain an eye-comfort modifier.
- Breakpoints extended to the five M3 window classes; list-detail; content caps.
- Nested-shape rules (concentric radius with a limit, card types, no card in card).
- Anti-patterns grew from 27 to 53; checklist covers platforms, RTL, messages, motion and verification.

### Templates
- `AppThemeConfig` (seed, variant, font, Arabic script, eye-comfort surfaces, filled/outlined inputs, densities, scheme override); `AppDensity` ThemeExtension by platform.
- Fixed contradictions: theme density vs Enterprise Dense, pure-white cards vs "no pure white", optional status icons, Arabic letter-spacing, desktop hover/cursor/focus.
- New widgets: `AppMessenger` (+ `PendingDeletes`, Undo), `showAppSheet` / `SheetScaffold` / `SheetSection`, `AppChoiceChips`, `AdaptiveShell`, `ContentWidth`, `KpiTile` / `KpiGrid`, `EmojiBadge`, `Ltr` / `ltr()`, `ShowAfter`, `PressScale` (replaces `Pressable`).
- Motion widgets: `Entrance`, `AnimatedItems`, `StateSwitcher`, `SubmitButton`, `AnimatedNumber`, `AppProgressBar`, `ShakeOnChange`, `PopOnChange`, `MiniBarChart`, `NiceScale`.
- Examples: app shell, dashboard, records list-detail with filter sheet and Undo, long form.
- Requires Flutter 3.41+ (verified by CI on stable 3.47).

### Repo
- CI: manifest and skill checks, sandbox app built from the templates, `flutter analyze`, UI tests, screenshots as an artifact.
- CONTRIBUTING and a feedback template.

## 0.1.0

- `flutter-modern-ui` and `flutter-ui-audit` skills, design-system templates, dashboard example.
