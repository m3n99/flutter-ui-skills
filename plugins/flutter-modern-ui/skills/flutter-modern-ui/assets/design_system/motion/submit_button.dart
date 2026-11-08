import 'dart:async';

import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';
import '../widgets/controls.dart';

/// Primary button for saves and submits.
///
/// - While busy it shows a spinner, keeps its width and ignores presses, so
///   a second tap never sends twice.
/// - Busy comes from [busy] (state-driven, e.g. `state.status == saving`) or
///   automatically while the Future returned by [onPressed] runs.
/// - With [successFeedback] it shows a check for a moment after the Future
///   completes (use when the screen stays open after saving).
///
/// Errors thrown by [onPressed] are not caught here; handle them inside it
/// (show the failure message) so the button returns to idle cleanly.
class SubmitButton extends StatefulWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.successFeedback = false,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final IconData? icon;
  final bool busy;
  final bool successFeedback;

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

enum _Phase { idle, busy, done }

class _SubmitButtonState extends State<SubmitButton> {
  bool _running = false;
  bool _done = false;
  Timer? _doneTimer;

  _Phase get _phase {
    if (widget.busy || _running) return _Phase.busy;
    return _done ? _Phase.done : _Phase.idle;
  }

  Future<void> _press() async {
    final action = widget.onPressed;
    if (action == null || _phase != _Phase.idle) return;

    final result = action();
    if (result is! Future<void>) return;

    setState(() => _running = true);
    var completed = false;
    try {
      await result;
      completed = true;
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _done = completed && widget.successFeedback;
        });
        if (_done) {
          _doneTimer?.cancel();
          _doneTimer = Timer(const Duration(milliseconds: 1200), () {
            if (mounted) setState(() => _done = false);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phase;
    final foreground = context.colors.onPrimary;
    final icon = widget.icon;

    // Rich text rather than a Row with Flexible, so the button also works
    // in unbounded slots and still ellipsizes long labels.
    final label = Text.rich(
      TextSpan(
        children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                child: Icon(icon, size: AppIconSize.dense),
              ),
            ),
          TextSpan(text: widget.label),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    final Widget overlay = switch (phase) {
      _Phase.idle => const SizedBox.shrink(key: ValueKey('idle')),
      _Phase.busy => AppSpinner(key: const ValueKey('busy'), color: foreground),
      _Phase.done => Icon(Icons.check_rounded, key: const ValueKey('done'), color: foreground),
    };

    return IgnorePointer(
      ignoring: phase != _Phase.idle,
      child: FilledButton(
        onPressed: widget.onPressed == null ? null : _press,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The label stays in the tree (invisible) so the width never jumps
            // and screen readers keep the button's name.
            AnimatedOpacity(
              opacity: phase == _Phase.idle ? 1 : 0,
              duration: context.motion(AppDurations.fast),
              child: label,
            ),
            AnimatedSwitcher(
              duration: context.motion(AppDurations.fast),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation.drive(Tween<double>(begin: 0.6, end: 1)),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: overlay,
            ),
          ],
        ),
      ),
    );
  }
}
