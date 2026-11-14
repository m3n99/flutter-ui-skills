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

**5. Motion** — "Where should things animate? (pick any)"
- **Cards**: entrance on load (fade + slight slide, staggered), press feedback, hover lift on desktop
- **Lists**: animated insert / remove, neighbours slide into place, reorder
- **Pages and views**: route transitions, tab switches, shared-element / container transform
- **Buttons**: press scale, spinner inside the button while saving, success check
- **Charts and numbers**: bars and lines move from old to new values, counters tween
- **Sheets and dialogs**: slide-up, keyboard-aware
- **Skeletons**: shimmer while loading

Add: "All motion stays 150–350 ms with standard easing and switches off when the system asks for reduced motion."

**6. Direction** (only when there is no design system yet) — "Any brand color or apps whose look you like? Otherwise I'll pick a direction that fits the domain." Options: the six directions in `directions.md`, "match these screenshots", or "you choose".

## Defaults when nobody answers

State the defaults in one line at the top of the work and carry on:

| Question | Default |
|---|---|
| Platforms | What the project folders contain (`android/`, `ios/`, `windows/`…) |
| RTL | Yes if any ARB / l10n file is `ar`, `he`, `fa` or `ur`; otherwise no |
| Look | **Don't default silently.** Build the first list screen with cards, show its screenshot and ask before doing the rest. Never fall back to bare `ListTile` rows: they read as unstyled |
| Emoji | None |
| Motion | Press feedback, skeleton shimmer, state cross-fades, list insert/remove, buttons with progress |
| Direction | From the domain (`directions.md` › Choosing quickly) |

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

**Motion** → build one reusable piece per surface and route every screen through it (`flutter-motion` skill): `Entrance` / `AnimatedItems` for cards and lists, `StateSwitcher` for states, `SubmitButton` for buttons, `AnimatedNumber` / `AppProgressBar` / chart durations for values, theme page transitions for routes. Durations from tokens, gated by `context.motion(...)`.

**Direction** → `directions.md`, then the `flutter-design-system` skill.
