import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// Fades [child] in and slides it up by [offset] of its own height, once,
/// when it first appears. [index] staggers siblings by 40 ms; only the first
/// 8 are staggered.
///
/// Decided once: later rebuilds never replay it, and it is skipped when
/// [animate] is false or the platform asks for reduced motion.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.animate = true,
    this.offset = 0.08,
  });

  final Widget child;
  final int index;
  final bool animate;
  final double offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  bool _decided = false;
  AnimationController? _controller;
  CurvedAnimation? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) return;

    final delay = AppDurations.stagger * math.min(widget.index, AppDurations.staggerLimit);
    final total = delay + AppDurations.medium;
    final controller = AnimationController(vsync: this, duration: total);
    _animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: AppCurves.enter),
    );
    _controller = controller..forward();
  }

  @override
  void dispose() {
    _animation?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _animation;
    if (animation == null) return widget.child;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(Tween<Offset>(begin: Offset(0, widget.offset), end: Offset.zero)),
        child: widget.child,
      ),
    );
  }
}
