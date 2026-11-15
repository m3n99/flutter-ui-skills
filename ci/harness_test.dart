// CI only (copied to test/ci/ by scripts/sandbox.sh): the harness reports what
// it should, and stays quiet where it says it does.
// - an overflow is reported once, with the source line of the widget;
// - a pick-one sheet that stays open, a sheet with no primary action and a
//   primary action under the keyboard all fail the sheet check;
// - the system-bar check tells an overlap from the house rule, exempts
//   Cupertino bars, and skips an endless list instead of asserting;
// - dark variants set the device brightness too;
// - `only` trims the matrix.

import 'package:app/design_system/design_system.dart';
import 'package:flutter/cupertino.dart' show CupertinoNavigationBar, CupertinoPageScaffold;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/ui_cases.dart';
import '../ui/ui_harness.dart';

void main() {
  setUpAll(loadUiFonts);

  testWidgets('layout errors: an overflow is reported with its source line', (tester) async {
    const variant = UiVariant(size: UiSize.phone);
    final errors = await collectUiErrors(
      () => runVariant(tester, variant, () async {
        await pumpUi(
          tester,
          uiConfig,
          variant,
          (_) => const Scaffold(
            body: SafeArea(
              child: Row(children: [Text('A customer name that is far too long for a 360 px phone and has no Expanded')]),
            ),
          ),
          settle: Duration.zero,
        );
      }),
    );
    await tester.pumpWidget(const SizedBox.shrink());

    final report = errors.join('\n');
    expect(report, contains('overflowed'));
    expect(report, contains(RegExp(r'← test/ci/harness_test\.dart:\d+')), reason: 'the line names where the widget was created');
  });

  testWidgets('sheets: a stuck picker, a missing primary action and one under the keyboard fail', (tester) async {
    const variant = UiVariant(size: UiSize.phone);

    Future<String> problemsFor(SheetCase sheet) async {
      var problems = <String>[];
      await runVariant(tester, variant, () async {
        await pumpUi(tester, uiConfig, variant, sheetHost, settle: Duration.zero);
        await openSheet(tester, sheet);
        problems = await sheetProblems(tester, uiConfig, variant, sheet);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      return problems.join('\n');
    }

    final stuck = await problemsFor(
      SheetCase.picker(
        'stuck',
        (context) => showDialog<void>(
          context: context,
          builder: (_) => SimpleDialog(
            title: const Text('Sort by'),
            children: [
              for (final label in const ['Due date', 'Amount']) ListTile(title: Text(label), onTap: () {}),
            ],
          ),
        ),
      ),
    );
    expect(stuck, contains('tapping an option left the sheet open'));

    final noPrimary = await problemsFor(
      SheetCase(
        'no_primary',
        (context) => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export invoices?'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
        ),
      ),
    );
    expect(noPrimary, contains('primary action not found'));

    final covered = await problemsFor(
      SheetCase(
        'covered',
        // Not padded by the keyboard's height: the button stays at the
        // bottom edge, under the keyboard.
        (context) => showModalBottomSheet<void>(
          context: context,
          builder: (context) => SizedBox(
            height: 240,
            child: Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: FilledButton(
                key: sheetPrimaryActionKey,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Save payment'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(covered, contains('primary action hidden by a 300 px keyboard'));
  });

  testWidgets('system bars: overlap is a defect, the gap is the house rule and can be changed', (tester) async {
    const variant = UiVariant(size: UiSize.phone);
    // A plain list directly inside SafeArea: nothing is covered, but its
    // first and last rows touch the safe area's edges.
    Widget flushList(BuildContext context) => Scaffold(
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [for (var i = 0; i < 30; i++) ListTile(title: Text('Row $i'), onTap: () {})],
            ),
          ),
        );

    Future<String> problemsWith(UiConfig config) async {
      var problems = <String>[];
      await runVariant(tester, variant, () async {
        await pumpUi(tester, config, variant, flushList, settle: Duration.zero);
        problems = await systemBarProblems(tester, config, variant);
      });
      return problems.join('\n');
    }

    final house = await problemsWith(uiConfig);
    expect(house, contains('house rule'));
    expect(house, isNot(contains('px under')), reason: 'nothing is under a bar');

    expect(await problemsWith(UiConfig(theme: uiConfig.theme, systemBarGap: 0)), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('system bars: Cupertino bars pad themselves; an endless list is skipped, not asserted on', (tester) async {
    const ios = UiVariant(size: UiSize.phone, platform: TargetPlatform.iOS);
    var problems = <String>['not run'];
    final cupertinoErrors = await collectUiErrors(
      () => runVariant(tester, ios, () async {
        await pumpUi(
          tester,
          uiConfig,
          ios,
          (_) => const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text('Invoices')),
            child: SafeArea(
              child: Padding(padding: EdgeInsets.all(AppSpace.md), child: Text('Nothing to collect today')),
            ),
          ),
          settle: Duration.zero,
        );
        problems = await systemBarProblems(tester, uiConfig, ios);
      }),
    );
    expect(cupertinoErrors, isEmpty);
    expect(problems, isEmpty);

    const android = UiVariant(size: UiSize.phone);
    problems = ['not run'];
    final endlessErrors = await collectUiErrors(
      () => runVariant(tester, android, () async {
        await pumpUi(
          tester,
          uiConfig,
          android,
          (_) => Scaffold(
            body: SafeArea(
              bottom: false,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpace.md),
                itemBuilder: (context, index) => ListTile(title: Text('Row $index'), onTap: () {}),
              ),
            ),
          ),
          settle: Duration.zero,
        );
        problems = await systemBarProblems(tester, uiConfig, android);
      }),
    );
    expect(endlessErrors, isEmpty, reason: 'an endless list has no end to jump to');
    expect(problems, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dark variants set the device brightness, not only the theme', (tester) async {
    const variant = UiVariant(size: UiSize.phone, brightness: Brightness.dark);
    Brightness? device;
    await runVariant(tester, variant, () async {
      await pumpUi(tester, uiConfig, variant, (context) {
        device = MediaQuery.platformBrightnessOf(context);
        return const Scaffold(body: SizedBox.expand());
      }, settle: Duration.zero);
    });
    expect(device, Brightness.dark);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('only: drops the combinations the app never meets', () {
    final all = UiConfig(theme: uiConfig.theme, platforms: const [TargetPlatform.android, TargetPlatform.windows]);
    final trimmed = UiConfig(
      theme: uiConfig.theme,
      platforms: const [TargetPlatform.android, TargetPlatform.windows],
      only: (variant) => variant.isTouch || variant.size.width >= 600,
    );
    // 3 sizes × 2 platforms × 2 themes × 1 direction × 3 text scales.
    expect(all.matrix.length, 36);
    // Windows at 360 px is gone: 2 themes × 3 text scales.
    expect(trimmed.matrix.length, 30);
    expect(trimmed.matrix.where((v) => !v.isTouch && v.size.width < 600), isEmpty);
  });
}
