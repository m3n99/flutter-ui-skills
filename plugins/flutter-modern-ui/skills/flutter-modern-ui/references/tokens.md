# Design tokens

Tokens are named constants. Widgets use names (`AppSpace.md`), never numbers (`16`). Templates: `assets/design_system/tokens.dart`.

## Spacing (4-pt scale)

| Token | px | Use |
|---|---|---|
| `xxs` | 4 | icon ↔ label inside a chip, tight stacks |
| `xs` | 8 | title ↔ subtitle, items inside a row |
| `sm` | 12 | between list rows, inside compact cards |
| `md` | 16 | card padding, between cards |
| `screen` | 20 | horizontal screen padding |
| `lg` | 24 | between sections |
| `xl` | 32 | before/after hero blocks |
| `xxl` | 48 | top of empty states, onboarding |
| `xxxl` | 64 | rare, hero whitespace |

Rules:
- **Proximity = relationship.** Space inside a group must be smaller than space between groups (e.g. 8 inside, 24 between). Equal spacing everywhere is the #1 reason screens look flat.
- Use `Column(spacing: AppSpace.xs)` / `Row(spacing: ...)` (Flutter 3.27+) instead of sprinkling `SizedBox`.
- Vertical rhythm on a typical screen: `screen` horizontal, `lg` between sections, `md` between cards, `xs` inside text groups.

## Radius

| Token | px | Use |
|---|---|---|
| `sm` | 8 | chips, small badges, thumbnails |
| `md` | 12 | buttons, inputs, list-tile ink |
| `lg` | 16 | cards |
| `xl` | 24 | bottom sheets, dialogs, hero cards |
| `pill` | 999 | pill buttons, tags, avatars-with-text |

Nested radius: inner = outer − padding. A 16-radius card with 8 padding holds an 8-radius image, not 16.

## Type scale

Defined in `app_typography.dart`; reach it through `Theme.of(context).textTheme` (or `context.textStyles`).

| Role | Size / line height | Weight | Tracking | Use |
|---|---|---|---|---|
| displayLarge | 44 / 1.10 | 700 | -1.0 | onboarding hero, big stat |
| displayMedium | 36 / 1.12 | 700 | -0.8 | balance, score |
| displaySmall | 30 / 1.15 | 700 | -0.5 | secondary big numbers |
| headlineLarge | 28 / 1.20 | 700 | -0.4 | screen title (large header) |
| headlineMedium | 24 / 1.25 | 700 | -0.3 | screen title |
| headlineSmall | 20 / 1.30 | 600 | -0.2 | dialog title, hero card title |
| titleLarge | 18 / 1.33 | 600 | -0.1 | app bar title, section header |
| titleMedium | 16 / 1.40 | 600 | 0 | card title, list title |
| titleSmall | 14 / 1.40 | 600 | 0 | dense list title |
| bodyLarge | 16 / 1.50 | 400 | 0 | primary body, inputs |
| bodyMedium | 14 / 1.50 | 400 | 0 | secondary body |
| bodySmall | 12 / 1.45 | 400 | 0.1 | captions, timestamps |
| labelLarge | 14 / 1.20 | 600 | 0.1 | buttons |
| labelMedium | 12 / 1.20 | 600 | 0.2 | nav labels, chips |
| labelSmall | 11 / 1.20 | 600 | 0.3 | overlines, badges |

Hierarchy recipe for any block of text: **one** strong element (title role, `onSurface`) + supporting text (body role, `onSurfaceVariant`). Contrast comes from size, weight *and* color together — not size alone.

Numbers: use `fontFeatures: [FontFeature.tabularFigures()]` for amounts, timers and tables so digits don't jiggle.

## Color roles (from `ColorScheme`)

| Need | Role |
|---|---|
| Screen background | `surface` |
| Card / grouped section | `surfaceContainerLowest` (light) · `surfaceContainer` (dark) |
| Input fill, inactive chip | `surfaceContainerHigh` |
| Skeleton base | `surfaceContainerHighest` |
| Primary text | `onSurface` |
| Secondary text, icons | `onSurfaceVariant` |
| Hairline borders, dividers | `outlineVariant` |
| Strong borders (focused, selected) | `primary` / `outline` |
| Accent fills (selected chip, hero) | `primaryContainer` + `onPrimaryContainer` |
| Secondary accent | `secondaryContainer` / `tertiaryContainer` |
| Destructive | `error`, `errorContainer` |
| Success / warning / info | `AppPalette` (ThemeExtension) |

Opacity: derive tints with `color.withValues(alpha: x)` using only 0.08, 0.12, 0.16, 0.38, 0.6. Prefer a container role over an alpha tint when one exists.

## Elevation and shadows
Material 3 expresses depth with **tonal surfaces**, not shadows. Card hierarchy = surface container levels + hairline border.
Use shadows only for things that float over content (FAB, sticky bottom CTA bar, floating nav, dragged item), and keep them soft: large blur (16–32), low opacity (0.06–0.10), small y offset (4–12). `AppPalette.softShadow` has a ready value; it is tuned separately for dark mode.

## Icons
Sizes: 16 (inline with label text), 20 (dense rows, buttons), 24 (default), 28–32 (feature tiles), 48+ (empty states, inside a tinted circle). Stick to one family per app: Material Symbols Rounded (`material_symbols_icons`), Lucide (`lucide_icons_flutter`), Phosphor, or the built-in `Icons.*_rounded` / `Icons.*_outlined` set. Never mix filled, outlined and sharp variants randomly; use filled for the *selected* state only.

## Durations and curves

| Token | Value | Use |
|---|---|---|
| `AppDurations.fast` | 150 ms | press feedback, toggles, color changes |
| `AppDurations.medium` | 250 ms | expand/collapse, switcher, small moves |
| `AppDurations.slow` | 400 ms | page-level, hero, large layout changes |
| `AppCurves.standard` | `Curves.easeOutCubic` | default for entering/settling |
| `AppCurves.emphasized` | `Curves.easeInOutCubicEmphasized` | larger moves, sheets |
| `AppCurves.exit` | `Curves.easeInCubic` | leaving the screen |
