# Intake: the questions to ask once

These answers change the character of the app, and the right answer varies a lot (a ledger app and a kids' app want different things). Ask them **once, early, in one round** — with the question tool when the session has one — and skip any that DESIGN.md already answers. Record the answers in DESIGN.md under *Decisions*.

## The questions

**1. Platforms** — "Which platforms ship: Android, iOS, Windows, macOS, Linux, web?"
→ Touch needs 48 px targets; desktop needs mouse density, hover, cursors, visible scrollbars, tooltips and shortcuts. Many apps ship both from one codebase.

**2. Right-to-left** — "Does the app use a right-to-left language (Arabic, Hebrew, Persian/Farsi, Urdu), only or alongside left-to-right languages?"

**3. Emoji** — "Would you like emoji in the UI?"
- none
- only on dashboard / KPI tiles
- on section headers too
- on empty states and success messages too

**4. Motion** — "Where should things animate? (pick any)"
- **Cards**: entrance on load (fade + slight slide, staggered), press feedback, hover lift on desktop
- **Lists**: animated insert / remove, neighbours slide into place, reorder
- **Pages and views**: route transitions, tab switches, shared-element / container transform
- **Buttons**: press scale, spinner inside the button while saving, success check
- **Charts and numbers**: bars and lines move from old to new values, counters tween
- **Sheets and dialogs**: slide-up, keyboard-aware
- **Skeletons**: shimmer while loading

Add: "All motion stays 150–350 ms with standard easing and switches off when the system asks for reduced motion."

**5. Direction** (only when there is no design system yet) — "Any brand color or apps whose look you like? Otherwise I'll pick a direction that fits the domain." Options: the six directions in `directions.md`, "match these screenshots", or "you choose".

## Defaults when nobody answers

State the defaults in one line at the top of the work and carry on:

| Question | Default |
|---|---|
| Platforms | What the project folders contain (`android/`, `ios/`, `windows/`…) |
| RTL | Yes if any ARB / l10n file is `ar`, `he`, `fa` or `ur`; otherwise no |
| Emoji | None |
| Motion | Press feedback, skeleton shimmer, state cross-fades, list insert/remove, buttons with progress |
| Direction | From the domain (`directions.md` › Choosing quickly) |

## Acting on the answers

**Platforms**
- Touch only → `AppDensity.touch`, `MaterialTapTargetSize.padded`; check with `androidTapTargetGuideline`.
- Desktop too → density by `TargetPlatform` (`AppDensity.forPlatform`), `references/adaptive.md`; test at 1366 and 1920 px.
- Web → treat as pointer on desktop browsers; check hover and keyboard focus.

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
