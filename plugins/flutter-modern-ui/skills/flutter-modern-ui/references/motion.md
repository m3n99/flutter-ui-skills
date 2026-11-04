# Motion and feedback

Motion should explain change (where did this come from, what happened), never decorate. Every animation uses `AppDurations` and `AppCurves`.

## Always
- **Press feedback** on every tappable surface: ink ripple (Material widgets) or `Pressable` (scale to 0.97, 150 ms) for custom cards.
- **State swaps** with `AnimatedSwitcher` (loading → content → error), duration `medium`, fade + slight slide:
```dart
AnimatedSwitcher(
  duration: AppDurations.medium,
  switchInCurve: AppCurves.standard,
  switchOutCurve: AppCurves.exit,
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
      child: child,
    ),
  ),
  child: switch (state) { /* each branch needs a distinct key */ },
)
```
- **Implicit animations** for property changes: `AnimatedContainer`, `AnimatedOpacity`, `AnimatedAlign`, `AnimatedSize` (expand/collapse), `AnimatedDefaultTextStyle`, `TweenAnimationBuilder` for number count-ups.
- **Respect reduced motion**: `if (MediaQuery.disableAnimationsOf(context))` use `Duration.zero` or skip decorative motion. `Pressable` and `Shimmer` templates already do this.

## Often
- **Hero** for image/card → detail transitions. Same `tag` on both ends; keep the hero child visually identical (same radius via `ClipRRect`).
- **Staggered list entrance** on first load only (not on every rebuild or scroll): fade + 8–12 px slide, 40–60 ms stagger, cap at the first ~8 items.
```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: 1),
  duration: AppDurations.slow + Duration(milliseconds: 50 * index.clamp(0, 8)),
  curve: AppCurves.standard,
  builder: (context, t, child) => Opacity(
    opacity: t,
    child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
  ),
  child: item,
)
```
- **Number transitions** for balances/scores: `TweenAnimationBuilder<double>` over the value with tabular figures.
- **Haptics** on meaningful moments: `HapticFeedback.selectionClick()` for toggles/selection, `lightImpact()` for successful actions, `mediumImpact()` for errors or long-press. Never on every tap of a list.

## Page transitions
- Keep platform defaults (Cupertino slide on iOS with back-swipe, Material zoom/fade on Android) unless the design requires otherwise. Set them centrally in `pageTransitionsTheme`, never per route.
- Modal flows (create, edit, compose): bottom sheet or full-screen dialog route (`fullscreenDialog: true`).
- For shared-axis or fade-through effects, the `animations` package (`SharedAxisTransition`, `FadeThroughTransition`) is the standard choice if the project allows the dependency.

## Avoid
- Animations longer than 500 ms for UI responses.
- Bounce/elastic curves on functional UI (fine for celebratory moments in Playful apps).
- Animating layout on every scroll frame or wrapping whole screens in `AnimatedBuilder`.
- Infinite animations other than loading indicators/shimmer.
- Lottie for simple icon changes; use `AnimatedIcon` or `AnimatedSwitcher` on the icon.

## Performance
- Animate `opacity`/`transform` (cheap) instead of size/layout when possible; use `FadeTransition`/`ScaleTransition` with an `Animation` rather than `Opacity` widget rebuilds in tight loops.
- Wrap independently animating regions in `RepaintBoundary`.
- `BackdropFilter` and large `boxShadow` blur are expensive; limit count on screen.
- Dispose every `AnimationController`.
