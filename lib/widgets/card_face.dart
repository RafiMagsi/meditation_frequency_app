import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/card_styles.dart';
import 'scene_art.dart';

/// The body every card shares — the private-collection look of the
/// money cards, applied everywhere:
///
/// * the default is an **onyx card**: near-black ground faintly tinted by
///   the card's accent metal, a soft accent glow, fine engraving, a
///   polished top sheen and a metallic hairline on continuous corners;
/// * with [art] it is an **art face** — the card's photograph or painted
///   scene, full-bleed (medallions, the player jewel, the lake).
///
/// It is also the [Hero] child on both ends of a card flight, which lets
/// [cardFlightShuttle] morph one card into another.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.style,
    this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(18),
    this.art = false,
    this.scrim = 1,
    this.elevation = 1,
    this.contentAlignment = Alignment.bottomLeft,
  });

  final CardStyle style;
  final Widget? child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// Show the style's photo/scene full-bleed instead of the onyx card.
  final bool art;

  /// Strength of the bottom fade that keeps type readable on art (0 = none).
  final double scrim;
  final double elevation;

  /// Where content stays anchored while the card morphs in flight.
  final Alignment contentAlignment;

  static List<BoxShadow> _shadows(double elevation) => elevation <= 0
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5 * elevation),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -6,
          ),
        ];

  @override
  Widget build(BuildContext context) => art ? _artFace() : _onyxFace();

  Widget _onyxFace() {
    final radius = BorderRadius.circular(borderRadius);
    final accent = style.glow;
    final engraving = switch (style.scene) {
      Scene.gold => Scene.gold,
      Scene.none => null,
      _ => Scene.engraved,
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(borderRadius: radius),
        shadows: _shadows(elevation),
      ),
      child: ClipRSuperellipse(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      const Color(0xFF09090C),
                      Color.lerp(const Color(0xFF0E0D12), accent, 0.05)!,
                      Color.lerp(const Color(0xFF16141B), accent, 0.13)!,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.95),
                    radius: 1.1,
                    colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            if (engraving != null) Positioned.fill(child: SceneArt(scene: engraving, accent: accent)),
            // Polished top: the faintest sheen, as on a lacquered card.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0FFFFFFF), Color(0x00FFFFFF)],
                    stops: [0, 0.4],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child ?? const SizedBox.shrink()),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _HairlinePainter(radius: borderRadius, accent: accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artFace() {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: _shadows(elevation)),
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
            if (style.image != null)
              Positioned.fill(child: CardPhoto(style: style))
            else if (style.scene != Scene.none)
              Positioned.fill(child: SceneArt(scene: style.scene, accent: style.glow)),
            if (scrim > 0) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: _scrim(scrim)))),
            Padding(padding: padding, child: child ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  /// An eased fade (no banding, no hard edge) that keeps type legible on
  /// art and is gone by the upper third.
  static LinearGradient _scrim(double strength) {
    final a = 0.72 * strength;
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        for (final f in const [1.0, 0.74, 0.48, 0.26, 0.1, 0.0]) Colors.black.withValues(alpha: a * f),
      ],
      stops: const [0, 0.14, 0.28, 0.42, 0.56, 0.72],
    );
  }
}

/// A metallic hairline: brightest where the light falls (top left),
/// fading around the card, catching again at the far corner.
class _HairlinePainter extends CustomPainter {
  const _HairlinePainter({required this.radius, required this.accent});

  final double radius;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = (Offset.zero & size).deflate(0.45);
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.white, 0.45)!.withValues(alpha: 0.6),
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.32),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_HairlinePainter old) => old.radius != radius || old.accent != accent;
}

/// A card's photograph: a slow Ken Burns drift keeps it alive, with only a
/// light tint toward the card's palette. Falls back to the painted scene
/// if it can't load.
class CardPhoto extends StatefulWidget {
  const CardPhoto({super.key, required this.style});

  final CardStyle style;

  @override
  State<CardPhoto> createState() => _CardPhotoState();
}

class _CardPhotoState extends State<CardPhoto> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _t = ValueNotifier(ArtClock.value);
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (elapsed - _last < const Duration(milliseconds: 32)) return;
      _last = elapsed;
      _t.value = ArtClock.value;
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final photo = Image.asset(
      style.image!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, __) => SceneArt(scene: style.scene, accent: style.glow),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        // Own layer: the drift repaints only the photo, not the card.
        RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: _t,
            child: photo,
            builder: (context, t, child) {
              // One slow breath of zoom and drift per 24 s loop.
              final a = t * 2 * math.pi;
              return Transform.scale(
                scale: 1.08 + 0.04 * math.sin(a),
                alignment: Alignment(0.3 * math.cos(a), 0.2 * math.sin(a)),
                child: child,
              );
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.center,
              colors: [style.colors.first.withValues(alpha: 0.3), style.colors.first.withValues(alpha: 0)],
            ),
          ),
        ),
      ],
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
  final same = lower.style == upper.style && lower.art == upper.art;

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
        if (same) {
          return CardFace(
            style: upper.style,
            art: upper.art,
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
              art: lower.art,
              borderRadius: radius,
              padding: EdgeInsets.zero,
              scrim: scrim,
              elevation: lower.elevation * (1 - t),
            ),
            Opacity(
              opacity: Curves.easeInOut.transform(t),
              child: CardFace(
                style: upper.style,
                art: upper.art,
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
