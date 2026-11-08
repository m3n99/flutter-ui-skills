# Changelog

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
