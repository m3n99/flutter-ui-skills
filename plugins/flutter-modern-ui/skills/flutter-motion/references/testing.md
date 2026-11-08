# Testing motion

## Behaviour tests

- Drive time with `tester.pump(duration)`. `pumpAndSettle()` never returns while an infinite animation runs (shimmer, spinners): use explicit pumps when a skeleton or progress indicator is on screen.
- Assert intermediate states: right after a removal, the item is still there (animating out); after `pump(AppDurations.medium + …)`, it's gone; neighbours kept their state.
- Route transitions take 450 ms on Android since Flutter 3.38; don't hard-code 300 ms. `TransitionDurationObserver` reads the real duration.
- Animations started by a `Timer` or post-frame callback are still at frame 0 after one pump: pump twice.
- Pending timers fail tests ("A Timer is still pending"): cancel timers in `dispose`, and pump an empty widget at the end of tests that leave delayed work.
- `design_system_test.dart` (flutter-ui-verify) covers `AnimatedItems` (state kept across insert/remove, reorder), reduced-motion removal, Undo deletes and `SubmitButton`.

## Reduced motion

```dart
await tester.pumpWidget(MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: app,
));
```

Expect: no shimmer, no entrance, removals complete in one frame, durations zero. Every new animated widget gets one reduced-motion assertion.

## Filmstrips: look at the motion

For anything non-trivial (an entrance, a container transform, a chart update), render a few frames and view them:

```dart
testWidgets('filmstrip: invoices entrance', (tester) async {
  debugDisableShadows = false;
  try {
    final variant = const UiVariant(size: UiSize.phone);
    await runVariant(tester, variant, () async {
      await pumpUi(tester, uiConfig, variant, (_) => RecordsScreen(repository: fakeRepo), settle: Duration.zero);
      for (var frame = 0; frame < 6; frame++) {
        await takeShot('film_invoices_entrance_$frame');
        await tester.pump(const Duration(milliseconds: 60));
      }
    });
  } finally {
    debugDisableShadows = true;
  }
}, skip: !kVisualTests);
```

Run with `--update-goldens --dart-define=VISUAL=true`, then open the frames in order: check the stagger order, that nothing jumps, that the last frame equals the settled layout, and that the direction is right in RTL.

## Manual inspection

- Slow everything down in a debug run: `timeDilation = 5.0;` (from `package:flutter/scheduler.dart`) temporarily in `main`, or the DevTools "Slow animations" toggle.
- Check with the platform's reduce-motion setting on.
- Desktop: hover every interactive surface; nothing should jump or shift layout on hover.

## Performance

- Profile mode on a real device: `flutter run --profile`, DevTools › Performance; look for frames over budget (16 ms at 60 Hz, 8 ms at 120 Hz) during the animation.
- "Highlight repaints" in DevTools: a continuously animating region should repaint alone (add `RepaintBoundary`).
- Watch for layout in animations (`AnimatedContainer` changing padding on a big subtree, `AnimatedSize` around a whole list).
