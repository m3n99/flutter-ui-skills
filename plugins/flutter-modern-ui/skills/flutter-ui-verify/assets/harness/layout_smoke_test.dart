// Every screen × every size, text scale, theme, platform and direction in
// uiConfig: fails with one line per error and the source location. A case's
// `act` (push a route from the shell, open edit mode…) runs in every
// variant, and its errors count too.
//
//   flutter test test/ui/layout_smoke_test.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_cases.dart';
import 'ui_harness.dart';

void main() {
  setUpAll(() async {
    await loadUiFonts();
    await uiConfig.setUp?.call();
  });

  for (final uiCase in uiCases) {
    testWidgets('layout: ${uiCase.name}', (tester) async {
      final failures = <String>[];
      for (final variant in uiConfig.matrix) {
        final errors = await collectUiErrors(
          () => runVariant(tester, variant, () => pumpCase(tester, uiConfig, variant, uiCase)),
        );
        failures.addAll(errors.map((error) => '[${variant.id}] $error'));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
    });
  }
}
