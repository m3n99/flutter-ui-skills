import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// The bar that holds a form's one primary action under the scrolling
/// fields: surface color, a hairline on top, and the button inside the safe
/// area plus [AppSpace.sm], so it never touches the navigation bar or the
/// home indicator.
///
/// Make it the last child of the body's Column, under an Expanded scroll
/// view. In `Scaffold.bottomNavigationBar` the soft keyboard covers it
/// (references/forms.md › Long forms).
class SaveBar extends StatelessWidget {
  const SaveBar({super.key, required this.child, this.horizontalPadding = AppSpace.screen});

  /// Usually a SubmitButton or a FilledButton; it gets the full width.
  final Widget child;

  /// Match the fields above, e.g. `ContentWidth.horizontalPadding(width,
  /// maxWidth: AppSize.formMaxWidth)`.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpace.sm),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
