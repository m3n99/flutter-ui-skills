# Design directions

Pick one direction per app and apply it everywhere. Mixing directions (glass cards next to flat enterprise tables) is what makes an app feel unfinished.

Each direction is a set of token values. Plug them into `AppTheme.seed`, `AppTheme.fontFamily`, `AppRadius`, and the `DynamicSchemeVariant`.

---

## 1. Soft Minimal (default when unsure)
**Fits:** fintech, productivity, health, SaaS companions, most B2C.
**Feel:** calm, airy, confident.

| Token | Value |
|---|---|
| Seed | Indigo `#4F46E5`, teal `#0F766E`, or the brand color |
| Scheme variant | `DynamicSchemeVariant.tonalSpot` |
| Font | Inter, Manrope, Plus Jakarta Sans (Arabic: IBM Plex Sans Arabic) |
| Radius | cards 16, inputs/buttons 12, sheets 24 |
| Surfaces | scaffold `surface`, cards `surfaceContainerLowest` (light) / `surfaceContainer` (dark) |
| Borders | hairline `outlineVariant` at 60% |
| Shadows | none on cards; `softShadow` on floating CTA only |
| Density | generous: 20 screen padding, 24 between sections |
| Motion | 200–300 ms ease-out, subtle scale on press |

Signature moves: large bold headline at the top of the scroll (`SliverAppBar.large` or a custom header), muted secondary text, one accent color used sparingly.

---

## 2. Bold Contrast
**Fits:** fitness, media, crypto, consumer apps that want energy.
**Feel:** punchy, high-contrast, editorial-sporty.

| Token | Value |
|---|---|
| Seed | Saturated: `#FF5A1F`, `#7C3AED`, `#E11D48` |
| Scheme variant | `DynamicSchemeVariant.vibrant` or `fidelity` (keeps the exact brand hue) |
| Font | Satoshi, General Sans, Sora, Space Grotesk (Arabic: Cairo, Readex Pro) |
| Radius | cards 20–24, buttons pill (`StadiumBorder`) |
| Surfaces | dark-first; hero cards use `primaryContainer` or a two-stop gradient of primary → tertiary |
| Typography | headlines w800, tight tracking (-0.5 to -1.0), big numbers for stats |
| Motion | snappier (150–220 ms), staggered list entrances |

Signature moves: oversized numerals, full-bleed hero card, pill buttons, icon in a filled tinted circle.

---

## 3. Editorial
**Fits:** news, reading, journaling, recipes, portfolios.
**Feel:** typographic, quiet, magazine-like.

| Token | Value |
|---|---|
| Seed | Near-neutral: `#3F3F46`, warm `#7C5C3B` |
| Scheme variant | `DynamicSchemeVariant.neutral` or `monochrome` |
| Font | Headlines serif (Fraunces, Newsreader, Source Serif 4), body sans (Inter) (Arabic: Noto Naskh Arabic for body, Amiri for display) |
| Radius | small: 8–12; images 12 |
| Surfaces | flat, almost no borders; dividers carry structure |
| Typography | body 17/1.6 for reading screens, max line length ~65 characters (cap width at 600 on tablets) |
| Motion | minimal; fades only |

Signature moves: big images with 3:2 or 4:5 aspect, serif titles, small caps labels (labelSmall + letterSpacing 1.2 + uppercase), generous whitespace.

---

## 4. Glass & Depth
**Fits:** music, weather, smart-home, premium/lifestyle apps.
**Feel:** layered, luminous, premium.

| Token | Value |
|---|---|
| Seed | Deep blue/violet `#312E81`, or derived from content artwork |
| Scheme variant | `DynamicSchemeVariant.content` |
| Background | gradient or blurred artwork behind content |
| Cards | `ClipRRect` + `BackdropFilter(ImageFilter.blur(sigmaX: 20, sigmaY: 20))` + fill `surface.withValues(alpha: 0.55)` + 1px border `onSurface.withValues(alpha: 0.08)` |
| Radius | 20–28 |
| Motion | parallax on scroll, Hero transitions on artwork |

Rules: blur is expensive. Use it on at most 2–3 elements on screen, never inside long scrolling lists. Ensure text contrast ≥ 4.5:1 over the busiest part of the background.

---

## 5. Playful
**Fits:** kids, education, habits, social, games.
**Feel:** friendly, rounded, colorful.

| Token | Value |
|---|---|
| Seed | Warm `#F59E0B`, `#10B981`, `#8B5CF6` |
| Scheme variant | `DynamicSchemeVariant.expressive` or `rainbow` |
| Font | Nunito, Baloo 2, Fredoka (Arabic: Baloo Bhaijaan 2, Tajawal) |
| Radius | 24+ everywhere, pill buttons |
| Color | each category gets its own container color (primary/secondary/tertiaryContainer + palette) |
| Motion | springy (`Curves.elasticOut` sparingly, `easeOutBack` for pops), confetti/success moments |

Signature moves: illustrations in empty states, chunky 56px buttons, progress rings, emoji-sized icons.

---

## 6. Enterprise Dense
**Fits:** admin panels, field-service, CRM, logistics, internal tools.
**Feel:** efficient, trustworthy, information-rich without clutter.

| Token | Value |
|---|---|
| Seed | Blue `#2563EB` or slate `#334155` |
| Scheme variant | `DynamicSchemeVariant.tonalSpot` |
| Font | Inter, Roboto Flex (Arabic: IBM Plex Sans Arabic) |
| Radius | 10–12 cards, 8 inputs |
| Density | `VisualDensity.compact` on lists, 16 screen padding, 12–16 section gaps |
| Data | tabular figures (`FontFeature.tabularFigures()`) for numbers, `StatusPill` for states, sticky section headers |
| Motion | functional only (150–200 ms) |

Signature moves: KPI row at the top, filter chips under the app bar, dense but aligned rows with right-aligned numbers, clear status colors from `AppPalette`.

---

## Choosing quickly
- Money, health, trust → Soft Minimal or Enterprise Dense.
- Energy, youth, performance → Bold Contrast.
- Lots of reading → Editorial.
- Media and atmosphere → Glass & Depth.
- Kids, learning, habits → Playful.

If the app already has a brand color, keep it as the seed and use `DynamicSchemeVariant.fidelity` so the primary stays on-brand.
