import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One card in a screen's deck. It reads its route's animations, so
/// nothing has to be wired up by hand:
///
/// * when the screen is pushed, cards are dealt in from the right, one
///   after another;
/// * when another screen is pushed on top, cards cascade off to the left,
///   tilting away in 3D — except the tapped card, whose hero is flying;
/// * pops play the same choreography backwards, still top card first.
class DeckItem extends StatefulWidget {
  const DeckItem({super.key, required this.index, required this.child});

  /// Position in the deck; drives the stagger.
  final int index;
  final Widget child;

  /// Marks the deck item enclosing [context] as the tapped card so it
  /// stays put while the others slide away.
  static void markActive(BuildContext context) {
    context.findAncestorStateOfType<_DeckItemState>()?._markActive();
  }

  @override
  State<DeckItem> createState() => _DeckItemState();
}

class _DeckItemState extends State<DeckItem> {
  // Dealing in is leisurely; clearing the deck is quick so the cascade
  // reads before the incoming screen covers it.
  static const _deal = (step: 0.065, maxDelay: 0.33, span: 0.67);
  static const _clear = (step: 0.045, maxDelay: 0.22, span: 0.45);

  ModalRoute<Object?>? _route;
  bool _active = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      _route?.secondaryAnimation?.removeStatusListener(_onCoverStatus);
      _route = route;
      route?.secondaryAnimation?.addStatusListener(_onCoverStatus);
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeStatusListener(_onCoverStatus);
    super.dispose();
  }

  void _markActive() => setState(() => _active = true);

  void _onCoverStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _active && mounted) {
      setState(() => _active = false);
    }
  }

  /// Staggered progress of [animation] for this card. The top card leads
  /// in both directions: forwards its window opens first, in reverse its
  /// window sits at the top of the range so it moves back first.
  double _staggered(
    Animation<double> animation,
    Curve curve, {
    required ({double step, double maxDelay, double span}) timing,
  }) {
    final delay = math.min(widget.index * timing.step, timing.maxDelay);
    final start = animation.status == AnimationStatus.reverse ? 1 - timing.span - delay : delay;
    final local = ((animation.value - start) / timing.span).clamp(0.0, 1.0);
    return curve.transform(local);
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final enter = route?.animation;
    final cover = route?.secondaryAnimation;
    if (enter == null || cover == null) return widget.child;

    return AnimatedBuilder(
      animation: Listenable.merge([enter, cover]),
      child: widget.child,
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        final e = _staggered(enter, Curves.easeOutCubic, timing: _deal);
        final s = _active ? 0.0 : _staggered(cover, Curves.easeInOutCubic, timing: _clear);

        // Same widget shape at rest and in motion, so the child is never
        // remounted when a transition starts.
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..translateByDouble(width * (0.42 * (1 - e) - 0.7 * s), 0, 0, 1)
          ..rotateY(0.5 * s - 0.18 * (1 - e))
          ..scaleByDouble(1 - 0.12 * s - 0.05 * (1 - e), 1 - 0.12 * s - 0.05 * (1 - e), 1, 1);
        return Opacity(
          opacity: (e * (1 - 0.9 * s)).clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: child,
          ),
        );
      },
    );
  }
}
