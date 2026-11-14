# The UI harness

## Setup

From the project root:

```bash
python3 <skill-dir>/scripts/copy_harness.py                         # test/ui
python3 <skill-dir>/scripts/copy_harness.py --design-system-test    # + shared-widget tests (AnimatedItems, AppMessenger, SubmitButton, AppChoiceChips, tones)
python3 <skill-dir>/scripts/copy_harness.py --pdf                   # + test/pdf (references/printed-documents.md)
```

Running it again updates the harness and keeps your `ui_cases.dart` / `pdf_cases.dart`. In a `material_ui` project (Flutter 3.50+) it rewrites `package:flutter/material.dart` imports to `package:material_ui/material_ui.dart`. By hand: copy `assets/harness/*.dart` (and `assets/pdf/*.dart`), then `dart fix --apply --code=migrate_design_widgets` if the project uses `material_ui`.

Add `test/ui/screenshots/` and `test/pdf/out/` to `.gitignore` unless the team wants golden baselines.

## `ui_cases.dart`

```dart
final UiConfig uiConfig = UiConfig(
  theme: (brightness, platform) => AppTheme.build(brightness, platform: platform),
  platforms: const [TargetPlatform.android, TargetPlatform.windows],   // what ships
  directions: const [TextDirection.rtl],                              // RTL-only app
  localizationsDelegates: const [
    S.delegate,                                   // the app's generated delegate
    GlobalMaterialLocalizations.delegate,         // with material_ui: ...GlobalMaterialLocalizations.delegates
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

### Faking dependencies

Register fakes once in `uiConfig.setUp`; every test file runs it before its first case:

```dart
final UiConfig uiConfig = UiConfig(
  theme: ...,
  setUp: () async {
    final sl = GetIt.instance;
    await sl.reset();
    sl.registerLazySingleton<ExpenseStore>(FakeExpenseStore.new);
    sl.registerLazySingleton<ConnectivityService>(() => FakeConnectivity(online: true));
  },
);
```

**Plugins that call native code when a screen starts** (connectivity, auth, location, secure storage) fail in widget tests with `MissingPluginException`, so the screen never renders. In order of preference:

1. **Inject an interface** the bloc or repository takes (`ConnectivityService`, `AuthRepository`), with the plugin only in the production implementation; register a fake in `setUp`. A screen that can't render in a test is telling you something should be injected.
2. **Use the plugin's own test double** when it has one (`firebase_auth_mocks` for `FirebaseAuth`, `SharedPreferences.setMockInitialValues`).
3. **Answer its channel** as a last resort; the channel name is in the plugin's source (`MethodChannel('…')`):

```dart
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
  const MethodChannel('<the plugin channel>'),
  (call) async => <the value the app expects>,
);
```

### Forms: a create case and an edit case

Some bugs only exist when the fields start filled (a controller set in `build` calls `setState` during the build). Render every form both ways:

```dart
UiCase('expense_form', (_) => ExpenseForm(store: fakeStore)),
UiCase('expense_form_edit', (_) => ExpenseForm(store: fakeStore, initial: sampleExpense)),
```

### The app shell

Pages rendered one at a time can't show bugs of the shell: tabs of an `IndexedStack` (or go_router's `StatefulShellRoute.indexedStack`) all live in one route, so two FABs with the default hero tag only throw once a route is pushed. Add a case with the real shell and push a route in `act`:

```dart
UiCase('shell', (_) => AppShell(...), act: (tester) async {
  await tester.tap(find.byIcon(Icons.receipt_long_outlined));    // switch tab
  await settleFrames(tester);
  await tester.tap(find.text('New expense'));                     // push a route
  await settleFrames(tester);
  Navigator.of(tester.element(find.byType(ExpenseForm))).pop();
  await settleFrames(tester);
}),
```

A go_router app renders its router in the case (`Router.withConfig(config: router)`) the same way. `act` runs in every variant of the matrix and its errors are reported like layout errors; the screenshot shows the state it ends in.

### Sheets

```dart
SheetCase('payment', (context) => showPaymentSheet(context, bill: sampleBill)),
SheetCase('export', (context) => showExportDialog(context), primary: find.text('Export')),
SheetCase.picker('currency', (context) => showCurrencyPicker(context, current: 'ILS')),
```

`primary` defaults to `SheetScaffold`'s primary action key; pass a finder for sheets that don't use it. Pick-one sheets, where tapping an option is the action, have no primary button: `SheetCase.picker` checks that the options are on screen with real tap targets and that a tap closes the sheet (`options:` takes a finder when they aren't `ListTile`s). No sheets at all: leave `sheetCases` empty.

## Running

```bash
flutter test test/ui                                     # layout, sheets, contrast (+ design system)
flutter test test/ui/layout_smoke_test.dart --plain-name "layout: records"   # one case
flutter test test/ui/visual_test.dart test/ui/sheets_test.dart --update-goldens --dart-define=VISUAL=true
```

Screenshots land in `test/ui/screenshots/<case>__<variant>.png`, with one contact sheet per case and per sheet in `test/ui/screenshots/contact_sheets/` (every shot variant side by side, labeled). Review the contact sheets first; open single shots for detail.

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
- run: flutter test test/ui/visual_test.dart test/ui/sheets_test.dart --update-goldens --dart-define=VISUAL=true
- run: flutter test test/pdf            # if the app prints
- run: |
    python -m pip install pymupdf
    python tool/rasterize_pdf.py test/pdf/out --text   # a copy of scripts/rasterize_pdf.py
- uses: actions/upload-artifact@v4
  with:
    name: ui-screenshots
    path: |
      test/ui/screenshots/
      test/pdf/out/
```

Reviewers then open the screenshots and printed pages from the CI run.
