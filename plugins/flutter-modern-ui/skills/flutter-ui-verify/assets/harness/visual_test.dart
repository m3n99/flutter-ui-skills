// Screenshots of every case (and every sheet) in the curated uiConfig.shots
// variants, with real fonts and real shadows, for looking at, not for
// pixel-diffing. Skipped unless VISUAL is defined:
//
//   flutter test test/ui/visual_test.dart --update-goldens --dart-define=VISUAL=true
//
// Output: test/ui/screenshots/<case>__<variant>.png

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_cases.dart';
import 'ui_harness.dart';

void main() {
  setUpAll(loadUiFonts);

  for (final uiCase in uiCases) {
    testWidgets('screenshot: ${uiCase.name}', (tester) async {
      // flutter_test disables shadows (they render as hard bands); turn them
      // on for real-looking shots and back off before the test body ends.
      debugDisableShadows = false;
      try {
        for (final variant in uiConfig.shots) {
          await runVariant(tester, variant, () async {
            await pumpUi(tester, uiConfig, variant, uiCase.builder, settle: uiCase.settle);
            await takeShot('${uiCase.name}__${variant.id}');
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        debugDisableShadows = true;
      }
    }, skip: !kVisualTests);
  }

  for (final sheet in sheetCases) {
    testWidgets('screenshot: sheet ${sheet.name}', (tester) async {
      debugDisableShadows = false;
      try {
        for (final variant in const [
          UiVariant(size: UiSize.phone),
          UiVariant(size: UiSize.phone, brightness: Brightness.dark),
          UiVariant(size: UiSize.tablet),
        ]) {
          await runVariant(tester, variant, () async {
            await pumpUi(tester, uiConfig, variant, sheetHost, settle: Duration.zero);
            await openSheet(tester, sheet);
            await takeShot('sheet_${sheet.name}__${variant.id}');
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        debugDisableShadows = true;
      }
    }, skip: !kVisualTests);
  }
}
