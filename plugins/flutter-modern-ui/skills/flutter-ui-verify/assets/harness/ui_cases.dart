// What the UI tests render. THE ONLY HARNESS FILE TO EDIT PER PROJECT.
//
// 1. Imports: replace the `package:app/...` lines with the project's theme
//    and screens.
// 2. uiConfig: the real theme function, the platforms that ship, RTL if the
//    app supports a right-to-left language, localization delegates.
// 3. uiCases: every screen in the states that matter (content, loading,
//    empty, error), built with fake data: no network, no real database, no
//    pending timers. Register fakes for DI here or in `wrap`.
// 4. sheetCases: every bottom sheet and dialog opener.
//
// The entries below are the plugin's example screens, as used by its CI.

import 'package:app/design_system/design_system.dart';
import 'package:app/examples/dashboard_screen.dart';
import 'package:app/examples/record_form_screen.dart';
import 'package:app/examples/records_screen.dart';
import 'package:app/examples/sample_data.dart';
import 'package:flutter/material.dart';

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
);

InvoiceRepository _instant() => InvoiceRepository(latency: Duration.zero);

final List<UiCase> uiCases = [
  UiCase('dashboard', (_) => DashboardScreen(repository: _instant())),
  UiCase('dashboard_loading', (_) => DashboardScreen(repository: InvoiceRepository.loadingForever())),
  UiCase('dashboard_error', (_) => DashboardScreen(repository: _instant()..failNextLoad = true)),
  UiCase('invoices', (_) => RecordsScreen(repository: _instant())),
  // From 840 px: the detail pane open, with its ✕ (phones show the list).
  UiCase('invoices_selected', (_) => RecordsScreen(repository: _instant(), initialSelectedId: 1041)),
  UiCase('invoices_loading', (_) => RecordsScreen(repository: InvoiceRepository.loadingForever())),
  UiCase('invoice_form', (_) => RecordFormScreen(repository: _instant())),
];

final List<SheetCase> sheetCases = [
  SheetCase('invoice_filters', (context) => showInvoiceFilters(context, const InvoiceFilters())),
];
