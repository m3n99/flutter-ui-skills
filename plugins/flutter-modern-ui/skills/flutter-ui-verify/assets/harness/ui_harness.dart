// UI test harness: renders screens and sheets across sizes, text scales,
// themes, platforms and reading directions, under the system bars a phone
// draws (status bar, Dynamic Island, navigation bar); collects layout errors
// with the source line; checks tap targets, the keyboard and what touches the
// system bars; saves screenshots.
//
// Project-independent. Configure it in ui_cases.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show DiagnosticsDebugCreator;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// True when run with `--dart-define=VISUAL=true` (screenshot tests).
const bool kVisualTests = bool.fromEnvironment('VISUAL');

/// Wraps the whole app; screenshots capture this boundary (dialogs and
/// sheets included).
final GlobalKey uiShotKey = GlobalKey(debugLabel: 'ui-shot');

/// Finds SheetScaffold's primary action (design-system sheets).
const Key sheetPrimaryActionKey = Key('sheet-primary-action');

/// A window size to render at.
@immutable
class UiSize {
  const UiSize(this.name, this.width, this.height, {this.devicePixelRatio = 2});

  final String name;
  final double width;
  final double height;
  final double devicePixelRatio;

  /// Small Android phone.
  static const UiSize phone = UiSize('360', 360, 780);

  /// Tablet / small desktop window (expanded size class).
  static const UiSize tablet = UiSize('1000', 1000, 800, devicePixelRatio: 1);

  /// Common laptop.
  static const UiSize desktop = UiSize('1366', 1366, 768, devicePixelRatio: 1);
}

/// One rendering condition.
@immutable
class UiVariant {
  const UiVariant({
    required this.size,
    this.textScale = 1.0,
    this.brightness = Brightness.light,
    this.platform = TargetPlatform.android,
    this.direction = TextDirection.ltr,
    this.reduceMotion = false,
  });

  final UiSize size;
  final double textScale;
  final Brightness brightness;
  final TargetPlatform platform;
  final TextDirection direction;
  final bool reduceMotion;

  bool get isTouch =>
      platform == TargetPlatform.android || platform == TargetPlatform.iOS || platform == TargetPlatform.fuchsia;

  /// Stable, file-name-safe id: `360_light_android_ltr_x1.3`.
  String get id => '${size.name}_${brightness.name}_${platform.name}_${direction.name}_x$textScale';
}

/// The system bars a phone or tablet draws over the app, in logical pixels:
/// on top the status bar with a camera cutout (Android) or the Dynamic Island
/// (iOS); at the bottom the three-button navigation bar (Android) or the home
/// indicator (iOS). Desktop windows have none.
EdgeInsets defaultSystemBars(UiVariant variant) => switch (variant.platform) {
      TargetPlatform.android || TargetPlatform.fuchsia => const EdgeInsets.only(top: 32, bottom: 48),
      TargetPlatform.iOS => const EdgeInsets.only(top: 59, bottom: 34),
      TargetPlatform.linux || TargetPlatform.macOS || TargetPlatform.windows => EdgeInsets.zero,
    };

/// A screen in a given state, built with fake data.
@immutable
class UiCase {
  const UiCase(this.name, this.builder, {this.settle = const Duration(milliseconds: 1200), this.act});

  final String name;
  final WidgetBuilder builder;

  /// Time to let entrances, charts and fake loads finish before checking.
  final Duration settle;

  /// Runs after the screen settles, before the checks and the screenshot:
  /// switch tabs and push a route from the app shell, scroll to the end,
  /// open a menu. Errors it causes are reported like layout errors.
  final Future<void> Function(WidgetTester tester)? act;
}

/// A sheet or dialog, opened from a blank host screen.
@immutable
class SheetCase {
  /// A sheet with a primary action (Save, Apply): it must stay on screen and
  /// above a 300 px keyboard.
  const SheetCase(this.name, this.open, {this.primary})
      : picker = false,
        options = null;

  /// A pick-one sheet: tapping an option is the action, so there is no
  /// primary button. Its options must be on screen with real tap targets,
  /// and tapping one must close the sheet.
  const SheetCase.picker(this.name, this.open, {this.options})
      : picker = true,
        primary = null;

  final String name;
  final void Function(BuildContext context) open;

  /// The primary action. Defaults to SheetScaffold's primary action key.
  final Finder? primary;

  /// Pick-one sheets only.
  final bool picker;

  /// The options of a pick-one sheet. Defaults to [sheetOptions].
  final Finder? options;
}

/// The options of a pick-one sheet: list tiles (radio tiles included) and
/// simple-dialog options.
Finder get sheetOptions => find.byWidgetPredicate(
      (widget) => widget is ListTile || widget is SimpleDialogOption,
      description: 'sheet options (ListTile, SimpleDialogOption)',
    );

/// Everything project-specific: theme, matrix, localization, wrappers.
@immutable
class UiConfig {
  const UiConfig({
    required this.theme,
    this.sizes = const [UiSize.phone, UiSize.tablet, UiSize.desktop],
    this.textScales = const [1.0, 1.3, 1.6],
    this.brightnesses = const [Brightness.light, Brightness.dark],
    this.platforms = const [TargetPlatform.android],
    this.directions = const [TextDirection.ltr],
    this.shots = const [
      UiVariant(size: UiSize.phone),
      UiVariant(size: UiSize.phone, brightness: Brightness.dark),
      UiVariant(size: UiSize.phone, textScale: 1.3),
      UiVariant(size: UiSize.phone, textScale: 1.6),
      UiVariant(size: UiSize.desktop),
    ],
    this.systemBars = defaultSystemBars,
    this.systemBarGap = 8,
    this.localizationsDelegates = const <LocalizationsDelegate<dynamic>>[],
    this.supportedLocales = const [Locale('en')],
    this.localeFor,
    this.scaffoldMessengerKey,
    this.navigatorKey,
    this.wrap,
    this.setUp,
    this.extraContrastPairs,
    this.softContainers,
  });

  /// The app's real theme for a brightness and platform (density).
  final ThemeData Function(Brightness brightness, TargetPlatform platform) theme;

  final List<UiSize> sizes;

  /// 1.3 is Android's old largest font; 1.6 stands for the bigger sizes of
  /// Android 14+ and iOS, and for large display sizes.
  final List<double> textScales;
  final List<Brightness> brightnesses;

  /// Platforms that ship: touch (android/iOS) and/or desktop (windows/macOS/linux).
  final List<TargetPlatform> platforms;

  /// Add TextDirection.rtl when the app supports Arabic, Hebrew, Persian or Urdu.
  final List<TextDirection> directions;

  /// The curated set of screenshots per case.
  final List<UiVariant> shots;

  /// The system bars each variant renders under. They reach the app as
  /// MediaQuery padding, like on a device (SafeArea, app bars and navigation
  /// bars react to them), and screenshots draw them. `(_) => EdgeInsets.zero`
  /// turns them off.
  final EdgeInsets Function(UiVariant variant) systemBars;

  /// The least space between the system bars and text, icons or tap targets:
  /// the little padding on top of the safe area, so nothing touches the
  /// status bar, the Dynamic Island or the navigation bar. null skips the
  /// check (the bars are still drawn).
  final double? systemBarGap;

  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;
  final List<Locale> supportedLocales;

  /// Locale to use for a direction, e.g. `(d) => d == TextDirection.rtl ? const Locale('ar') : const Locale('en')`.
  final Locale? Function(TextDirection direction)? localeFor;

  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Wraps the app's content (Navigator), e.g. with providers.
  final Widget Function(Widget child)? wrap;

  /// Runs once before the first case of every test file: register fakes in
  /// the service locator, answer the channels of plugins that call native
  /// code on start. See references/harness.md › Faking dependencies.
  final Future<void> Function()? setUp;

  /// Extra (label, foreground, background, minimum ratio) pairs to check,
  /// e.g. status tones from a ThemeExtension.
  final List<(String, Color, Color, double)> Function(ThemeData theme)? extraContrastPairs;

  /// The (label, color) containers that must read as soft tints: light tints
  /// in light mode, deep tones in dark mode. Default: the scheme's four
  /// containers. Add theme-extension tones (pills, KPI tiles).
  final List<(String, Color)> Function(ThemeData theme)? softContainers;

  /// Every combination of the lists above.
  Iterable<UiVariant> get matrix sync* {
    for (final size in sizes) {
      for (final platform in platforms) {
        for (final brightness in brightnesses) {
          for (final direction in directions) {
            for (final textScale in textScales) {
              yield UiVariant(
                size: size,
                textScale: textScale,
                brightness: brightness,
                platform: platform,
                direction: direction,
              );
            }
          }
        }
      }
    }
  }
}

/// Runs [body] with [variant]'s platform as the default target platform and
/// always resets it, so the test ends with the override unset.
Future<void> runVariant(WidgetTester tester, UiVariant variant, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = variant.platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

/// Pumps [home] in a fresh app for [variant]. A blank frame first discards
/// state, routes and theme cross-fades from the previous variant.
Future<void> pumpUi(
  WidgetTester tester,
  UiConfig config,
  UiVariant variant,
  WidgetBuilder home, {
  Duration settle = const Duration(milliseconds: 1200),
}) async {
  tester.view.physicalSize = Size(
    variant.size.width * variant.size.devicePixelRatio,
    variant.size.height * variant.size.devicePixelRatio,
  );
  tester.view.devicePixelRatio = variant.size.devicePixelRatio;
  final bars = config.systemBars(variant);
  final ratio = variant.size.devicePixelRatio;
  final barPadding = FakeViewPadding(
    left: bars.left * ratio,
    top: bars.top * ratio,
    right: bars.right * ratio,
    bottom: bars.bottom * ratio,
  );
  tester.view.padding = barPadding;
  tester.view.viewPadding = barPadding;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    RepaintBoundary(
      key: uiShotKey,
      child: Stack(
        fit: StackFit.expand,
        textDirection: TextDirection.ltr,
        children: [
          MaterialApp(
            key: ValueKey(variant.id),
            debugShowCheckedModeBanner: false,
            theme: config.theme(variant.brightness, variant.platform),
            locale: config.localeFor?.call(variant.direction),
            localizationsDelegates: config.localizationsDelegates,
            supportedLocales: config.supportedLocales,
            scaffoldMessengerKey: config.scaffoldMessengerKey,
            navigatorKey: config.navigatorKey,
            builder: (context, child) {
              final content = child ?? const SizedBox.shrink();
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(variant.textScale),
                  disableAnimations: variant.reduceMotion,
                ),
                child: Directionality(
                  textDirection: variant.direction,
                  child: config.wrap?.call(content) ?? content,
                ),
              );
            },
            home: Builder(builder: home),
          ),
          // On top of everything, like the real bars: what they cover shows
          // in screenshots. It takes no taps and adds no semantics.
          IgnorePointer(
            child: CustomPaint(
              painter: SystemBarsPainter(bars: bars, platform: variant.platform, brightness: variant.brightness),
            ),
          ),
        ],
      ),
    ),
  );
  // Advance the clock in frames, not in one jump. A plain pump() doesn't
  // move time, so fake loads (Future.delayed) and delayed skeletons fire
  // inside the settle time; in a single jump, whatever they start (row
  // entrances, cross-fades) would still be at its first frame in the
  // screenshot, showing the loading or empty state instead of the content.
  await tester.pump();
  const frame = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < settle; elapsed += frame) {
    await tester.pump(frame);
  }
}

/// [pumpUi] for [uiCase], then its [UiCase.act].
Future<void> pumpCase(WidgetTester tester, UiConfig config, UiVariant variant, UiCase uiCase) async {
  await pumpUi(tester, config, variant, uiCase.builder, settle: uiCase.settle);
  final act = uiCase.act;
  if (act != null) await act(tester);
}

/// Pumps [frames] frames of [frame] each: lets a tap, a push or a pop
/// finish its animations.
Future<void> settleFrames(WidgetTester tester, {int frames = 8, Duration frame = const Duration(milliseconds: 100)}) async {
  await tester.pump();
  for (var i = 0; i < frames; i++) {
    await tester.pump(frame);
  }
}

/// Collects every error reported while [body] runs (overflows, build and
/// layout exceptions) as one line each, with the source location when the
/// widget was created in lib/ or test/.
Future<List<String>> collectUiErrors(Future<void> Function() body) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(describeUiError(details));
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

String describeUiError(FlutterErrorDetails details) {
  final headline = details.exceptionAsString().split('\n').first.trim();
  final location = _sourceLocation(details.toString());
  return location == null ? headline : '$headline  ← $location';
}

String? _sourceLocation(String text) {
  for (final match in RegExp(r'file://(/\S+?\.dart):(\d+):(\d+)').allMatches(text)) {
    final path = match.group(1)!;
    if (path.contains('/packages/flutter/') ||
        path.contains('/.pub-cache/') ||
        path.contains('/Pub/Cache/') ||
        path.contains('/flutter_test/')) {
      continue;
    }
    final project = RegExp(r'/(lib|test)/').firstMatch(path);
    if (project != null) return '${path.substring(project.start + 1)}:${match.group(2)}';
  }
  return null;
}

/// Opens [sheet] from a blank host screen and waits for the route animation.
Future<void> openSheet(WidgetTester tester, SheetCase sheet) async {
  sheet.open(tester.element(find.byKey(_sheetHostKey)));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

const Key _sheetHostKey = Key('ui-sheet-host');

/// Blank screen the sheet cases open from.
Widget sheetHost(BuildContext context) => const Scaffold(body: SizedBox.expand(key: _sheetHostKey));

/// Simulates a [height] px software keyboard. Like on a device, it covers
/// the navigation bar, so the bottom padding drops to zero while it's up.
void showKeyboard(WidgetTester tester, double height) {
  final bars = tester.view.viewPadding;
  tester.view.padding = FakeViewPadding(left: bars.left, top: bars.top, right: bars.right);
  tester.view.viewInsets = FakeViewPadding(bottom: height * tester.view.devicePixelRatio);
}

void hideKeyboard(WidgetTester tester) {
  final bars = tester.view.viewPadding;
  tester.view.padding = FakeViewPadding(left: bars.left, top: bars.top, right: bars.right, bottom: bars.bottom);
  tester.view.resetViewInsets();
}

/// Paints the system bars over the app the way a phone shows them: the
/// status bar (time, camera cutout or Dynamic Island, battery) and the
/// navigation bar (back, home and recents on a translucent scrim) or the home
/// indicator. Screenshots then show what the bars cover.
class SystemBarsPainter extends CustomPainter {
  const SystemBarsPainter({required this.bars, required this.platform, required this.brightness});

  final EdgeInsets bars;
  final TargetPlatform platform;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = brightness == Brightness.dark ? const Color(0xFFF1F1F1) : const Color(0xFF1F1F1F);
    final fill = Paint()..color = ink;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final black = Paint()..color = const Color(0xFF000000);
    final ios = platform == TargetPlatform.iOS;

    if (bars.top > 0) {
      final y = ios ? 11 + 37 / 2 : bars.top / 2;
      final time = TextPainter(
        text: TextSpan(
          text: '9:41',
          style: TextStyle(color: ink, fontSize: ios ? 17 : 14, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      time.paint(canvas, Offset(ios ? 32 : 16, y - time.height / 2));
      time.dispose();
      final battery = Rect.fromLTWH(size.width - (ios ? 36 : 30), y - 5.5, 22, 11);
      canvas.drawRRect(RRect.fromRectAndRadius(battery, const Radius.circular(3)), line);
      canvas.drawRRect(RRect.fromRectAndRadius(battery.deflate(2.5), const Radius.circular(1.5)), fill);
      if (ios) {
        final island = Rect.fromCenter(center: Offset(size.width / 2, y), width: 126, height: 37);
        canvas.drawRRect(RRect.fromRectAndRadius(island, const Radius.circular(18.5)), black);
      } else {
        canvas.drawCircle(Offset(size.width / 2, y), 6, black);
      }
    }

    if (bars.bottom > 0) {
      final top = size.height - bars.bottom;
      if (ios) {
        final indicator = Rect.fromCenter(center: Offset(size.width / 2, size.height - 10.5), width: 134, height: 5);
        canvas.drawRRect(RRect.fromRectAndRadius(indicator, const Radius.circular(2.5)), fill);
      } else {
        final scrim = brightness == Brightness.dark ? const Color(0xB3000000) : const Color(0xB3FFFFFF);
        canvas.drawRect(Rect.fromLTWH(0, top, size.width, bars.bottom), Paint()..color = scrim);
        final y = top + bars.bottom / 2;
        final x = size.width / 2;
        final step = math.min(size.width / 4, 96.0);
        final back = Path()
          ..moveTo(x - step + 5, y - 7)
          ..lineTo(x - step - 6, y)
          ..lineTo(x - step + 5, y + 7)
          ..close();
        canvas.drawPath(back, line);
        canvas.drawCircle(Offset(x, y), 7.5, line);
        final recents = Rect.fromCenter(center: Offset(x + step, y), width: 13, height: 13);
        canvas.drawRRect(RRect.fromRectAndRadius(recents, const Radius.circular(2.5)), line);
      }
    }
  }

  @override
  bool shouldRepaint(SystemBarsPainter oldDelegate) =>
      oldDelegate.bars != bars || oldDelegate.platform != platform || oldDelegate.brightness != brightness;
}

/// What touches the system bars in the current frame: text, icons, fields and
/// tap targets under the status bar or the navigation bar, or closer to them
/// than [UiConfig.systemBarGap]. Checked:
/// - what stays put (headers, bottom bars, buttons): both bars;
/// - scroll views at their start: the status bar;
/// - every scroll view that reaches the navigation bar or a floating action
///   button, scrolled to its end: the last rows must clear both.
/// App bars and navigation bars pad themselves, so for them only overlap
/// counts. One line per problem, with the source line in lib/ or test/.
Future<List<String>> systemBarProblems(WidgetTester tester, UiConfig config, UiVariant variant) async {
  final gap = config.systemBarGap;
  final bars = config.systemBars(variant);
  if (gap == null || (bars.top <= 0 && bars.bottom <= 0)) return const [];
  final height = variant.size.height;
  final top = bars.top;
  final bottom = height - bars.bottom;
  final lines = <String>{};

  String distance(double space, String bar) =>
      space < 0 ? '${(-space).round()} px under $bar' : '${space.round()} px from $bar';
  final statusBar = 'the status bar (${top.round()} px)';
  final navigationBar = 'the navigation bar (${bars.bottom.round()} px)';

  // At rest: what stays put, and scroll views at their start.
  final atRest = <(Element, String)>[];
  for (final item in _barItems(height)) {
    final margin = item.padsItself ? 0.0 : gap;
    final scroll = item.scrollable;
    final position = scroll?.position;
    final atStart = position == null ||
        !position.hasContentDimensions ||
        position.pixels <= position.minScrollExtent + 0.5;
    if (top > 0 && atStart && item.rect.top < top + margin - 0.5) {
      final where = scroll == null ? '' : 'at the top of the scroll, ';
      atRest.add((
        item.element,
        '$where${_describeBarItem(item.element)} is ${distance(item.rect.top - top, statusBar)}: '
            'keep it inside SafeArea plus ${gap.round()} px or more',
      ));
    } else if (bars.bottom > 0 && scroll == null && item.rect.bottom > bottom - margin + 0.5) {
      atRest.add((
        item.element,
        '${_describeBarItem(item.element)} is ${distance(bottom - item.rect.bottom, navigationBar)}: '
            'SafeArea(top: false) around it, plus ${gap.round()} px or more',
      ));
    }
  }
  lines.addAll(_barLines(atRest));

  // Each scroll view that runs into the navigation bar or under a floating
  // action button, scrolled to its end.
  final fabs = [
    for (final element in find.byType(FloatingActionButton).evaluate())
      if (_globalRect(element) case final Rect rect) rect,
  ];
  final scrollables = [
    for (final element in find.byType(Scrollable).evaluate())
      if (element is StatefulElement && element.state is ScrollableState) element.state as ScrollableState,
  ];
  for (final state in scrollables) {
    if (!state.mounted || axisDirectionToAxis(state.widget.axisDirection) != Axis.vertical) continue;
    if (_insideTextField(state.context)) continue;
    final viewport = _globalRect(state.context);
    if (viewport == null) continue;
    final reachesBar = bars.bottom > 0 && viewport.bottom > bottom - gap + 0.5;
    if (!reachesBar && !fabs.any(viewport.overlaps)) continue;
    final position = state.position;
    if (!position.hasContentDimensions || !position.hasPixels) continue;
    final start = position.pixels;
    for (var i = 0; i < 5 && position.pixels < position.maxScrollExtent - 0.5; i++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
    }
    await settleFrames(tester, frames: 4);
    final atEnd = <(Element, String)>[];
    for (final item in _barItems(height)) {
      if (!identical(item.scrollable, state) || item.padsItself) continue;
      if (reachesBar && item.rect.bottom > bottom - gap + 0.5) {
        atEnd.add((
          item.element,
          'at the end of the scroll, ${_describeBarItem(item.element)} is '
              '${distance(bottom - item.rect.bottom, navigationBar)}: end the list with the bottom inset '
              '(MediaQuery.paddingOf(context).bottom) plus 24 px',
        ));
      } else if (fabs.any((fab) => fab.overlaps(item.rect))) {
        atEnd.add((
          item.element,
          'at the end of the scroll, ${_describeBarItem(item.element)} is behind the floating action button: '
              'end the list with the bottom inset plus the FAB height and 24 px',
        ));
      }
    }
    // Before scrolling back: rows that scroll out are unmounted.
    lines.addAll(_barLines(atEnd));
    if (state.mounted) {
      state.position.jumpTo(start);
      await tester.pump();
    }
  }
  return lines.toList();
}

/// One line per flagged thing, with its source line: a tap target that's
/// flagged covers its own label and icon. Call it while the elements are
/// still mounted.
List<String> _barLines(List<(Element, String)> flagged) {
  final elements = {for (final (element, _) in flagged) element};
  final lines = <String>[];
  for (final (element, message) in flagged) {
    var covered = false;
    element.visitAncestorElements((ancestor) {
      covered = elements.contains(ancestor);
      return !covered;
    });
    if (covered) continue;
    final location = _projectLocation(element);
    lines.add(location == null ? message : '$message  ← $location');
  }
  return lines;
}

class _BarItem {
  const _BarItem(this.element, this.rect, this.scrollable, this.padsItself);

  final Element element;
  final Rect rect;

  /// The vertical scroll view it moves with; null when it stays put.
  final ScrollableState? scrollable;

  /// Inside an app bar or a navigation bar, which pad themselves.
  final bool padsItself;
}

/// Text, icons, fields and tap targets on screen.
List<_BarItem> _barItems(double screenHeight) {
  final items = <_BarItem>[];
  for (final element in find.byWidgetPredicate(_isBarContent).evaluate()) {
    final rect = _globalRect(element);
    if (rect == null || rect.bottom <= 0 || rect.top >= screenHeight || rect.height > screenHeight / 2) continue;
    ScrollableState? scrollable;
    var padsItself = false;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (scrollable == null &&
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.vertical &&
          ancestor is StatefulElement) {
        scrollable = ancestor.state as ScrollableState;
      }
      if (_padsForSystemBars(widget)) padsItself = true;
      return true;
    });
    items.add(_BarItem(element, rect, scrollable, padsItself));
  }
  return items;
}

bool _isBarContent(Widget widget) => switch (widget) {
      RichText(:final text) => text.toPlainText().trim().isNotEmpty,
      EditableText() => true,
      InkResponse(:final onTap, :final onLongPress, :final onDoubleTap) =>
        onTap != null || onLongPress != null || onDoubleTap != null,
      GestureDetector(:final onTap, :final onLongPress) => onTap != null || onLongPress != null,
      _ => false,
    };

/// Material components that keep their own content clear of the system bars.
bool _padsForSystemBars(Widget widget) =>
    widget is AppBar ||
    widget is NavigationBar ||
    widget is BottomNavigationBar ||
    widget is BottomAppBar ||
    widget is NavigationRail ||
    widget is SnackBar ||
    widget is MaterialBanner;

bool _insideTextField(BuildContext context) {
  var inside = false;
  context.visitAncestorElements((ancestor) {
    inside = ancestor.widget is EditableText;
    return !inside;
  });
  return inside;
}

Rect? _globalRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize || box.size.isEmpty) return null;
  return MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
}

/// `"Save changes"`, `"Edit invoice" (icon button)`, `an icon`.
String _describeBarItem(Element element) {
  final widget = element.widget;
  if (widget is RichText) {
    final text = widget.text.toPlainText();
    return _isIconGlyph(text.trim()) ? 'an icon' : _quote(text);
  }
  if (widget is EditableText) return 'a text field';
  String? label;
  void visit(Element child) {
    if (label != null) return;
    final childWidget = child.widget;
    if (childWidget is RichText) {
      final text = childWidget.text.toPlainText().trim();
      if (text.isNotEmpty && !_isIconGlyph(text)) {
        label = text;
        return;
      }
    }
    child.visitChildren(visit);
  }

  element.visitChildren(visit);
  final text = label;
  if (text != null) return '${_quote(text)} (tap target)';
  String? tooltip;
  var depth = 0;
  element.visitAncestorElements((ancestor) {
    final ancestorWidget = ancestor.widget;
    if (ancestorWidget is Tooltip) tooltip = ancestorWidget.message;
    return tooltip == null && ++depth < 12;
  });
  final message = tooltip;
  return message == null ? 'an icon button' : '${_quote(message)} (icon button)';
}

String _quote(String text) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return '"${flat.length > 32 ? '${flat.substring(0, 31)}…' : flat}"';
}

/// A single icon-font glyph (Material icons live in the private use areas).
bool _isIconGlyph(String text) {
  final runes = text.runes.toList();
  return runes.length == 1 && ((runes.first >= 0xE000 && runes.first <= 0xF8FF) || runes.first >= 0xF0000);
}

/// The source line of the nearest widget created in the project's lib/ or
/// test/, walking up from [element] past framework and package widgets
/// (Material widgets live in a package from Flutter 3.50).
String? _projectLocation(Element element) {
  String? found;
  bool visit(Element candidate) {
    if (!debugIsLocalCreationLocation(candidate)) return true;
    final nodes = debugTransformDebugCreator(<DiagnosticsNode>[DiagnosticsDebugCreator(DebugCreator(candidate))]);
    found = _sourceLocation(nodes.map((node) => node.toStringDeep()).join('\n'));
    return found == null;
  }

  if (visit(element)) element.visitAncestorElements(visit);
  return found;
}

/// Saves a screenshot of the whole app to `test/ui/screenshots/<name>.png`
/// (run with `--update-goldens`). Shadows are drawn only when the test has
/// set `debugDisableShadows = false`.
Future<void> takeShot(String name) async {
  await expectLater(find.byKey(uiShotKey), matchesGoldenFile('screenshots/$name.png'));
}

/// Writes `test/ui/screenshots/contact_sheets/<title>.png`: the screenshots
/// [shots] (names passed to [takeShot]) side by side at one height, each
/// labeled, so light, dark, text scale 1.3, RTL and desktop can be compared
/// in one image. Shots that weren't written are skipped.
Future<void> writeContactSheet(WidgetTester tester, String title, List<String> shots) async {
  final comparator = goldenFileComparator;
  final base = comparator is LocalFileComparator ? comparator.basedir : Directory.current.uri.resolve('test/ui/');
  await tester.runAsync(() async {
    final images = <(String, ui.Image)>[];
    for (final name in shots) {
      final file = File.fromUri(base.resolve('screenshots/$name.png'));
      if (!file.existsSync()) continue;
      final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
      images.add((name.contains('__') ? name.split('__').last : name, (await codec.getNextFrame()).image));
      codec.dispose();
    }
    if (images.isEmpty) return;

    const shotHeight = 720.0;
    const gap = 24.0;
    const labelHeight = 40.0;
    final widths = [for (final (_, image) in images) image.width * shotHeight / image.height];
    final width = widths.fold(gap, (sum, w) => sum + w + gap);
    const height = labelHeight + shotHeight + gap;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..drawColor(const Color(0xFFE6E6E6), ui.BlendMode.src);
    var x = gap;
    for (var i = 0; i < images.length; i++) {
      final (label, image) = images[i];
      final paragraph = (ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 18))
            ..pushStyle(ui.TextStyle(color: const Color(0xFF202124)))
            ..addText(label))
          .build()
        ..layout(ui.ParagraphConstraints(width: widths[i]));
      canvas.drawParagraph(paragraph, ui.Offset(x, 10));
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        ui.Rect.fromLTWH(x, labelHeight, widths[i], shotHeight),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      x += widths[i] + gap;
    }
    final sheet = await recorder.endRecording().toImage(width.ceil(), height.ceil());
    final png = await sheet.toByteData(format: ui.ImageByteFormat.png);
    final out = File.fromUri(base.resolve('screenshots/contact_sheets/$title.png'));
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(png!.buffer.asUint8List());
    sheet.dispose();
    for (final (_, image) in images) {
      image.dispose();
    }
  });
}

/// CIE L*a*b* lightness and chroma of an opaque color. The lightness equals
/// the HCT tone that ColorScheme.fromSeed works in (0 black, 100 white).
({double tone, double chroma}) colorLab(Color color) {
  double linear(double c) => c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double f(double t) => t > 216 / 24389 ? math.pow(t, 1 / 3).toDouble() : (24389 / 27 * t + 16) / 116;
  final r = linear(color.r);
  final g = linear(color.g);
  final b = linear(color.b);
  final fx = f((0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047);
  final fy = f(0.2126 * r + 0.7152 * g + 0.0722 * b);
  final fz = f((0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883);
  final a = 500 * (fx - fy);
  final bb = 200 * (fy - fz);
  return (tone: 116 * fy - 16, chroma: math.sqrt(a * a + bb * bb));
}

/// Null when [color] reads as a soft container: a light tint in light mode
/// (tone ≥ 80, chroma ≤ 50), a deep tone in dark mode (tone ≤ 40).
/// Otherwise what's wrong. Contrast alone can't see this: a container as
/// strong as its seed passes 4.5:1 with white text and still reads as a
/// solid block.
String? softContainerProblem(Color color, Brightness brightness) {
  final (:tone, :chroma) = colorLab(color);
  if (brightness == Brightness.light) {
    if (tone < 80) return 'tone ${tone.round()}: a solid block, not a tint (light mode needs ≥ 80)';
    if (chroma > 50) return 'chroma ${chroma.round()}: glaring, not a tint (light mode needs ≤ 50)';
    return null;
  }
  return tone > 40 ? 'tone ${tone.round()}: glaring in dark mode (needs ≤ 40)' : null;
}

/// WCAG contrast ratio between two opaque colors (1 to 21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Loads the app's bundled fonts (FontManifest.json, including the Material
/// icon font) so tests measure and draw real glyphs instead of boxes. Falls
/// back to Roboto from the Flutter SDK for platform-default font families.
/// Emoji still render as boxes: flutter_test has no emoji font.
Future<void> loadUiFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  try {
    final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  } on FlutterError {
    // No FontManifest: the app bundles no fonts.
  }
  await _loadSdkRoboto();
}

Future<void> _loadSdkRoboto() async {
  final root = _flutterRoot();
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final files = dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.contains('Roboto-') && file.path.endsWith('.ttf'))
      .toList();
  if (files.isEmpty) return;

  // Default Material typography family names per platform.
  const families = [
    'Roboto',
    'Segoe UI',
    '.AppleSystemUIFont',
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    'Ubuntu',
    'Cantarell',
    'DejaVu Sans',
    'Liberation Sans',
    'Arial',
  ];
  for (final family in families) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }
}

String? _flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  final exe = Platform.resolvedExecutable;
  final index = exe.indexOf('${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}');
  return index > 0 ? exe.substring(0, index) : null;
}
