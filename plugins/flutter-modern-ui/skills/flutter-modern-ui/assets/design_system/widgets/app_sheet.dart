import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// Opens [builder] as a modal bottom sheet below 600 px and as a centered
/// dialog (up to 560 px wide) from 600 px up. Build the content with
/// [SheetScaffold] so both forms look and behave the same.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  final asDialog = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;

  if (asDialog) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => _SheetMode(
        asDialog: true,
        child: Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(AppSpace.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSize.sheetMaxWidth),
            child: Builder(builder: builder),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    builder: (context) => _SheetMode(asDialog: false, child: Builder(builder: builder)),
  );
}

class _SheetMode extends InheritedWidget {
  const _SheetMode({required this.asDialog, required super.child});

  final bool asDialog;

  static bool? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_SheetMode>()?.asDialog;

  @override
  bool updateShouldNotify(_SheetMode oldWidget) => asDialog != oldWidget.asDialog;
}

/// Anatomy shared by every sheet and sheet-like dialog:
///
/// 1. Header: title at the start, close button at the end.
/// 2. Body: scrolls when long; [children] are usually [SheetSection]s, 24 apart.
/// 3. Footer: sticky (never scrolls), hairline on top, inside the safe area.
///    Secondary action at the start, as wide as its label; primary action
///    fills the rest. In RTL the primary therefore sits on the left.
///    Pick-one sheets have no footer: tapping an option is the action
///    ([showAppPicker]).
///
/// As a bottom sheet the content is lifted above the keyboard; dialogs move
/// themselves.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.children,
    this.primaryAction,
    this.secondaryAction,
    this.showClose = true,
    this.bodyPadding = const EdgeInsetsDirectional.fromSTEB(AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.lg),
  });

  /// Lets tests find the primary action of any sheet.
  static const Key primaryActionKey = Key('sheet-primary-action');

  final String title;
  final List<Widget> children;

  /// One filled button (FilledButton or SubmitButton). Null for pick-one
  /// sheets and read-only sheets: no footer then.
  final Widget? primaryAction;

  /// An OutlinedButton or TextButton (Cancel, Clear all, Share).
  final Widget? secondaryAction;
  final bool showClose;

  /// Around the body. Pickers pass less, so their rows reach the edges.
  final EdgeInsetsGeometry bodyPadding;

  @override
  Widget build(BuildContext context) {
    final asDialog = _SheetMode.of(context) ?? context.windowSize != WindowSize.compact;
    final keyboard = asDialog ? 0.0 : MediaQuery.viewInsetsOf(context).bottom;
    final primary = primaryAction;
    final secondary = secondaryAction;
    final hasFooter = primary != null || secondary != null;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(AppSpace.lg, asDialog ? AppSpace.md : 0, AppSpace.xs, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.textStyles.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showClose)
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
          Flexible(
            child: SafeArea(
              top: false,
              // The footer keeps clear of the home indicator; without one,
              // the body does.
              bottom: !hasFooter,
              child: SingleChildScrollView(
                padding: bodyPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.lg,
                  children: children,
                ),
              ),
            ),
          ),
          if (hasFooter)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.colors.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
                  child: Row(
                    spacing: AppSpace.xs,
                    children: [
                      ?secondary,
                      if (primary != null) Expanded(child: KeyedSubtree(key: primaryActionKey, child: primary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A pick-one sheet: one tap chooses an option and closes the sheet, so there
/// is no footer button. The current choice shows a check and the selected
/// colors (never color alone). Returns null when dismissed.
///
/// For a choice inside a form or a filter sheet that's applied later, use
/// chips or radio tiles in a [SheetScaffold] with a primary action instead.
Future<T?> showAppPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T option) labelOf,
  T? selected,
  IconData Function(T option)? iconOf,
}) {
  return showAppSheet<T>(
    context: context,
    builder: (context) => SheetScaffold(
      title: title,
      bodyPadding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
      children: [
        Column(
          children: [
            for (final option in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                leading: iconOf == null ? null : Icon(iconOf(option)),
                title: Text(labelOf(option)),
                trailing: option == selected ? const Icon(Icons.check_rounded) : null,
                selected: option == selected,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ],
    ),
  );
}

/// A labeled group inside a sheet: label in labelLarge / onSurfaceVariant,
/// 8 px above its content.
class SheetSection extends StatelessWidget {
  const SheetSection({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.xs,
      children: [
        Text(label, style: context.textStyles.labelLarge?.copyWith(color: context.colors.onSurfaceVariant)),
        child,
      ],
    );
  }
}
