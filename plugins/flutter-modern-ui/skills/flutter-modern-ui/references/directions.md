# Design directions

Pick one direction per app and apply it everywhere. Mixing directions (glass cards next to flat enterprise tables) is what makes an app feel unfinished. A direction is a set of token values: set them in `AppTheme.config` (`AppThemeConfig`), `AppRadius.card` / `AppRadius.control`, `AppSpace.screen` and `AppDensity`.

**A direction is the chassis, not the identity.** It settles density, depth, roundness and liveliness. What makes the app recognizably itself (its colors, its typeface, its one signature element) comes from the brief in `identity.md`, written first. The seeds and fonts in the tables below are fallbacks for a brief that leaves them open, and the first thing the sameness check questions: two apps on the same direction should still not look alike.

Each table lists every value the templates need, so the theme never contradicts the direction.

---

## 1. Soft Minimal (default when unsure)
**Fits:** fintech, productivity, health, SaaS companions, most consumer apps. **Feel:** calm, airy, confident.

| Token | Value |
|---|---|
| Seed / variant | the brand color or one from the subject (`identity.md`); fallbacks: teal `#0F766E`, ink `#1F2A44`, forest `#166534` · `tonalSpot` (`fidelity` for exact brand hue) |
| Font | chosen from the brief's feeling (`identity.md` › Type); fallbacks: Manrope, Plus Jakarta Sans, Figtree · Arabic: IBM Plex Sans Arabic |
| Radius | card 16 · control 12 · sheet 24 |
| Control height | touch 48–52 · desktop 40 |
| Screen padding | 20 |
| Cards | flat: `surfaceContainerLowest` (light) / `surfaceContainer` (dark) + hairline border |
| Inputs | `InputStyle.filled` |
| Surfaces | `SurfaceStyle.tonal` |
| Motion | 200–300 ms, press scale, staggered entrance |
| Emoji fit | KPI tiles only, if at all |

Typical moves: large bold title at the top of the scroll (`SliverAppBar.large`), muted secondary text, one accent used sparingly, the answer to the user's daily question first. The app's own signature comes from its brief.

---

## 2. Bold Contrast
**Fits:** fitness, media, crypto, consumer apps that want energy. **Feel:** punchy, high-contrast, editorial-sporty.

| Token | Value |
|---|---|
| Seed / variant | Saturated: `#FF5A1F`, `#7C3AED`, `#E11D48` · `vibrant` or `fidelity` |
| Font | Satoshi, General Sans, Sora, Space Grotesk · Arabic: Cairo, Readex Pro |
| Radius | card 20–24 · control pill (`StadiumBorder`) · sheet 28 |
| Control height | touch 52–56 · desktop 44 |
| Screen padding | 20 |
| Cards | dark-first; hero card `primaryContainer` or a primary → tertiary gradient (one element only) |
| Inputs | filled |
| Motion | snappy 150–220 ms, staggered entrances, counters that tween, `PopOnChange` on toggles |
| Emoji fit | headers and empty states work |

Typical moves: oversized numerals (displayMedium + tabular), full-bleed hero card, pill buttons, icons in filled tinted circles.

---

## 3. Editorial
**Fits:** news, reading, journaling, recipes, portfolios. **Feel:** typographic, quiet, magazine-like.

| Token | Value |
|---|---|
| Seed / variant | Near-neutral `#3F3F46`, warm `#7C5C3B` · `neutral` or `monochrome` |
| Font | Headlines serif (Fraunces, Newsreader, Source Serif 4), body sans (Inter) · Arabic: Noto Naskh Arabic body, Amiri display |
| Radius | card 12 · control 8 · images 12 |
| Control height | touch 48 · desktop 40 |
| Screen padding | 24 |
| Cards | almost none: whitespace and dividers carry structure |
| Inputs | outlined |
| Reading | body 17 / 1.6, max line ~65 characters (`AppSize.readingMaxWidth` 720) |
| Motion | minimal: fades only |
| Emoji fit | none |

Typical moves: big images at 3:2 or 4:5, serif titles, small-caps overlines (labelSmall + letterSpacing 1.2 + uppercase; never on Arabic), generous whitespace.

---

## 4. Glass & Depth
**Fits:** music, weather, smart home, premium lifestyle. **Feel:** layered, luminous, premium.

| Token | Value |
|---|---|
| Seed / variant | Deep blue / violet `#312E81`, or from artwork · `content` |
| Font | Inter, SF-like grotesques · Arabic: IBM Plex Sans Arabic |
| Radius | card 20–28 · control 14 · sheet 28 |
| Control height | touch 52 · desktop 44 |
| Background | gradient or blurred artwork behind content |
| Cards | `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX: 20, sigmaY: 20))`, fill `surface` at 0.55 alpha, 1 px border `onSurface` at 0.08 |
| Motion | parallax on scroll, Hero on artwork, slow 350–450 ms |

Rules: blur is expensive: at most 2–3 blurred elements on screen, never inside long lists. Text over busy backgrounds must keep 4.5:1; check the worst spot.

---

## 5. Playful
**Fits:** kids, education, habits, social, games. **Feel:** friendly, rounded, colorful.

| Token | Value |
|---|---|
| Seed / variant | Warm `#F59E0B`, `#10B981`, `#8B5CF6` · `expressive` or `rainbow` |
| Font | Nunito, Baloo 2, Fredoka · Arabic: Baloo Bhaijaan 2, Tajawal |
| Radius | card 24 · control pill · sheet 32 |
| Control height | touch 56 · desktop 44 |
| Color | each category gets its own container color (primary / secondary / tertiary containers + palette tones) |
| Motion | springy pops (`AppCurves.pop`) for celebrations only, confetti on success, progress rings |
| Emoji fit | everywhere it carries meaning, always with a label |

Typical moves: illustrations in empty states, chunky buttons, progress rings, big friendly icons.

---

## 6. Enterprise Dense
**Fits:** admin panels, field service, CRM, logistics, ledgers, internal tools. **Feel:** efficient, trustworthy, information-rich without clutter.

| Token | Value |
|---|---|
| Seed / variant | Blue `#2563EB`, slate `#334155`, teal `#2D6A64` · `tonalSpot` (`fidelity` for brand) |
| Font | Inter, Roboto Flex · Arabic: IBM Plex Sans Arabic |
| Radius | card 12 · control 8 · sheet 24 |
| Control height | touch 48 · desktop 40 (`AppDensity.desktop`) |
| Row height | touch 52–56 · desktop 40 |
| Screen padding | 16 |
| Cards | flat bordered; raised shadow only on dashboard KPI tiles |
| Inputs | `InputStyle.outlined` (field edges stay visible on dense forms) |
| Surfaces | `tonal`, or `eyeComfort` for long sessions |
| Data | tabular figures, end-aligned numbers, status pills with icons, sticky table headers |
| Motion | functional 150–250 ms: list insert/remove, state cross-fades, chart value changes |
| Emoji fit | KPI tiles and section headers, if the user wants them |

Typical moves: KPI row at the top, filter chips under the app bar, table + detail pane on wide windows, clear status tones from `AppPalette`.

---

## Modifier: Eye comfort (any direction)

For apps used for hours (ledgers, admin, reading, field tools): `AppThemeConfig(surfaces: SurfaceStyle.eyeComfort)`.

- Dimmed warm neutrals; no `#FFFFFF` surfaces, no `#000000` text.
- Scaffold = `surface` (warm paper), cards = `surfaceContainerLowest` (lighter, never pure white).
- The template's values keep onSurface ≥ 10:1, onSurfaceVariant ≥ 5.5:1, outline ≥ 3.2:1 on every surface level in both modes. Re-run `contrast_test.dart` after any tweak.
- Pair with outlined inputs: filled fields lose their edges on low-contrast warm surfaces.

---

## Choosing quickly

- Money, health, trust → Soft Minimal, or Enterprise Dense for heavy data entry.
- Energy, youth, performance → Bold Contrast.
- Lots of reading → Editorial.
- Media and atmosphere → Glass & Depth.
- Kids, learning, habits → Playful.
- Long working sessions → add Eye comfort.

If the app already has a brand color, keep it as the seed with `DynamicSchemeVariant.fidelity`. If the user shared reference apps, derive the direction from them (`flutter-design-system` skill › study-reference-apps). Either way, write the brief (`identity.md`) before setting tokens: the direction narrows the choices, the brief makes them.

When a direction changes radius or density, update the tokens, not individual widgets: a 16 px card in an Enterprise Dense app is a token bug, not a screen bug.
