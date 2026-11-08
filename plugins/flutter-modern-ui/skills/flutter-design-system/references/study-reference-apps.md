# Deriving a direction from reference apps

When the user shares screenshots, screen recordings or names apps whose look they like, turn them into a direction and token values. Take **patterns** (rhythm, hierarchy, shape language, density, motion feel), never **identity** (logos, illustrations, mascots, exact brand colors, proprietary icon sets, product names).

## 1. Gather

- Ask for 3–6 screenshots (or app names) and **what they like about each** ("the calm cards", "how dense the table is", "the big numbers"). The why matters more than the pictures.
- Note device and platform for each (phone/tablet/desktop, iOS/Android/Windows), light or dark.
- If they only name apps, ask for screenshots: don't describe an app's UI from memory.

View the images with the Read tool.

## 2. Calibrate

Convert screenshot pixels to logical pixels before measuring: find the device scale from the image width (e.g. 1179 px wide iPhone screenshot = 393 pt at 3×; 1080 px Android = 360–412 dp at 2.625–3×). Use known components (status bar, nav bar, a standard button) as rulers.

## 3. Extract per reference

| Aspect | Look for |
|---|---|
| Palette | neutral temperature (cool grey, warm paper, pure white), how many accents, saturation, dark/light, how status is colored |
| Typography | family class (geometric, grotesque, humanist, serif), title : body size ratio, weights in use, tight or loose tracking, numerals |
| Shape | card and control radius, pill usage, nesting |
| Density | screen margin, row height, gaps between cards, control height |
| Depth | flat bordered, tonal layers, soft shadows, glass/blur |
| Iconography | outlined / rounded / filled, size, badges |
| Layout | header style, hero/summary blocks, grouping, navigation pattern |
| Motion (from video) | speed, entrances, list behavior, transitions |
| Signature | the one or two things that make it recognizable *as a style* |

Write one row per reference in a table.

## 4. Synthesize

- List what the references share; that's the direction. Where they disagree, follow what the user said they liked.
- Map to the closest direction in `../../flutter-modern-ui/references/directions.md`, then adjust its values: seed hue family, variant, font class, radius roles, control height, screen padding, card style, input style, surfaces (eye comfort?), motion character, emoji fit.
- Write a short "take / leave" list:
  - **Take**: generous whitespace, 16 px cards with hairlines, big tabular numbers, filter chips under the header.
  - **Leave**: their brand purple, their illustrations, their custom icon set, their name for features.
- Pick colors with the brand (or a neutral seed), not by sampling the reference's brand color.

## 5. Validate with one screen

Build one representative screen (dashboard or main list) with the derived tokens and real-looking data, screenshot it (flutter-ui-verify), and view it next to the references. Compare the **feel** (rhythm, hierarchy, density, calm vs energy), not pixels. Adjust tokens once, then roll out.

## 6. Record

In DESIGN.md › Direction: "Derived from references: A (cards, spacing), B (numbers, chips). Kept: …. Changed: …. Left out: …". Future sessions then extend the style without needing the screenshots again.
