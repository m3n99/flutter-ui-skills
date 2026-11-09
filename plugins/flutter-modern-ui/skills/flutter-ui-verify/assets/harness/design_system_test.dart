// Behaviour tests for the plugin's shared widgets. Copy this file only when
// the project uses them (AnimatedItems, AppMessenger.deleteWithUndo,
// SubmitButton, AppChoiceChips).
//
//   flutter test test/ui/design_system_test.dart

import 'dart:async';

import 'package:app/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_harness.dart';

class _Counter extends StatefulWidget {
  const _Counter(this.label);

  final String label;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () => setState(() => _taps++), child: Text('${widget.label} · $_taps'));
  }
}

Widget _list(List<int> items, {bool reduceMotion = false}) {
  return MaterialApp(
    theme: AppTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          AnimatedItems<int>(
            items: items,
            keyOf: (item) => item,
            itemBuilder: (context, item) => _Counter('item $item'),
          ),
        ],
      ),
    ),
  );
}

void main() {
  // Real glyph widths: chip and label sizes depend on them.
  setUpAll(loadUiFonts);

  testWidgets('AnimatedItems keeps item state across inserts and removes', (tester) async {
    await tester.pumpWidget(_list([1, 2, 3]));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('item 2 · 0'));
    await tester.pump();
    expect(find.text('item 2 · 1'), findsOneWidget);

    // Insert above: item 2 moves down but keeps its state.
    await tester.pumpWidget(_list([0, 1, 2, 3]));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('item 0 · 0'), findsOneWidget);
    expect(find.text('item 2 · 1'), findsOneWidget);

    // Remove: the item animates out, then disappears; neighbours keep state.
    await tester.pumpWidget(_list([0, 2, 3]));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('item 1 · 0'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('item 1 · 0'), findsNothing);
    expect(find.text('item 2 · 1'), findsOneWidget);

    // Reorder: rebuilt with the entrance.
    await tester.pumpWidget(_list([3, 2, 0]));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('item 3'), findsOneWidget);
    expect(find.textContaining('item 0'), findsOneWidget);
  });

  testWidgets('AnimatedItems removes at once under reduced motion', (tester) async {
    await tester.pumpWidget(_list([1, 2, 3], reduceMotion: true));
    await tester.pump();
    await tester.pumpWidget(_list([1, 3], reduceMotion: true));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('item 2'), findsNothing);
  });

  testWidgets('deleteWithUndo: Undo keeps the item, a timeout commits it', (tester) async {
    final pending = PendingDeletes<int>();
    final committed = <int>[];
    addTearDown(pending.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        scaffoldMessengerKey: AppMessenger.key,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: pending,
            builder: (context, _) => Column(
              children: [for (final id in pending.visible([1, 2], (int id) => id)) Text('row $id')],
            ),
          ),
        ),
      ),
    );

    final undone = AppMessenger.deleteWithUndo<int>(
      pending: pending,
      key: 1,
      message: 'Deleted row 1',
      commit: () async => committed.add(1),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('row 1'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await undone;
    await tester.pump();
    expect(committed, isEmpty);
    expect(find.text('row 1'), findsOneWidget);

    final deleted = AppMessenger.deleteWithUndo<int>(
      pending: pending,
      key: 2,
      message: 'Deleted row 2',
      commit: () async => committed.add(2),
    );
    // The 6 s timer starts once the message has finished sliding in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(seconds: 1));
    await deleted;
    expect(committed, [2]);
  });

  testWidgets('SubmitButton shows progress and submits once', (tester) async {
    final completer = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SubmitButton(
              label: 'Save',
              onPressed: () {
                calls++;
                return completer.future;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(SubmitButton), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('AppChoiceChips: an inline label wraps with the chips; every option stays on a 360 px phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const options = ['A4 portrait', 'A5 landscape', 'Letter', 'Legal'];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: AppChoiceChips<String>(
              label: 'Paper',
              options: options,
              selected: const {'A4 portrait'},
              labelOf: (option) => option,
              onToggle: (_) {},
            ),
          ),
        ),
      ),
    );

    final label = tester.getRect(find.text('Paper'));
    final first = tester.getRect(find.widgetWithText(ChoiceChip, options.first));
    expect((label.center.dy - first.center.dy).abs(), lessThan(1), reason: 'the label sits on the first chip\'s line');
    for (final option in options) {
      final chip = tester.getRect(find.widgetWithText(ChoiceChip, option));
      expect(chip.left, greaterThanOrEqualTo(0), reason: option);
      expect(chip.right, lessThanOrEqualTo(360), reason: option);
    }
  });
}
