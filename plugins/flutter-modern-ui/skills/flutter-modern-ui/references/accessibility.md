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
- `a11y_test.dart` measures the text each screen actually paints, on the pixels behind it: it catches the one-off color, the faded caption and the text on a photo that the token pairs can't see.
- A sheet's or dialog's scrim is judged on the result: the content behind must read as set aside, and the sheet's own text against its own surface, not against the scrim.
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
- **An icon's semantics follow its use, not the glyph.** Beside a visible label it is decoration (`ExcludeSemantics`, or `Icon` without `semanticLabel`); standing alone with meaning (a warning sign before a value) it gets a `semanticLabel`; as a control it gets a name and its state. The same `Icons.star` is all three in different places.
- **Toggles say their state**: an icon that switches (favourite, pin, mute) is `IconButton(isSelected: …, selectedIcon: …)` or `Semantics(toggled: …)`, so a screen reader hears "Pin, on", not just "Pin". Expand/collapse rows: `Semantics(expanded: …)`.
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
- **Announce a whole phrase, once.** A badge or counter that changes is read as "3 unread messages", not "3"; announce the settled value after a burst of changes, not every step; never move focus to announce. A banner that appears with news ("Back online") is a `Semantics(liveRegion: true)`; a toast that the user may need later (an error) stays on screen instead (`messages.md`).
- Loading states: the skeleton container gets `Semantics(label: 'Loading invoices')`.
- Test with TalkBack / VoiceOver / Narrator on the main flows at least once per release.

## WCAG 2.2 criteria that are easy to miss

The 2.2 additions mostly fail in apps by default. Each line: the criterion, what it means in Flutter, how to check.

| Criterion | In a Flutter app | Check |
|---|---|---|
| 2.4.11 Focus not obscured | The focused field or control is never hidden under the keyboard, a sticky save bar, a FAB or a banner. Give fields `scrollPadding` that includes the bar's height (`EdgeInsets.fromLTRB(20, 20, 20, 20 + barHeight)`), and keep the bar as the body's last child (`forms.md` › Long forms) | Tab through a long form on desktop; tap the last field on a phone |
| 2.5.7 Dragging movements | Every drag has a tap alternative: reorder → "Move up / Move down" in the row menu or a `ReorderableListView` handle plus menu items; swipe to delete → delete in the row menu; a slider → its value editable as text or ± buttons where precision matters; a map pan → search or zoom buttons | Do the task without dragging |
| 2.5.8 Target size (minimum) | Pointer targets ≥ 24 × 24 px with spacing, also on desktop where 40 px density applies; touch keeps ≥ 48 px | `a11y_test` on touch; by eye on desktop |
| 3.2.6 Consistent help | Help, contact or "How does this work?" sits in the same place on every screen that has it (the same overflow menu item, the same footer row) | Screenshots side by side |
| 3.3.7 Redundant entry | Don't ask again for what the user gave earlier in the same flow: carry it forward, prefill it, or offer it as a choice ("Same as billing address") | Walk the flow once |
| 3.3.8 Accessible authentication | No memory or puzzle test to sign in: allow paste and password managers (`AutofillGroup`, `autofillHints`, never block paste in password or code fields), offer a magic link, passkey or biometric path | Paste a password; fill from a manager |
| 2.2.2 Pause, stop, hide | Anything that moves by itself for more than 5 s (an auto-advancing carousel, a ticker) has a pause control, stops while focused or touched, and doesn't move with reduced motion | Wait on the screen; turn on reduced motion |
| 4.1.3 Status messages | Results, progress and errors with no focus change are announced (`SemanticsService.announce`, `liveRegion`) as full phrases | TalkBack / VoiceOver on the main flow |

