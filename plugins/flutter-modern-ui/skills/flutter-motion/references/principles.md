# Motion principles

## What motion is for

1. **Feedback**: the app heard you (press scale, ripple, button progress, toggle pop).
2. **Continuity**: where did this come from and go to (hero, container transform, list insert/remove, sheet slide).
3. **State change**: something loaded, failed, emptied, updated (cross-fades, counters, chart values).
4. **Focus**: draw the eye to what changed (a new row growing in, a shake on the invalid field).

If an animation does none of these, it's decoration: cut it or make it optional.

## Durations (tokens)

| Token | ms | Use |
|---|---|---|
| `AppDurations.fast` | 150 | press, hover, toggles, color and border changes, small icon swaps |
| `AppDurations.medium` | 250 | state cross-fades, list insert/remove, expand/collapse, chips |
| `AppDurations.slow` | 350 | charts, progress bars, counters, larger layout changes |
| `AppDurations.page` | 450 | route transitions (Android's default since Flutter 3.38) |
| `AppDurations.stagger` | 40 per item, first 8 | staggered entrances |

Larger distance or area → longer duration, within the range. Exits are ~20 % faster than entrances.

Material 3 also exposes `Durations.short1` … `Durations.extralong4` (50–1000 ms); the tokens map onto that scale.

## Easing (tokens)

| Token | Curve | Use |
|---|---|---|
| `AppCurves.enter` | `Easing.emphasizedDecelerate` | elements arriving: entrances, inserts, sheets opening |
| `AppCurves.exit` | `Easing.emphasizedAccelerate` | elements leaving: removals, dismissals |
| `AppCurves.standard` | `Easing.standard` | small on-screen changes: progress, counters, color |
| `AppCurves.emphasized` | `Curves.easeInOutCubicEmphasized` | large moves that stay on screen: list item size, expanding panels |
| `AppCurves.pop` | `Curves.easeOutBack` | celebrations only (like, success, level-up) |

Linear only for continuous loops (shimmer, spinners).

## Choreography

- **One thing leads.** In a transition, the primary element moves first; secondary content follows by 30–60 ms.
- **Stagger lists** by 40 ms, first 8 items; the rest appear with the 8th. Never stagger 30 rows one by one.
- **Shared motion direction**: forward navigation moves toward the reading end (right in LTR, left in RTL); back reverses it.
- **Container transform** when a card opens into its detail: the card's shape grows into the page (`OpenContainer` or Hero with matching radius).
- **Fade-through** between unrelated views (tabs, top-level destinations): outgoing fades out, incoming fades in with a slight scale (0.92 → 1).
- **Shared axis** between related steps (wizard steps, list → filtered list): slide on one axis + fade.
- **Neighbours make room**: when an item is inserted or removed, siblings slide; nothing jumps.

## Continuity rules

- Animate from the current value, not from zero (counters, progress, charts, list positions).
- Keep identity: items matched by id keep their state across inserts, removes and reorders (`AnimatedItems`).
- Hidden content doesn't animate: hold values while `TickerMode` is off, play the change when shown.
- Don't replay entrances on rebuilds, refreshes or scroll.

## Accessibility

- Reduced motion (`MediaQuery.disableAnimationsOf(context)`; iOS "Reduce Motion", Android "Remove animations", Windows "Show animations" off): durations zero, no shimmer, no parallax, no entrance. `context.motion(d)` does this for every token.
- No flashing more than 3 times per second; no large flashes of saturated red.
- Motion never carries meaning alone; pair with text, icons or color.
- Don't move content the user is reading or about to tap (no auto-reflow under the pointer).

## Performance

- Prefer transitions driven by an `Animation` (`FadeTransition`, `ScaleTransition`, `SlideTransition`, `SizeTransition`) over rebuilding with `Opacity` / `Transform` each frame.
- Animate transform and opacity rather than layout (size, padding) when the effect is the same; when size must change, keep the subtree small (`AnimatedSize` around the changing part only).
- Pass static subtrees as `child` to `AnimatedBuilder` / transition widgets.
- `RepaintBoundary` around continuously animating regions (shimmer, charts, spinners).
- `BackdropFilter` and large shadow blurs are expensive: few on screen, never in long lists.
- Dispose every `AnimationController` and `CurvedAnimation`; use `SingleTickerProviderStateMixin` for one controller.
- Profile in profile mode on a real device (DevTools performance view); 120 Hz devices halve the frame budget.

## What not to animate

- Text content while it's being read (except counters).
- Every rebuild of a list row.
- Form validation on each keystroke.
- Things the user didn't cause and doesn't need to notice.
