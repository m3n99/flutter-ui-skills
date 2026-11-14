# Accessibility

Accessible UI is also better-looking UI: clear contrast, real hierarchy, comfortable targets. Target WCAG 2.2 AA.

## Contrast

| Element | Minimum |
|---|---|
| Body text and labels | 4.5:1 |
| Large text (≥ 24 px regular, ≥ 18.66 px bold) | 3:1 |
| Icons that carry meaning, input borders, focus rings, chart lines | 3:1 |
| Disabled controls | exempt (but still legible) |

- `contrast_test.dart` (flutter-ui-verify) checks every text role on every surface level, containers, inverse surface and palette tones, in light and dark. Run it after any palette change, brand override or eye-comfort tweak.
- Text over images or gradients: check the worst spot, add a scrim (`surface` at 0.6–0.8) when needed.

## Never color alone

- Status: icon + label (`StatusPill` requires an icon).
- Selected chips: check mark + fill.
- Errors in fields: error text, not only a red border.
- Charts: labels, patterns or direct annotations when series colors are close; tooltips with values.
- Links in text: underline or weight, not only `primary` color.

## Targets and spacing

- ≥ 48 × 48 px on touch platforms (`MaterialTapTargetSize.padded`; check with `androidTapTargetGuideline`). The visual control can be smaller; the target can't.
- ≥ 8 px between adjacent targets.
- Desktop: 40 px controls are fine with a mouse (`AppDensity.desktop`).

## Semantics

- Icon-only buttons: `tooltip` (also becomes the semantic label).
- Custom tappables: use `InkWell` / buttons (they bring semantics), or `Semantics(button: true, label: …)`.
- List rows: `MergeSemantics` so a row reads as one item ("Blue Harbor Café, 842 dollars, due soon").
- Decorative elements (emoji badges, illustrations, dividers): `ExcludeSemantics`.
- Animated numbers: expose the final value (`AnimatedNumber` does), not every intermediate frame.
- Charts: a one-sentence summary label.
- Selection in lists: `Semantics(selected: true)`.
- `labeledTapTargetGuideline` in tests catches unlabeled tappables.

## Text scaling

- Layouts survive text scale 1.3 and 1.6 (tested) and stay usable at 2.0. When the width ÷ text scale drops under 340 (`context.isNarrow`), stack what sits side by side (`layout.md` › Big fonts).
- Never clamp the app's text scaling. If a fixed area really can't grow (a tab bar label), clamp that widget only (`MediaQuery.withClampedTextScaling(maxScaleFactor: 1.5)`), not the app.
- Values in tiles shrink to fit (`FittedBox`) rather than overflow; labels wrap to 2 lines.
- Emoji and icons inside badges don't scale with text (they are icons).

## Focus and keyboard

- Visible focus on every interactive element (ink focus highlight or a 2 px outline).
- Logical traversal order matching the visual order, also in RTL (`FocusTraversalGroup`).
- Forms: `textInputAction: next` moves through fields; Enter submits on desktop.
- Dialogs and sheets trap focus and return it to the opener when closed (default routes do).
- Escape closes dialogs, sheets and menus.

## Motion

- Respect `MediaQuery.disableAnimationsOf(context)`: every duration through `context.motion(...)`; shimmer, entrance and parallax off.
- No flashing more than 3 times per second.
- Motion never carries meaning alone (a shake on error comes with an error message).

## Screen readers

- Announce results that have no visual message: `SemanticsService.announce('3 invoices match', textDirection)`.
- Loading states: the skeleton container gets `Semantics(label: 'Loading invoices')`.
- Test with TalkBack / VoiceOver / Narrator on the main flows at least once per release.
