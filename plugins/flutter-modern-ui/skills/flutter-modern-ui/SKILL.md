---
name: flutter-modern-ui
description: Build or restyle Flutter UI and UX that looks modern, belongs to the app's subject and stays consistent with the project's design system — screens (home, lists, detail, forms, sign-in, onboarding, settings, search), flows, interface wording, themes, adaptive phone/tablet/desktop layouts, sheets, dashboards, RTL and Arabic, printed PDFs. Use this skill for ANY Flutter UI or UX request before answering from memory, however small: building or changing a screen or one widget, a layout or overflow problem, what a screen should show, how to word a button or an error, big fonts, safe areas, bottom sheets, RTL, and whenever the UI looks plain, dated, generic, templated or AI-made or a flow takes too many steps. It holds rules from real projects that general Flutter knowledge misses. Studies the existing app first, writes a design brief, asks about platforms, RTL, the look, emoji and motion, and verifies with screenshots.
---

# Flutter Modern UI

Generic Flutter output fails in three predictable ways. It looks dated: untuned Material defaults, hard-coded sizes and colors, flat hierarchy, shadow-heavy cards, no loading/empty/error states, touch metrics on desktop, broken RTL. It drifts: every screen invents its own spacing, sheet layout and message style. And it could be any app: the same purple seed, the same font, a greeting over a grid of numbers, "Submit" and "Something went wrong", whatever the app is about.

This skill works like a product designer and UI engineer joining a team: **study the app → write the brief → agree on the system → plan the flow → build on it → animate with purpose → look at the result and take one thing away → record the decisions.**

## Step 0 — Read first (never skip)

Do this before any direction, token file or screen. Details: `references/discovery.md`.

1. **Find and read the existing design system**: search for `ThemeData(`, `ThemeExtension`, `ColorScheme`, `TextTheme`, folders like `theme`, `design_system`, `ui_kit`, `core/ui`, `shared/`, and UI packages under `sdk/` or `packages/`. Read tokens, palette, typography, theme, context extensions and shared widgets end to end.
2. **Read the contract**: `DESIGN.md` (or `docs/design-system.md`) at the project root, and any UI progress log (`UI_PASS.md`). They hold decisions that override this skill's defaults.
3. **Map, don't replace**: write down the project's names (its spacing class, color access, card widget, message component) and use them. A missing token goes **into the existing file**. Never create a second system or a new `theme/` folder.
4. **Follow the existing flows**: how screens get data (bloc → state → builder, service locator, providers), how messages are shown, how navigation and platform differences work. New UI reuses those paths.
5. **Respect deliberate deviations** (a custom palette instead of `fromSeed`, desktop-sized controls, outlined inputs) and note them.
6. **Material library**: `package:flutter/material.dart` or, from Flutter 3.50, `package:material_ui/material_ui.dart` (`material_ui` in pubspec.yaml). New code imports what the project imports.
7. **Baseline**: run `flutter analyze` and `flutter test` before changing UI so new warnings and failures are clearly yours.

## Step 1 — Intake: ask once, early

Ask the questions in `references/intake.md` in one short round (use the question tool when available): **platforms**, **RTL languages**, **the look** (cards, plain rows or rich), **emoji**, **how much motion and where**, and, if no system exists yet, **the brief and the direction**: propose the five-line brief (subject, audience, the job, the feeling, a signature element) from what the project shows and ask whether it's right, along with any brand color or apps they like. Skip what DESIGN.md already answers. When nobody is there to answer, take the stated defaults and say which you took, except for the look: build the first list screen with cards, show its screenshot and ask before doing the rest. A spec that says "basic" or "simple" doesn't answer it; a wrong guess costs a full redesign round.

**Motion is always asked before building**, even when a spec or the customer already hinted at it: the level (**none**: Material's own motion only; **soft**: calm fades and short rises; **expressive**: staggered, bouncier, more surfaces) and the places, each with the one-line soft and expressive example from `references/intake.md` › Motion, so the user picks from something concrete. A hint from the customer ("keep it basic", "make it lively") becomes the recommended option, not the answer.

## Step 2 — The brief, then the design system

- **Project has a system** → extend it in place (Step 0). Add only what's missing. Its DESIGN.md brief is the identity you build inside; if it has none, write the five lines from what the app already is and add them.
- **Project has none** → **brief first** (`references/identity.md`): the subject in its own words, the audience and setting, the one job, three feeling words, and a signature element from the subject's world. From it come the seed color, the typeface, the shapes and what the home screen shows. Run the sameness check ("would this line fit any other app?") before any token is set: the template's seed and font are placeholders, and two apps on the same direction should not look alike.
- Then set the system up with the `flutter-design-system` skill: pick a direction (`references/directions.md`: the chassis), copy the templates with `python3 scripts/copy_design_system.py` (this skill's folder) into the project's conventional location (default `lib/core/design_system/`), set `AppTheme.config`, retune the `DIRECTION` lines, and write `DESIGN.md`.
  - **Core kit** (default), what every app needs: tokens, density, motion level, palette, typography, theme, context extensions (`isNarrow`, `listEndPadding`), `AppCard`, `StatusPill` / `IconBadge` / `EmojiBadge`, `MetaItem`, `EmptyState`, skeletons, sheets and pick-one sheets, chips, `SaveBar`, messages, `SectionHeader`, `Ltr`.
  - **Extras** (`--kit extras`, later is fine): motion pieces, `AdaptiveShell` / `ContentWidth`, `KpiTile` / `KpiGrid`. Add them when the app animates, ships on tablet or desktop, or has a dashboard; don't hand-write lookalikes.
  - The script keeps files you already changed, writes the barrel for what's there, and rewrites imports for `material_ui` projects.
- **User shared reference apps or screenshots** → derive the direction from them with the `flutter-design-system` skill.

Templates require Flutter ≥ 3.41 (`SnackBar.persist`, `AppBarThemeData`, `InputDecorationThemeData`, `SizeTransition.alignment`). On older SDKs: drop `persist`, use `AppBarTheme` / `InputDecorationTheme` and `SizeTransition.axisAlignment`; `CupertinoPageTransitionsBuilder` comes from `package:flutter/cupertino.dart`. On Flutter 3.50+ with `material_ui`, the copy scripts import `material_ui` / `cupertino_ui` instead (`references/theming.md` › API notes, including the `GlobalMaterialLocalizations` clash with `flutter_localizations`).

## Step 3 — Plan the screen

Before writing widgets, decide in a few lines (in `UI_PASS.md` for multi-screen work):

- **the task**: who arrives, from where, to do what, and where next; the taps for the most frequent task (two or fewer for the daily one) — `references/ux.md`;
- the **screen type** and its anatomy (home, detail, sign-in, onboarding, settings, search…) — `references/screens.md`;
- the **one primary thing** and **one primary action**, placed where the thumb is;
- the layout per window size (compact / medium / expanded+) — `references/layout.md`, `references/adaptive.md`;
- every state: loading, empty, error, content, refreshing — `references/states.md`;
- the motion level and places from intake (DESIGN.md › Motion) — `flutter-motion` skill;
- what sits at the top and bottom edges: app bar or a header in `SafeArea`, a bottom bar or the last list row clear of the navigation bar — `references/layout.md` › System bars;
- **the words**: the title, the button (verb + object), the empty and error text, written now, not as placeholders — `references/writing.md`.

## Step 4 — Build

Read only the references the screen needs. **When the app has a right-to-left language, `references/rtl-arabic.md` is required reading before the first widget**, whatever the screen.

| Need | Read |
|---|---|
| The brief, signature element, palette and typeface from the subject, the sameness check | `references/identity.md` |
| Tasks, navigation, defaults, feedback, forgiveness, first run | `references/ux.md` |
| What each screen type is for and how it's built (home, detail, sign-in, onboarding, settings, profile, search, paywall, reading) | `references/screens.md` |
| Button labels, titles, empty and error text, Arabic interface wording | `references/writing.md` |
| Spacing, radius, type, color roles, sizes | `references/tokens.md` |
| Theme, color scheme, eye comfort, fonts | `references/theming.md` |
| Screen anatomy, hierarchy, nested shapes, system bars, big fonts | `references/layout.md` |
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

Reference compositions to imitate for structure and craft: `assets/examples/` (a home that answers the daily question, records list-detail with filter sheet and undo, long form, sign-in with its failed state, settings, app shell, printed invoice). They are one app with its own brief (`assets/examples/example_app.dart`): take the patterns, not its ink color, its ledger lines or its words.

## Step 5 — Motion

Apply the `flutter-motion` skill at the level and on the surfaces the user chose: set `AppTheme.config`'s `motion` (`MotionLevel.none`, `.soft` or `.expressive`) and the shared pieces (`Entrance`, `AnimatedItems`, `StateSwitcher`, `PressScale`, `SubmitButton`, `AnimatedNumber`, `AppProgressBar`) follow it; every duration comes from tokens and goes through `context.motion(...)`.

## Step 6 — Verify by looking

Apply the `flutter-ui-verify` skill: `flutter analyze`, the layout matrix (360 / 1000 / 1366 px × text scale 1.0 / 1.3 / 1.6 × light / dark × platforms × directions, phones and tablets under their system bars, with a check that nothing touches them), the sheet test (keyboard, tap targets), contrast, then **render screenshots and look at them** against `references/review-checklist.md` and against the brief: does the screen answer its task, could it be any app, do the words say what happens? Fix and re-shoot. Before calling it done, **take one thing away from each screen**: a border, a tint, an icon or a label that carries no information. Printed documents get the same loop: sample PDFs (typical, empty optional fields, longest content), block checks, then rasterize and open every page. **When a pass touches more than three screens, or it's the first pass on an app, hand the screenshots to the `flutter-ui-reviewer` agent** with DESIGN.md: fresh eyes catch what the builder has stopped seeing, such as a whole pass that came out too plain for the agreed look.

## Step 7 — Record and report

- Run `python3 scripts/lint_ui.py --diff` (raw colors, sizes, spacing and durations, token arithmetic like `AppSpace.xs + 2`, left/right APIs), fix what it finds, then scan the diff against `references/anti-patterns.md` for what a grep can't see.
- Update `DESIGN.md` with any new token, pattern or decision, and tick `UI_PASS.md`.
- Report in a few lines: direction, what changed, which screenshots were reviewed, anything left open.

## Non-negotiables

1. No raw colors (`Colors.blue`, `Color(0x…)`) or font sizes in widgets: scheme roles, palette tones, text theme roles.
2. Spacing, radius, durations, sizes come from tokens. No 2, 3, 6, 10, 14, 18 px.
3. One radius family per screen. Nested rounded shapes are concentric while the gap is smaller than the outer radius (`AppRadius.concentric`); no card inside a card; no double borders.
4. Cards are flat: tonal fill + hairline `outlineVariant` border. Shadows only for floating elements and raised dashboard tiles.
5. One primary action per screen and per sheet.
6. Status is never shown by color alone: every status has an icon and a label; selected chips show a check.
7. Every data screen has loading (skeleton), empty, error and refresh states (pull to refresh for loaded data; live data, such as a local-first store or a stream, needs none).
8. One message component; messages name the thing; errors say what failed and what to do; destructive actions confirm or offer Undo.
9. Touch targets ≥ 48 px on touch platforms; desktop gets hover, cursor, focus, visible scrollbars and tooltips.
10. Directional APIs only (`EdgeInsetsDirectional`, `AlignmentDirectional`, start/end). Numbers, dates and phones stay LTR inside RTL. Arabic gets zero letter-spacing.
11. Text never overflows at 360 px and text scale 1.3 or 1.6. Dynamic text has `maxLines` + ellipsis or shrinks to fit; when the screen is narrow for its text (`context.isNarrow`: width ÷ text scale < 340), rows that pair two things stack.
12. **Nothing touches the system bars.** Whatever sits near the top or bottom edge (a header, a search bar, a bottom bar, a button, the last list row) is inside `SafeArea` plus at least 8 px, clear of the status bar, the camera cutout or Dynamic Island, the navigation bar and the home indicator. App bars and navigation bars handle this themselves; bottom bars use `SaveBar`, lists end with `context.listEndPadding()`.
13. Light and dark both look intentional and pass the contrast test.
14. Motion follows the agreed level (none, soft or expressive), uses tokens, respects reduced motion, and never animates from zero what was already on screen.
15. Presentation only: state management, routing, DI and data flow stay as they are unless the user asks.
16. The app has a brief in DESIGN.md (subject, audience, job, feeling, signature). The seed, the typeface and what the home screen shows follow from it; a template default that survives is a decision somebody made, not a leftover.
17. Words are part of the design: buttons name what happens ("Save changes", not "Submit"), one name per thing through the flow, no placeholder copy ("Success", "No data", "Something went wrong").

## Scope discipline

- When editing a screen, keep its structure, wiring and names. Change presentation.
- Don't add packages without asking. Everything here works with the SDK alone.
- Edit the code that exists; don't add wrapper layers, extra lists or new abstractions to apply a style.
- If the project uses generated l10n (`intl_utils` / `flutter_intl`), regenerate after editing ARB files: `dart pub global run intl_utils:generate`. With `gen-l10n`, run `flutter gen-l10n`.
