# Step 0: study the project before touching UI

This is the difference between UI that fits the app and UI that fights it. Do all of it before picking a direction, copying a template or editing a screen. For a full inventory, run the `flutter-design-system` skill's script: `bash ../flutter-design-system/scripts/ui_inventory.sh lib`.

## A. Find the design system

Search (adapt paths for monorepos: `apps/*/lib`, `packages/*/lib`, `sdk/*/lib`):

```bash
rg -l "ThemeData\(|ThemeExtension<|ColorScheme\.|TextTheme\(" lib packages sdk 2>/dev/null
rg -l "class App(Colors|Spacing|Space|Radius|Theme|TextStyles|Typography|Palette|Dimens|Sizes)\b" lib packages sdk 2>/dev/null
fd -t d "theme|design_system|ui_kit|core/ui|shared" lib packages sdk 2>/dev/null
```

If `rg`/`fd` are missing: `grep -rlE "ThemeData\(|ThemeExtension<" lib` and `find lib -type d -name "*theme*"`.

Read every file you find: tokens, colors, typography, the theme builder, context extensions, shared widgets (cards, buttons, inputs, sheets, dialogs, pills, toasts, empty states, skeletons).

Check which Material library the project imports: `package:flutter/material.dart`, or `package:material_ui/material_ui.dart` (Flutter 3.50 deprecated the former; `material_ui` in pubspec.yaml). Everything you add imports the same one (`theming.md` › API notes).

Then read the project's **design notes**: `DESIGN.md`, `docs/design*`, `README` sections about UI, and `UI_PASS.md` if a previous pass left one. These override this skill's defaults.

## B. Map, don't replace

Write a short mapping table (keep it in your working notes or `UI_PASS.md`):

| Skill concept | This project |
|---|---|
| Spacing tokens (`AppSpace`) | e.g. `Gaps`, `Insets`, `AppDimens` |
| Radius tokens (`AppRadius`) | … |
| Color access (`context.colors`, `context.palette`) | e.g. `AppColors.of(context)`, `context.theme.colors` |
| Text styles (`context.textStyles`) | e.g. `AppTextStyles.title` |
| Card (`AppCard`) | … |
| Status pill (`StatusPill`) | … |
| Message component (`AppMessenger`) | e.g. `CustomToastMessage`, `showToast` |
| Sheet (`showAppSheet` / `SheetScaffold`) | … |
| Density by platform (`AppDensity`) | … |

Rules:

- Use the project's names everywhere. Never import this skill's widgets next to equivalent project widgets.
- A missing token or widget is **added to the project's existing file or folder**, in its style (naming, file layout, doc comments).
- When the project's system lacks something big (sheet anatomy, undo deletes, animated lists), port the pattern into the project's naming instead of dropping the template in.

## C. Follow the existing flows

Trace one existing screen end to end and reuse every path:

- **Data**: how the screen gets state (e.g. bloc → state → `BlocBuilder`; `sl<T>()` service locator; providers; controllers). New UI consumes state the same way. Check the project's conventions for accessing blocs (some projects forbid `context.read` and use a service locator only).
- **Status enums**: per-field status (`BaseStatus`, `Status.loading`), `Either<Failure, T>` folding: map them to the loading / empty / error / content widgets without changing the state layer.
- **Messages**: the one class that shows toasts or snackbars. Route every new message through it.
- **Navigation**: router (go_router, auto_route, Navigator 1.0 with named routes and a global `navigatorKey`) and any route helpers. Ask rather than assume when it isn't obvious.
- **Platform differences**: existing checks on `TargetPlatform`, density classes, desktop window setup.
- **Localization**: ARB files and generator (`gen-l10n` vs `intl_utils`); never hard-code user-visible strings when the project localizes.
- **Lints**: read `analysis_options.yaml` so new code matches (const, trailing commas, import ordering).

## D. Respect deliberate deviations

A project may override this skill on purpose: a hand-picked warm palette instead of `fromSeed` surfaces, 40 px desktop controls, outlined inputs, pill buttons, no dark mode yet. Keep them, and write them in DESIGN.md under *Decisions* so the next session doesn't "fix" them.

Ask before changing anything that looks deliberate but conflicts with the user's request.

## E. Audit before you change

For any task bigger than one widget, list what exists and write it as a checklist the work can resume from (`UI_PASS.md`, template in the `flutter-design-system` skill):

- every screen, card type, list, chart, filter, sheet, dialog and message;
- a grep of hard-coded values in UI code:

```bash
rg -n "Colors\.\w+|Color\(0x" lib --glob '!**/design_system/**' --glob '!**/theme/**'
rg -n "fontSize:\s*\d" lib
rg -n "EdgeInsets\.(all|only|symmetric|fromLTRB)\([^)]*\b(2|3|5|6|7|9|10|11|13|14|15|18|22)\b" lib
rg -n "BorderRadius\.circular\(\d" lib
rg -n "SizedBox\((height|width):\s*\d" lib
rg -n "EdgeInsets\.only\((left|right)|Alignment\.(centerLeft|centerRight)|TextAlign\.(left|right)|Positioned\((left|right)" lib
```

## F. Baseline

```bash
flutter analyze
flutter test
```

Record the result (e.g. "analyze clean, 45/45 tests pass") at the top of `UI_PASS.md`. Anything new after your change is yours to fix.

## When there is no design system

Say so in one line, then set one up with the `flutter-design-system` skill before building screens. Building screens first and extracting a system later produces the drift this skill exists to prevent.
