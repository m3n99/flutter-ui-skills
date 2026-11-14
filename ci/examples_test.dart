// CI only (copied to test/ci/ by scripts/sandbox.sh): behaviour the example
// screens promise in the references.
// - layout.md › List-detail: the pane closes with its ✕, by clicking the open
//   row again, and with Esc.
// - components.md › Chips: a few single-choice options wrap with their
//   inline label, and every option stays on screen at 360 px and 1.3.
// - components.md › Navigation: in an IndexedStack shell, FABs with the
//   default hero tag throw when a route is pushed; `heroTag: null` doesn't
//   (and the harness's shell case would catch it).

import 'package:app/examples/record_form_screen.dart';
import 'package:app/examples/records_screen.dart';
import 'package:app/examples/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/ui_cases.dart';
import '../ui/ui_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  setUpAll(loadUiFonts);

  testWidgets('list-detail: the pane closes with ✕, a second click on the open row, and Esc', (tester) async {
    const variant = UiVariant(size: UiSize.desktop, platform: TargetPlatform.windows);
    await runVariant(tester, variant, () async {
      await pumpUi(tester, uiConfig, variant, (_) => RecordsScreen(repository: InvoiceRepository(latency: Duration.zero)));

      final row = find.text('INV-1033 · due Oct 5');
      final close = find.byTooltip('Close details');
      final empty = find.text('Select an invoice');
      expect(empty, findsOneWidget);

      await tester.tap(row);
      await _settle(tester);
      expect(close, findsOneWidget);
      expect(empty, findsNothing);

      await tester.tap(close);
      await _settle(tester);
      expect(empty, findsOneWidget, reason: 'the ✕ returns to the empty pane');

      await tester.tap(row);
      await _settle(tester);
      await tester.tap(row);
      await _settle(tester);
      expect(empty, findsOneWidget, reason: 'clicking the open row again deselects it');

      await tester.tap(row);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(empty, findsOneWidget, reason: 'Esc closes the pane');
    });
  });

  testWidgets('form: the labeled terms chips wrap and stay on screen at 360 px and text scale 1.3', (tester) async {
    const variant = UiVariant(size: UiSize.phone, textScale: 1.3, direction: TextDirection.rtl);
    await runVariant(tester, variant, () async {
      await pumpUi(tester, uiConfig, variant, (_) => RecordFormScreen(repository: InvoiceRepository(latency: Duration.zero)));

      final label = find.text('Terms');
      await tester.ensureVisible(label);
      await _settle(tester);

      final width = variant.size.width;
      final labelRect = tester.getRect(label);
      final first = tester.getRect(find.widgetWithText(ChoiceChip, 'Due on receipt'));
      expect((labelRect.center.dy - first.center.dy).abs(), lessThan(1), reason: 'the label stays on the first chip\'s line');

      for (final option in ['Due on receipt', 'Net 14', 'Net 30']) {
        final chip = tester.getRect(find.widgetWithText(ChoiceChip, option));
        expect(chip.left, greaterThanOrEqualTo(0), reason: '$option starts on screen');
        expect(chip.right, lessThanOrEqualTo(width), reason: '$option ends on screen');
      }

      await tester.tap(find.widgetWithText(ChoiceChip, 'Net 30'));
      await _settle(tester);
      expect(find.text('Due in 30 days'), findsOneWidget);
    });
  });

  testWidgets('shell: default FAB hero tags throw on push, heroTag: null does not', (tester) async {
    const variant = UiVariant(size: UiSize.phone);

    Widget tab(String label, {required bool untagged}) => Scaffold(
          body: Center(child: Text(label)),
          floatingActionButton: untagged
              ? FloatingActionButton(heroTag: null, onPressed: () {}, child: const Icon(Icons.add_rounded))
              : FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add_rounded)),
        );

    Future<List<String>> pushFromShell({required bool untagged}) => collectUiErrors(
          () => runVariant(tester, variant, () async {
            await pumpUi(
              tester,
              uiConfig,
              variant,
              (_) => IndexedStack(children: [tab('Home', untagged: untagged), tab('Records', untagged: untagged)]),
              settle: Duration.zero,
            );
            Navigator.of(tester.element(find.text('Home'))).push(
              MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Center(child: Text('Next')))),
            );
            await settleFrames(tester);
          }),
        );

    expect((await pushFromShell(untagged: false)).join('\n'), contains('multiple heroes that share the same tag'));
    expect(await pushFromShell(untagged: true), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
