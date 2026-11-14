// UI test harness: renders screens and sheets across sizes, text scales,
// themes, platforms and reading directions; collects layout errors with the
// source line; checks tap targets and the keyboard; saves screenshots.
//
// Project-independent. Configure it in ui_cases.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    this.textScales = const [1.0, 1.3],
    this.brightnesses = const [Brightness.light, Brightness.dark],
    this.platforms = const [TargetPlatform.android],
    this.directions = const [TextDirection.ltr],
    this.shots = const [
      UiVariant(size: UiSize.phone),
      UiVariant(size: UiSize.phone, brightness: Brightness.dark),
      UiVariant(size: UiSize.phone, textScale: 1.3),
      UiVariant(size: UiSize.desktop),
    ],
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
  final List<double> textScales;
  final List<Brightness> brightnesses;

  /// Platforms that ship: touch (android/iOS) and/or desktop (windows/macOS/linux).
  final List<TargetPlatform> platforms;

  /// Add TextDirection.rtl when the app supports Arabic, Hebrew, Persian or Urdu.
  final List<TextDirection> directions;

  /// The curated set of screenshots per case.
  final List<UiVariant> shots;

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
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    RepaintBoundary(
      key: uiShotKey,
      child: MaterialApp(
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
    if (path.contains('/packages/flutter/') || path.contains('/.pub-cache/') || path.contains('/flutter_test/')) {
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

/// Simulates a [height] px software keyboard.
void showKeyboard(WidgetTester tester, double height) {
  tester.view.viewInsets = FakeViewPadding(bottom: height * tester.view.devicePixelRatio);
}

void hideKeyboard(WidgetTester tester) => tester.view.resetViewInsets();

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
