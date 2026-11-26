// Behaviour tests for the plugin's shared widgets and theme. Copy this file
// only when the project uses them (AnimatedItems, AppMessenger.deleteWithUndo,
// SubmitButton, Shimmer, AppChoiceChips, ToneColors, AppTheme, the motion
// level, context.isNarrow / listEndPadding, SheetScaffold.error).
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

  testWidgets('EmptyState.inline works inside a page that already scrolls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ListView(
            children: [
              const SizedBox(height: AppSize.touchTarget, child: Text('The form above the log')),
              const EmptyState.inline(icon: Icons.receipt_long_outlined, message: 'No cheques printed yet.'),
              EmptyState.inlineError(message: "Couldn't load the log.", onRetry: () {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull, reason: 'a nested scroll view in a scrolling page asserts; the inline state has none');
    expect(find.text('No cheques printed yet.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // Sized for a section, not a screen: far shorter than the full state.
    expect(tester.getSize(find.byType(EmptyState).first).height, lessThan(200));
  });

  testWidgets('keepTogether: a wrapped line breaks between values, never inside one', (tester) async {
    final pieces = [keepTogether('1–3 × 500 ₪'), keepTogether('4–6 × 1,200 ₪'), keepTogether('7–9 × 2,500 ₪')];
    final text = pieces.join('، ');
    final painter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 16, fontFamily: 'IBM Plex Sans Arabic')),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: 150);
    expect(painter.computeLineMetrics().length, greaterThan(1), reason: 'narrow enough to wrap');
    var offset = 0;
    final broken = <String>[];
    while (offset < text.length) {
      final line = painter.getLineBoundary(TextPosition(offset: offset));
      final content = text.substring(line.start, line.end).replaceAll('،', '').trim();
      if (content.isNotEmpty && !pieces.contains(content)) broken.add(content);
      offset = line.end > offset ? line.end : offset + 1;
    }
    expect(broken, isEmpty, reason: 'a line holds part of a value: ${broken.join(' | ')}');
    painter.dispose();
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

  testWidgets('deleteWithUndo: a failed refresh is not reported as a failed delete; a closed screen still commits', (tester) async {
    final pending = PendingDeletes<int>();
    final committed = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        scaffoldMessengerKey: AppMessenger.key,
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );

    final deleted = AppMessenger.deleteWithUndo<int>(
      pending: pending,
      key: 1,
      message: 'Deleted row 1',
      commit: () async => committed.add(1),
      reload: () async => throw StateError('offline'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // The screen closes during the Undo window and disposes its list.
    pending.dispose();
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(seconds: 1));
    await deleted;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(committed, [1], reason: 'the confirmed delete runs although the screen is gone');
    expect(find.textContaining("couldn't refresh"), findsOneWidget);
    expect(find.textContaining("Couldn't delete"), findsNothing);

    // Let the message close, so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Shimmer: no frames scheduled under reduced motion, animating otherwise', (tester) async {
    // One theme for every pump: a new ThemeData would start MaterialApp's own
    // theme cross-fade, which is a ticker too.
    final theme = AppTheme.light();
    Widget app({required bool reduceMotion}) => MaterialApp(
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: const Scaffold(body: Shimmer(child: SkeletonBox(height: AppSize.touchTarget))),
        );

    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, 0, reason: 'a static skeleton must not keep a ticker running');

    await tester.pumpWidget(app(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0), reason: 'the shimmer sweeps when motion is allowed');

    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, 0, reason: 'turning reduced motion on stops the ticker');
    await tester.pumpWidget(const SizedBox.shrink());
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

    // The label is invisible while busy, but the button still has its name.
    final semantics = tester.ensureSemantics();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel(RegExp('Save')), findsWidgets, reason: 'a busy SubmitButton keeps its name for screen readers');
    semantics.dispose();

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

  test('ToneColors.fromSeed: saturated seeds still give soft containers with readable text', () {
    const seeds = {
      'red': Color(0xFFD32F2F),
      'amber': Color(0xFFFFB300),
      'green': Color(0xFF1E8E3E),
      'orange': Color(0xFFFF5A1F),
      'purple': Color(0xFF7C3AED),
      'lime': Color(0xFFC6FF00),
    };
    final failures = <String>[];
    for (final MapEntry(key: name, value: seed) in seeds.entries) {
      for (final brightness in Brightness.values) {
        final tone = ToneColors.fromSeed(seed, brightness);
        final label = '$name ${brightness.name}';
        final problem = softContainerProblem(tone.container, brightness);
        if (problem != null) failures.add('$label: container $problem');
        final ratio = contrastRatio(tone.onContainer, tone.container);
        if (ratio < 4.5) failures.add('$label: onContainer on container ${ratio.toStringAsFixed(2)}:1');
      }
    }
    expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
  });

  testWidgets('motion level: none shows entrances at once, soft and expressive animate them', (tester) async {
    Future<Duration> pumpLevel(MotionLevel level) async {
      late Duration medium;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(config: AppThemeConfig(motion: level)),
          home: Builder(
            builder: (context) {
              medium = context.motion(AppDurations.medium);
              return const Scaffold(body: Entrance(child: Text('row')));
            },
          ),
        ),
      );
      return medium;
    }

    final entranceFade = find.descendant(of: find.byType(Entrance), matching: find.byType(FadeTransition));

    expect(await pumpLevel(MotionLevel.none), Duration.zero);
    expect(entranceFade, findsNothing, reason: 'none: the end state at once');

    await tester.pumpWidget(const SizedBox.shrink());
    expect(await pumpLevel(MotionLevel.soft), AppDurations.medium);
    expect(entranceFade, findsOneWidget);
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(const SizedBox.shrink());
    expect(await pumpLevel(MotionLevel.expressive), AppDurations.medium * 1.2);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('isNarrow follows width ÷ text scale; listEndPadding clears the bars and the FAB', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 48);
    addTearDown(tester.view.reset);

    Future<(bool, double)> measure(double textScale) async {
      late bool narrow;
      late double end;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              narrow = context.isNarrow;
              end = context.listEndPadding(fab: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return (narrow, end);
    }

    expect((await measure(1.0)).$1, isFalse, reason: '360 px at 1.0 is not narrow');
    expect((await measure(1.3)).$1, isTrue, reason: '360 ÷ 1.3 = 277 < 340');
    expect((await measure(1.0)).$2, 48 + AppSpace.lg + AppSize.fabClearance);
  });

  testWidgets('SheetScaffold.error shows inside the sheet, above the footer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SheetScaffold(
            title: 'Add payment',
            error: "Couldn't save: the check number is already used.",
            primaryAction: FilledButton(onPressed: null, child: Text('Save')),
            children: [Text('Amount')],
          ),
        ),
      ),
    );

    final error = tester.getRect(find.textContaining("Couldn't save"));
    final save = tester.getRect(find.text('Save'));
    expect(error.bottom, lessThanOrEqualTo(save.top), reason: 'the message sits above the footer');
  });

  test('AppTheme: a fidelity brand seed keeps its containers soft', () {
    const config = AppThemeConfig(seed: Color(0xFFE11D48), variant: DynamicSchemeVariant.fidelity);
    for (final brightness in Brightness.values) {
      final scheme = AppTheme.build(brightness, config: config).colorScheme;
      for (final (name, color) in [
        ('primaryContainer', scheme.primaryContainer),
        ('tertiaryContainer', scheme.tertiaryContainer),
      ]) {
        expect(softContainerProblem(color, brightness), isNull, reason: '$name, ${brightness.name}');
      }
    }
  });
}
