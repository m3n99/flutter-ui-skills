import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// Empty or error placeholder: tinted icon, title, one-sentence message and
/// an optional action.
///
/// Say what is empty or what failed ("No invoices yet", "Couldn't load your
/// invoices"), never a generic "Something went wrong".
///
/// Two sizes (references/states.md › Empty):
/// - the default fills a pane or a screen: centered, a 88 px tinted circle,
///   its own scroll view for short windows and big fonts. It needs a bounded
///   height: a list pane, a tab, a page body;
/// - [EmptyState.inline] is for a list that is one section of a page that
///   already scrolls (a log under a form, "recent" under a dashboard card):
///   no scroll view (a nested one gets unbounded height and asserts), a
///   plain icon, one sentence. Loading there is a few `SkeletonBox` rows.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required String this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  })  : isError = false,
        inline = false;

  /// A failed load: what failed in [title], what to do in [message], and a
  /// retry button.
  const EmptyState.error({
    super.key,
    required this.title,
    this.message,
    this.actionLabel = 'Retry',
    required VoidCallback? onRetry,
  })  : icon = Icons.cloud_off_rounded,
        onAction = onRetry,
        isError = true,
        inline = false;

  /// For a section inside a scrolling page: icon, an optional title, one
  /// sentence and an optional outlined action, in the section's own width.
  const EmptyState.inline({
    super.key,
    required this.icon,
    this.title,
    required String this.message,
    this.actionLabel,
    this.onAction,
  })  : isError = false,
        inline = true;

  /// A failed load inside a section: what failed, and a retry.
  const EmptyState.inlineError({
    super.key,
    required String this.message,
    this.title,
    this.actionLabel = 'Retry',
    required VoidCallback? onRetry,
  })  : icon = Icons.cloud_off_rounded,
        onAction = onRetry,
        isError = true,
        inline = true;

  final IconData icon;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  /// Sized for a section of a scrolling page (see [EmptyState.inline]).
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final title = this.title;
    if (inline) return _inline(context, title);
    final tint = isError ? colors.errorContainer : colors.primaryContainer;
    final onTint = isError ? colors.onErrorContainer : colors.onPrimaryContainer;
    final label = actionLabel;
    final action = onAction;

    return Align(
      alignment: const Alignment(0, -0.2),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.emptyStateWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSize.emptyStateBadge,
                height: AppSize.emptyStateBadge,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, size: AppIconSize.emptyState, color: onTint),
              ),
              const SizedBox(height: AppSpace.lg),
              if (title != null) Text(title, style: text.titleLarge, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  message!,
                  style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (label != null && action != null) ...[
                const SizedBox(height: AppSpace.lg),
                isError
                    ? OutlinedButton.icon(
                        onPressed: action,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(label),
                      )
                    : FilledButton(onPressed: action, child: Text(label)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _inline(BuildContext context, String? title) {
    final colors = context.colors;
    final text = context.textStyles;
    final label = actionLabel;
    final action = onAction;
    final message = this.message;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.xs,
        children: [
          Icon(
            icon,
            size: context.iconSize(AppIconSize.feature),
            color: isError ? colors.error : colors.onSurfaceVariant,
          ),
          if (title != null) Text(title, style: text.titleSmall, textAlign: TextAlign.center),
          if (message != null)
            Text(message, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant), textAlign: TextAlign.center),
          if (label != null && action != null)
            OutlinedButton.icon(
              onPressed: action,
              icon: isError ? const Icon(Icons.refresh_rounded) : null,
              label: Text(label),
            ),
        ],
      ),
    );
  }
}
