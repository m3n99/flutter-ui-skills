# UI review checklist

Run before reporting a UI task as done. Each item is pass/fail; fix fails before finishing.

## System
- [ ] No hard-coded colors, font sizes, radii or off-scale spacing in changed widgets.
- [ ] New repeated styles were added to the theme/tokens, not copy-pasted.
- [ ] Uses the project's existing design system names if one exists.

## Visual hierarchy
- [ ] The most important element is obvious within one second (size + weight + position).
- [ ] Exactly one primary action per screen.
- [ ] Secondary text uses `onSurfaceVariant`; primary text `onSurface`.
- [ ] Spacing inside groups is smaller than spacing between groups.
- [ ] Edges align: icons, text and cards share the same start line.
- [ ] One radius family; nested radii are reduced.
- [ ] At least one signature element from the chosen direction.

## States
- [ ] Loading uses skeletons shaped like content (or a stable inline spinner for actions).
- [ ] Empty state with icon, message and action where applicable.
- [ ] Error state with human message and retry.
- [ ] Refresh keeps existing content visible.

## Interaction
- [ ] Every tappable element has feedback and a ≥ 48×48 target.
- [ ] Icon-only buttons have `tooltip` / semantics labels.
- [ ] Destructive actions confirm or offer undo.
- [ ] Forms: correct keyboard types, input actions, autofill hints, keyboard doesn't cover the CTA.

## Robustness
- [ ] Light **and** dark themes look intentional.
- [ ] Text scale 1.3 doesn't overflow or clip.
- [ ] RTL works (directional insets/alignments, mirrored directional icons).
- [ ] Long strings truncate gracefully; numbers use tabular figures where they change.
- [ ] Safe areas respected; last list item clears the bottom inset/nav bar.
- [ ] Tablet width (≥ 600) doesn't stretch forms or text edge to edge.

## Motion and performance
- [ ] Animations use tokens (150–400 ms) and respect reduced motion.
- [ ] No `shrinkWrap` long lists, controllers are disposed, blur/shadows used sparingly.
- [ ] `const` constructors wherever possible.

## Scope
- [ ] State management, routing and DI untouched (presentation-only change unless asked).
- [ ] `flutter analyze` is clean for changed files (run it if the environment has Flutter).
