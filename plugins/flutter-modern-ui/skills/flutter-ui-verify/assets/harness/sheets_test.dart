// Every sheet and dialog at phone and tablet width, text scale 1.0 and 1.3,
// each platform in uiConfig:
// - no layout errors;
// - touch platforms: tap targets ≥ 48 px and labeled;
// - sheets with a primary action: it's on screen, and still above a 300 px
//   keyboard;
// - pick-one sheets (SheetCase.picker): options on screen, and tapping one
//   closes the sheet.
// With VISUAL defined it also saves each sheet's screenshots and a contact
// sheet (test/ui/screenshots/sheet_<name>__<variant>.png).
//
//   flutter test test/ui/sheets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_cases.dart';
import 'ui_harness.dart';

const double _keyboardHeight = 300;

void main() {
  setUpAll(() async {
    await loadUiFonts();
    await uiConfig.setUp?.call();
  });

  for (final sheet in sheetCases) {
    testWidgets('sheet: ${sheet.name}', (tester) async {
      final failures = <String>[];

      for (final size in const [UiSize.phone, UiSize.tablet]) {
        for (final platform in uiConfig.platforms) {
          for (final textScale in uiConfig.textScales) {
            final variant = UiVariant(size: size, platform: platform, textScale: textScale);
            final label = '[${variant.id}]';

            final errors = await collectUiErrors(() => runVariant(tester, variant, () async {
                  await pumpUi(tester, uiConfig, variant, sheetHost, settle: Duration.zero);
                  await openSheet(tester, sheet);

                  if (variant.isTouch) {
                    final targets = await _guideline(tester, androidTapTargetGuideline);
                    if (targets != null) failures.add('$label $targets');
                    final labels = await _guideline(tester, labeledTapTargetGuideline);
                    if (labels != null) failures.add('$label $labels');
                  }

                  if (sheet.picker) {
                    await _checkPicker(tester, sheet, size, label, failures);
                  } else {
                    await _checkPrimary(tester, sheet, size, label, failures);
                  }
                }));
            failures.addAll(errors.map((error) => '$label $error'));
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

Future<void> _checkPrimary(WidgetTester tester, SheetCase sheet, UiSize size, String label, List<String> failures) async {
  final primary = sheet.primary ?? find.byKey(sheetPrimaryActionKey);
  if (primary.evaluate().length != 1) {
    failures.add('$label primary action not found (a pick-one sheet? use SheetCase.picker)');
    return;
  }
  final rect = tester.getRect(primary);
  if (rect.top < 0 || rect.bottom > size.height) {
    failures.add('$label primary action off screen: $rect');
  }

  showKeyboard(tester, _keyboardHeight);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  final withKeyboard = tester.getRect(primary);
  if (withKeyboard.bottom > size.height - _keyboardHeight + 0.5) {
    failures.add('$label primary action hidden by a ${_keyboardHeight.round()} px keyboard: $withKeyboard');
  }
  hideKeyboard(tester);
}

Future<void> _checkPicker(WidgetTester tester, SheetCase sheet, UiSize size, String label, List<String> failures) async {
  final options = sheet.options ?? sheetOptions;
  if (options.evaluate().isEmpty) {
    failures.add('$label no options found (pass SheetCase.picker(options: ...))');
    return;
  }
  final first = tester.getRect(options.first);
  if (first.top < 0 || first.bottom > size.height) {
    failures.add('$label first option off screen: $first');
  }

  // Tapping an option is the action: the sheet must close.
  await tester.tap(options.first);
  await settleFrames(tester);
  if (options.evaluate().isNotEmpty) {
    failures.add('$label tapping an option left the sheet open');
  }
}

/// Null when the guideline passes, otherwise its failure reason.
Future<String?> _guideline(WidgetTester tester, AccessibilityGuideline guideline) async {
  final handle = tester.ensureSemantics();
  try {
    final result = await guideline.evaluate(tester);
    return result.passed ? null : '${guideline.description}: ${result.reason}';
  } finally {
    handle.dispose();
  }
}
