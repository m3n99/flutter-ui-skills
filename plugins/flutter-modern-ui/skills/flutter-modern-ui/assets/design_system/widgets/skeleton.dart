import 'package:flutter/material.dart';

import '../tokens.dart';

/// Animated shimmer over skeleton shapes. No external package.
/// Static when the platform asks for reduced motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final colors = Theme.of(context).colorScheme;
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

/// A placeholder block. Shape it like the content it replaces.
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: _circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: _circle ? null : borderRadius,
      ),
    );
  }
}
