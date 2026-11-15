// Every sheet and dialog at phone and tablet width, each text scale,
// platform and reading direction in uiConfig (sheetProblems in
// ui_harness.dart):
// - no layout errors;
// - touch platforms: tap targets ≥ 48 px and labeled; nothing under or
//   touching the system bars (a footer keeps clear of the navigation bar);
// - sheets with a primary action: it's on screen, and still above a 300 px
//   keyboard;
// - pick-one sheets (SheetCase.picker): options on screen, and tapping one
//   closes the sheet.
// With VISUAL defined it also saves each sheet's screenshots and a contact
// sheet (test/ui/screenshots/sheet_<name>__<variant>.png). With QUICK
// defined it renders phones only, at the smallest and largest text scale.
//
//   flutter test test/ui/sheets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_cases.dart';
import 'ui_harness.dart';

void main() {
  setUpAll(() async {
    await loadUiFonts();
    await uiConfig.setUp?.call();
  });

  for (final sheet in sheetCases) {
    testWidgets('sheet: ${sheet.name}', (tester) async {
      final failures = <String>[];

      final scales = uiConfig.textScales;
      for (final size in kQuickUi ? const [UiSize.phone] : const [UiSize.phone, UiSize.tablet]) {
        for (final platform in uiConfig.platforms) {
          for (final direction in uiConfig.directions) {
            for (final textScale in kQuickUi ? {scales.first, scales.last} : scales) {
              final variant = UiVariant(size: size, platform: platform, direction: direction, textScale: textScale);
              final label = '[${variant.id}]';

              final errors = await collectUiErrors(() => runVariant(tester, variant, () async {
                    await pumpUi(tester, uiConfig, variant, sheetHost, settle: Duration.zero);
                    await openSheet(tester, sheet);
                    for (final problem in await sheetProblems(tester, uiConfig, variant, sheet)) {
                      failures.add('$label $problem');
                    }
                  }));
              failures.addAll(errors.map((error) => '$label $error'));
            }
          }
        }
      }

      await tester.pumpWidget(const SizedBox.shrink());
      expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
    });

    testWidgets('screenshot: sheet ${sheet.name}', (tester) async {
      debugDisableShadows = false;
      try {
        final shots = <String>[];
        for (final variant in const [
          UiVariant(size: UiSize.phone),
          UiVariant(size: UiSize.phone, brightness: Brightness.dark),
          UiVariant(size: UiSize.phone, textScale: 1.3, direction: TextDirection.rtl),
          UiVariant(size: UiSize.tablet),
        ]) {
          await runVariant(tester, variant, () async {
            await pumpUi(tester, uiConfig, variant, sheetHost, settle: Duration.zero);
            await openSheet(tester, sheet);
            final name = 'sheet_${sheet.name}__${variant.id}';
            await takeShot(name);
            shots.add(name);
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await writeContactSheet(tester, 'sheet_${sheet.name}', shots);
      } finally {
        debugDisableShadows = true;
      }
    }, skip: !kVisualTests);
  }
}
