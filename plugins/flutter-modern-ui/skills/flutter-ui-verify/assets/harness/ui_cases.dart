// What the UI tests render. THE ONLY HARNESS FILE TO EDIT PER PROJECT.
//
// 1. Imports: replace the `package:app/...` lines with the project's theme
//    and screens.
// 2. uiConfig: the real theme function, the platforms that ship, RTL if the
//    app supports a right-to-left language, localization delegates, `setUp`
//    for DI fakes and plugin stubs (references/harness.md › Faking
//    dependencies), the theme-extension tones to check.
// 3. uiCases: every screen in the states that matter (content, loading,
//    empty, error), built with fake data: no network, no real database, no
//    pending timers. Also:
//    - every form twice: create AND edit (pre-filled), since some crashes
//      only happen when the fields start filled;
//    - the app shell with every tab mounted, pushing a route in `act`: tabs
//      in an IndexedStack share one route, so clashing hero tags only show
//      there.
// 4. sheetCases: every bottom sheet and dialog opener. Pick-one sheets,
//    where tapping an option is the action, are SheetCase.picker. No sheets:
//    leave the list empty.
//
// The entries below are the plugin's example screens, as used by its CI.

import 'package:app/design_system/design_system.dart';
import 'package:app/examples/dashboard_screen.dart';
import 'package:app/examples/example_app.dart';
import 'package:app/examples/record_form_screen.dart';
import 'package:app/examples/records_screen.dart';
import 'package:app/examples/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_harness.dart';

final UiConfig uiConfig = UiConfig(
  theme: (brightness, platform) => AppTheme.build(brightness, platform: platform),
  platforms: const [TargetPlatform.android, TargetPlatform.windows],
  directions: const [TextDirection.ltr, TextDirection.rtl],
  scaffoldMessengerKey: AppMessenger.key,
  shots: const [
    UiVariant(size: UiSize.phone),
    UiVariant(size: UiSize.phone, brightness: Brightness.dark),
    UiVariant(size: UiSize.phone, textScale: 1.3, direction: TextDirection.rtl),
    UiVariant(size: UiSize.desktop, platform: TargetPlatform.windows),
  ],
  // Status tones live in a ThemeExtension, so the theme-level contrast test
  // can't see them on its own.
  extraContrastPairs: (theme) {
    final palette = theme.extension<AppPalette>();
    if (palette == null) return const [];
    return [
      ('success', palette.success.onContainer, palette.success.container, 4.5),
      ('warning', palette.warning.onContainer, palette.warning.container, 4.5),
      ('info', palette.info.onContainer, palette.info.container, 4.5),
    ];
  },
  // Containers that must read as tints, not solid blocks: the scheme's and
  // the status tones behind pills and KPI tiles.
  softContainers: (theme) {
    final s = theme.colorScheme;
    final palette = theme.extension<AppPalette>();
    return [
      ('primaryContainer', s.primaryContainer),
      ('secondaryContainer', s.secondaryContainer),
      ('tertiaryContainer', s.tertiaryContainer),
      ('errorContainer', s.errorContainer),
      if (palette != null) ...[
        ('success.container', palette.success.container),
        ('warning.container', palette.warning.container),
        ('info.container', palette.info.container),
      ],
    ];
  },
);

InvoiceRepository _instant() => InvoiceRepository(latency: Duration.zero);

/// Edit mode's pre-filled data.
final Invoice _editing = Invoice(
  id: 1041,
  number: 'INV-1041',
  customer: 'Kinetic Labs',
  amountCents: 1250000,
  due: DateTime(2026, 11, 22),
  status: InvoiceStatus.overdue,
);

/// From the shell: switch to the Invoices tab, push the form, pop it.
/// Every tab stays mounted, so this is where clashing hero tags throw.
Future<void> _pushFromShell(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.receipt_long_outlined));
  await settleFrames(tester);
  await tester.tap(find.text('New invoice'));
  await settleFrames(tester);
  Navigator.of(tester.element(find.byType(RecordFormScreen))).pop();
  await settleFrames(tester);
}

final List<UiCase> uiCases = [
  UiCase('dashboard', (_) => DashboardScreen(repository: _instant())),
  UiCase('dashboard_loading', (_) => DashboardScreen(repository: InvoiceRepository.loadingForever())),
  UiCase('dashboard_error', (_) => DashboardScreen(repository: _instant()..failNextLoad = true)),
  UiCase('invoices', (_) => RecordsScreen(repository: _instant())),
  // From 840 px: the detail pane open, with its ✕ (phones show the list).
  UiCase('invoices_selected', (_) => RecordsScreen(repository: _instant(), initialSelectedId: 1041)),
  UiCase('invoices_loading', (_) => RecordsScreen(repository: InvoiceRepository.loadingForever())),
  UiCase('invoice_form', (_) => RecordFormScreen(repository: _instant())),
  UiCase('invoice_form_edit', (_) => RecordFormScreen(repository: _instant(), initial: _editing)),
  UiCase('shell', (_) => ExampleShell(repository: _instant()), act: _pushFromShell),
];

final List<SheetCase> sheetCases = [
  SheetCase('invoice_filters', (context) => showInvoiceFilters(context, const InvoiceFilters())),
  SheetCase.picker('invoice_sort', (context) => showInvoiceSort(context, InvoiceSort.dueDate)),
];
