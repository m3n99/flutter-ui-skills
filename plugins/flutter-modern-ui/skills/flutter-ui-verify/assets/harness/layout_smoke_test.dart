// Every screen × every size, text scale, theme, platform and direction in
// uiConfig: fails with one line per error and the source location. A case's
// `act` (push a route from the shell, open edit mode…) runs in every
// variant, and its errors count too.
//
// Phones and tablets render under their system bars (uiConfig.systemBars):
// text, icons and tap targets must stay clear of the status bar, the Dynamic
// Island and the navigation bar by uiConfig.systemBarGap, at rest and with
// every scroll view scrolled to its end (the last row also clears a FAB).
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
      // The same system-bar problem usually shows in many variants: one line
      // each, with the variants it showed in.
      final barProblems = <String, List<String>>{};
      for (final variant in uiConfig.matrix) {
        final errors = await collectUiErrors(
          () => runVariant(tester, variant, () async {
            await pumpCase(tester, uiConfig, variant, uiCase);
            for (final problem in await systemBarProblems(tester, uiConfig, variant)) {
              (barProblems[problem] ??= []).add(variant.id);
            }
          }),
        );
        failures.addAll(errors.map((error) => '[${variant.id}] $error'));
      }
      barProblems.forEach((problem, variants) {
        final more = variants.length > 1 ? ' and ${variants.length - 1} more' : '';
        failures.add('[${variants.first}$more] $problem');
      });
      await tester.pumpWidget(const SizedBox.shrink());
      expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
    });
  }
}
