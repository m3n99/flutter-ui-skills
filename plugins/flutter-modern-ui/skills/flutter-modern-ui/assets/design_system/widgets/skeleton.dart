import 'dart:async';

import 'package:flutter/material.dart';

import '../context_ext.dart';
import '../tokens.dart';

/// Animated shimmer over skeleton shapes. No external package.
/// Static when the platform asks for reduced motion; the sweep follows the
/// reading direction.
///
/// Tests: the shimmer repeats forever, so use `pump(duration)` instead of
/// `pumpAndSettle()` while a skeleton is on screen.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;

    final colors = context.colors;
    final base = colors.surfaceContainerHighest;
    final highlight = colors.surfaceContainerLow;
    final direction = Directionality.of(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
            transform: _SlideGradient(_controller.value),
          ).createShader(bounds, textDirection: direction),
          child: child,
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.progress);

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (progress * 2 - 1);
    return Matrix4.translationValues(textDirection == TextDirection.rtl ? -dx : dx, 0, 0);
  }
}

/// A placeholder block. Shape it like the content it replaces: same
/// paddings, row heights and radii, so nothing jumps when data arrives.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.smAll,
  }) : _circle = false;

  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = BorderRadius.zero,
        _circle = true;

  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final bool _circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        shape: _circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: _circle ? null : borderRadius,
      ),
    );
  }
}

/// Reveals [child] only after [delay], so loads that finish quickly never
/// flash a skeleton. Space is reserved from the start.
class ShowAfter extends StatefulWidget {
  const ShowAfter({super.key, required this.child, this.delay = AppDurations.skeletonDelay});

  final Widget child;
  final Duration delay;

  @override
  State<ShowAfter> createState() => _ShowAfterState();
}

class _ShowAfterState extends State<ShowAfter> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: context.motion(AppDurations.fast),
      child: widget.child,
    );
  }
}
