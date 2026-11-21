# Color when the user has none

A palette is chosen, not defaulted. When the user names no color, find the app's own first; when there is none, look at what designers have already put together on real palette sites, check it the way the theme will use it, and show the user three options before building. The template's teal seed and the purple and indigo generated apps fall back on are never the answer (`identity.md` › defaults).

Order:

1. [The app's own color](#1-the-apps-own-color), if it has one.
2. [Search real palettes](#2-search-real-palettes) that fit the brief.
3. [Check and rank them](#3-check-and-rank) with `scripts/palette.py`.
4. [Show three](#4-show-three) and let the user pick (this is the intake's color question).
5. [Apply and record](#5-apply-and-record), then render.

The user's own answer always wins, at any step: "use our green", "something like Revolut", a hex code, a screenshot.

## 1. The app's own color

Look before searching: a brand color the user forgot to mention is better than any palette site.

| Where | What to read |
|---|---|
| The launcher icon and splash | `assets/` icon files, `flutter_launcher_icons` and `flutter_native_splash` config in `pubspec.yaml` (`color:`, `background_color:`) |
| Android | `android/app/src/main/res/values/colors.xml`, `launch_background.xml` |
| iOS | `ios/Runner/Assets.xcassets` (AccentColor, LaunchBackground), `LaunchScreen.storyboard` |
| Web | `web/manifest.json` (`theme_color`, `background_color`), `web/index.html` |
| The code | existing `Color(0x…)` constants, a theme file, a logo SVG's `fill` |
| The world | the business's website, shopfront, packaging, store listing (ask) |

Found one → it is the primary (`fidelity` keeps its hue). Search the sites below only for its companions, with that color **locked**: Coolors and Huemint both lock a color and generate around it.

## 2. Search real palettes

Turn the brief into search words: the **subject** and the three **feeling words** (`identity.md` › The brief), plus light or dark if the brief says. "A ledger for a shop owner, trustworthy, calm, quick" searches *finance*, *calm*, *navy*, *paper*, *earth*. "Kids' Arabic reading, playful, warm, safe" searches *kids*, *warm*, *pastel*, *happy*.

Gather **six to ten candidates from at least two sources**, keeping each one's URL.

| Source | Good for | How to get the colors |
|---|---|---|
| **Color Hunt** (colorhunt.co) | Hand-picked four-color palettes, ranked by likes, browsable by mood and subject: `colorhunt.co/palettes/<tag>`. Tags: pastel, vintage, retro, neon, gold, light, dark, warm, cold, summer, fall, winter, spring, happy, nature, earth, night, space, rainbow, gradient, sunset, sky, sea, kids, skin, food, cream, coffee, wedding, christmas, halloween; colors too (blue, teal, mint, green, sage, beige, brown, navy…) | The palettes are drawn by script, so a plain fetch of the page has no hex codes. Open it in a browser, or find palette links in search results: a palette's URL **is** its colors, `colorhunt.co/palette/<four hex codes run together>`. |
| **Coolors** (coolors.co) | Trending and explore pages; a generator that locks colors (keep a brand color, generate the rest) | The URL **is** the palette: `coolors.co/264653-2a9d8f-e9c46a-f4a261-e76f51`. Browse with a browser, or take palette links from search results; the page itself may refuse a fetch. |
| **Figma palettes** (figma.com/color-palettes/) | Named palettes by color and mood, e.g. `figma.com/color-palettes/navy-blue/` | The page text holds the hex codes ("Copy Hex: #…"): fetch it, or save its text and pass it with `--file`. |
| **Realtime Colors** (realtimecolors.com) | Palettes already split into UI roles: text, background, primary, secondary, accent, shown on a whole page, with a contrast readout and a light/dark switch | The share link holds the roles: `realtimecolors.com/?colors=<text>-<bg>-<primary>-<secondary>-<accent>`. `palette.py` prints this link for every candidate, so the user can see each one on a real page. |
| **Adobe Color** (color.adobe.com, Explore and Trends) | Large curated collection, searchable by word, with trend sets by industry | Needs a browser; copy the hex codes from the palette's panel, or ask the user to paste them. |
| **Huemint** (huemint.com) | Palettes generated for a use (brand, a website with one to three accents), with colors you lock | Needs a browser; copy the hex codes. |
| **Happy Hues** (happyhues.co) | Palettes shown as a real page with roles named (background, headline, paragraph, button) | Copy the hex codes per role and pass them with `--roles`. |
| **Real products in the same field** | How the category uses color (calm fintech greens, food apps' warm reds) | `flutter-design-system` › `study-reference-apps.md`. Take the structure (how many accents, how loud, light or dark), never a competitor's brand color. |

With no browser and no reachable site (offline, or the sites refuse fetches), use the **curated library**: `python3 scripts/palette.py --tags` lists its tags, and `--curated finance calm` gives the palettes that have any of them. They were written for this plugin, cover common subjects, and pass every check as they are. Say in the report that the palette came from the fallback library, not from a search.

**What these sites are for, and what they aren't.** Most palettes there are made for posters and illustrations: five colors of equal weight. An interface needs two neutrals (text and background), one main color and at most one accent, roughly 60 % background, 30 % surfaces and text, 10 % color. Take a site palette as a source of hues that go together, not as five colors to spread over the screen. `palette.py` gives each color a role and says which colors to keep out of the UI.

## 3. Check and rank

Put every candidate through the script in one run:

```bash
python3 scripts/palette.py \
  https://colorhunt.co/palette/f9f7f7dbe2ef3f72af112d4e \
  https://coolors.co/1b4332-2d6a4f-52b788-d8f3dc-f9c74f \
  "https://www.realtimecolors.com/?colors=1b1b1e-faf9f6-1f4e79-d9e4ec-c8963e" \
  "#04529D #ED8171 #EE2835 #3A6963" \
  --curated finance calm
```

For each candidate it:

- **gives every color a role**: ink (text), paper (background), primary, secondary, accent. A Realtime Colors link brings its own; otherwise it decides by lightness and chroma, and makes a missing ink or paper from the primary's hue;
- **checks contrast as the UI will use it**: body text on the background, the primary as a text button and a link, a label on a filled button, the accent as an icon or chart mark, text on a light secondary used as a chip;
- **darkens a color that is too light for its job** (same hue) and says from what to what. A pastel primary stays in illustrations, its darker twin carries the buttons;
- **warns** about the generated-app purple and indigo, a primary that reads as an error, a neon primary that glares in dark mode, a poster palette with too many loud colors, an accent too close to the primary to stand out;
- **ranks** them: failures last; palettes found on real sources before the fallback library; then fewer warnings and adjustments, then better contrast.

The ranking sorts, it doesn't choose. Among the ones that pass, choose by the brief: does it feel like the three words? Would it fit an app in another field just as well (`identity.md` › The sameness check)? Pick three that differ in character, e.g. one calm, one warmer, one bolder, not three blues.

## 4. Show three

This is the intake's color question, answered with pictures instead of words:

```bash
python3 scripts/palette.py <the three> --preview palettes.png
```

The sheet shows each palette's roles with hex codes, then a light and an approximate dark mock-up: a total, a filled button, chips, rows and a link. Open it yourself first; a palette that looks wrong there will look wrong in the app. Then ask, with the sheet and each palette's Realtime Colors link:

> "No brand color yet, so here are three palettes from Color Hunt, Coolors and Figma that fit *calm, trustworthy, quick*: 1 Ledger ink (navy and brass), 2 Harbor (sea blue and sunset orange), 3 Olive (olive and harvest gold). I'd go with 1. Which one, or any color you'd rather keep?"

Recommend one and say why in a few words. When nobody is there to answer (an unattended run), take the recommendation, say so at the top of the report, and record it in DESIGN.md as a default to confirm.

## 5. Apply and record

```bash
python3 scripts/palette.py <the chosen one> --dart        # AppThemeConfig
python3 scripts/palette.py <the chosen one> --design-md   # the DESIGN.md › Color block
```

`--dart` writes the seeds: `seed` (primary, `fidelity` keeps its hue), `secondarySeed`, `tertiarySeed` (the accent) and `neutralSeed` (the background; surfaces, text and outlines are tinted toward its hue). Each role gets its own Material tonal palette, so dark mode, the on-colors and the containers are derived and stay soft: nothing is hand-picked per mode. A secondary with almost no color of its own is left to Material.

Then:

- record the block in DESIGN.md › *Color* with the **source URL**, the roles, any adjustment, and the words from the brief it was chosen for, so a later session keeps it instead of choosing again;
- add the domain tones to `AppPalette` (`theming.md` › Semantic and domain colors). A red primary needs an error tone clearly apart from it;
- run `contrast_test.dart`, render the screens and look at light and dark (`flutter-ui-verify`). The script's dark mock-up is an approximation; the rendered app is the answer.

A palette from a site that fails, after its colors are adjusted, is not forced in: take the next one.
