import 'package:flutter/material.dart';

/// The signature transition of the app: the incoming page fades up,
/// scales from 0.96 and drifts slightly upward — like it was already
/// there and simply stepped forward. Feels seamless in recordings.
class SeamlessRoute<T> extends PageRouteBuilder<T> {
  SeamlessRoute({required this.page, this.transitionDurationMs = 480})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black38,
          transitionDuration: Duration(milliseconds: transitionDurationMs),
          reverseTransitionDuration: Duration(milliseconds: (transitionDurationMs * 0.72).round()),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.955, end: 1).animate(curved),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.035),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );

  final Widget page;
  final int transitionDurationMs;
}

/// Push a page with the seamless transition.
Future<T?> pushSeamless<T>(BuildContext context, Widget page) {
  return Navigator.of(context, rootNavigator: true).push<T>(SeamlessRoute<T>(page: page));
}
