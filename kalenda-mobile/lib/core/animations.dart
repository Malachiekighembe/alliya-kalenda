import 'dart:async';

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

  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    _revealTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
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

/// Phrases qui defilent les unes apres les autres.
///
/// Le message de l'ecran de connexion change selon le module : on tourne
/// plutot que d'afficher une liste, ce qui tient sur une seule ligne et
/// evite d'alourdir l'ecran.
class RotatingPhrases extends StatefulWidget {
  const RotatingPhrases({
    required this.phrases,
    this.interval = const Duration(seconds: 4),
    this.style,
    this.duration = const Duration(milliseconds: 420),
    super.key,
  });

  final List<String> phrases;
  final Duration interval;

  /// Duree de la transition : la phrase sort, la suivante entre.
  final Duration duration;
  final TextStyle? style;

  @override
  State<RotatingPhrases> createState() => _RotatingPhrasesState();
}

class _RotatingPhrasesState extends State<RotatingPhrases>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    // Une seule phrase : il n'y a rien a faire tourner.
    if (widget.phrases.length < 2) return;
    _timer = Timer(widget.interval, _advance);
  }

  void _advance() {
    if (!mounted) return;
    // Enchainement direct : la transition occupe toute la duree, la phrase
    // suivante est affichee une fois l'animation terminee.
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.phrases.length);
      _controller.reset();
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phrases.isEmpty) return const SizedBox.shrink();

    final phrase = widget.phrases[_index.clamp(0, widget.phrases.length - 1)];
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        // Fondu croise : sort a 0, revient a 1.
        opacity: (1 - curve.value).clamp(0.0, 1.0),
        child: Transform.translate(
          // Legere montee pour accompagner le fondu.
          offset: Offset(0, -6 * curve.value),
          child: child,
        ),
      ),
      child: Text(
        phrase,
        // La hauteur est figee pour que la ligne ne saute pas a chaque
        // rotation, que les phrases soient courtes ou longues.
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
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
