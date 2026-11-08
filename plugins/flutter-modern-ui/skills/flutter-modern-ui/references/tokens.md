# Design tokens

Tokens are named constants. Widgets use names (`AppSpace.md`), never numbers (`16`). Template: `assets/design_system/tokens.dart` and `app_density.dart`. In a project with its own tokens, use its names and add missing ones to its files.

## Spacing (4-pt scale)

| Token | px | Use |
|---|---|---|
| `xxs` | 4 | title ↔ subtitle line, icon ↔ label in pills, rows inside a menu |
| `xs` | 8 | chips (both ways), buttons in a bar, group-card inset, list cards in dense lists |
| `sm` | 12 | list cards, fields in a form grid, row padding, KPI tiles |
| `md` | 16 | card padding, form sections, cards in a row |
| `lg` | 24 | sections, sheet/dialog side padding, sheet sections |
| `xl` | 32 | empty-state side padding, before hero blocks |
| `xxl` | 48 | empty-state top, onboarding |
| `screen` | 20 (16 dense, 24 editorial) | horizontal page padding |

Rules:

- **Proximity = relationship**: space inside a group is smaller than space between groups (8 inside, 24 between). Equal spacing everywhere is the main reason screens look flat.
- Use `Column(spacing:)` / `Row(spacing:)` instead of sprinkling `SizedBox`.
- Every padding, gap and spacing value is one of these. No 2, 3, 6, 10, 14, 18, 20 in widgets (20 only via `AppSpace.screen`).

## Radius

| Token | px | Use |
|---|---|---|
| `xs` | 4 | chart bar tops, legend swatches, rows inside group cards and menus |
| `sm` | 8 | badges, small thumbnails, tooltips, dense controls |
| `md` | 12 | buttons, inputs, snackbars (Soft Minimal) |
| `lg` | 16 | cards (Soft Minimal) |
| `xl` | 24 | sheets, dialogs, hero cards |
| `pill` | 999 | pills, chips, progress bars, pill buttons |

Roles pick from the scale per direction: `AppRadius.card`, `AppRadius.control`, `AppRadius.sheet`.

### Nested shapes (concentric corners)

A rounded shape `gap` px inside a rounded parent uses `AppRadius.concentric(outer, gap)`:

1. **Gap smaller than the outer radius** → inner = outer − gap. Rows 8 px inside a 12 px card → 4. Rows 8 px inside a 16 px card → 8. Tiles 4 px inside an 8 px menu → 4.
2. **Gap ≥ outer radius** → the corners no longer read as nested; the child keeps its own component radius (an input 16 px inside a 12 px card stays 8 or 12).
3. **A child that fills its parent** (gap 0) → radius 0, clipped by the parent (`Clip.antiAlias` on the card or dialog). Example: a row's ink filling its card.
4. **No card inside a card.** A card holds rows, fields or text. One tinted summary block inside a sheet is fine.
5. **No double borders, no stacked shadows.** `ExpansionTile` inside a card draws no border (theme sets `shape: Border()`).
6. **Same card type → same padding, radius and border** across the app. List them in DESIGN.md.

## Elevation and shadows

| Token | Value | Use |
|---|---|---|
| `AppElevation.flat` | 0 | cards, app bars, nav bars, rails |
| `AppElevation.raised` | 1 | FAB at rest |
| `AppElevation.overlay` | 3 | menus, autocomplete overlays |

Material 3 shows depth with tonal surfaces. Cards are flat with a hairline `outlineVariant` border; a bordered element never also has elevation (overlays excepted).

**Named exception: raised tiles** (`AppCard(raised: true)`, dashboard KPIs only): `palette.softShadow`, two layers (24 blur / 8 down, 4 blur / 1 down). Light mode tints the shadow with the text color at 10 % / 6 % and drops the border; dark mode uses black at 35 % / 20 % and keeps the border, because shadows barely read on dark. Hover swaps to `hoverShadow`.

## Strokes, opacity

- Strokes: 1 hairline (borders, dividers, gridlines), 1.5 focused input, 2 selected outline.
- Opacity (`AppOpacity`): hover 0.08, focus 0.10, pressed 0.10, dragged 0.16, tint 0.12, disabled 0.38, muted 0.6. Prefer a container role over an alpha tint when one exists.

## Sizes (`AppSize`, `AppIconSize`)

- Touch target 48 × 48 on touch platforms. Desktop controls 40 px (`AppDensity.desktop`).
- Icons: 14 in pills, 16 inline, 20 dense rows and buttons, 24 default, 32 feature, 48 hero.
- Avatars 40; icon badges 40; emoji badges 36 with a 20 px emoji.
- Progress bars 8; spinners 18.
- Widths: confirm dialog 420, sheet-as-dialog 560, desktop message 420, forms 640, reading 720, dashboards and tables cap at 1440.

## Density (`AppDensity`, a ThemeExtension)

| | Touch (Android, iOS) | Desktop (Windows, macOS, Linux) |
|---|---|---|
| Controls (buttons, inputs) | 48 (52–56 for Soft Minimal / Playful) | 40 |
| List and table rows | 56 | 40 |
| VisualDensity | standard | compact |
| Tap target size | padded | shrinkWrap |
| Pointer affordances | — | hover, cursor, visible scrollbars, tooltips |

Chosen by `TargetPlatform` in `AppTheme.build`; read with `context.density`. One app can ship both.

## Type scale

Defined in `app_typography.dart`; read through `context.textStyles`.

| Role | Size / weight | Latin line height · tracking | Arabic line height | Use |
|---|---|---|---|---|
| displayLarge | 44 / 700 | 1.10 · −1.0 | 1.25 | onboarding hero, huge stat |
| displayMedium | 36 / 700 | 1.12 · −0.8 | 1.25 | balance, score |
| displaySmall | 30 / 700 | 1.15 · −0.5 | 1.30 | detail amount |
| headlineLarge | 28 / 700 | 1.20 · −0.4 | 1.35 | large screen title |
| headlineMedium | 24 / 700 | 1.25 · −0.3 | 1.40 | screen title |
| headlineSmall | 20 / 600 | 1.30 · −0.2 | 1.45 | sheet / dialog titles, KPI values |
| titleLarge | 18 / 600 | 1.33 · −0.1 | 1.45 | app bar title, section headers |
| titleMedium | 16 / 600 | 1.40 · 0 | 1.50 | card titles, form section titles |
| titleSmall | 14 / 600 | 1.40 · 0 | 1.50 | row titles, field labels, amounts in rows |
| bodyLarge | 16 / 400 | 1.50 · 0 | 1.60 | body, inputs |
| bodyMedium | 14 / 400 | 1.50 · 0 | 1.60 | secondary body |
| bodySmall | 12 / 400 | 1.45 · 0.1 | 1.55 | dates, captions, helper text |
| labelLarge | 14 / 600 | 1.20 · 0.1 | 1.35 | buttons, chips, sheet section labels |
| labelMedium | 12 / 600 | 1.20 · 0.2 | 1.35 | pills, KPI labels, legends |
| labelSmall | 11 / 600 | 1.20 · 0.3 | 1.35 | chart axes, overlines |

**Arabic (connected scripts) uses letter-spacing 0 on every role**: any tracking breaks the joins. `AppScript.arabic` does this.

Hierarchy recipe for any text block: one strong element (title role, `onSurface`) + supporting text (body role, `onSurfaceVariant`). Contrast comes from size, weight and color together.

**Numbers**: amounts, dates, timers and table columns use tabular figures (`style.tabular`). Check the font supports `tnum` (inspect its GSUB table or test that "111" and "888" render the same width); some fonts (IBM Plex Sans Arabic, for one) have no `tnum` but already use equal-width digits.

## Color roles

| Need | Role |
|---|---|
| Screen background | `surface` |
| Card / grouped section | `surfaceContainerLowest` (light) · `surfaceContainer` (dark) |
| Bottom sheet | `surfaceContainerLow` |
| Dialog, filled input | `surfaceContainerHigh` |
| Skeleton, neutral pill | `surfaceContainerHighest` |
| Primary text | `onSurface` |
| Secondary text, icons | `onSurfaceVariant` |
| Hairlines, dividers, card borders | `outlineVariant` |
| Input borders, focus-visible boundaries | `outline` (≥ 3:1) |
| Accent fill (selected chip, hero) | `primaryContainer` + `onPrimaryContainer` |
| Nav indicator | `secondaryContainer` + `onSecondaryContainer` |
| Failures, form errors, destructive | `error`, `errorContainer` |
| Success / warning / info, business states | `AppPalette` tones (add domain tones there) |
| Messages | `inverseSurface` (success/info), `errorContainer` (errors) |

## Breakpoints (window size classes)

| Class | Width | Typical layout |
|---|---|---|
| compact | < 600 | bottom nav, 1 column, bottom sheets |
| medium | 600–839 | nav rail, 2 columns, sheets become dialogs |
| expanded | 840–1199 | rail, list-detail, 4 KPI tiles |
| large | 1200–1599 | extended rail, table + detail pane |
| extra-large | ≥ 1600 | as large; content capped at 1440 |

Read with `context.windowSize`. Use the available width (`LayoutBuilder`) for components inside panes.

## Motion tokens (details in the `flutter-motion` skill)

| Token | Value | Use |
|---|---|---|
| `AppDurations.fast` | 150 ms | press, toggles, color/border changes |
| `AppDurations.medium` | 250 ms | state switches, insert/remove, expand |
| `AppDurations.slow` | 350 ms | charts, progress, counters |
| `AppDurations.page` | 450 ms | routes (Android default since 3.38) |
| `AppDurations.stagger` | 40 ms, first 8 only | staggered entrances |
| `AppCurves.enter` / `exit` / `standard` / `emphasized` | M3 easing | entering / leaving / small / large moves |

Every duration goes through `context.motion(d)` (zero under reduced motion).
