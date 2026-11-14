# UI review checklist

Run before reporting UI work as done, against the code **and the screenshots** (flutter-ui-verify). Each item is pass / fail; fix fails first.

## System
- [ ] Built on the project's existing design system and names; no second system.
- [ ] No hard-coded colors, font sizes, radii, durations or off-scale spacing in changed widgets.
- [ ] New repeated styles went into the theme / tokens and DESIGN.md.
- [ ] Deliberate deviations recorded in DESIGN.md were respected.

- [ ] The screens match the agreed look (cards, plain rows or rich in DESIGN.md); nothing reads as unstyled defaults.
- [ ] `lint_ui.py --diff` is clean, or each finding is a marked, explained exception.

## Hierarchy
- [ ] The most important element is obvious within one second (size + weight + position).
- [ ] One primary action per screen and per sheet.
- [ ] Secondary text uses `onSurfaceVariant`; primary text `onSurface`.
- [ ] Spacing inside groups is smaller than between groups.
- [ ] Edges align: icons, text and cards share the same start line.
- [ ] At least one signature element of the direction.

## Shapes
- [ ] One radius family per screen; nested shapes concentric while the gap < outer radius.
- [ ] No card in a card; no double borders; no stacked shadows.
- [ ] Same card type → same padding, radius and border.
- [ ] Shadows only on floating elements and raised KPI tiles.

## Status and selection
- [ ] Every status has an icon + label (never color alone); business states use palette tones, not `error`.
- [ ] Selected chips show a check; selected rows have fill + selected semantics.
- [ ] A few single-choice chips wrap (never scroll) and every option is on screen at 360 px × 1.3; an inline label sits in the same wrap.
- [ ] Tinted containers (pills, tiles, selected chips) read as soft tints in light mode and deep tones in dark mode, not solid blocks.

## States
- [ ] Loading uses skeletons shaped like the content (all data screens).
- [ ] Empty (first use / no results / nothing to do) and error (what failed + Retry) states exist.
- [ ] Refresh keeps content visible.

## Messages
- [ ] One message component; messages name the thing; errors say what failed and what to do.
- [ ] Messages with actions close by themselves (`persist: false`).
- [ ] Destructive actions confirm and/or offer Undo (hide → Undo → commit on close).
- [ ] Saves can't be submitted twice.

## Sheets and forms
- [ ] Sheets use the shared anatomy: header + ✕, scrolling body, sticky footer; secondary start (label width), primary end.
- [ ] Filter sheets: "Clear all" in place, "Apply (n)".
- [ ] Form save bar stays above the keyboard; labels above fields; keyboard types, input actions, autofill set.
- [ ] Validation after first submit; warnings don't block.
- [ ] Every form renders in create and edit mode; edit mode fills its controllers outside `build`.
- [ ] Pick-one sheets close on the tap that chooses (no Apply).

## Platforms
- [ ] Touch: targets ≥ 48 px (sheet test passes `androidTapTargetGuideline`).
- [ ] Desktop: hover, click cursor, focus, visible scrollbars, tooltips, 40 px density, shortcuts for the main actions.
- [ ] Layout adapts at 600 / 840 / 1200; content capped (forms 640, dashboards 1440).
- [ ] List-detail: the pane has a visible ✕ with a tooltip, a second click on the open row deselects, Esc closes it.
- [ ] FABs on the tabs of an IndexedStack shell have `heroTag: null`; the shell case (all tabs mounted, a route pushed) passes.

## RTL (if applicable)
- [ ] Directional APIs only; pointing icons mirror.
- [ ] Numbers, dates, phones and amounts stay LTR.
- [ ] Arabic text has zero letter-spacing and readable line height.
- [ ] Charts mirrored with the value axis on the reading start.
- [ ] Amount fields: digits at the reading start, not glued to the currency; chevrons not swapped by hand.
- [ ] `check_glyphs.py` finds nothing missing: currency signs, `٫` `٬`, `✓` all in the font or its fallback.

## Printed documents (if the app prints)
- [ ] Sample PDFs for the typical case, every optional field empty and the longest content the forms allow, in each printed direction; block checks pass (inside the margins, stamp clear of text, page count).
- [ ] Every page rasterized and opened: signatures and footer present at the bottom; nothing cut at the margins; no bare labels or `null`.
- [ ] Growing blocks have line budgets the forms enforce; overlays are anchored to their block, not to a fraction of the page.
- [ ] LTR runs (numbers, dates, phones, amounts) are separate `pw.Text`s; Arabic joins correctly.

## Accessibility
- [ ] Light and dark pass `contrast_test.dart`.
- [ ] Text scale 1.3 doesn't overflow or clip (layout test).
- [ ] Icon-only buttons have tooltips; rows merge semantics; decorative emoji/icons excluded.

## Motion
- [ ] Only the surfaces chosen in intake animate; durations from tokens; reduced motion respected.
- [ ] Lists keep item state on insert/remove; charts and numbers animate from previous values.
- [ ] No infinite animations besides loading indicators; controllers disposed.

## Verification
- [ ] `flutter analyze` clean for changed files; existing tests still pass.
- [ ] Layout matrix and sheet tests pass.
- [ ] Screenshots rendered and **looked at** (light, dark, 1.3 text scale, RTL if applicable, desktop if applicable), contact sheets first.
- [ ] More than three screens touched, or a first pass: the `flutter-ui-reviewer` agent reviewed them.

## Scope and records
- [ ] State management, routing, DI untouched (presentation-only) unless asked.
- [ ] DESIGN.md updated; UI_PASS.md ticked with decisions and open questions.
