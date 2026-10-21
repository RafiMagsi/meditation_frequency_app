import 'package:flutter/material.dart';

/// The signature transition of the app — everything is a card:
///
/// The incoming screen glides in from the right as a rounded card that
/// swings flat and takes over the screen. The screen underneath becomes a
/// card too: it recedes to the left, tilting away and dimming, while its
/// own [DeckItem] cards cascade off ahead of it and the tapped card's
/// hero morphs into the new screen.
class SeamlessRoute<T> extends PageRouteBuilder<T> {
  SeamlessRoute({required this.page, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 820),
          reverseTransitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              DeckTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          ),
        );

  final Widget page;
}

/// Gives plain [MaterialPageRoute]s (like the app's home) the same deck
/// motion, so every screen recedes as a card when covered.
class DeckPageTransitionsBuilder extends PageTransitionsBuilder {
  const DeckPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return DeckTransition(animation: animation, secondaryAnimation: secondaryAnimation, child: child);
  }
}

/// Push a page with the seamless card-deck transition.
Future<T?> pushSeamless<T>(BuildContext context, Widget page) {
  return Navigator.of(context, rootNavigator: true).push<T>(SeamlessRoute<T>(page: page));
}

class DeckTransition extends StatefulWidget {
  const DeckTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<DeckTransition> createState() => _DeckTransitionState();
}

class _DeckTransitionState extends State<DeckTransition> {
  late CurvedAnimation _enter;
  late CurvedAnimation _cover;

  @override
  void initState() {
    super.initState();
    _curve();
  }

  @override
  void didUpdateWidget(DeckTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _enter.dispose();
      _cover.dispose();
      _curve();
    }
  }

  void _curve() {
    // The incoming card waits a beat so the deck's cascade reads first,
    // then glides in and settles softly. On pop both directions use
    // easeIn in reverse: fast off the mark, gentle landing.
    _enter = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.2, 1, curve: Cubic(0.2, 0.8, 0.2, 1)),
      reverseCurve: Curves.easeInCubic,
    );
    _cover = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _enter.dispose();
    _cover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _cover]),
      child: widget.child,
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        final out = 1 - _enter.value.clamp(0.0, 1.0); // 1 = still off to the right
        final s = _cover.value.clamp(0.0, 1.0); // 1 = fully receded left
        final radius = 44 * (out > s ? out : s);
        final scale = 1 - 0.07 * out - 0.09 * s;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translateByDouble(width * (out * 1.04 - 0.3 * s), 0, 0, 1)
          ..rotateY(-0.2 * out + 0.22 * s)
          ..scaleByDouble(scale, scale, 1, 1);
        // Shadow peaks mid-flight to lift the incoming card off the deck.
        final lift = out > 0 && out < 1 ? 0.5 * (1 - (2 * out - 1).abs()) : 0.0;

        // The widget shape never changes between rest and motion, so the
        // page underneath keeps its state when it gets covered.
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: lift <= 0
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: lift),
                        blurRadius: 40,
                        offset: const Offset(-12, 0),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: radius > 0.5 ? Clip.antiAlias : Clip.none,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55 * s)),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
