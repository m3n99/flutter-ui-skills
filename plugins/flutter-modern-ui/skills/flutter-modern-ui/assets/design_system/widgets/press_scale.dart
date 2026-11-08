import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// Scales its child slightly while a pointer is pressed on it.
///
/// It listens to raw pointer events, so it never competes with the child's
/// own gestures: wrap an already tappable widget (an InkWell, a button, an
/// AppCard). Ink keeps providing hover, focus, ripple and the click cursor.
/// Releases as soon as the pointer moves like a scroll.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.97, this.enabled = true});

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  Offset? _origin;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final animate = widget.enabled && !MediaQuery.disableAnimationsOf(context);

    return Listener(
      onPointerDown: (event) {
        _origin = event.position;
        _set(true);
      },
      onPointerMove: (event) {
        final origin = _origin;
        if (origin != null && (event.position - origin).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: animate && _pressed ? widget.scale : 1,
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        child: widget.child,
      ),
    );
  }
}
