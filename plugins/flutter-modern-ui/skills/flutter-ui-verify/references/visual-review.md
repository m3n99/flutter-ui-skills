# Reviewing screenshots

Open each PNG with the Read tool. Review it like a product designer would, against DESIGN.md and the other screenshots. Name the file in every finding.

Start with the contact sheets (`test/ui/screenshots/contact_sheets/<case>.png`): light, dark, text scale 1.3 in RTL, 1.6 and desktop side by side make inconsistencies jump out (a tile saturated only in dark mode, a label that wraps only at 1.3, a name squeezed to three letters at 1.6). Then open single shots for the details below.

Phone and tablet shots carry the system bars drawn on top (status bar with a camera cutout or the Dynamic Island, the navigation bar or home indicator): look at what they cover and what sits right against them.

## Against the brief, before the details

With DESIGN.md's brief beside the screenshots (`flutter-modern-ui` › identity, ux, writing):

1. **Whose app is this?** Cover the title: would you guess the subject from the colors, the type and the one signature element, or could it be any app? A default-looking seed, a stock font and identical cards everywhere are findings, not taste.
2. **Does the screen do its job?** Say its task in one sentence, then find the answer and the action on the screenshot. On the home screen, is the user's daily question answered first?
3. **Read the words alone.** Each button says what will happen; the same thing has the same name on every screen; empty and error text says what to do next.
4. **Take one thing away.** Name the element on each screen that carries no information (a border, a tint, an icon, a label) and remove it.

## Per screenshot

1. **One-second test**: what's the primary thing and the primary action? Are they obviously primary (size, weight, position, color)? Is there exactly one filled button?
2. **Alignment**: draw imaginary vertical lines: do icons, titles, values and cards share start edges? Anything 2–4 px off?
3. **Spacing rhythm**: tighter inside groups than between them? Any gap that isn't on the 4-pt scale? Equal gaps everywhere (flat page)?
4. **Typography**: how many sizes and weights are visible (more than ~4 sizes is noise)? Secondary text muted? Numbers tabular and aligned in columns?
5. **Color**: one accent; status shown with icon + label, not color alone; nothing that looks like a raw default (purple tint, grey-50 boxes); dark mode equally intentional.
6. **Shapes**: one radius family; nested corners concentric; no card in a card; no double borders; shadows only on floating elements / KPI tiles.
7. **Density**: comfortable on phones (48 px targets), compact on desktop; nothing cramped or oversized for the platform.
8. **Truncation and clipping**: important text cut with "…" (names, amounts, button labels)? Anything clipped at text scale 1.3 or 1.6? Labels on two lines that should fit? At 1.6, did paired rows stack instead of squeezing the name?
9. **Edges**: a header, a button or a bottom bar touching the status bar, the Dynamic Island or the navigation bar, or hidden under them? Everything near an edge needs the safe area plus a little padding.
10. **States**: does the skeleton match the content's shape? Empty and error states say what happened and what to do? Loading on every data screen (no lone spinners)?
11. **RTL** (if applicable): layout mirrored, pointing icons mirrored, numbers / dates / phones still LTR, primary button on the left in footers, charts reading right to left.
12. **Wide windows**: content capped, no lines of text 1,200 px long, no huge empty areas, navigation rail instead of a stretched bottom bar, visible scrollbars.
13. **Consistency**: the same component looks the same across screenshots (cards, pills, headers, sheets).
14. **Signature**: is the brief's signature element where DESIGN.md says it appears, and absent elsewhere?

## Across the set

- Compare light vs dark of the same screen: same hierarchy, nothing disappearing (borders, dividers, disabled states).
- Compare 1.0 vs 1.3 vs 1.6 text scale: what wrapped, what truncated, what overflowed, what stacked.
- Compare phone vs desktop: did the layout adapt, or just stretch?
- Compare with screenshots from before the change: everything that moved should have been intended.

Printed pages (rasterized PDFs) have their own order, bottom of the page first: `references/printed-documents.md` › Rasterize and look.

## Severity

- **High**: broken or inaccessible: overflow, clipped or unreadable text, contrast failures, broken dark mode or RTL, tiny targets, missing empty/error states, a primary action off screen or under the keyboard.
- **Medium**: dated, generic or inconsistent: an identity that would fit any app (default seed and font, no signature), a home screen that doesn't answer its question, placeholder wording, default tints, heavy shadows, no hierarchy, off-grid spacing, two primary buttons, spinner-only loading, a sheet laid out differently from the others.
- **Low**: polish: icon style mixing, 2 px misalignment, missing tabular figures, a gap that could be tighter.

## Reporting

| Screenshot | Where | Issue | Severity | Fix |
|---|---|---|---|---|
| `invoices__360_light_android_rtl_x1.3.png` | card footer | amount truncated to "$12,4…" | High | let the amount take its intrinsic width; customer name gets `Expanded` |

Lead with a two-line verdict, then the table, then what you'll fix now vs. what needs a decision.

## Limits of `flutter_test` screenshots

- Emoji render as boxes (no emoji font); judge emoji on a device.
- Fonts must be bundled and loaded, otherwise text is drawn as boxes.
- Shadows only appear because `visual_test.dart` sets `debugDisableShadows = false`.
- Network images don't load (use assets / placeholders); platform views (maps, web views, video) render empty.
- Animations are captured at one frame; use filmstrips for motion.
