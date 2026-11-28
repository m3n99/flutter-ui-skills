// Every screen, rendered, against flutter_test's accessibility guidelines:
// tap targets ≥ 48 × 48 px on Android (44 × 44 on iOS), a label on every
// tappable, and text contrast measured on the pixels behind the text
// (WCAG 2.2 AA: 4.5:1, or 3:1 from 18 px / 14 px bold; disabled controls
// are exempt).
//
// contrast_test.dart checks the theme's color pairs. This checks what the
// screens actually paint: text on an image or a gradient, on a tinted card,
// in a custom color, a hint that looks disabled but isn't.
//
// It runs one variant per platform, theme and direction (uiConfig.a11yMatrix:
// the smallest size, text scale 1.0). It uses flutter_test's own font on
// purpose: its glyphs are solid squares, so the measured color is the text's
// color and not the anti-aliased edge of a thin stroke. Layout errors from
// the wider glyphs are ignored here; layout_smoke_test.dart checks layout
// with the real fonts.
//
//   flutter test test/ui/a11y_test.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_cases.dart';
import 'ui_harness.dart';

void main() {
  setUpAll(() async {
    await uiConfig.setUp?.call();
  });

  for (final uiCase in uiCases) {
    testWidgets('a11y: ${uiCase.name}', (tester) async {
      // The same problem usually shows in several variants: one line each,
      // with the variants it showed in.
      final found = <String, List<String>>{};
      for (final variant in uiConfig.a11yMatrix) {
        // Layout errors are layout_smoke_test's job (with the real fonts).
        await collectUiErrors(
          () => runVariant(tester, variant, () async {
            await pumpCase(tester, uiConfig, variant, uiCase);
            for (final problem in await screenA11yProblems(tester, variant)) {
              (found[problem] ??= []).add(variant.id);
            }
          }),
        );
      }
      final failures = [
        for (final entry in found.entries)
          '[${entry.value.first}${entry.value.length > 1 ? ' and ${entry.value.length - 1} more' : ''}] ${entry.key}',
      ];
      await tester.pumpWidget(const SizedBox.shrink());
      expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
    });
  }
}
