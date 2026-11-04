---
name: flutter-modern-ui
description: Build or restyle Flutter mobile UI so it looks modern, polished and intentional instead of default Material. Use whenever creating or changing a Flutter screen, widget, theme, design system, or component (cards, lists, forms, nav bars, sheets, dashboards, onboarding), or when the user says the UI looks plain, old, generic or "AI-made".
---

# Flutter Modern UI

Default Flutter output looks dated for predictable reasons: raw Material colors, hard-coded sizes, cramped or random spacing, shadow-heavy cards, no type hierarchy, and no loading/empty/error states. This skill replaces those defaults with a small design system and a set of composition rules.

**Core rule: system first, screen second.** Widgets never hard-code colors, font sizes, radii or spacing. They read from the theme and the token files.

## Workflow

Follow these steps in order. Skip a step only when the project already covers it.

### 1. Inspect the project (always)
- Read `pubspec.yaml`: Flutter/Dart SDK constraint, fonts, existing UI packages.
- Search for an existing theme or design system: `ThemeData(`, `ThemeExtension`, `ColorScheme`, folders named `theme`, `design_system`, `ui_kit`, `core/ui`, or an `sdk/` / `packages/` UI package.
- **If a system exists, use and extend it. Never create a second one.** Map the rules below onto its names.
- Note the state management and routing in use. This skill changes presentation only; it never introduces a new state-management, DI or routing approach.
- API level: the templates target Flutter ≥ 3.32 (`Color.withValues`, `WidgetState`, `CardThemeData`, `DialogThemeData`, `Row/Column(spacing:)`). On older SDKs, swap to `withOpacity`, `MaterialState`, `CardTheme`, `DialogTheme`, and `SizedBox` gaps.

### 2. Choose a design direction
Read `references/directions.md`. If the user did not specify a style, pick the direction that fits the app's domain and state your pick in one line before building (e.g. "Going with *Soft Minimal*: calm fintech, indigo seed, 16px radii"). A deliberate direction is the single biggest difference between modern and generic.

### 3. Set up tokens and theme (if missing)
Copy from `assets/design_system/` into the project's conventional location (default `lib/core/design_system/`), fix imports, and set the seed color and font from the chosen direction:

| File | Purpose |
|---|---|
| `tokens.dart` | Spacing, radius, durations, curves, icon sizes |
| `app_palette.dart` | `ThemeExtension` for success / warning / info + shadows |
| `app_typography.dart` | Tuned type scale (sizes, weights, line heights, tracking) |
| `app_theme.dart` | Light + dark `ThemeData` with every common component themed |
| `context_ext.dart` | `context.colors`, `context.textStyles`, `context.palette` |
| `widgets/` | `AppCard`, `Pressable`, `Shimmer`/`SkeletonBox`, `EmptyState`, `SectionHeader`, `StatusPill` |

Details and rationale: `references/tokens.md`, `references/theming.md`.

### 4. Build the screen
Apply `references/layout.md` (screen anatomy, spacing rhythm, hierarchy, RTL, responsive) and `references/components.md` (patterns for cards, lists, buttons, inputs, sheets, nav, app bars). A full reference composition lives in `assets/examples/dashboard_screen.dart`.

### 5. Add states and motion
Every data-driven screen ships with loading (skeleton, not a centered spinner), empty, and error states: `references/states.md`. Add purposeful motion and press feedback: `references/motion.md`.

### 6. Self-review before finishing
Run through `references/review-checklist.md`. Scan the diff for anything in `references/anti-patterns.md`. Fix violations before reporting done.

## Non-negotiables

1. No `Colors.blue`, `Colors.grey[300]`, or hex literals inside widgets. Use `ColorScheme` roles or `AppPalette`.
2. No raw font sizes in widgets. Use `textTheme` roles; adjust with `copyWith(color:/fontWeight:)` only.
3. Spacing comes from the 4-pt scale in `AppSpace`. No 7, 13, 15, 18 px values.
4. One radius family per screen (from `AppRadius`). Nested corners: inner radius = outer radius − padding.
5. Cards: elevation 0, tonal surface + hairline `outlineVariant` border. Shadows only for floating elements, and soft (see `AppPalette.softShadow`).
6. Clear hierarchy: one primary action per screen (`FilledButton`), secondary actions as `OutlinedButton`/`TextButton`. Never two filled buttons side by side with equal weight.
7. Content stays inside `SafeArea`; horizontal screen padding is `AppSpace.screen` (20).
8. Touch targets ≥ 48×48. Tappable things give feedback (ripple or `Pressable` scale).
9. Light and dark both work. Test mentally against both schemes; never assume white backgrounds.
10. Use directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`) so RTL (Arabic, Hebrew) works without changes.
11. Text never overflows: `maxLines` + `TextOverflow.ellipsis` on dynamic strings, `Flexible`/`Expanded` in rows, and layouts survive text scale 1.3.
12. Loading = skeletons shaped like the content. Empty and error states have an icon, a sentence, and an action.
13. Prefer composition from the theme over one-off styling. If a style repeats twice, it belongs in the theme or a shared widget.

## Scope discipline
- When editing an existing screen, keep its structure, state wiring and naming. Change presentation, not architecture.
- Don't add packages without asking. Everything here works with the Flutter SDK alone; `google_fonts` is optional (bundled fonts are preferred for production).
- When finished, summarize the direction used and any tokens added, in two or three lines.
