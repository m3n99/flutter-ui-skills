// CI only (copied to test/ci/ by scripts/sandbox.sh): the harness reports what
// it should, and stays quiet where it says it does.
// - an overflow is reported once, with the source line of the widget;
// - a pick-one sheet that stays open, a sheet with no primary action and a
//   primary action under the keyboard all fail the sheet check;
// - the system-bar check tells an overlap from the house rule, exempts
//   Cupertino bars, and skips an endless list instead of asserting;
// - dark variants set the device brightness too;
// - `only` trims the matrix;
// - the rendered accessibility check catches low-contrast text, a small and
//   an unlabeled tap target, passes a clean screen, and runs one variant per
//   platform, theme and direction.

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

  testWidgets('a11y: low-contrast text, a small and an unlabeled target fail; a clean screen passes', (tester) async {
    const variant = UiVariant(size: UiSize.phone);
    Future<List<String>> problemsOf(Widget body) async {
      late List<String> problems;
      await runVariant(tester, variant, () async {
        await pumpUi(tester, uiConfig, variant, (_) => Scaffold(body: SafeArea(child: body)), settle: Duration.zero);
        problems = await screenA11yProblems(tester, variant);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      return problems;
    }

    final clean = await problemsOf(
      ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Center(
          child: TextButton(
            onPressed: () {},
            child: const Text('Save changes', style: TextStyle(color: Color(0xFF000000), fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
    expect(clean, isEmpty, reason: clean.join('\n'));

    final faint = await problemsOf(
      const ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Center(child: Text('Due next week', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 14))),
      ),
    );
    expect(faint.where((p) => p.startsWith('text contrast: "Due next week"')), hasLength(1), reason: faint.join('\n'));

    final small = await problemsOf(
      Center(
        child: Semantics(
          button: true,
          label: 'Close',
          child: GestureDetector(onTap: () {}, child: const SizedBox(width: 24, height: 24)),
        ),
      ),
    );
    expect(small.where((p) => p.startsWith('tap target: "Close"')), hasLength(1), reason: small.join('\n'));

    final unlabeled = await problemsOf(
      Center(
        child: Semantics(
          button: true,
          child: GestureDetector(onTap: () {}, child: const SizedBox(width: 56, height: 56)),
        ),
      ),
    );
    expect(unlabeled.where((p) => p.startsWith('tappable without a label')), hasLength(1), reason: unlabeled.join('\n'));
  });

  test('a11yMatrix: one variant per platform, theme and direction, at the smallest size the app meets', () {
    final config = UiConfig(
      theme: uiConfig.theme,
      platforms: const [TargetPlatform.android, TargetPlatform.windows],
      directions: const [TextDirection.ltr, TextDirection.rtl],
      only: (variant) => variant.isTouch || variant.size.width >= 600,
    );
    final variants = config.a11yMatrix.toList();
    // 2 platforms × 2 themes × 2 directions.
    expect(variants, hasLength(8));
    expect(variants.where((v) => v.isTouch).map((v) => v.size.width).toSet(), {360});
    expect(variants.where((v) => !v.isTouch).map((v) => v.size.width).toSet(), {1000});
    expect(variants.map((v) => v.textScale).toSet(), {1.0});
  });
}
