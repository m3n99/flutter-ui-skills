# Motion packages: when to use them

Everything in the recipes works with the SDK alone. Add a package only when it saves real work, and ask the user first.

| Package | Use for | Notes |
|---|---|---|
| `animations` (Flutter team) | `OpenContainer` (container transform), `SharedAxisTransition`, `FadeThroughTransition`, `PageTransitionSwitcher` | The standard for Material motion patterns. Pass token durations. |
| `flutter_animate` | Declarative effect chains: `.animate().fadeIn(duration: …).slideY(begin: 0.08)` | Fine if the project already uses it. Pass durations through `context.motion(...)` (or set `Animate.defaultDuration` from tokens) and skip the chain under reduced motion (`reduce ? child : child.animate()…`). Don't mix it with hand-written equivalents of the same effect. |
| `lottie` | Illustrations in empty states, onboarding, one-off success | Small files (< 100 KB), `repeat: false` unless it's a loader, paused under reduced motion, a static fallback frame. Never for icon swaps. |
| `rive` | Interactive animated illustrations with state machines | Heavier runtime; only when the design team delivers Rive files. |
| `confetti` | Celebrations in Playful apps | Once per real achievement; off under reduced motion. |
| `fl_chart` | Charts with value transitions | Pass `duration` and `curve` from tokens; mirror x in RTL; hold data while `TickerMode` is off. |
| `shimmer` | Skeleton shimmer | Not needed: the design system's `Shimmer` is direction-aware and reduced-motion aware. |

Rules for any package:

- Durations and curves still come from tokens.
- Reduced motion still turns it off.
- One package per job; remove one-off duplicates.
- Wrap it in a project widget (`AppLottie`, `AppConfetti`) so screens don't depend on the package directly.
