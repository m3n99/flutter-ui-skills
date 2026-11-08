import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// Empty or error placeholder: tinted icon, title, one-sentence message and
/// an optional action.
///
/// Say what is empty or what failed ("No invoices yet", "Couldn't load your
/// invoices"), never a generic "Something went wrong".
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : isError = false;

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
        isError = true;

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final tint = isError ? colors.errorContainer : colors.primaryContainer;
    final onTint = isError ? colors.onErrorContainer : colors.onPrimaryContainer;
    final label = actionLabel;
    final action = onAction;

    return Align(
      alignment: const Alignment(0, -0.2),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: onTint),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(title, style: text.titleLarge, textAlign: TextAlign.center),
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
}
