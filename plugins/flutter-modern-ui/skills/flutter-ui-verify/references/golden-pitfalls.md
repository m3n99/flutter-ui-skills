# Screenshot (golden) pitfalls

Things that make `flutter_test` screenshots lie, and how the harness handles them.

| # | Pitfall | Symptom | Fix |
|---|---|---|---|
| 1 | Fonts not loaded | every glyph is a box; layout measured with the test font | bundle fonts in pubspec; `loadUiFonts()` in `setUpAll` (loads FontManifest, incl. Material icons, plus SDK Roboto for platform-default families) |
| 2 | Emoji | boxes | no emoji font in `flutter_test`; check emoji on a device |
| 3 | Shadows disabled | shadows render as hard bands / missing | set `debugDisableShadows = false` for the visual test and back to `true` **at the end of the test body** (in `finally`), not in `addTearDown`, or the painting-variables assertion fails |
| 4 | Animation started by a `Timer` or post-frame callback | still at frame 0 after one pump | pump twice (`pump()` then `pump(settle)`) |
| 5 | Theme change mid-test | text looks faded / disabled: the shot is mid cross-fade | pump ≥ 1 s after a theme change, or pump a blank widget first so each variant starts fresh (the harness does) |
| 6 | Routes pushed through a global `navigatorKey` | screens from the previous shot are still on top | pump a blank widget between variants (harness), or `navigatorKey.currentState?.popUntil((r) => r.isFirst)` |
| 7 | Real I/O inside `testWidgets` (DB, files, image decoding) | hangs or never completes | fakes; or wrap the I/O in `tester.runAsync(() async { … })`; `precacheImage` inside `runAsync` for asset images |
| 8 | Infinite animations | `pumpAndSettle` times out | `pump(duration)` |
| 9 | Pending timers at the end | "A Timer is still pending" | zero-latency fakes; never-completing futures for loading states; end with an empty tree |
| 10 | `debugDefaultTargetPlatformOverride` left set | invariant assertion after the test | set and reset inside the body (`runVariant` does) |
| 11 | Device pixel ratio | blurry or huge PNGs | phone shots at DPR 2, tablet/desktop at DPR 1 (`UiSize`) |
| 12 | Different OS, different pixels | golden diffs on CI vs laptop | treat shots as screenshots for review, not baselines; if you need baselines, generate and compare them on one OS |
| 13 | Network images | blank boxes | asset images or placeholders in fakes |
| 14 | Platform views | empty rectangles | review on a device |
| 15 | Text scale via `platformDispatcher` | ignored by some widgets | set `MediaQuery.textScaler` in the app builder (harness) |
