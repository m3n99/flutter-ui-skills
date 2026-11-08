---
name: flutter-ui-verify
description: Verify Flutter UI by actually rendering it — a layout matrix (phone/tablet/desktop × text scale 1.0/1.3 × light/dark × touch/desktop × LTR/RTL) that reports overflows with the source line, sheet checks (keyboard, tap targets), a contrast test, and screenshots Claude opens and reviews like a designer. Use after building or changing UI, before saying UI work is done, or when asked to test, check, screenshot or QA Flutter screens.
---

# Flutter UI Verify

Code that compiles isn't UI that works. This skill closes the loop: render every screen in the conditions users actually have, catch what breaks, then **look at the pixels** and review them.

The harness lives in `assets/harness/` and runs on plain `flutter_test`: no device, no extra packages.

| File | Goes to | Checks |
|---|---|---|
| `ui_harness.dart` | `test/ui/` | shared machinery (pumping, error capture, fonts, keyboard, shots, contrast math) |
| `ui_cases.dart` | `test/ui/` | **the only file to edit**: theme, matrix, screens and sheets to render |
| `layout_smoke_test.dart` | `test/ui/` | every case × matrix: no overflow / layout / build errors, with the source line |
| `sheets_test.dart` | `test/ui/` | every sheet: primary action on screen, ≥ 48 px labeled tap targets on touch, still visible above a 300 px keyboard |
| `contrast_test.dart` | `test/ui/` | text, icons, borders and status tones ≥ WCAG AA in light and dark |
| `visual_test.dart` | `test/ui/` | screenshots to `test/ui/screenshots/` (only with `VISUAL`) |
| `design_system_test.dart` | `test/ui/` | behaviour of the shared widgets (only if the project uses them) |

## Workflow

1. **Set up once.** Copy the harness into `test/ui/`. Edit `ui_cases.dart`:
   - imports → the project's theme and screens;
   - `uiConfig.theme` → the app's real theme function for a brightness and platform;
   - `platforms`, `directions` (add RTL if the app supports it), localization delegates and `localeFor`;
   - `uiCases` → every screen in each state that matters (content, loading, empty, error), with **fake data**: no network, no real database, no pending timers. See `references/harness.md` for BLoC / service-locator / provider setups.
   - `sheetCases` → every sheet and dialog opener.

   Bundle the app's fonts (the harness loads `FontManifest.json` and falls back to the SDK's Roboto) so tests measure and draw real glyphs.
2. **Static check**: `flutter analyze`. Changed files clean.
3. **Layout matrix**: `flutter test test/ui/layout_smoke_test.dart`. Each failure reads `[360_dark_android_rtl_x1.3] A RenderFlex overflowed by 13 pixels on the right. ← lib/features/bills/bill_tile.dart:42`. Fix by cause (`references/harness.md` › Fix table), then re-run.
4. **Sheets**: `flutter test test/ui/sheets_test.dart`.
5. **Contrast**: `flutter test test/ui/contrast_test.dart`.
6. **Screenshots**: `flutter test test/ui/visual_test.dart --update-goldens --dart-define=VISUAL=true`.
7. **Look.** Open every PNG in `test/ui/screenshots/` with the Read tool and review it with `references/visual-review.md`. Write findings as *screenshot · where · issue · fix*. Never report visual verification without having opened the images.
8. **Fix and re-shoot.** Compare before and after for each finding; make sure nothing else moved.
9. **Independent review** for larger passes: give the `flutter-ui-reviewer` agent the screenshot paths and DESIGN.md. It hasn't seen the code being written, so it doesn't grade its own work.
10. **Report** briefly: what ran (cases × variants, number of screenshots viewed), what was fixed, what remains. Send the key screenshots to the user when the environment can deliver files.

For motion, render filmstrips (several frames of one animation): `../flutter-motion/references/testing.md`.

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
