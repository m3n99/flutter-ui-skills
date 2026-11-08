import 'package:flutter/material.dart';

import '../tokens.dart';

enum _Kind { success, info, error }

/// The app's single message component (floating SnackBar).
///
/// Wire [key] into `MaterialApp(scaffoldMessengerKey: AppMessenger.key)`;
/// then call it from anywhere, including blocs and routes helpers.
///
/// - Every message has an icon and text. Success and info use the inverse
///   surface; errors use the error container.
/// - Plain messages close after 4 s and show a close button; messages with an
///   action stay 6 s and then close by themselves (`persist: false`; since
///   Flutter 3.38 a SnackBar with an action never closes on its own).
/// - 420 px wide on desktop (theme), full width on phones.
///
/// `fluttertoast` has no Windows support; this works on every platform.
abstract final class AppMessenger {
  static final GlobalKey<ScaffoldMessengerState> key = GlobalKey<ScaffoldMessengerState>();

  /// Returns the user-facing text of a failure that should be shown as is
  /// (validation: "Amount is larger than the remaining balance"), or null for
  /// anything else. Set it once at startup to match the project's failure types.
  static String? Function(Object failure) userMessageOf = (_) => null;

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? success(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(message, _Kind.success, actionLabel: actionLabel, onAction: onAction);

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? info(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(message, _Kind.info, actionLabel: actionLabel, onAction: onAction);

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? error(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(message, _Kind.error, actionLabel: actionLabel, onAction: onAction);

  /// Shows what failed and what to do, e.g. "Couldn't delete the record. It's
  /// back in the list; try again." Validation messages recognised by
  /// [userMessageOf] pass through instead. Never shows raw exception text or
  /// a generic "unexpected error"; log [failure] separately.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showFailure(
    Object failure, {
    required String whatFailed,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return error(userMessageOf(failure) ?? whatFailed, actionLabel: actionLabel, onAction: onAction);
  }

  /// Deferred delete with Undo:
  ///
  /// 1. the item disappears at once ([pending] hides [key]);
  /// 2. a message with Undo is shown;
  /// 3. Undo releases the key: the item comes back where it was;
  /// 4. any other close (timeout, swipe, replaced by another message) runs
  ///    [commit], then [reload], and only then releases the key, so the row
  ///    never flashes back while the list is reloading.
  ///
  /// [commit] must delete by explicit id, never "the currently open item":
  /// that can change during the Undo window. Keys are always released, so a
  /// database that reuses ids never hides a new item by mistake.
  static Future<void> deleteWithUndo<K>({
    required PendingDeletes<K> pending,
    required K key,
    required String message,
    required Future<void> Function() commit,
    Future<void> Function()? reload,
    String undoLabel = 'Undo',
    String failureMessage = "Couldn't delete it. It's back in the list; try again.",
  }) async {
    pending.hide(key);
    final controller = _show(message, _Kind.success, actionLabel: undoLabel, onAction: () {});
    final reason = controller == null ? SnackBarClosedReason.timeout : await controller.closed;

    if (reason == SnackBarClosedReason.action) {
      pending.release(key);
      return;
    }
    try {
      await commit();
      await reload?.call();
    } catch (failure) {
      pending.release(key);
      showFailure(failure, whatFailed: failureMessage);
      return;
    }
    pending.release(key);
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _show(
    String message,
    _Kind kind, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = key.currentState;
    final context = key.currentContext;
    if (messenger == null || context == null) return null;

    final colors = Theme.of(context).colorScheme;
    final (Color background, Color foreground, IconData icon) = switch (kind) {
      _Kind.success => (colors.inverseSurface, colors.onInverseSurface, Icons.check_circle_rounded),
      _Kind.info => (colors.inverseSurface, colors.onInverseSurface, Icons.info_outline_rounded),
      _Kind.error => (colors.errorContainer, colors.onErrorContainer, Icons.error_outline_rounded),
    };
    final SnackBarAction? action = actionLabel != null && onAction != null
        ? SnackBarAction(
            label: actionLabel,
            onPressed: onAction,
            textColor: kind == _Kind.error ? foreground : colors.inversePrimary,
          )
        : null;

    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        backgroundColor: background,
        persist: false,
        duration: action != null ? AppDurations.messageWithAction : AppDurations.message,
        showCloseIcon: action == null,
        closeIconColor: foreground,
        content: Row(
          spacing: AppSpace.sm,
          children: [
            Icon(icon, size: AppIconSize.dense, color: foreground),
            Expanded(child: Text(message, style: TextStyle(color: foreground))),
          ],
        ),
        action: action,
      ),
    );
  }
}

/// Keys of items hidden while their delete waits for Undo. Lists filter with
/// [visible] and rebuild when this notifies (ListenableBuilder).
class PendingDeletes<K> extends ChangeNotifier {
  final Set<K> _keys = <K>{};

  bool contains(K key) => _keys.contains(key);

  List<T> visible<T>(Iterable<T> items, K Function(T item) keyOf) =>
      [for (final item in items) if (!_keys.contains(keyOf(item))) item];

  void hide(K key) {
    if (_keys.add(key)) notifyListeners();
  }

  void release(K key) {
    if (_keys.remove(key)) notifyListeners();
  }
}
