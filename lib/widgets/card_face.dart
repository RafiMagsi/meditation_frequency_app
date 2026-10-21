import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/card_styles.dart';
import 'gloss.dart';
import 'scene_art.dart';

/// The body every card shares: gradient ground, painted art, a legibility
/// scrim, the content, and a glass finish on top.
///
/// It is also the [Hero] child on both ends of a card flight, which lets
/// [cardFlightShuttle] morph one card into another.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.style,
    this.child,
    this.borderRadius = 26,
    this.padding = const EdgeInsets.all(18),
    this.sheen,
    this.scrim = 1,
    this.elevation = 1,
    this.contentAlignment = Alignment.bottomLeft,
  });

  final CardStyle style;
  final Widget? child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// 0→1 drives one gloss sweep across the card; null keeps it still.
  final Animation<double>? sheen;

  /// Strength of the bottom scrim that keeps type readable (0 = none).
  final double scrim;
  final double elevation;

  /// Where content stays anchored while the card morphs in flight.
  final Alignment contentAlignment;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: elevation <= 0
            ? null
            : [
                BoxShadow(
                  color: style.glow.withValues(alpha: 0.26 * elevation),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: style.colors,
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
            if (style.scene != Scene.none)
              Positioned.fill(child: SceneArt(scene: style.scene, accent: style.glow)),
            if (scrim > 0)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: _scrim(style.scene.isArt, scrim)),
                ),
              ),
            Padding(padding: padding, child: child ?? const SizedBox.shrink()),
            Positioned.fill(
              child: IgnorePointer(
                child: sheen == null
                    ? CustomPaint(painter: GlossPainter(borderRadius: borderRadius))
                    : AnimatedBuilder(
                        animation: sheen!,
                        builder: (context, _) => CustomPaint(
                          // Enters and exits fully off-card (hidden at rest).
                          painter: GlossPainter(
                            borderRadius: borderRadius,
                            sheen: Curves.easeInOut.transform(sheen!.value) * 1.5 - 0.25,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Art gets a deeper scrim than plain colour cards; both fade out
  /// before the upper half so the artwork stays vivid.
  static LinearGradient _scrim(bool art, double strength) {
    final a = (art ? 0.66 : 0.3) * strength;
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.black.withValues(alpha: a),
        Colors.black.withValues(alpha: a * 0.35),
        Colors.black.withValues(alpha: 0),
      ],
      stops: const [0, 0.45, 0.8],
    );
  }
}

/// A [Hero] whose flight morphs one [CardFace] into another.
class CardHero extends StatelessWidget {
  const CardHero({super.key, required this.tag, required this.face});

  final Object tag;
  final CardFace face;

  @override
  Widget build(BuildContext context) {
    return Hero(tag: tag, flightShuttleBuilder: cardFlightShuttle, child: face);
  }
}

/// Morphs the lower route's card into the upper route's card: the ground
/// and artwork stretch to the flying rect, corners re-round, and both
/// contents cross-fade at their own natural size, so text never squashes.
Widget cardFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final push = direction == HeroFlightDirection.push;
  final lowerContext = push ? fromHeroContext : toHeroContext;
  final upperContext = push ? toHeroContext : fromHeroContext;
  final lower = (lowerContext.widget as Hero).child;
  final upper = (upperContext.widget as Hero).child;
  if (lower is! CardFace || upper is! CardFace) {
    return (toHeroContext.widget as Hero).child;
  }
  final lowerSize = _laidOutSize(lowerContext);
  final upperSize = _laidOutSize(upperContext);
  final sameStyle = lower.style == upper.style;

  // Hero flights live in the overlay, outside any Material; give text a
  // proper ancestor so it never picks up the debug underline style.
  return Material(
    type: MaterialType.transparency,
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // 0 = the lower card, 1 = the upper card, in both directions.
        final t = animation.value.clamp(0.0, 1.0);
        final lowerOpacity = 1 - Curves.easeOut.transform((t / 0.45).clamp(0.0, 1.0));
        final upperOpacity = Curves.easeIn.transform(((t - 0.4) / 0.6).clamp(0.0, 1.0));
        final radius = lerpDouble(lower.borderRadius, upper.borderRadius, t)!;
        final scrim = lerpDouble(lower.scrim, upper.scrim, t)!;
        final ghosts = Stack(
          fit: StackFit.expand,
          children: [
            _ghost(lower, lowerSize, lowerOpacity),
            _ghost(upper, upperSize, upperOpacity),
          ],
        );
        if (sameStyle) {
          return CardFace(
            style: upper.style,
            borderRadius: radius,
            padding: EdgeInsets.zero,
            scrim: scrim,
            elevation: lerpDouble(lower.elevation, upper.elevation, t)!,
            child: ghosts,
          );
        }
        // Different identities (e.g. a card becoming a disc): cross-fade
        // the grounds, keep the contents on top of both.
        return Stack(
          fit: StackFit.expand,
          children: [
            CardFace(
              style: lower.style,
              borderRadius: radius,
              padding: EdgeInsets.zero,
              scrim: scrim,
              elevation: lower.elevation * (1 - t),
            ),
            Opacity(
              opacity: Curves.easeInOut.transform(t),
              child: CardFace(
                style: upper.style,
                borderRadius: radius,
                padding: EdgeInsets.zero,
                scrim: scrim,
                elevation: upper.elevation * t,
              ),
            ),
            ClipRRect(borderRadius: BorderRadius.circular(radius), child: ghosts),
          ],
        );
      },
    ),
  );
}

Size? _laidOutSize(BuildContext context) {
  final box = context.findRenderObject();
  return box is RenderBox && box.hasSize ? box.size : null;
}

/// One card's content, laid out at its original size and faded.
Widget _ghost(CardFace face, Size? size, double opacity) {
  if (face.child == null || size == null || opacity <= 0.01) {
    return const SizedBox.shrink();
  }
  return Opacity(
    opacity: opacity,
    child: OverflowBox(
      alignment: face.contentAlignment,
      minWidth: size.width,
      maxWidth: size.width,
      minHeight: size.height,
      maxHeight: size.height,
      child: Padding(padding: face.padding, child: face.child),
    ),
  );
}
