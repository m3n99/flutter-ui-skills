# Reviewing screenshots

Open each PNG with the Read tool. Review it like a product designer would, against DESIGN.md and the other screenshots. Name the file in every finding.

Start with the contact sheets (`test/ui/screenshots/contact_sheets/<case>.png`): light, dark, text scale 1.3 in RTL and desktop side by side make inconsistencies jump out (a tile saturated only in dark mode, a label that wraps only at 1.3). Then open single shots for the details below.

## Per screenshot

1. **One-second test**: what's the primary thing and the primary action? Are they obviously primary (size, weight, position, color)? Is there exactly one filled button?
2. **Alignment**: draw imaginary vertical lines: do icons, titles, values and cards share start edges? Anything 2–4 px off?
3. **Spacing rhythm**: tighter inside groups than between them? Any gap that isn't on the 4-pt scale? Equal gaps everywhere (flat page)?
4. **Typography**: how many sizes and weights are visible (more than ~4 sizes is noise)? Secondary text muted? Numbers tabular and aligned in columns?
5. **Color**: one accent; status shown with icon + label, not color alone; nothing that looks like a raw default (purple tint, grey-50 boxes); dark mode equally intentional.
6. **Shapes**: one radius family; nested corners concentric; no card in a card; no double borders; shadows only on floating elements / KPI tiles.
7. **Density**: comfortable on phones (48 px targets), compact on desktop; nothing cramped or oversized for the platform.
8. **Truncation and clipping**: important text cut with "…" (names, amounts, button labels)? Anything clipped at text scale 1.3? Labels on two lines that should fit?
9. **States**: does the skeleton match the content's shape? Empty and error states say what happened and what to do? Loading on every data screen (no lone spinners)?
10. **RTL** (if applicable): layout mirrored, pointing icons mirrored, numbers / dates / phones still LTR, primary button on the left in footers, charts reading right to left.
11. **Wide windows**: content capped, no lines of text 1,200 px long, no huge empty areas, navigation rail instead of a stretched bottom bar, visible scrollbars.
12. **Consistency**: the same component looks the same across screenshots (cards, pills, headers, sheets).
13. **Signature**: is there at least one element of the chosen direction, or could this be any app?

## Across the set

- Compare light vs dark of the same screen: same hierarchy, nothing disappearing (borders, dividers, disabled states).
- Compare 1.0 vs 1.3 text scale: what wrapped, what truncated, what overflowed.
- Compare phone vs desktop: did the layout adapt, or just stretch?
- Compare with screenshots from before the change: everything that moved should have been intended.

Printed pages (rasterized PDFs) have their own order, bottom of the page first: `references/printed-documents.md` › Rasterize and look.

## Severity

- **High**: broken or inaccessible: overflow, clipped or unreadable text, contrast failures, broken dark mode or RTL, tiny targets, missing empty/error states, a primary action off screen or under the keyboard.
- **Medium**: dated or inconsistent: default tints, heavy shadows, no hierarchy, off-grid spacing, two primary buttons, spinner-only loading, a sheet laid out differently from the others.
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
