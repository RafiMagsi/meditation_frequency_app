import 'package:flutter/material.dart';

/// The signature transition of the app:
///
/// On push, the incoming screen slides in from the right and takes over,
/// while the screen behind it (the card grid) becomes a rounded card that
/// glides to the left and dims — like pushing a card aside on a table.
class SeamlessRoute<T> extends PageRouteBuilder<T> {
  SeamlessRoute({required this.page, this.transitionDurationMs = 500})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black38,
          transitionDuration: Duration(milliseconds: transitionDurationMs),
          reverseTransitionDuration:
              Duration(milliseconds: (transitionDurationMs * 0.7).round()),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final incomingCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Incoming: takes over the screen from the right.
            final incoming = FadeTransition(
              opacity: Tween<double>(begin: 0.25, end: 1).animate(incomingCurve),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(incomingCurve),
                child: child,
              ),
            );

            final secondary = secondaryAnimation;
            if (secondary.status == AnimationStatus.dismissed) {
              return incoming;
            }

            // Outgoing: turns into a rounded card, drifts left, dims.
            final outgoingCurve = CurvedAnimation(
              parent: secondary,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return AnimatedBuilder(
              animation: outgoingCurve,
              child: incoming,
              builder: (context, cachedChild) {
                final t = outgoingCurve.value.clamp(0.0, 1.0);
                final width = MediaQuery.sizeOf(context).width;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(34 * t),
                  child: Transform.translate(
                    offset: Offset(-0.26 * width * t, -0.015 * 200 * t),
                    child: Transform.scale(
                      scale: 1 - 0.07 * t,
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          cachedChild!,
                          Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.4 * t),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );

  final Widget page;
  final int transitionDurationMs;
}

/// Push a page with the seamless card-stack transition.
Future<T?> pushSeamless<T>(BuildContext context, Widget page) {
  return Navigator.of(context, rootNavigator: true)
      .push<T>(SeamlessRoute<T>(page: page));
}
