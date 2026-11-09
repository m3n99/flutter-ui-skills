# Changelog

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
