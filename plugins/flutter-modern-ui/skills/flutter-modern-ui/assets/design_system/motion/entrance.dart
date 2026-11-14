import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// Fades [child] in and slides it up by [offset] of its own height, once,
/// when it first appears. [index] staggers siblings by the motion level's
/// stagger (expressive: 40 ms; soft: all at once); only the first 8 are
/// staggered.
///
/// Decided once: later rebuilds never replay it, and it is skipped when
/// [animate] is false, at MotionLevel.none, or when the platform asks for
/// reduced motion.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.animate = true,
    this.offset,
  });

  final Widget child;
  final int index;
  final bool animate;

  /// Rise as a fraction of the child's height. Default: the motion level's
  /// (soft 4 %, expressive 12 %).
  final double? offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  bool _decided = false;
  AnimationController? _controller;
  CurvedAnimation? _animation;
  double _offset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    if (!widget.animate || context.reduceMotion) return;

    final motion = context.appMotion;
    _offset = widget.offset ?? motion.entranceOffset;
    final delay = motion.stagger * math.min(widget.index, AppDurations.staggerLimit);
    final total = delay + context.motion(AppDurations.medium);
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
        position: animation.drive(Tween<Offset>(begin: Offset(0, _offset), end: Offset.zero)),
        child: widget.child,
      ),
    );
  }
}
