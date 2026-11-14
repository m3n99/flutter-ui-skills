# Identity: a look that belongs to this app

Tokens make an app consistent. They don't make it *this* app. Left to defaults, every generated Flutter app lands in the same place: an indigo or purple seed, Inter or Roboto, everything in identical rounded cards, a greeting header over a 2 × 2 grid of KPI tiles. It is tidy and nobody could say what the app is about.

A direction (`directions.md`) is the chassis: density, depth, how round, how lively. The identity comes from a **brief** about this app's subject, written before any token is set. Skip this file only when the project already has a design system and a DESIGN.md with a brief: then you build inside that identity.

## 1. The brief: five lines before any token

| Line | Write | Not |
|---|---|---|
| **Subject** | what the app is, in its own world's words: "the notebook where a shopkeeper tracks who owes him and which checks fall due" | "a finance app" |
| **Audience and setting** | who, where, for how long, in what light, with which hand: "one shop owner, at the counter, glancing between customers" | "users" |
| **The job** | the one thing the app must make easy; it becomes the primary thing on the home screen | a feature list |
| **Feeling** | three words that rule something out: "plain-spoken, trustworthy, unhurried" | "modern, clean, user-friendly" |
| **Signature** | one element from the subject's world that the app is remembered by (§ 2) | "nice cards" |

When the user hasn't said these, propose them yourself from what the project shows (name, data model, strings, store listing) and confirm in the intake round (`intake.md` › Direction): one short message, five lines, "is this right?". What the user fixes always wins: a brand color, a font, "make it look like app X".

## 2. Find the signature in the subject's world

Distinctive choices come from the subject's materials, tools, places and habits, not from a style gallery.

| Look at | It gives you |
|---|---|
| Materials and documents (a ledger page, a receipt, a prescription, a boarding pass) | rules and columns, a stamp, a perforated edge, a ticket notch, how totals are set |
| Tools and objects (a scoreboard, a stopwatch, a kitchen scale, a siren light) | numerals, dials, rings, stripes, a status light |
| Places (a pitch, a clinic, a market stall, a workshop) | color pairs, floor markings, signage |
| How its people write (amounts, dates, names, abbreviations; in Arabic: Naskh for reading, Kufi for signs, Ruq'ah for handwriting) | type choice, number style, what a "row" looks like |
| The brand, if there is one (logo, shopfront, packaging) | the seed color, a shape, a word |

Signatures that are cheap to build in Flutter and carry meaning:

| App | Signature | Built with |
|---|---|---|
| Debt ledger | amounts set as a ruled column in tabular figures with a hairline above each total, like a ledger page; a rotated "paid" stamp on settled rows | `Divider`, `FontFeature.tabularFigures`, `Transform.rotate` on a bordered pill |
| Football trivia | a scoreboard band (big tabular numerals on a dark strip) and answer buttons shaped like shirt-number badges | one `ShapeBorder`, `displayMedium` |
| News reader | serif headlines at display size with the section's color as a 4 px rule on the start edge | `BorderDirectional(start:)`, a serif family |
| Ambulance trip log | each trip as a route line (dot, line, dot) from pickup to drop-off, with the time in large numerals | a 20-line `CustomPainter` |
| Habit tracker | the week as seven rings that fill | `CircularProgressIndicator` with tokens |
| Recipe app | the ingredient list as a tear-off shopping slip with check boxes | a notched `ShapeBorder` |

One signature, in one to three places (the home hero, the record card, the empty state). Everywhere else stays quiet, which is what makes the signature visible. Build it once as a shared widget, from tokens, and record where it may appear.

## 3. Decide five things from the brief

**Color.** Seed from the brand or the subject (ink blue-black, check-paper green, pitch green, saffron), never the template's placeholder. Name the palette, four to six colors with a job each: ink, paper, accent, and the status tones. The neutrals carry more of the mood than the accent: tint the surfaces toward the seed (`tonalSpot` does it lightly; `SurfaceStyle.eyeComfort` gives warm paper; `schemeOverride` sets exact surfaces). One accent does the pointing; a second color appears only if the content has two real categories. Decide which mode is home: an app used at night in a vehicle is dark-first. Then the contrast and soft-container tests.

**Type.** The typeface is most of the personality, and the cheapest change. Choose for the script first, then the feeling:

| Feeling | Latin | Arabic |
|---|---|---|
| Neutral, technical, clear figures | IBM Plex Sans, Source Sans 3 | IBM Plex Sans Arabic, Almarai |
| Friendly, rounded | Nunito Sans, Figtree, Rubik | Tajawal (no ₪: add a fallback), Rubik, Baloo Bhaijaan 2 |
| Geometric, confident | Manrope, Outfit, Plus Jakarta Sans, Sora | Readex Pro, Cairo |
| Characterful | Space Grotesk, Bricolage Grotesque, Instrument Sans | Noto Kufi Arabic (headlines), Changa |
| Reading | Newsreader, Literata, Source Serif 4, Fraunces (display) | Noto Naskh Arabic, Amiri (display) |

Inter and Roboto are fine choices when chosen; they are tells when they're just what was there. One family is enough; a second only when clearly different (serif display over sans body). Decide how big the one big thing is: a display size three or four times the body gives a screen a focal point that weight alone doesn't. When numbers are the content (money, scores, times), pick the family by its figures and use tabular figures. Bundle the font files (runtime font fetching flashes and fails offline), set `AppThemeConfig(fontFamily:, fontFamilyFallback:)`, and run `check_glyphs.py`.

**Shape.** Radius is temperament: 4–8 precise, 12–16 neutral, 20–28 friendly, pills playful. Set `AppRadius.card` / `.control` once. Not everything is a card: a ledger or a reading app carries structure with rules, columns and whitespace; cards are for things that are objects (a record, a tile).

**Rhythm.** Screen padding, row height and section gaps are tokens too. Give each screen one dense area and one open one; equal weight everywhere is what "flat hierarchy" looks like.

**Icons and pictures.** One icon family in one style (`Icons.*_rounded` or `*_outlined` throughout, or the project's icon package), sized by tokens. Empty states get a simple motif from the subject (the signature works well) drawn with a `CustomPainter` or one SVG, not stock blobs. Photos get fixed aspect ratios and one treatment.

## 4. The sameness check

Write the plan in six lines: palette (named), typeface, radius and card style, the home screen's primary thing, the signature, the motion level. Then ask of each line: **if this were a different app in another field, would the line still fit?** A line that would fit any app was a default, not a decision: redo it from the brief and say what changed.

Defaults that show up whatever the subject (fine when the brief calls for them, tells when it doesn't):

1. `ColorScheme.fromSeed(Colors.deepPurple)`, the Material baseline purple, or an indigo seed with no brand behind it.
2. Roboto or Inter because nothing was chosen; every title the same size and weight.
3. Every piece of content in the same rounded card with the same padding.
4. A 2 × 2 grid of KPI tiles, each with an icon in a tinted circle, on top of every home screen.
5. "Good morning, {name} 👋" with an avatar and a bell, in an app with no account and no notifications.
6. A gradient hero card with a big white number.
7. An icon in a tinted circle in front of every list row, though all rows are the same kind.
8. ALL-CAPS tracked labels over every section; "See all" on every section; emoji standing in for icons.
9. App bar actions, a FAB and bottom navigation all present because they exist, not because the flows need them.
10. Placeholder words: "Welcome back!", "Something went wrong", "No data".

## 5. Spend boldness in one place

The signature and the screen's primary thing get the design budget. Everything around them is disciplined: neutral surfaces, one accent, standard components, the tokens. After the screenshots are rendered, take one thing away from each screen: a border, a tint, an icon, a label that carries no information. Screens improve more often by removal than by addition.

## 6. Record it

DESIGN.md › *Brief* holds the five lines, the named palette, the typeface, and the signature with the places it appears. Every later session reads it first; the reviewer checks screenshots against it ("could this be any app?").

## Worked example

> **Subject:** a shopkeeper's notebook of who owes what and which checks fall due. **Audience:** one owner, Arabic, phone at the counter, quick looks between customers. **Job:** see who to call today. **Feeling:** plain-spoken, trustworthy, unhurried. **Signature:** the ledger column.

- **Color:** ink blue-black `#1F2A44` as the seed (`fidelity`), warm paper surfaces (`eyeComfort`), check-green for settled, stamp-red for returned and overdue, pencil grey for details. No second accent.
- **Type:** IBM Plex Sans Arabic for its figures; amounts in tabular figures; the one big number on the home screen is "due this week" in `displaySmall`.
- **Shape:** radius 10 / 8, paper-like rather than bubbly. One card per customer; inside it, checks are ruled rows, not cards.
- **Home:** today's due and overdue list with a call button on each row, not a KPI grid.
- **Signature:** every total sits under a hairline at the end edge, like a ledger; settled rows carry a small rotated "paid" stamp. Used on the customer card and the month summary only.
- **Sameness check:** the first draft had an indigo seed, a KPI grid and a greeting header. All three would fit any app, so the seed became ink, the grid became "who to call today", and the greeting went.
