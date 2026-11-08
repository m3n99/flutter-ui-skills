import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Shakes [child] sideways whenever [trigger] changes, e.g. a failed submit
/// count or a wrong PIN. Pair it with an error message; motion alone never
/// carries the meaning.
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange({super.key, required this.trigger, required this.child, this.distance = 8});

  final Object? trigger;
  final Widget child;
  final double distance;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _reduceMotion = false;

  @override
  void didUpdateWidget(ShakeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger && !_reduceMotion) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * widget.distance * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Pops [child] (scale 1 → 1.18 → 1) whenever [value] changes: a badge
/// count, a favourite toggle, a cart total.
class PopOnChange extends StatefulWidget {
  const PopOnChange({super.key, required this.value, required this.child});

  final Object? value;
  final Widget child;

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppDurations.slow);
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.18).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: Tween<double>(begin: 1.18, end: 1).chain(CurveTween(curve: AppCurves.pop)), weight: 60),
  ]).animate(_controller);
  bool _reduceMotion = false;

  @override
  void didUpdateWidget(PopOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_reduceMotion) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Cross-fades between loading, empty, error and content with a slight
/// upward settle. Give every state child a distinct key, e.g.
/// `ValueKey('loading')`. Children align to the top so short and long
/// states don't jump.
class StateSwitcher extends StatelessWidget {
  const StateSwitcher({super.key, required this.child, this.alignment = Alignment.topCenter});

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : AppDurations.medium,
      switchInCurve: AppCurves.enter,
      switchOutCurve: AppCurves.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: animation.drive(Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
