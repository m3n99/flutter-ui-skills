import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// Empty / error placeholder: tinted icon, title, one-sentence message, and
/// an optional action. Use [EmptyState.error] for failed loads.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  const EmptyState.error({
    super.key,
    this.title = "Something went wrong",
    this.message = "Check your connection and try again.",
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
                child: Icon(icon, size: AppIconSize.hero * 0.85, color: onTint),
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
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpace.lg),
                isError
                    ? OutlinedButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(actionLabel!),
                      )
                    : FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
