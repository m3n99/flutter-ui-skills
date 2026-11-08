# Motion recipes

Each recipe names the shared piece to use and shows the pattern. Durations are tokens and go through `context.motion(...)`.

## 1. Press feedback

Material ink (ripple, hover, focus) for everything tappable, plus a subtle scale on cards and tiles:

```dart
PressScale(child: InkWell(onTap: onTap, child: content)) // AppCard does this for you
```

`PressScale` listens to raw pointer events, so it never competes with the child's gestures, and releases when the pointer moves like a scroll. Buttons keep plain ink (no scale).

Haptics on touch only, on meaningful moments: `HapticFeedback.selectionClick()` for toggles and selection, `lightImpact()` for success. Never on every tap.

## 2. Desktop hover

- `AppCard`: border darkens to `outline` on hover; raised tiles swap to `palette.hoverShadow`.
- Custom hover lift:

```dart
MouseRegion(
  cursor: SystemMouseCursors.click,
  onEnter: (_) => setState(() => _hovered = true),
  onExit: (_) => setState(() => _hovered = false),
  child: AnimatedContainer(
    duration: context.motion(AppDurations.fast),
    curve: AppCurves.standard,
    transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
    decoration: BoxDecoration(
      borderRadius: AppRadius.cardAll,
      boxShadow: _hovered ? context.palette.hoverShadow : context.palette.softShadow,
    ),
    child: tile,
  ),
)
```

## 3. Entrance (first load, new sort)

```dart
Entrance(index: i, child: card) // fade + 8 % slide up, 40 ms stagger, first 8 only, plays once
```

Inside lists, `AnimatedItems` applies it automatically, only to items built in the first frame, so rows scrolled into view later don't animate. Don't replay it on refresh.

## 4. Lists: insert, remove, reorder

```dart
CustomScrollView(
  slivers: [
    SliverPadding(
      padding: AppSpace.screenH,
      sliver: AnimatedItems<Invoice>(
        items: visible,                    // after filters, search and pending deletes
        keyOf: (invoice) => invoice.id,    // unique, stable
        spacing: AppSpace.sm,              // animates with each item
        itemBuilder: (context, invoice) => InvoiceCard(invoice),
      ),
    ),
  ],
)
```

What it does: removals shrink and fade (neighbours slide up), inserts grow and fade in, kept items keep their State even when their index shifts (an expanded tile stays expanded), a changed order replays the staggered entrance. Grids (`gridDelegate:`) fade and scale instead.

Why not `AnimatedList`: it has no `findChildIndexCallback`, so after an insert at the top, item State (expanded tiles, text fields) shifts to the wrong rows. `AnimatedItems` is built on `SliverAnimatedList` / `SliverAnimatedGrid` with `findChildIndexCallback` and diffs by id.

Drag to reorder: `ReorderableListView.builder` with a `proxyDecorator` that lifts the dragged row:

```dart
proxyDecorator: (child, index, animation) => AnimatedBuilder(
  animation: animation,
  builder: (context, child) => Transform.scale(
    scale: 1 + 0.02 * Curves.easeOut.transform(animation.value),
    child: Material(elevation: 6 * animation.value, borderRadius: AppRadius.cardAll, child: child),
  ),
  child: child,
),
```

## 5. State switches (loading → content → empty → error)

```dart
StateSwitcher(
  child: switch (status) {
    Status.loading => const ListSkeleton(key: ValueKey('loading')),
    Status.failure => EmptyState.error(key: const ValueKey('error'), title: …, onRetry: …),
    _ => InvoiceList(key: const ValueKey('content'), items: items),
  },
)
```

Cross-fade with a 2 % upward settle, top-aligned so short and long states don't jump. The skeleton is wrapped in `ShowAfter` (150 ms) so fast loads never flash it.

## 6. Expand and collapse

- Size changes: `AnimatedSize(duration: context.motion(AppDurations.medium), curve: AppCurves.emphasized, child: …)` around the part that changes.
- `ExpansionTile(expansionAnimationStyle: AnimationStyle(duration: …, curve: …))`.
- Swapping two children of different height: `AnimatedSwitcher` inside `AnimatedSize` (smoother than `AnimatedCrossFade`, which clips).
- Chevron rotation: `AnimatedRotation(turns: expanded ? 0.5 : 0, duration: context.motion(AppDurations.fast))`.

## 7. Page transitions

- Set them once in the theme (`pageTransitionsTheme`, template): predictive back on Android (falls back to fade-forwards), Cupertino on iOS/macOS, fade-forwards on Windows/Linux. Never per route.
- Modal flows (create, edit): `MaterialPageRoute(fullscreenDialog: true)` (slides up, close ✕).
- Custom route, shared-axis style, direction-aware:

```dart
PageRouteBuilder<T>(
  transitionDuration: AppDurations.page,
  reverseTransitionDuration: AppDurations.medium,
  pageBuilder: (context, animation, secondaryAnimation) => page,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) return child;
    final enter = CurvedAnimation(parent: animation, curve: AppCurves.enter, reverseCurve: AppCurves.exit);
    final dx = Directionality.of(context) == TextDirection.rtl ? -0.08 : 0.08;
    return FadeTransition(
      opacity: enter,
      child: SlideTransition(position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(enter), child: child),
    );
  },
)
```

- go_router: `CustomTransitionPage(child: page, transitionsBuilder: …)` with the same builder.
- With the official `animations` package: `SharedAxisTransition` (related steps), `FadeThroughTransition` (unrelated views, tabs), `PageTransitionSwitcher` for in-place switches.

## 8. Hero and container transform

Card → detail with continuity:

```dart
// list
Hero(tag: 'invoice-${invoice.id}', child: ClipRRect(borderRadius: AppRadius.cardAll, child: thumbnail))
// detail
Hero(tag: 'invoice-${invoice.id}', child: ClipRRect(borderRadius: AppRadius.cardAll, child: thumbnail))
```

- Same tag, visually identical child, same radius (clip both ends).
- Text in heroes: wrap in `Material(type: MaterialType.transparency)` or use `flightShuttleBuilder` to avoid a style jump mid-flight.
- Whole-card expansion: `OpenContainer` (`animations` package) with `closedShape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll)`, `closedElevation: 0`, `closedColor` = card color, `openColor` = scaffold color, `transitionDuration: AppDurations.page`.

## 9. Tabs and top-level destinations

- `TabBarView` swipes by default; fine for peers.
- Bottom-nav destinations: `IndexedStack` (keeps state, pauses hidden tickers) with a fade-through on switch, or `PageTransitionSwitcher` + `FadeThroughTransition` from `animations` if state needn't be kept.
- Don't slide between top-level destinations: they aren't spatially related.

## 10. Buttons

- Save / submit: `SubmitButton`: spinner while the Future runs (or `busy:` from state), same width, presses ignored while busy; optional success check (`successFeedback: true`) for screens that stay open.
- Icon swaps (play/pause, copy → check): `AnimatedSwitcher` with a scale + fade transition and distinct keys; revert the "copied" check after ~1.5 s.
- Toggle-like buttons (favourite, follow): `PopOnChange(value: liked, child: Icon(…))` + `HapticFeedback.selectionClick()` on touch.

## 11. Numbers, progress and charts

- Counters: `AnimatedNumber(value:, format:)` tweens from the shown value with tabular figures; `fromZero: true` only for a playful first appearance.
- Progress: `AppProgressBar(value:)` tweens from the previous value; fills from the reading start.
- Charts:
  - fl_chart: pass `duration: context.motion(AppDurations.slow)` and `curve: AppCurves.standard`; it lerps between data sets, so bars and lines move from old to new values.
  - In a hidden tab, hold the last shown data while `TickerMode.valuesOf(context).enabled` is false and swap when it turns true (see `MiniBarChart`); otherwise the animation finishes off-screen and the user never sees the change.
  - First appearance: grow once from zero, or appear static. Pick one per app.

## 12. Sheets and dialogs

- Keep the platform's default sheet and dialog motion. Tune with `showModalBottomSheet(sheetAnimationStyle: AnimationStyle(duration: AppDurations.medium, reverseDuration: AppDurations.fast))` if needed.
- Content that changes inside a sheet (step 1 → 2): `StateSwitcher`, and `AnimatedSize` so the sheet height follows.
- The keyboard: sheets lift their content by the inset (`SheetScaffold`), no extra animation needed.
- Custom dialog entrance (rarely needed): `showGeneralDialog` with `FadeTransition` + `ScaleTransition(0.96 → 1)` and `AppCurves.enter`.

## 13. Skeleton → content

`ShowAfter(child: Shimmer(child: skeleton))` inside a `StateSwitcher`. The shimmer sweep follows the reading direction and stops under reduced motion. Skeleton shapes match the content, so the cross-fade has no jump.

## 14. Micro-interactions

- Failed submit / wrong PIN: `ShakeOnChange(trigger: failedAttempts, child: submitButton)` with the error text visible.
- Badge counts, cart totals, favourites: `PopOnChange(value: count, child: badge)`.
- Checkbox / switch: the built-in animations; don't replace them.
- Pull to refresh: `RefreshIndicator.adaptive` (platform spinner).
- Success moments (Playful / Bold only): a quick check draw or confetti, once, never on routine saves.

## 15. Scroll effects

- Collapsing titles: `SliverAppBar.large` / `.medium`.
- Hairline under the app bar once content scrolls beneath it:

```dart
NotificationListener<ScrollUpdateNotification>(
  onNotification: (n) {
    final scrolled = n.metrics.pixels > 0;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  },
  child: …,
)
// AppBar(bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
//   child: AnimatedOpacity(opacity: _scrolled ? 1 : 0, duration: context.motion(AppDurations.fast), child: const Divider())))
```

- Parallax header image: `SliverAppBar(expandedHeight: 240, flexibleSpace: FlexibleSpaceBar(collapseMode: CollapseMode.parallax, background: image))`.
- Extended FAB that collapses while scrolling down: `FloatingActionButton.extended(isExtended: !_scrollingDown, …)` inside `AnimatedSize`.
- No scroll-jacking, no snapping that fights the user.

## 16. Gestures and physics

Drag to dismiss with a spring back:

```dart
late final AnimationController _drag = AnimationController.unbounded(vsync: this);

void _onDragUpdate(DragUpdateDetails d) => _drag.value = math.max(0, _drag.value + d.delta.dy);

void _onDragEnd(DragEndDetails d) {
  final velocity = d.primaryVelocity ?? 0;
  if (_drag.value > 120 || velocity > 800) {
    Navigator.of(context).pop();
    return;
  }
  _drag.animateWith(SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 420, damping: 32),
    _drag.value,
    0,
    velocity,
  ));
}
// build: AnimatedBuilder(animation: _drag, builder: (_, child) => Transform.translate(offset: Offset(0, _drag.value), child: child), child: sheet)
```

`SpringSimulation` comes from `package:flutter/physics.dart`. Physics-based motion should respect reduced motion too (jump to the end).

## 17. Celebrations (opt-in)

Playful apps only, and only for real achievements: `confetti` package or a Lottie animation once (`repeat: false`), skipped under reduced motion, never blocking input, never on routine actions.
