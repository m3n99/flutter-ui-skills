---
name: flutter-design-system
description: Create, extend, repair or document a Flutter app's design system — tokens, color scheme, typography, density, shared components and a DESIGN.md contract that keeps every screen consistent. Use when setting up theming for a new app, when an existing app's UI is inconsistent, when the user shares screenshots or names apps whose look they want, or before building screens in a project with no design system.
---

# Flutter Design System

A design system is what makes the tenth screen look like the first. This skill produces three things:

1. **Tokens and theme in the code**: spacing, radius, type, color roles, density, motion, component themes (the project's own files, or `../flutter-modern-ui/assets/design_system/`).
2. **Shared components**: card, status pill, sheet scaffold, message component, skeleton, empty state, animated list… only what the app needs.
3. **`DESIGN.md`** at the project root: the contract every later session reads first (template: `assets/templates/DESIGN.md`).

## Pick the mode

| Situation | Mode |
|---|---|
| The project has a theme / tokens / shared widgets | **A. Extend** |
| No system yet | **B. Create** |
| The user shared screenshots or named apps they like | **C. From references**, then A or B |
| A system exists but screens ignore it (magic numbers, five card styles) | **D. Repair** |

### A. Extend an existing system

1. Run the discovery protocol (`../flutter-modern-ui/references/discovery.md`) and the inventory script: `bash <skill-dir>/scripts/ui_inventory.sh lib` (pass several dirs for monorepos).
2. Map the project's names to the concepts here; keep the names.
3. Fill gaps **in the existing files**: missing tokens (elevation, sizes, concentric radius helper, density), missing component themes, semantic/domain tones, a single message component, the sheet anatomy.
4. Resolve contradictions inside the theme (a dense app with 52 px buttons, white cards in an eye-comfort palette), not per screen.
5. Run the contrast test (flutter-ui-verify › `contrast_test.dart`).
6. Write or update DESIGN.md from what now exists, including deliberate deviations.

### B. Create a new system

1. Intake (`../flutter-modern-ui/references/intake.md`): platforms, RTL, the look (cards, rows or rich), brand color, emoji, how much motion (none, soft, expressive) and where.
2. Choose a direction (`../flutter-modern-ui/references/directions.md`); state it in one line.
3. Copy the templates with `python3 ../flutter-modern-ui/scripts/copy_design_system.py --to <folder>` (default `lib/core/design_system/`): the **core kit** first; `--kit extras` adds motion, the adaptive shell and KPI tiles when the app needs them. It writes the barrel and, in `material_ui` projects, the right imports. Then:
   - set `AppTheme.config` (seed, variant, font, script, surfaces, input style, motion level);
   - retune every `DIRECTION` line in `tokens.dart` and `app_density.dart`;
   - add domain tones to `AppPalette` (e.g. `overdue`, `paid`) and one status → label/icon/tone mapping per domain enum;
   - bundle fonts in `pubspec.yaml`;
   - wire `MaterialApp(theme:, darkTheme:, scaffoldMessengerKey: AppMessenger.key)`.
4. Need another template later? Run the script again with that kit; it keeps the files you changed. Don't rebuild a template widget by hand: hand copies drift from the originals.
5. Contrast test, then build one representative screen and screenshot it (flutter-ui-verify) before rolling out.
6. Write DESIGN.md from the template.

### C. From references (screenshots, apps the user likes)

Follow `references/study-reference-apps.md`: calibrate, extract palette / type / shape / density / elevation / iconography / motion cues per reference, find what they share, map it to a direction and token values, record what was taken and what was deliberately left out. Take patterns, never identity (logos, illustrations, brand colors, trademarked names). Then continue with A or B.

### D. Repair an inconsistent system

Follow `references/study-existing-app.md`: inventory every value actually used, measure drift (distinct radii, paddings, font sizes, raw colors), propose a "found → token" mapping, get approval when the visual change is noticeable, extract repeated structures into shared widgets, migrate screen by screen with before/after screenshots, and record it all in `UI_PASS.md`.

## DESIGN.md: the contract

Write it so a reviewer can check every rule against a screen or the source. Sections (template has them all):

- Direction and decisions (with the intake answers and deliberate deviations)
- Tokens: spacing, radius, elevation (with the raised-tile exception), type roles, color roles, sizes, density
- Nested shapes and card types (padding / radius per card type)
- Sheets and dialogs (anatomy, footer order per sheet)
- Lists, chips, status mapping, KPI tiles, emoji per meaning (if any)
- Motion table (what animates, duration, curve)
- Messages table (event → message), Undo rules
- Layout: breakpoints, navigation, content caps, RTL rules
- How to check a change (analyze, tests, screenshots)

Keep it current: every later UI change that adds a token, pattern or decision updates DESIGN.md in the same change.

## Progress log for big passes

For multi-screen work (a redesign, an audit fix-up), keep `UI_PASS.md` (template `assets/templates/UI_PASS.md`): audit, checklist, done notes, decisions, open decisions. Tick items as they land so the next session resumes from the first unticked item.

## Rules

- One system. Never a second theme folder next to the project's.
- Names from the project; values from the direction; decisions in DESIGN.md.
- Every color pair passes the contrast test in light and dark.
- Components are extracted only when repeated (twice or more) or when the pattern is error-prone (sheets, undo, animated lists, messages).
- Presentation only: no changes to state management, routing or data flow.
