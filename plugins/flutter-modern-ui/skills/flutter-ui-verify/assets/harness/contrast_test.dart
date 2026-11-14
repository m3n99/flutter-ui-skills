// Checks the theme's color pairs in light and dark mode:
// text ≥ 4.5:1 on every surface level and on every container it is meant
// for, outlines and primary ≥ 3:1 / 4.5:1 on surfaces (WCAG 2.2 AA).
// Then that containers read as soft tints: a container as strong as its
// seed passes every contrast check and still looks like a solid block.
// Run after any palette change, brand override or eye-comfort tweak.
//
//   flutter test test/ui/contrast_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_cases.dart';
import 'ui_harness.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('contrast: ${brightness.name}', () {
      final theme = uiConfig.theme(brightness, TargetPlatform.android);
      final s = theme.colorScheme;
      final failures = <String>[];

      void check(String name, Color foreground, Color background, double minimum) {
        final ratio = contrastRatio(foreground, background);
        if (ratio < minimum) failures.add('$name: ${ratio.toStringAsFixed(2)}:1 (needs $minimum:1)');
      }

      final surfaces = {
        'surface': s.surface,
        'surfaceContainerLowest': s.surfaceContainerLowest,
        'surfaceContainerLow': s.surfaceContainerLow,
        'surfaceContainer': s.surfaceContainer,
        'surfaceContainerHigh': s.surfaceContainerHigh,
        'surfaceContainerHighest': s.surfaceContainerHighest,
      };
      for (final entry in surfaces.entries) {
        check('onSurface on ${entry.key}', s.onSurface, entry.value, 4.5);
        check('onSurfaceVariant on ${entry.key}', s.onSurfaceVariant, entry.value, 4.5);
        check('primary (text buttons, links) on ${entry.key}', s.primary, entry.value, 4.5);
        check('outline (input borders) on ${entry.key}', s.outline, entry.value, 3);
        check('error on ${entry.key}', s.error, entry.value, 4.5);
      }

      check('onPrimary on primary', s.onPrimary, s.primary, 4.5);
      check('onPrimaryContainer on primaryContainer', s.onPrimaryContainer, s.primaryContainer, 4.5);
      check('onSecondaryContainer on secondaryContainer', s.onSecondaryContainer, s.secondaryContainer, 4.5);
      check('onTertiaryContainer on tertiaryContainer', s.onTertiaryContainer, s.tertiaryContainer, 4.5);
      check('onError on error', s.onError, s.error, 4.5);
      check('onErrorContainer on errorContainer', s.onErrorContainer, s.errorContainer, 4.5);
      check('onInverseSurface on inverseSurface', s.onInverseSurface, s.inverseSurface, 4.5);
      check('inversePrimary (message actions) on inverseSurface', s.inversePrimary, s.inverseSurface, 4.5);

      for (final (name, foreground, background, minimum) in uiConfig.extraContrastPairs?.call(theme) ?? const <(String, Color, Color, double)>[]) {
        check(name, foreground, background, minimum);
      }

      final soft = uiConfig.softContainers?.call(theme) ??
          [
            ('primaryContainer', s.primaryContainer),
            ('secondaryContainer', s.secondaryContainer),
            ('tertiaryContainer', s.tertiaryContainer),
            ('errorContainer', s.errorContainer),
          ];
      for (final (name, color) in soft) {
        final problem = softContainerProblem(color, brightness);
        if (problem != null) failures.add('$name $problem');
      }

      expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
    });
  }
}
