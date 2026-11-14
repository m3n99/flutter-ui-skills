# Intake: the questions to ask once

These answers change the character of the app, and the right answer varies a lot (a ledger app and a kids' app want different things). Ask them **once, early, in one round** — with the question tool when the session has one — and skip any that DESIGN.md already answers. Record the answers in DESIGN.md under *Decisions*.

## The questions

**1. Platforms** — "Which platforms ship: Android, iOS, Windows, macOS, Linux, web?"
→ Touch needs 48 px targets; desktop needs mouse density, hover, cursors, visible scrollbars, tooltips and shortcuts. Many apps ship both from one codebase.

**2. Right-to-left** — "Does the app use a right-to-left language (Arabic, Hebrew, Persian/Farsi, Urdu), only or alongside left-to-right languages?"

**3. The look: list style and visual richness** — "How should list screens and the app as a whole look?" This is the main design decision, and the one that costs a full redesign when guessed wrong. **Ask it even when the spec says "basic", "simple" or "clean"**: those words usually mean *uncluttered*, not *unstyled*. When the question tool supports previews, show these sketches:

```
Cards (recommended)            Plain rows                     Rich
╭──────────────────────────╮   Blue Harbor Café     $842.00   ╭──────────────────────────╮
│ Blue Harbor Café $842.00 │   INV-1042 · Nov 10   Due soon   │ (◷) Blue Harbor Café     │
│ INV-1042 · due Nov 10    │   ────────────────────────────   │     INV-1042     $842.00 │
│ ◷ Due soon               │   Kinetic Labs      $12,500.00   │     ◷ Due soon · Nov 10  │
╰──────────────────────────╯   INV-1041 · Nov 2     Overdue   ╰──────────────────────────╯
╭──────────────────────────╮   ────────────────────────────   ╭──────────╮ ╭──────────╮
│ Kinetic Labs  $12,500.00 │                                  │ (¤) Owed │ │ (!) Late │
│ ! Overdue                │                                  │  $20,508 │ │  $12,675 │
╰──────────────────────────╯                                  ╰──────────╯ ╰──────────╯
```

- **Cards**: one flat card per record (tonal fill, hairline border), status pill, amount aligned at the end; `assets/examples/records_screen.dart`.
- **Plain rows**: divider-separated `ListTile`s, denser, neutral surfaces; for data-heavy back-office screens. Still themed: `IconBadge` leading, muted subtitles, status pills.
- **Rich**: cards plus icon badges, tinted KPI tiles, charts and more motion; `assets/examples/dashboard_screen.dart`.

**4. Emoji** — "Would you like emoji in the UI?"
- none
- only on dashboard / KPI tiles
- on section headers too
- on empty states and success messages too

**5. Motion: how much, and where** — always asked **before the first screen is built**, in two parts, with the examples below so the user picks from something concrete. Ask even when the spec or the customer already hinted at motion ("keep it basic", "make it feel alive"): the hint becomes the recommended option, not the answer, because "basic" may still mean a calm fade and "alive" rarely means bouncing everything.

*a. "How much motion do you want?"*

| Level | What it feels like | Small example: invoices loading |
|---|---|---|
| **None** | Material's own motion only: ripples, page transitions, switches, sheets sliding up | the rows are simply there |
| **Soft** (recommended for most apps) | calm and quick: things fade in with a short rise, all at once; a light press; no overshoot | the rows fade in together, rising 4 % of their height, in 250 ms |
| **Expressive** | noticeable and lively: rows rise one after another, grids scale in, counters roll, a pop on success, a shake on errors | the rows rise 12 % one after another, 40 ms apart, in 300 ms each |

*b. "Where should it move?" (pick any)*, each place with its soft and expressive version:

| Place | Soft | Expressive |
|---|---|---|
| **Cards and lists on load** | fade + 4 % rise, together | 12 % rise, staggered row by row (first 8) |
| **List changes** (add, delete, filter) | rows fade and fold; neighbours slide | the same, grid tiles also scale in from 92 % |
| **Numbers and charts** | values tween from old to new; a changed badge grows 8 % | the same, a little longer; a changed badge pops 18 % |
| **Buttons** | ripple, 2 % press, spinner while saving, a check when done | 4 % press, spinner, a check that overshoots into place |
| **Errors** | a 4 px shake of the button, with the message | an 8 px shake, with the message |
| **Pages** | the platform's transition | container transform from a card into its page, shared axis between steps (`flutter-motion` › recipes) |
| **Sheets and dialogs** | Material's slide-up | Material's slide-up |
| **Loading** | skeleton shimmer | skeleton shimmer |

Add: "Every level keeps motion short (150–450 ms), switches it off when the system asks for reduced motion, and never moves what you're reading."

**6. The brief and the direction** (only when there is no design system yet) — don't ask "what style do you want?"; propose and let the user correct. Write the five-line brief (`identity.md` › The brief) from what the project shows (its name, data model, strings, store listing), with the direction you'd pick and why:

> **Subject:** the notebook where a shopkeeper tracks who owes him and which checks fall due. **Audience:** one owner, at the counter, quick looks. **Job:** see who to call today. **Feeling:** plain-spoken, trustworthy, unhurried. **Signature:** amounts set like a ledger column. **Direction:** Soft Minimal on warm paper, ink-blue accent.
>
> "Is this right? Any brand color, logo or apps whose look you like?"

Options: "yes", corrections, "match these screenshots" (`flutter-design-system` › study-reference-apps), or a brand color and font to keep. What the user fixes always wins.

## Defaults when nobody answers

State the defaults in one line at the top of the work and carry on:

| Question | Default |
|---|---|
| Platforms | What the project folders contain (`android/`, `ios/`, `windows/`…) |
| RTL | Yes if any ARB / l10n file is `ar`, `he`, `fa` or `ur`; otherwise no |
| Look | **Don't default silently.** Build the first list screen with cards, show its screenshot and ask before doing the rest. Never fall back to bare `ListTile` rows: they read as unstyled |
| Emoji | None |
| Motion | **Ask anyway** (it's quick, and the user may be back before the first screen is done); until then soft, on cards and lists on load, list changes, numbers, buttons and loading. A spec that says "basic" points to none or soft: confirm which |
| Brief and direction | Write the brief yourself from the project and state it in one line at the top of the work; the direction from the domain (`directions.md` › Choosing quickly). Never the template's placeholder seed and font unchanged |

## Acting on the answers

**Platforms**
- Touch only → `AppDensity.touch`, `MaterialTapTargetSize.padded`; check with `androidTapTargetGuideline`.
- Desktop too → density by `TargetPlatform` (`AppDensity.forPlatform`), `references/adaptive.md`; test at 1366 and 1920 px.
- Web → treat as pointer on desktop browsers; check hover and keyboard focus.

**Look** → record it in DESIGN.md (*Look*). Cards: `AppCard` per record, `references/components.md` › Cards. Plain rows: a grouped list in one card or full-bleed rows with `Divider(indent:)`, still with `IconBadge`s, pills and muted subtitles. Rich: add `KpiTile`s, charts and entrances, `references/data-display.md`. The reviewer checks screens against this answer.

**RTL** → `references/rtl-arabic.md` from the first widget: directional APIs, `Ltr` for numbers, `AppScript.arabic` (zero tracking, taller line heights), mirrored charts, Arabic plural forms. Mixed LTR + RTL apps test both directions.

**Emoji** → an emoji is an icon, not text:
- fixed size: `TextScaler.noScaling`, 20 px on a 36 px badge (`EmojiBadge`);
- on a tinted badge of the tone's container color;
- one emoji per meaning, used consistently (📁 records, 💰 outstanding, 🚨 overdue, ✅ paid…);
- never the only carrier of meaning: keep the label;
- excluded from semantics (the label speaks);
- `flutter_test` has no emoji font: screenshots show boxes; devices render them in color.

**Motion** → record the level and the places in DESIGN.md (*Motion*), set `AppThemeConfig.motion` (`MotionLevel.none`, `.soft` or `.expressive`), and route every screen through one shared piece per place (`flutter-motion` skill): `Entrance` / `AnimatedItems` for cards and lists, `StateSwitcher` for states, `PressScale` (in `AppCard`) and `SubmitButton` for buttons, `AnimatedNumber` / `AppProgressBar` / chart durations for values, theme page transitions for routes. They read the level from the theme (rise, stagger, press, pop, shake); durations come from tokens through `context.motion(...)`, which also scales them by the level. A place the user didn't pick doesn't move, whatever the level.

**Brief and direction** → record the brief in DESIGN.md (*Brief*); take the seed, the typeface, the shapes and the home screen's content from it (`identity.md`), the density and depth from the direction (`directions.md`); then the `flutter-design-system` skill.
