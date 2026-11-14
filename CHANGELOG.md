# Changelog

## 1.3.0

Two rules from the maintainer, and the design contract of an Arabic, Android-only app built with 1.2.

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

From the feedback log of 1.1.0 on an Arabic, Android-only app built on Flutter 3.50 (problems 1–11).

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

From the feedback log of 1.0.0 on the same Arabic, Windows-first + Android app (entries 1–3).

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

A rebuild driven by feedback from using 0.1.0 on a real Arabic, Windows-first + Android app, and by one goal: a skill set that understands design systems, studies the existing app, keeps screens consistent and verifies its own work visually.

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
