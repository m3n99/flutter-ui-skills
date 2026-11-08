// Every sheet and dialog at phone and tablet width, text scale 1.0 and 1.3,
// each platform in uiConfig:
// - no layout errors;
// - the primary action is on screen;
// - touch platforms: tap targets ≥ 48 px and labeled;
// - with a 300 px keyboard open, the primary action is still above it.
//
//   flutter test test/ui/sheets_test.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_cases.dart';
import 'ui_harness.dart';

const double _keyboardHeight = 300;

void main() {
  setUpAll(loadUiFonts);

  for (final sheet in sheetCases) {
    testWidgets('sheet: ${sheet.name}', (tester) async {
      final failures = <String>[];
      final primary = sheet.primary ?? find.byKey(sheetPrimaryActionKey);

      for (final size in const [UiSize.phone, UiSize.tablet]) {
        for (final platform in uiConfig.platforms) {
          for (final textScale in uiConfig.textScales) {
            final variant = UiVariant(size: size, platform: platform, textScale: textScale);
            final label = '[${variant.id}]';

            final errors = await collectUiErrors(() => runVariant(tester, variant, () async {
                  await pumpUi(tester, uiConfig, variant, sheetHost, settle: Duration.zero);
                  await openSheet(tester, sheet);

                  if (primary.evaluate().length != 1) {
                    failures.add('$label primary action not found');
                    return;
                  }
                  final rect = tester.getRect(primary);
                  if (rect.top < 0 || rect.bottom > size.height) {
                    failures.add('$label primary action off screen: $rect');
                  }

                  if (variant.isTouch) {
                    final targets = await _guideline(tester, androidTapTargetGuideline);
                    if (targets != null) failures.add('$label $targets');
                    final labels = await _guideline(tester, labeledTapTargetGuideline);
                    if (labels != null) failures.add('$label $labels');
                  }

                  showKeyboard(tester, _keyboardHeight);
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 500));
                  final withKeyboard = tester.getRect(primary);
                  if (withKeyboard.bottom > size.height - _keyboardHeight + 0.5) {
                    failures.add('$label primary action hidden by a ${_keyboardHeight.round()} px keyboard: $withKeyboard');
                  }
                  hideKeyboard(tester);
                }));
            failures.addAll(errors.map((error) => '$label $error'));
          }
        }
      }

      await tester.pumpWidget(const SizedBox.shrink());
      expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
    });
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
