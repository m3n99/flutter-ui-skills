# The UI harness

## Setup

```bash
mkdir -p test/ui
cp <skill-dir>/assets/harness/{ui_harness,ui_cases,layout_smoke_test,sheets_test,contrast_test,visual_test}.dart test/ui/
# only if the project uses AnimatedItems / AppMessenger / SubmitButton:
cp <skill-dir>/assets/harness/design_system_test.dart test/ui/
```

Add `test/ui/screenshots/` to `.gitignore` unless the team wants golden baselines.

## `ui_cases.dart`

```dart
final UiConfig uiConfig = UiConfig(
  theme: (brightness, platform) => AppTheme.build(brightness, platform: platform),
  platforms: const [TargetPlatform.android, TargetPlatform.windows],   // what ships
  directions: const [TextDirection.rtl],                              // RTL-only app
  localizationsDelegates: const [
    S.delegate,                                   // the app's generated delegate
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('ar')],
  localeFor: (_) => const Locale('ar'),
  scaffoldMessengerKey: AppMessenger.key,        // or the project's messenger key
  navigatorKey: navigatorKey,                    // if routes use a global key
);
```

### Fake data, by architecture

Screens should render from state that tests can control.

**Constructor-injected repositories** (simplest):

```dart
UiCase('records', (_) => RecordsScreen(repository: FakeRecordsRepository(records: sampleRecords))),
UiCase('records_empty', (_) => RecordsScreen(repository: FakeRecordsRepository(records: const []))),
UiCase('records_error', (_) => RecordsScreen(repository: FakeRecordsRepository(error: const ServerFailure()))),
```

**BLoC + service locator (`sl<T>()`, GetIt)**: register fakes before pumping, and give the screen a bloc already in the state you want:

```dart
UiCase('bills_overdue', (_) {
  sl.allowReassignment = true;
  sl.registerLazySingleton<BillsRepo>(() => FakeBillsRepo(bills: overdueBills));
  sl.registerFactory<BillsBloc>(() => BillsBloc(sl())..add(const BillsRequested()));
  return const BillsScreen();
}),
```

Or seed the bloc directly with a state (`BillsBloc.seeded(BillsState(status: Status.success, bills: overdueBills))`) when the bloc supports it. Reset the locator between cases if registrations differ (`uiConfig.wrap` or a helper called at the top of each builder).

**Providers / Riverpod**: use `wrap` to put the app under overrides:

```dart
wrap: (child) => ProviderScope(overrides: [recordsProvider.overrideWith((_) => sampleRecords)], child: child),
```

**Loading states without pending timers**: return a Future that never completes (`Completer<T>().future`), not `Future.delayed(const Duration(days: 1))`; a pending timer fails the test.

**Databases (SQLite, Drift, Isar)**: don't open them in widget tests; use the repository fakes. If you must, run real I/O inside `tester.runAsync(() async { … })`.

### Sheets

```dart
SheetCase('payment', (context) => showPaymentSheet(context, bill: sampleBill)),
SheetCase('export', (context) => showExportDialog(context), primary: find.text('Export')),
```

`primary` defaults to `SheetScaffold`'s primary action key; pass a finder for sheets that don't use it.

## Running

```bash
flutter test test/ui                                     # layout, sheets, contrast (+ design system)
flutter test test/ui/layout_smoke_test.dart --plain-name "layout: records"   # one case
flutter test test/ui/visual_test.dart --update-goldens --dart-define=VISUAL=true
```

The default matrix is 3 sizes × 2 text scales × 2 themes × platforms × directions per case; it runs in seconds per case because time is fake. Trim only what the app doesn't ship.

## Reading failures

```
[360_light_android_rtl_x1.3] A RenderFlex overflowed by 13 pixels on the right.  ← lib/features/bills/widgets/bill_tile.dart:42
```

- The bracket is the variant: width, theme, platform, direction, text scale.
- The arrow is the widget's creation location in `lib/` (needs widget creation tracking, on by default in `flutter test`).
- Several variants failing at the same line is one bug.

## Fix table

| Error | Usual cause | Fix |
|---|---|---|
| RenderFlex overflowed … on the right | text or chips in a `Row` without flex | `Expanded`/`Flexible` + `maxLines` + ellipsis; `Wrap`; stack on compact; shorten a label |
| RenderFlex overflowed … on the bottom | fixed heights, text scale 1.3, keyboard | remove fixed heights; scroll view; `FittedBox(scaleDown)` for big values |
| Vertical viewport was given unbounded height | `ListView` inside `Column` / sliver list | `Expanded`, or slivers |
| BoxConstraints forces an infinite width | `TextField` / `Expanded` inside an unbounded `Row` | give the field `Expanded` or a width |
| Incorrect use of ParentDataWidget | `Expanded` / `Positioned` not directly in a Flex / Stack | move it |
| RenderBox was not laid out | follow-up of the first error | fix the first error |
| A bar fills the whole screen | `Align` without `heightFactor` in a bottom bar | `heightFactor: 1` |
| Primary action hidden by the keyboard | save bar in `bottomNavigationBar`; sheet not padded | last child of the body `Column`; pad sheets by `viewInsets` |
| Tap target < 48 | dense controls on touch, custom tappables | theme density, `MaterialTapTargetSize.padded`, min sizes |
| Unlabeled tap target | icon-only buttons | `tooltip:` |
| A Timer is still pending | delayed futures in fakes, `ShowAfter` without a final pump | zero-latency fakes, never-completing futures; the harness pumps an empty tree at the end |
| pumpAndSettle timed out | shimmer / spinner | `pump(duration)` |
| Text drawn as boxes in shots | fonts not bundled / loaded | bundle the font; `loadUiFonts()` in `setUpAll` |

## CI

```yaml
- run: flutter test test/ui
- run: flutter test test/ui/visual_test.dart --update-goldens --dart-define=VISUAL=true
- uses: actions/upload-artifact@v4
  with: { name: ui-screenshots, path: test/ui/screenshots/ }
```

Reviewers then open the screenshots from the CI run.
