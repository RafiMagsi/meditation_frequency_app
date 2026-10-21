import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/card_styles.dart';
import 'card_face.dart';
import 'luxury.dart';

/// Circular framed artwork — every card's "coin". The card's photo or
/// painted scene sits inside a ring of its accent metal, with a bevel and
/// a glint; given a [heroTag] it is what flies into the next screen.
class Medallion extends StatelessWidget {
  const Medallion({super.key, required this.style, this.size = 56, this.heroTag, this.child});

  final CardStyle style;
  final double size;
  final Object? heroTag;

  /// Optional overlay inside the circle (a duration, an emoji…).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ring = math.max(2.5, size * 0.055);
    final face = CardFace(
      style: style,
      art: true,
      borderRadius: size / 2 - ring,
      padding: EdgeInsets.zero,
      scrim: child == null ? 0 : 0.6,
      elevation: 0,
      child: child == null ? null : Center(child: child),
    );
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(accent: style.glow, ring: ring),
        foregroundPainter: _BevelPainter(ring: ring),
        child: Padding(
          padding: EdgeInsets.all(ring),
          child: heroTag == null ? face : CardHero(tag: heroTag!, face: face),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.accent, required this.ring});

  final Color accent;
  final double ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // Soft halo of the metal behind the coin.
    canvas.drawCircle(
      c,
      r * 1.35,
      Paint()
        ..shader = RadialGradient(colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r * 1.35)),
    );
    canvas.drawCircle(
      c,
      r - ring / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..shader = foilFor(accent).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.accent != accent || old.ring != ring;
}

class _BevelPainter extends CustomPainter {
  const _BevelPainter({required this.ring});

  final double ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final inner = size.shortestSide / 2 - ring;
    // Inner shadow where the artwork meets the ring, then a glint.
    canvas.drawCircle(
      c,
      inner - 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: inner - 2),
      math.pi * 1.05,
      math.pi * 0.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_BevelPainter old) => old.ring != ring;
}

/// A medallion struck with a glyph instead of artwork — the coins of the
/// money cards, in any metal.
class EmblemMedallion extends StatelessWidget {
  const EmblemMedallion({super.key, required this.color, this.icon, this.text, this.size = 64});

  final Color color;
  final IconData? icon;
  final String? text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = math.max(2.5, size * 0.055);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(accent: color, ring: ring),
        foregroundPainter: _BevelPainter(ring: ring),
        child: Padding(
          padding: EdgeInsets.all(ring),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [Color(0xFF2A2730), Color(0xFF0B0A0E)],
              ),
            ),
            child: Center(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => foilFor(color).createShader(b),
                child: icon != null
                    ? Icon(icon, size: size * 0.42, color: Colors.white)
                    : Text(
                        text ?? '',
                        style: TextStyle(
                          fontFamily: 'InterDisplay',
                          fontWeight: FontWeight.w600,
                          fontSize: (size * 0.3) * 0.8,
                          letterSpacing: size * 0.01,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
