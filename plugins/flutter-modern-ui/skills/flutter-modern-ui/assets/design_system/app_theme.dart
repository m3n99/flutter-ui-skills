import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_density.dart';
import 'app_motion.dart';
import 'app_palette.dart';
import 'app_typography.dart';
import 'tokens.dart';

/// How surfaces are colored.
enum SurfaceStyle {
  /// Material 3 tonal surfaces generated from the seed.
  tonal,

  /// Dimmed warm neutrals for long sessions (ledgers, admin, reading): no
  /// pure white surfaces, no pure black text. Every text/surface pair keeps
  /// at least 4.5:1 and outlines at least 3:1.
  eyeComfort,
}

/// How text fields look at rest.
enum InputStyle {
  /// Tinted fill, no border until focused. Light forms, consumer apps.
  filled,

  /// Card-colored fill with a visible border. Dense data entry, desktop,
  /// low-contrast palettes where filled fields lose their edges.
  outlined,
}

/// Everything a design direction changes in the theme.
/// See references/directions.md for each direction's values.
@immutable
class AppThemeConfig {
  const AppThemeConfig({
    this.seed = const Color(0xFF4F46E5),
    this.variant = DynamicSchemeVariant.tonalSpot,
    this.fontFamily,
    this.fontFamilyFallback,
    this.script = AppScript.latin,
    this.surfaces = SurfaceStyle.tonal,
    this.inputStyle = InputStyle.filled,
    this.touchDensity = AppDensity.touch,
    this.desktopDensity = AppDensity.desktop,
    this.motion = MotionLevel.soft,
    this.schemeOverride,
  });

  /// Brand color. Use [DynamicSchemeVariant.fidelity] to keep its exact hue;
  /// the containers stay soft either way (see [AppTheme.build]).
  final Color seed;
  final DynamicSchemeVariant variant;

  /// Bundled font family declared in pubspec.yaml. null = platform default.
  final String? fontFamily;

  /// E.g. `['IBM Plex Sans Arabic']` when the main font lacks Arabic glyphs.
  final List<String>? fontFamilyFallback;

  final AppScript script;
  final SurfaceStyle surfaces;
  final InputStyle inputStyle;
  final AppDensity touchDensity;
  final AppDensity desktopDensity;

  /// How much the app moves: none (Material's own motion only), soft or
  /// expressive. Asked before building; recorded in DESIGN.md.
  final MotionLevel motion;

  /// Last word on colors, e.g. a brand-supplied palette:
  /// `(scheme) => scheme.copyWith(primary: brandPrimary)`.
  /// Re-run the contrast test after any override.
  final ColorScheme Function(ColorScheme scheme)? schemeOverride;

  AppThemeConfig copyWith({
    Color? seed,
    DynamicSchemeVariant? variant,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    AppScript? script,
    SurfaceStyle? surfaces,
    InputStyle? inputStyle,
    AppDensity? touchDensity,
    AppDensity? desktopDensity,
    MotionLevel? motion,
    ColorScheme Function(ColorScheme scheme)? schemeOverride,
  }) {
    return AppThemeConfig(
      seed: seed ?? this.seed,
      variant: variant ?? this.variant,
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      script: script ?? this.script,
      surfaces: surfaces ?? this.surfaces,
      inputStyle: inputStyle ?? this.inputStyle,
      touchDensity: touchDensity ?? this.touchDensity,
      desktopDensity: desktopDensity ?? this.desktopDensity,
      motion: motion ?? this.motion,
      schemeOverride: schemeOverride ?? this.schemeOverride,
    );
  }
}

/// Light and dark themes with every common component tuned.
///
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light(),
///   darkTheme: AppTheme.dark(),
///   themeMode: ThemeMode.system,
///   scaffoldMessengerKey: AppMessenger.key,
/// )
/// ```
abstract final class AppTheme {
  /// DIRECTION: set the seed, variant, fonts, script and styles here once.
  static const AppThemeConfig config = AppThemeConfig();

  static ThemeData light({TargetPlatform? platform, AppThemeConfig config = AppTheme.config}) =>
      build(Brightness.light, platform: platform, config: config);

  static ThemeData dark({TargetPlatform? platform, AppThemeConfig config = AppTheme.config}) =>
      build(Brightness.dark, platform: platform, config: config);

  /// [platform] defaults to the running platform; tests pass it explicitly to
  /// render touch and desktop density side by side.
  static ThemeData build(
    Brightness brightness, {
    TargetPlatform? platform,
    AppThemeConfig config = AppTheme.config,
  }) {
    final isDark = brightness == Brightness.dark;
    final pointer = AppDensity.forPlatform(platform ?? defaultTargetPlatform).isPointer;
    final density = pointer ? config.desktopDensity : config.touchDensity;

    var scheme = ColorScheme.fromSeed(
      seedColor: config.seed,
      brightness: brightness,
      dynamicSchemeVariant: config.variant,
    );
    // fidelity and content put the primary and tertiary containers at the
    // seed's own tone: with a saturated seed, selected chips and tinted
    // blocks turn solid. Keep their strong colors; take the containers from
    // tonalSpot. (Vivid containers on purpose: set them in schemeOverride.)
    if (config.variant == DynamicSchemeVariant.fidelity || config.variant == DynamicSchemeVariant.content) {
      scheme = _softContainers(scheme, config.seed);
    }
    if (config.surfaces == SurfaceStyle.eyeComfort) scheme = _eyeComfort(scheme);
    scheme = config.schemeOverride?.call(scheme) ?? scheme;

    final text = AppTypography.textTheme(
      fontFamily: config.fontFamily,
      fontFamilyFallback: config.fontFamilyFallback,
      script: config.script,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final cardColor = isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    final controlSize = Size(64, density.control);
    final controlPadding = EdgeInsets.symmetric(horizontal: pointer ? AppSpace.md : AppSpace.lg);
    const controlShape = RoundedRectangleBorder(borderRadius: AppRadius.controlAll);

    final outlinedInputs = config.inputStyle == InputStyle.outlined;
    OutlineInputBorder inputBorder(Color color, double width) => OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
        );
    // Outlined fields use `outline` at rest: input boundaries need 3:1.
    final restBorder = outlinedInputs ? inputBorder(scheme.outline, AppStroke.hairline) : inputBorder(Colors.transparent, 0);

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      platform: platform,
      fontFamily: config.fontFamily,
      fontFamilyFallback: config.fontFamilyFallback,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: density.visualDensity,
      materialTapTargetSize: density.tapTargetSize,
      extensions: <ThemeExtension<dynamic>>[AppPalette.fromScheme(scheme), density, AppMotion.of(config.motion)],

      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: AppElevation.flat,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: AppStroke.hairline,
        space: AppStroke.hairline,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: controlSize,
          padding: controlPadding,
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: controlSize,
          padding: controlPadding,
          shape: controlShape,
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, density.control),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: Size.square(density.control)),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: outlinedInputs ? cardColor : scheme.surfaceContainerHigh,
        isDense: pointer,
        contentPadding: EdgeInsets.symmetric(
          horizontal: pointer ? AppSpace.sm : AppSpace.md,
          vertical: pointer ? AppSpace.xs : AppSpace.sm,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: restBorder,
        enabledBorder: restBorder,
        disabledBorder: inputBorder(scheme.outlineVariant, outlinedInputs ? AppStroke.hairline : 0),
        focusedBorder: inputBorder(scheme.primary, AppStroke.focus),
        errorBorder: inputBorder(scheme.error, AppStroke.hairline),
        focusedErrorBorder: inputBorder(scheme.error, AppStroke.focus),
      ),

      // Selected chips show a check AND a fill: never selection by color alone.
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const BorderSide(color: Colors.transparent)
              : BorderSide(color: scheme.outlineVariant),
        ),
        backgroundColor: cardColor,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        showCheckmark: true,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: AppElevation.flat,
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppIconSize.regular,
            color: states.contains(WidgetState.selected) ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        useIndicator: true,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: pointer ? AppSize.messageWidth : null,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        closeIconColor: scheme.onInverseSurface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        minVerticalPadding: pointer ? AppSpace.xs : AppSpace.sm,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
      ),

      // ExpansionTile draws its own top/bottom borders; inside a card that
      // doubles the card's border.
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      // Desktop: scrollbars always visible, tooltips after a short hover.
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(pointer),
        radius: const Radius.circular(AppRadius.pill),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => scheme.onSurfaceVariant.withValues(
            alpha: states.contains(WidgetState.hovered) || states.contains(WidgetState.dragged) ? 0.6 : 0.35,
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        waitDuration: pointer ? const Duration(milliseconds: 500) : null,
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: AppRadius.smAll),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        headingTextStyle: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        dataTextStyle: text.bodyMedium,
        headingRowHeight: density.row,
        dataRowMinHeight: density.row,
        dataRowMaxHeight: density.row + AppSpace.md,
        horizontalMargin: AppSpace.md,
        columnSpacing: AppSpace.lg,
        dividerThickness: AppStroke.hairline,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),

      // Predictive back on Android (the default since Flutter 3.38),
      // Cupertino on Apple platforms, fade-forwards on Windows and Linux.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Warm, dimmed neutrals. Keeps the seed's primary/secondary/tertiary.
  /// Contrast (checked): onSurface ≥ 10:1, onSurfaceVariant ≥ 5.5:1 and
  /// outline ≥ 3.2:1 on every surface level, both modes.
  /// Tinted containers for the primary and tertiary hues (tone 90 in light
  /// mode, 30 in dark), as tonalSpot builds them.
  static ColorScheme _softContainers(ColorScheme scheme, Color seed) {
    final primary = ColorScheme.fromSeed(seedColor: seed, brightness: scheme.brightness);
    final tertiary = ColorScheme.fromSeed(seedColor: scheme.tertiary, brightness: scheme.brightness);
    return scheme.copyWith(
      primaryContainer: primary.primaryContainer,
      onPrimaryContainer: primary.onPrimaryContainer,
      tertiaryContainer: tertiary.primaryContainer,
      onTertiaryContainer: tertiary.onPrimaryContainer,
    );
  }

  static ColorScheme _eyeComfort(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return scheme.copyWith(
        surface: const Color(0xFF181715),
        surfaceDim: const Color(0xFF181715),
        surfaceBright: const Color(0xFF3B3833),
        surfaceContainerLowest: const Color(0xFF121110),
        surfaceContainerLow: const Color(0xFF1C1B19),
        surfaceContainer: const Color(0xFF22201D),
        surfaceContainerHigh: const Color(0xFF2C2A26),
        surfaceContainerHighest: const Color(0xFF37342F),
        onSurface: const Color(0xFFE7E2D9),
        onSurfaceVariant: const Color(0xFFBDB6AA),
        outline: const Color(0xFF8F887D),
        outlineVariant: const Color(0xFF47423B),
        inverseSurface: const Color(0xFFE7E2D9),
        onInverseSurface: const Color(0xFF2A2824),
      );
    }
    return scheme.copyWith(
      surface: const Color(0xFFF6F3EC),
      surfaceDim: const Color(0xFFDCD6CB),
      surfaceBright: const Color(0xFFF6F3EC),
      surfaceContainerLowest: const Color(0xFFFCFAF6),
      surfaceContainerLow: const Color(0xFFF1EDE5),
      surfaceContainer: const Color(0xFFEBE7DE),
      surfaceContainerHigh: const Color(0xFFE5E0D6),
      surfaceContainerHighest: const Color(0xFFDED8CC),
      onSurface: const Color(0xFF2A2824),
      onSurfaceVariant: const Color(0xFF55504A),
      outline: const Color(0xFF7A746A),
      outlineVariant: const Color(0xFFD3CDC2),
      inverseSurface: const Color(0xFF33302B),
      onInverseSurface: const Color(0xFFF6F3EC),
    );
  }
}
