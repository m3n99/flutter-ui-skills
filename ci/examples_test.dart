// CI only (copied to test/ci/ by scripts/sandbox.sh): behaviour the example
// screens promise in the references.
// - layout.md › List-detail: the pane closes with its ✕, by clicking the open
//   row again, and with Esc.
// - components.md › Chips: a few single-choice options wrap with their
//   inline label, and every option stays on screen at 360 px and 1.3.
// - components.md › Navigation: in an IndexedStack shell, FABs with the
//   default hero tag throw when a route is pushed; `heroTag: null` doesn't
//   (and the harness's shell case would catch it).
// - layout.md › System bars: the harness's system-bar check catches a header
//   under the status bar, a button on the navigation bar and a list whose
//   end can't scroll clear of it, and passes SafeArea + padding, SaveBar and
//   context.listEndPadding().

import 'package:app/design_system/design_system.dart';
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

      final row = find.text('Due Oct 5');
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

  testWidgets('system bars: the check catches what touches them and passes the safe versions', (tester) async {
    const variant = UiVariant(size: UiSize.phone);

    Future<String> problemsFor(Widget body) async {
      var problems = <String>[];
      await runVariant(tester, variant, () async {
        await pumpUi(tester, uiConfig, variant, (_) => Scaffold(body: body), settle: Duration.zero);
        problems = await systemBarProblems(tester, uiConfig, variant);
      });
      return problems.join('\n');
    }

    Widget pinnedBottom(Widget bar) => Column(children: [const Expanded(child: SizedBox.expand()), bar]);
    Widget rows(EdgeInsetsGeometry padding) => ListView(
          padding: padding,
          children: [for (var i = 0; i < 30; i++) ListTile(title: Text('Row $i'), onTap: () {})],
        );

    final header = await problemsFor(const Text('Good morning'));
    expect(header, contains('"Good morning" is'));
    expect(header, contains('the status bar'));
    expect(
      await problemsFor(const SafeArea(child: Padding(padding: EdgeInsets.all(AppSpace.md), child: Text('Good morning')))),
      isEmpty,
    );

    final button = await problemsFor(pinnedBottom(FilledButton(onPressed: () {}, child: const Text('Pay now'))));
    expect(button, contains('"Pay now" (tap target) is'));
    expect(button, contains('the navigation bar'));
    expect(await problemsFor(pinnedBottom(SaveBar(child: FilledButton(onPressed: () {}, child: const Text('Pay now'))))), isEmpty);

    final list = await problemsFor(SafeArea(bottom: false, child: rows(const EdgeInsets.all(AppSpace.md))));
    expect(list, contains('at the end of the scroll, "Row 29"'));
    expect(
      await problemsFor(
        SafeArea(
          bottom: false,
          child: Builder(
            builder: (context) => rows(
              EdgeInsetsDirectional.fromSTEB(AppSpace.md, AppSpace.md, AppSpace.md, context.listEndPadding()),
            ),
          ),
        ),
      ),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
