# Theming

Goal: screens look right by default because every component is themed once, centrally, and the theme matches the chosen direction. Template: `assets/design_system/app_theme.dart` (with `AppThemeConfig`).

## 1. Configure, don't fork

All direction choices live in one `AppThemeConfig`:

```dart
static const AppThemeConfig config = AppThemeConfig(
  seed: Color(0xFF2D6A64),
  variant: DynamicSchemeVariant.fidelity,     // keep the brand hue exact
  fontFamily: 'IBM Plex Sans Arabic',
  script: AppScript.arabic,                   // zero tracking, taller lines
  surfaces: SurfaceStyle.eyeComfort,          // long sessions
  inputStyle: InputStyle.outlined,            // dense data entry
);
```

```dart
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system,
  scaffoldMessengerKey: AppMessenger.key,
)
```

`AppTheme.build(brightness, platform: …)` picks `AppDensity.touch` or `AppDensity.desktop` from the platform; tests pass the platform explicitly to render both.

Bilingual apps rebuild the theme when the locale changes: `AppTheme.light(config: AppTheme.config.copyWith(script: isArabic ? AppScript.arabic : AppScript.latin))`.

## 2. Color scheme

```dart
ColorScheme.fromSeed(seedColor: seed, brightness: brightness, dynamicSchemeVariant: variant)
```

- `tonalSpot`: balanced default. `fidelity`: keeps the seed hue (brands). `vibrant` / `expressive` / `rainbow`: more color. `neutral` / `monochrome`: editorial, grayscale-leaning. `content`: from imagery.
- **`fidelity` and `content` put the containers at the seed's own tone.** With a saturated seed (red, amber, green) `primaryContainer` is nearly the seed itself: selected chips and "soft" tinted tiles become solid blocks in light mode and glare in dark mode, and every contrast check still passes. `AppTheme` keeps their strong colors and takes the primary and tertiary containers from `tonalSpot`; `ToneColors.fromSeed` does the same for status tones. The contrast test's soft-container check (tone ≥ 80 and chroma ≤ 50 in light mode, tone ≤ 40 in dark) catches hand-picked or overridden containers that slip through. Vivid containers on purpose: set them in `schemeOverride`.
- Don't hand-pick twenty colors. For a brand-supplied palette, override the few roles that must match in `schemeOverride: (s) => s.copyWith(primary: brand, onPrimary: …)`, then run `contrast_test.dart`.
- Android 12+ wallpaper colors (`dynamic_color` package) only if the brand allows it.

### Eye comfort (`SurfaceStyle.eyeComfort`)

For apps used for hours. Replaces the neutral roles with dimmed warm values:

| Role | Light | Dark |
|---|---|---|
| surface (scaffold) | `#F6F3EC` | `#181715` |
| surfaceContainerLowest (cards) | `#FCFAF6` | `#121110` |
| surfaceContainerLow (sheets) | `#F1EDE5` | `#1C1B19` |
| surfaceContainer | `#EBE7DE` | `#22201D` |
| surfaceContainerHigh (dialogs, fills) | `#E5E0D6` | `#2C2A26` |
| surfaceContainerHighest | `#DED8CC` | `#37342F` |
| onSurface | `#2A2824` | `#E7E2D9` |
| onSurfaceVariant | `#55504A` | `#BDB6AA` |
| outline | `#7A746A` | `#8F887D` |
| outlineVariant | `#D3CDC2` | `#47423B` |

Checked: onSurface ≥ 10:1, onSurfaceVariant ≥ 5.5:1, outline ≥ 3.2:1 on every level, both modes. Primary / secondary / tertiary still come from the seed. To retune, keep the M3 order (lowest is the lightest surface in light mode, the darkest in dark mode) and re-run the contrast test.

## 3. Semantic and domain colors → `AppPalette`

Material has no success / warning / info roles. `AppPalette` (a `ThemeExtension`) adds them as `ToneColors` (color, onColor, container, onContainer), generated from fixed hues per brightness so they switch with dark mode and animate with theme changes.

- Business states get their own tones (`overdue`, `dueSoon`, `paid`, `pending`…). Add fields to `AppPalette` next to `success` / `warning` / `info`; don't reuse `colorScheme.error`, which means "something failed".
- Map each domain status to one label + one icon + one tone in a single enum extension (see `assets/examples/sample_data.dart`). Widgets build pills from that, never from raw colors.
- `softShadow` / `hoverShadow` live here too, so they adapt to brightness.

## 4. Typography

- **Bundle fonts** in `assets/fonts/` and declare them in `pubspec.yaml`. `google_fonts` is fine for prototypes; for release, bundle the files and set `GoogleFonts.config.allowRuntimeFetching = false`.
- Set the family once (`AppThemeConfig.fontFamily`); `fontFamilyFallback` when the main font lacks a script or a symbol. Check coverage with `../flutter-ui-verify/scripts/check_glyphs.py` (currency signs, separators, ✓): Tajawal, for one, has no `₪`.
- **Arabic**: a font with real Arabic glyphs (IBM Plex Sans Arabic, Noto Sans Arabic, Cairo, Tajawal, Readex Pro); `AppScript.arabic` (letter-spacing 0, body line height 1.6). Check the weights you use exist (many Arabic families ship 400/500/600/700 only).
- Check `tnum` support before relying on tabular figures (`tokens.md`).

## 5. Component themes (all set in the template)

| Component | Default problem | Template |
|---|---|---|
| AppBar (`AppBarThemeData`) | tint on scroll, shadow | surface color, `scrolledUnderElevation: 0`, transparent tint, start-aligned titleLarge |
| Card (`CardThemeData`) | elevation + tint, margins | flat, tonal color, card radius, hairline border, zero margin, clipped |
| Filled / Outlined / Text buttons | 40 px, mixed shapes | control height from density, control radius, labelLarge |
| Inputs (`InputDecorationThemeData`) | underline or heavy outline | `filled`: tinted fill, no rest border · `outlined`: card fill + `outline` border; 1.5 px primary on focus; dense on desktop |
| Chips | selection by color only | stadium, check mark + `primaryContainer` fill when selected, hairline border otherwise |
| NavigationBar / NavigationRail | tinted, 80 px | 68 px, `surfaceContainer`, `secondaryContainer` indicator, label colors by state |
| BottomSheet | sharp, no handle | 24 px top radius, drag handle, `surfaceContainerLow` |
| Dialog (`DialogThemeData`) | tinted | `surfaceContainerHigh`, 24 px radius, headlineSmall title |
| SnackBar | fixed full width | floating, 420 px on desktop, control radius, inverse surface |
| ListTile | tight | 16 px horizontal padding, density-aware vertical padding |
| ExpansionTile | draws its own borders | `shape` / `collapsedShape: Border()` |
| TabBar (`TabBarThemeData`) | divider line | label-size indicator, no divider |
| Scrollbar | hidden on desktop | always visible on pointer platforms |
| Tooltip | instant | 500 ms wait on desktop, inverse surface |
| DataTable | default heights | heading `surfaceContainerHigh`, row height from density, hairline dividers |
| Page transitions | — | predictive back (Android), Cupertino (Apple), fade-forwards (Windows, Linux) |

`surfaceTintColor: Colors.transparent` everywhere: the M3 tint over every surface is a giveaway of untuned defaults.

## 6. Density by platform

`AppDensity` is a ThemeExtension chosen from the platform: touch (48 px controls, padded tap targets) or desktop (40 px controls, compact visual density, shrink-wrapped targets). Button heights, input padding, list and table rows read from it, so one codebase gets the right metrics on Android and Windows. If a desktop build may run on touch screens, raise `desktopDensity.control` to 48.

## 7. Dark mode

- Always provide `darkTheme`; default `ThemeMode.system`.
- Dark surfaces come from the same seed (or the eye-comfort dark values). Never invert colors or use pure black (except an explicit OLED option).
- Borders carry separation in dark mode; shadows barely read (raised tiles keep their border in dark).
- Images and illustrations: check they don't glow; dim with an overlay if needed.
- Status bar: full-bleed headers set `SystemUiOverlayStyle` by background luminance; edge-to-edge on Android (`SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`, the default from Android 15) with `SafeArea` plus a little padding on content (`layout.md` › System bars and safe areas).

## 8. Reading the theme in widgets

```dart
final colors = context.colors;       // ColorScheme
final text = context.textStyles;     // TextTheme
final palette = context.palette;     // AppPalette
final density = context.density;     // AppDensity
Text('Balance', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant));
Text(amount, style: text.titleMedium.tabular);
```

Allowed per-widget adjustments: `color`, `fontWeight`, `fontFeatures`, `height` for a reading surface. Anything else means a token or theme entry is missing; add it there.

## 9. Adapting an existing theme

1. Keep its names, file layout and brand colors.
2. Add missing component themes from the table above.
3. Fix contradictions with its own direction (density, radius, card color) in the theme, not per screen.
4. Replace hard-coded colors in widgets with roles in small, reviewable steps.
5. Add an `AppPalette`-style extension only if the project has no semantic colors yet.

## 10. API notes

- Flutter 3.35 changed `ThemeData.appBarTheme`, `bottomAppBarTheme` and `inputDecorationTheme` to `AppBarThemeData`, `BottomAppBarThemeData` and `InputDecorationThemeData` (`CardThemeData`, `DialogThemeData`, `TabBarThemeData` came earlier).
- Flutter 3.38: SnackBars with an action no longer auto-dismiss (`persist` defaults to keeping them); the Android default route transition became `PredictiveBackPageTransitionsBuilder` (falls back to `FadeForwardsPageTransitionsBuilder`) and route transitions take 450 ms.
- `Color.withValues(alpha:)` replaced `withOpacity`; `WidgetState*` replaced `MaterialState*`.
- **Flutter 3.50 deprecates `package:flutter/material.dart` and `cupertino.dart`** in favor of the `material_ui` and `cupertino_ui` packages (same classes, new library; `dart fix --apply --code=migrate_design_widgets` rewrites the imports). Use whichever the project uses: the copy scripts rewrite the templates' and the harness's imports when `pubspec.yaml` lists `material_ui`, and `app_theme.dart` then needs `cupertino_ui` for `CupertinoPageTransitionsBuilder`. Both `material_ui` and `flutter_localizations` export `GlobalMaterialLocalizations`, so don't import both in one file: with `material_ui`, `localizationsDelegates: GlobalMaterialLocalizations.delegates` covers the Material, Cupertino and Widgets delegates.
