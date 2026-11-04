# Theming

Goal: screens get a modern look *for free* because every Material component is themed once, centrally. Template: `assets/design_system/app_theme.dart`.

## 1. Color scheme from a seed
```dart
final scheme = ColorScheme.fromSeed(
  seedColor: AppTheme.seed,
  brightness: brightness,
  dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot, // see directions.md
);
```
- `tonalSpot`: balanced default. `fidelity`: keeps the brand hue exact. `vibrant` / `expressive`: more color. `neutral` / `monochrome`: editorial, grayscale-leaning. `content`: derived from imagery.
- Never hand-pick 20 colors. Override at most `primary` (exact brand) via `.copyWith(primary: brand)`, and only if `fidelity` isn't close enough.
- Optional: `dynamic_color` package for Android 12+ wallpaper colors. Use only if the brand allows it.

## 2. Custom semantic colors → ThemeExtension
Material has no success/warning/info roles. Add them with `AppPalette` (a `ThemeExtension`) instead of global constants, so they switch with dark mode and animate with theme changes.

```dart
final palette = Theme.of(context).extension<AppPalette>()!; // or context.palette
Container(color: palette.successContainer, child: Text('Paid', style: TextStyle(color: palette.onSuccessContainer)));
```
The template generates these from fixed seed hues per brightness, so they harmonize with the scheme.

## 3. Typography
- Bundle fonts in `assets/fonts/` and declare in `pubspec.yaml` (production). `google_fonts` is fine for prototypes; if used, call `GoogleFonts.config.allowRuntimeFetching = false` and bundle the files for release.
- Set the family once: `ThemeData(fontFamily: ...)` plus the tuned `TextTheme` from `AppTypography`.
- Arabic/RTL apps: choose a family with real Arabic glyphs (IBM Plex Sans Arabic, Cairo, Tajawal, Noto Kufi Arabic, Readex Pro). If the Latin and Arabic fonts differ, set `fontFamilyFallback: ['<arabic family>']` on the theme's text styles. Arabic often needs slightly larger line height (1.5–1.7) for body text.

## 4. Component themes to always set
Defaults that look dated and the fix applied in the template:

| Component | Default problem | Template fix |
|---|---|---|
| `AppBarTheme` | tinted on scroll, centered title on Android only, shadow | `surface` bg, `scrolledUnderElevation: 0`, transparent tint, `centerTitle: false`, titleLarge |
| `CardThemeData` | elevation 1 + tint, 12px, margins | elevation 0, tonal color, 16 radius, hairline border, zero margin |
| `FilledButtonThemeData` | 40px tall | 52px min height, 12 radius, labelLarge |
| `OutlinedButtonThemeData` | heavy outline | `outlineVariant` side, same metrics as filled |
| `TextButtonThemeData` | — | 12 radius, labelLarge |
| `InputDecorationTheme` | underline / heavy outline | filled `surfaceContainerHigh`, no border at rest, 1.5px primary on focus, 16px padding |
| `ChipThemeData` | squared | stadium shape, `outlineVariant` side |
| `NavigationBarThemeData` | 80px, tinted | 68px, `surfaceContainer`, `secondaryContainer` indicator, label colors by state |
| `BottomSheetThemeData` | sharp, no handle | 24 top radius, drag handle, `surfaceContainerLow` |
| `DialogThemeData` | tinted | `surfaceContainerHigh`, 24 radius, headlineSmall title |
| `SnackBarThemeData` | fixed to bottom | floating, 12 radius, inverse surface |
| `ListTileThemeData` | tight | 16 horizontal padding, 12 min vertical padding, 12 ink radius |
| `DividerThemeData` | dark | `outlineVariant` at 50%, 1px |

Set `surfaceTintColor: Colors.transparent` on app bars, cards, sheets, dialogs and nav bars: the M3 tint over everything is a giveaway of untuned defaults. Tonal containers already give hierarchy.

## 5. Dark mode
- Always provide `darkTheme` and `themeMode` (default `ThemeMode.system`).
- Dark surfaces come from the same seed (`brightness: Brightness.dark`). Do not invert colors manually or use pure black, except for an explicit OLED/"true black" option.
- Borders and shadows: borders at lower alpha (≈0.4); shadows nearly invisible, so separation comes from `surfaceContainer` levels.
- Images and illustrations: check they don't glow; dim with a 0.9 opacity overlay if needed.
- Status bar: wrap screens with full-bleed headers in `AnnotatedRegion<SystemUiOverlayStyle>` and pick light/dark icons from the background luminance. Enable edge-to-edge on Android (`SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`), then respect `SafeArea`.

## 6. Accessing the theme in widgets
Use the helpers in `context_ext.dart`:
```dart
final colors = context.colors;      // ColorScheme
final text = context.textStyles;    // TextTheme
final palette = context.palette;    // AppPalette
Text('Balance', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant));
```
Allowed per-widget adjustments: `color`, `fontWeight`, `fontFeatures`, `height` for a specific reading surface. Anything else means the theme or a token is missing — add it there.

## 7. Adapting an existing theme
When the project already has a theme:
1. Keep its names, file layout and brand colors.
2. Add missing component themes from the table above.
3. Replace hard-coded colors in widgets with scheme roles in small, reviewable steps.
4. Add `AppPalette`-style extension only if the project has no semantic colors yet.
