---
name: flutter-motion
description: Add or review purposeful animation in Flutter apps — card entrances, list insert/remove/reorder, page and tab transitions, hero/container transforms, button progress and success, counters, progress bars and charts that move from old to new values, sheets, skeleton shimmer, micro-interactions, scroll effects, desktop hover. Use when the user asks for animations, transitions, "make it feel alive/smooth", or when motion feels janky, missing or overdone. Asks how much motion (none, soft or expressive) and where before building, with a small example of each.
---

# Flutter Motion

Motion explains change: where something came from, what just happened, what is now in focus. Good motion is fast, consistent and comes from a few shared pieces; bad motion is a different `AnimationController` in every widget.

Shared pieces live in the design system (`../flutter-modern-ui/assets/design_system/motion/` and `widgets/`). In a project with its own motion helpers, use and extend those.

## Workflow

1. **Ask how much and where, before building.** Unless DESIGN.md already records it, ask the two-part question in `../flutter-modern-ui/references/intake.md` › Motion: the level (**none**, **soft**, **expressive**) with its small example, and the places, each with its soft and expressive version. Ask even when the spec or the customer hinted at motion; offer the hint as the recommended option. Record the answer in DESIGN.md (*Motion*) and set `AppThemeConfig.motion`. If nobody can answer yet: soft, on cards and lists on load, list changes, numbers, buttons and loading, and say so.
2. **Inventory what exists**: `rg -n "AnimationController|Animated[A-Z]\w+\(|Hero\(|PageRouteBuilder|TweenAnimationBuilder|flutter_animate|Lottie|Rive" lib`. Reuse existing helpers; remove one-off duplicates when touching them.
3. **Pick one recipe per surface** from `references/recipes.md` and route every screen through it:

   | Surface | Shared piece |
   |---|---|
   | Press feedback | ink + `PressScale` (built into `AppCard`) |
   | Desktop hover | `AppCard` hover border / raised hover shadow |
   | Card entrance | `Entrance` (staggered, first frame only) |
   | Lists insert / remove / reorder | `AnimatedItems` |
   | Loading → content → empty → error | `StateSwitcher` + `ShowAfter` + `Shimmer` |
   | Buttons: busy, success | `SubmitButton` |
   | Counters | `AnimatedNumber` |
   | Progress | `AppProgressBar` |
   | Charts | `MiniBarChart` rules / chart `duration` + `TickerMode` hold |
   | Errors, toggles | `ShakeOnChange`, `PopOnChange` |
   | Pages | theme `pageTransitionsTheme`; `animations` package for shared axis / container transform |

4. **Tokens only**: durations from `AppDurations`, curves from `AppCurves`, every duration through `context.motion(d)`, which scales it by the level and turns it off under reduced motion and at `MotionLevel.none`. Distances, stagger, press, pop and shake come from the level (`context.appMotion`), not from per-screen numbers. `references/principles.md` › Motion levels.
5. **Check performance**: animate transforms and opacity, not layout, where possible; `RepaintBoundary` around continuously animating regions; at most 2–3 blurs on screen; dispose every controller.
6. **Test it** (`references/testing.md`): behaviour tests with `pump(duration)`, a reduced-motion test, and filmstrip screenshots for anything non-trivial; look at the frames.
7. **Record** the motion table (what animates, duration, curve) in DESIGN.md.

## Rules

The level and the places are the user's choice, made before building: nothing moves that they didn't pick, and nothing moves more than their level.

1. 150–350 ms for UI responses (routes 450 ms; × 1.2 at expressive). Nothing functional over 500 ms.
2. Enter with deceleration (`AppCurves.enter`), exit with acceleration (`AppCurves.exit`), move on screen with `standard` / `emphasized`. `AppCurves.pop` (overshoot) only for celebrations.
3. Animate **from the current value**: lists keep item state, counters and bars tween from what's on screen, never restart from zero.
4. Entrances play once, on first data or a new sort, for the first ~8 items only; never on scroll or on every rebuild.
5. Nothing animates while hidden: charts in background tabs hold their values until shown (`TickerMode`).
6. Reduced motion (`MediaQuery.disableAnimationsOf`) → zero durations, no shimmer, no entrance, no parallax.
7. Motion never carries meaning alone: a shake comes with an error message, a check with a label change.
8. No infinite animations except loading indicators. No bounce on functional UI.
9. Platform conventions win for routes and sheets (predictive back on Android, Cupertino on iOS).
10. One shared piece per surface; no ad-hoc controllers in screens.

## References

- `references/principles.md`: purpose, easing and duration tables, choreography, accessibility, performance.
- `references/recipes.md`: code for every surface above, plus hero, container transform, shared axis, tabs, sheets, scroll effects, drag physics, celebrations.
- `references/testing.md`: testing animations, filmstrip screenshots, reduced motion, profiling.
- `references/packages.md`: when to reach for `animations`, `flutter_animate`, Lottie, Rive, confetti, and how to keep them on tokens.
