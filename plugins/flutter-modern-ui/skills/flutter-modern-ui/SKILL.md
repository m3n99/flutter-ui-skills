---
name: flutter-modern-ui
description: Build or restyle Flutter UI that looks modern and stays consistent with the project's design system — screens, widgets, themes, adaptive phone/tablet/desktop layouts, sheets, forms, lists, dashboards, RTL, printed PDF documents. Use for any Flutter UI work, or when the user says the UI looks plain, dated, generic or AI-made. Studies the existing app first, asks about platforms, RTL, emoji and motion, and verifies its work with screenshots.
---

# Flutter Modern UI

Generic Flutter output looks dated for predictable reasons: untuned Material defaults, hard-coded sizes and colors, flat hierarchy, shadow-heavy cards, no loading/empty/error states, touch metrics on desktop, broken RTL. It also drifts: every screen invents its own spacing, sheet layout and message style.

This skill works like a UI engineer joining a team: **study the app → agree on the system → build on it → animate with purpose → look at the result → record the decisions.**

## Step 0 — Read first (never skip)

Do this before any direction, token file or screen. Details: `references/discovery.md`.

1. **Find and read the existing design system**: search for `ThemeData(`, `ThemeExtension`, `ColorScheme`, `TextTheme`, folders like `theme`, `design_system`, `ui_kit`, `core/ui`, `shared/`, and UI packages under `sdk/` or `packages/`. Read tokens, palette, typography, theme, context extensions and shared widgets end to end.
2. **Read the contract**: `DESIGN.md` (or `docs/design-system.md`) at the project root, and any UI progress log (`UI_PASS.md`). They hold decisions that override this skill's defaults.
3. **Map, don't replace**: write down the project's names (its spacing class, color access, card widget, message component) and use them. A missing token goes **into the existing file**. Never create a second system or a new `theme/` folder.
4. **Follow the existing flows**: how screens get data (bloc → state → builder, service locator, providers), how messages are shown, how navigation and platform differences work. New UI reuses those paths.
5. **Respect deliberate deviations** (a custom palette instead of `fromSeed`, desktop-sized controls, outlined inputs) and note them.
6. **Baseline**: run `flutter analyze` and `flutter test` before changing UI so new warnings and failures are clearly yours.

## Step 1 — Intake: ask once, early

Ask the questions in `references/intake.md` in one short round (use the question tool when available): **platforms**, **RTL languages**, **emoji**, **where things should animate**, and **direction / brand** if no system exists yet. Skip what DESIGN.md already answers. When nobody is there to answer, take the stated defaults and say which you took.

## Step 2 — The design system

- **Project has one** → extend it in place (Step 0). Add only what's missing.
- **Project has none** → set one up with the `flutter-design-system` skill: pick a direction (`references/directions.md`), copy `assets/design_system/` into the project's conventional location (default `lib/core/design_system/`), set `AppTheme.config`, retune the `DIRECTION` lines, and write `DESIGN.md`.
- **User shared reference apps or screenshots** → derive the direction from them with the `flutter-design-system` skill.

Templates require Flutter ≥ 3.41 (`SnackBar.persist`, `AppBarThemeData`, `InputDecorationThemeData`, `SizeTransition.alignment`). On older SDKs: drop `persist`, use `AppBarTheme` / `InputDecorationTheme` and `SizeTransition.axisAlignment`; `CupertinoPageTransitionsBuilder` comes from `package:flutter/cupertino.dart`.

## Step 3 — Plan the screen

Before writing widgets, decide in a few lines (in `UI_PASS.md` for multi-screen work):

- the **one primary thing** and **one primary action**;
- the layout per window size (compact / medium / expanded+) — `references/layout.md`, `references/adaptive.md`;
- every state: loading, empty, error, content, refreshing — `references/states.md`;
- the motion moments the user asked for — `flutter-motion` skill.

## Step 4 — Build

Read only the references the screen needs:

| Need | Read |
|---|---|
| Spacing, radius, type, color roles, sizes | `references/tokens.md` |
| Theme, color scheme, eye comfort, fonts | `references/theming.md` |
| Screen anatomy, hierarchy, nested shapes | `references/layout.md` |
| Desktop / tablet / platform differences | `references/adaptive.md` |
| Cards, lists, buttons, chips, status, nav, emoji | `references/components.md` |
| Forms, money, dates, autocomplete, settings | `references/forms.md` |
| Bottom sheets, filter sheets, dialogs | `references/sheets-dialogs.md` |
| KPI tiles, tables, charts | `references/data-display.md` |
| Loading / empty / error states | `references/states.md` |
| Messages, errors, delete with Undo | `references/messages.md` |
| Arabic / Hebrew / Persian, numbers | `references/rtl-arabic.md` |
| Printed documents (PDF): fonts, LTR runs, line budgets, stamps | `references/rtl-arabic.md` › Printing, `assets/examples/invoice_pdf.dart` |
| Contrast, semantics, text scale, focus | `references/accessibility.md` |

Reference compositions to imitate: `assets/examples/` (dashboard, records list-detail with filter sheet and undo, long form, app shell, printed invoice).

## Step 5 — Motion

Apply the `flutter-motion` skill for the surfaces the user chose. Reuse the shared pieces (`Entrance`, `AnimatedItems`, `StateSwitcher`, `SubmitButton`, `AnimatedNumber`, `AppProgressBar`); every duration comes from tokens and goes through `context.motion(...)`.

## Step 6 — Verify by looking

Apply the `flutter-ui-verify` skill: `flutter analyze`, the layout matrix (360 / 1000 / 1366 px × text scale 1.0 / 1.3 × light / dark × platforms × directions), the sheet test (keyboard, tap targets), contrast, then **render screenshots and look at them** against `references/review-checklist.md`. Fix and re-shoot. Printed documents get the same loop: sample PDFs (typical, empty optional fields, longest content), block checks, then rasterize and open every page. For larger passes, hand the screenshots to the `flutter-ui-reviewer` agent for an independent review.

## Step 7 — Record and report

- Scan the diff against `references/anti-patterns.md`.
- Update `DESIGN.md` with any new token, pattern or decision, and tick `UI_PASS.md`.
- Report in a few lines: direction, what changed, which screenshots were reviewed, anything left open.

## Non-negotiables

1. No raw colors (`Colors.blue`, `Color(0x…)`) or font sizes in widgets: scheme roles, palette tones, text theme roles.
2. Spacing, radius, durations, sizes come from tokens. No 2, 3, 6, 10, 14, 18 px.
3. One radius family per screen. Nested rounded shapes are concentric while the gap is smaller than the outer radius (`AppRadius.concentric`); no card inside a card; no double borders.
4. Cards are flat: tonal fill + hairline `outlineVariant` border. Shadows only for floating elements and raised dashboard tiles.
5. One primary action per screen and per sheet.
6. Status is never shown by color alone: every status has an icon and a label; selected chips show a check.
7. Every data screen has loading (skeleton), empty, error and refresh states.
8. One message component; messages name the thing; errors say what failed and what to do; destructive actions confirm or offer Undo.
9. Touch targets ≥ 48 px on touch platforms; desktop gets hover, cursor, focus, visible scrollbars and tooltips.
10. Directional APIs only (`EdgeInsetsDirectional`, `AlignmentDirectional`, start/end). Numbers, dates and phones stay LTR inside RTL. Arabic gets zero letter-spacing.
11. Text never overflows at 360 px and text scale 1.3. Dynamic text has `maxLines` + ellipsis or shrinks to fit.
12. Light and dark both look intentional and pass the contrast test.
13. Motion uses tokens, respects reduced motion, and never animates from zero what was already on screen.
14. Presentation only: state management, routing, DI and data flow stay as they are unless the user asks.

## Scope discipline

- When editing a screen, keep its structure, wiring and names. Change presentation.
- Don't add packages without asking. Everything here works with the SDK alone.
- Edit the code that exists; don't add wrapper layers, extra lists or new abstractions to apply a style.
- If the project uses generated l10n (`intl_utils` / `flutter_intl`), regenerate after editing ARB files: `dart pub global run intl_utils:generate`. With `gen-l10n`, run `flutter gen-l10n`.
