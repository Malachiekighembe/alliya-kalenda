import 'package:flutter/material.dart';

class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .035),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// Runs the given value up from `0` to `value` with an easing curve, and
/// renders it through [formatter]. Useful for animated KPI counters.
///
/// The line height is pinned so the counter keeps a predictable height inside
/// fixed-size grid tiles (Material 3 typography uses a tall ambient `height`).
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    required this.formatter,
    this.duration = const Duration(milliseconds: 850),
    this.style,
    super.key,
  });

  final double value;
  final String Function(double) formatter;
  final Duration duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: duration,
    curve: Curves.easeOutCubic,
    builder: (context, t, _) => Text(
      formatter(value * t),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ).merge(style),
    ),
  );
}
