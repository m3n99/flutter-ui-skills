// Screenshots of every case in the curated uiConfig.shots variants, with
// real fonts and real shadows, for looking at, not for pixel-diffing, plus
// one contact sheet per case with those variants side by side. Sheets take
// their screenshots in sheets_test.dart. Skipped unless VISUAL is defined:
//
//   flutter test test/ui/visual_test.dart test/ui/sheets_test.dart --update-goldens --dart-define=VISUAL=true
//
// Output: test/ui/screenshots/<case>__<variant>.png and
// test/ui/screenshots/contact_sheets/<case>.png (open these first).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_cases.dart';
import 'ui_harness.dart';

void main() {
  setUpAll(() async {
    await loadUiFonts();
    await uiConfig.setUp?.call();
  });

  for (final uiCase in uiCases) {
    testWidgets('screenshot: ${uiCase.name}', (tester) async {
      // flutter_test disables shadows (they render as hard bands); turn them
      // on for real-looking shots and back off before the test body ends.
      debugDisableShadows = false;
      try {
        final shots = <String>[];
        for (final variant in uiConfig.shots) {
          await runVariant(tester, variant, () async {
            await pumpCase(tester, uiConfig, variant, uiCase);
            final name = '${uiCase.name}__${variant.id}';
            await takeShot(name);
            shots.add(name);
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await writeContactSheet(tester, uiCase.name, shots);
      } finally {
        debugDisableShadows = true;
      }
    }, skip: !kVisualTests);
  }
}
