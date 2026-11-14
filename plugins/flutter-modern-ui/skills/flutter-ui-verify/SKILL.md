---
name: flutter-ui-verify
description: Verify Flutter UI by actually rendering it — a layout matrix (phone/tablet/desktop × text scale 1.0/1.3 × light/dark × touch/desktop × LTR/RTL) that reports overflows with the source line, sheet checks (keyboard, tap targets), a contrast test, screenshots Claude opens and reviews like a designer, and printed documents (sample PDFs checked for dropped or overlapping blocks, rasterized and reviewed). Use after building or changing UI or a PDF layout, before saying UI work is done, or when asked to test, check, screenshot or QA Flutter screens or printouts.
---

# Flutter UI Verify

Code that compiles isn't UI that works. This skill closes the loop: render every screen in the conditions users actually have, catch what breaks, then **look at the pixels** and review them.

The harness lives in `assets/harness/` and runs on plain `flutter_test`: no device, no extra packages.

| File | Goes to | Checks |
|---|---|---|
| `ui_harness.dart` | `test/ui/` | shared machinery (pumping, error capture, fonts, keyboard, shots, contrast math) |
| `ui_cases.dart` | `test/ui/` | **the only file to edit**: theme, matrix, screens and sheets to render |
| `layout_smoke_test.dart` | `test/ui/` | every case × matrix: no overflow / layout / build errors, with the source line |
| `sheets_test.dart` | `test/ui/` | every sheet: ≥ 48 px labeled tap targets on touch; the primary action on screen and above a 300 px keyboard; pick-one sheets: options on screen, a tap closes the sheet. With `VISUAL`, the sheets' screenshots |
| `contrast_test.dart` | `test/ui/` | text, icons, borders and status tones ≥ WCAG AA in light and dark; containers soft enough to read as tints |
| `visual_test.dart` | `test/ui/` | screenshots and one contact sheet per case to `test/ui/screenshots/` (only with `VISUAL`) |
| `design_system_test.dart` | `test/ui/` | behaviour of the shared widgets and tones (only if the project uses them) |

Copy them with `python3 <this skill>/scripts/copy_harness.py`, run from the project root (`--pdf` adds the PDF harness, `--design-system-test` the shared-widget tests). It never overwrites your `ui_cases.dart`, and in `material_ui` projects (Flutter 3.50+) it rewrites the Material imports.

## Workflow

1. **Set up once.** Copy the harness into `test/ui/`. Edit `ui_cases.dart`:
   - imports → the project's theme and screens;
   - `uiConfig.theme` → the app's real theme function for a brightness and platform;
   - `platforms`, `directions` (add RTL if the app supports it), localization delegates and `localeFor`;
   - `uiConfig.setUp` → fakes in the service locator and stubs for plugins that call native code on start (`references/harness.md` › Faking dependencies). A screen that can't render in a test is telling you something should be injected;
   - `uiCases` → every screen in each state that matters (content, loading, empty, error), with **fake data**: no network, no real database, no pending timers. Plus:
     - **every form twice, create and edit**: some crashes only happen when the fields start filled;
     - **the app shell** with every tab mounted, switching tabs and pushing a route in `act`: tabs of an IndexedStack shell share one route, so clashing hero tags only show there;
   - `sheetCases` → every sheet and dialog opener; pick-one sheets (a tap on an option is the action) as `SheetCase.picker`. No sheets: leave the list empty.

   Bundle the app's fonts (the harness loads `FontManifest.json` and falls back to the SDK's Roboto) so tests measure and draw real glyphs.
2. **Static check**: `flutter analyze`. Changed files clean.
3. **Layout matrix**: `flutter test test/ui/layout_smoke_test.dart`. Each failure reads `[360_dark_android_rtl_x1.3] A RenderFlex overflowed by 13 pixels on the right. ← lib/features/bills/bill_tile.dart:42`. Fix by cause (`references/harness.md` › Fix table), then re-run.
4. **Sheets**: `flutter test test/ui/sheets_test.dart`.
5. **Contrast**: `flutter test test/ui/contrast_test.dart`. Passing contrast isn't the same as looking right: the soft-container check flags containers as strong as their seed.
6. **Screenshots**: `flutter test test/ui/visual_test.dart test/ui/sheets_test.dart --update-goldens --dart-define=VISUAL=true`.
7. **Look.** Open the contact sheets first (`test/ui/screenshots/contact_sheets/<case>.png`: every shot variant of a case side by side), then single shots for detail, with the Read tool, and review them with `references/visual-review.md`. Write findings as *screenshot · where · issue · fix*. Never report visual verification without having opened the images.
8. **Fix and re-shoot.** Compare before and after for each finding; make sure nothing else moved.
9. **Independent review** whenever a pass touches more than three screens, or it's the first pass on an app: give the `flutter-ui-reviewer` agent the screenshot paths (or the contact sheets) and DESIGN.md. It hasn't seen the code being written, so it doesn't grade its own work, and it checks the screens against the agreed look.
10. **Report** briefly: what ran (cases × variants, number of screenshots viewed), what was fixed, what remains. Send the key screenshots to the user when the environment can deliver files.

For motion, render filmstrips (several frames of one animation): `../flutter-motion/references/testing.md`.

Glyphs: `python3 scripts/check_glyphs.py --font <each weight's .ttf> --chars "<symbols intl adds at run time>" lib` lists characters the app's fonts lack (a currency sign, `٫`, `✓`), which otherwise show only as boxes or odd fallbacks in screenshots.

## Printed documents (PDF)

A fixed `pw.Page` drops what doesn't fit without an error (the test stays green), and a stamp placed at a fraction of the page lands on text once the content above it grows. Printed documents get the same loop as screens. Details: `references/printed-documents.md`.

1. **Make the document testable**: a plain-Dart builder that takes data, print theme, labels and a `mark` callback (production passes nothing); mark the blocks that must survive on paper (signatures, totals, stamp, date line).
2. **Sample cases**: copy `assets/pdf/` into `test/pdf/` (`copy_harness.py --pdf`) and edit `pdf_cases.dart`: the typical document, one with every optional field empty, and the longest content the forms allow, in each printed direction. Each case says what must be painted, what must not overlap, and the page count.
3. **Render and check**: `flutter test test/pdf` writes `test/pdf/out/<case>.pdf` and fails when a marked block is missing, outside the margins or overlapping.
4. **Rasterize**: `python3 scripts/rasterize_pdf.py test/pdf/out --text` (this skill's folder; PyMuPDF or poppler's `pdftoppm`, since `Printing.raster` needs pdfium, which `flutter test` doesn't load). `--text` flags `null` and similar leftovers.
5. **Look**: open every PNG, bottom of the page first (signatures, footer), then overlays, the longest case, empty fields and RTL runs. Fix, re-render, compare.

## Other ways to see the app

- **Web build + browser**: if the app runs on web, `flutter build web` and screenshot it with Playwright/Chromium at phone (390 × 844) and desktop (1366 × 768) viewports; useful for interaction flows.
- **Device or emulator**: `flutter screenshot`, `adb exec-out screencap -p > shot.png`, `xcrun simctl io booted screenshot shot.png`, or `integration_test` with `binding.takeScreenshot`.
- **No Flutter SDK in the environment**: say so plainly, do the static review (code against `../flutter-modern-ui/references/review-checklist.md`), and give the user the exact commands to run, asking for the failure output and screenshots back.

## Rules

- Fake data that looks real: realistic names, long names, big amounts, empty lists, error states. "Item 1" hides layout problems.
- Deterministic: fixed "today", no network images (assets or placeholders), no timers left pending.
- Screenshots are for looking, not pixel-diffing; don't commit them as golden baselines unless the team wants golden tests (font rendering differs between OSes).
- Emoji show as boxes in `flutter_test` (no emoji font); platform views (maps, web views) render empty. Judge those on a device.
- A failing layout test is a bug in the UI, not in the test: fix the layout, don't loosen the matrix. Trim the matrix only to platforms or directions the app doesn't ship.
