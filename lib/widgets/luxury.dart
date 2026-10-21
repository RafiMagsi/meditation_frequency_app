import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Text filled with brushed gold foil.
class GoldText extends StatelessWidget {
  const GoldText(this.text, {super.key, required this.style, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppTheme.goldFoil.createShader(bounds),
      child: Text(text, textAlign: textAlign, style: style.copyWith(color: Colors.white)),
    );
  }
}

/// The contact chip of a metal black card.
class GoldChip extends StatelessWidget {
  const GoldChip({super.key, this.width = 40});

  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, width * 0.74), painter: _ChipPainter());
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height * 0.2));
    canvas.drawRRect(rrect, Paint()..shader = AppTheme.goldFoil.createShader(rect));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0x8A6E5016);
    final w = size.width, h = size.height;
    canvas.drawLine(Offset(w * 0.33, 0), Offset(w * 0.33, h), line);
    canvas.drawLine(Offset(w * 0.67, 0), Offset(w * 0.67, h), line);
    canvas.drawLine(Offset(0, h * 0.5), Offset(w * 0.33, h * 0.5), line);
    canvas.drawLine(Offset(w * 0.67, h * 0.34), Offset(w, h * 0.34), line);
    canvas.drawLine(Offset(w * 0.67, h * 0.66), Offset(w, h * 0.66), line);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rect.center, width: w * 0.3, height: h * 0.44),
        Radius.circular(h * 0.08),
      ),
      line,
    );
    canvas.drawRRect(rrect, line..color = const Color(0x66FFF1C9));
  }

  @override
  bool shouldRepaint(_ChipPainter oldDelegate) => false;
}

/// A struck gold coin with a reeded rim, a ring of pearls and a raised
/// emblem. [spin] turns it on its vertical axis — with real edge
/// thickness — and past 90° it shows the reverse (∞, "ABUNDANCE").
class GoldCoin extends StatelessWidget {
  const GoldCoin({
    super.key,
    required this.size,
    required this.emblem,
    this.caption = 'HZ',
    this.spin = 0,
  });

  final double size;
  final String emblem;
  final String caption;

  /// Rotation around the vertical axis, in radians.
  final double spin;

  @override
  Widget build(BuildContext context) {
    final angle = spin % (2 * math.pi);
    final showBack = angle > math.pi / 2 && angle < 3 * math.pi / 2;
    const layers = 6;
    final thickness = size * 0.07;

    Widget layer(int k) {
      final z = -thickness * k / layers;
      final transform = Matrix4.identity()
        ..setEntry(3, 2, 0.0016)
        ..rotateY(angle)
        ..translateByDouble(0, 0, z, 1);
      final Widget face;
      if (k == 0 || k == layers) {
        final back = k == layers;
        face = Transform.flip(
          flipX: back,
          child: CustomPaint(
            size: Size.square(size),
            painter: _CoinFacePainter(
              emblem: back ? '∞' : emblem,
              caption: back ? 'ABUNDANCE' : caption,
              glint: math.sin(angle),
            ),
          ),
        );
      } else {
        face = CustomPaint(size: Size.square(size), painter: const _CoinEdgePainter());
      }
      return Transform(alignment: Alignment.center, transform: transform, child: face);
    }

    // Painter's algorithm: draw the far side first.
    final order = showBack
        ? [for (var k = 0; k <= layers; k++) k]
        : [for (var k = layers; k >= 0; k--) k];
    return SizedBox.square(
      dimension: size,
      child: Stack(children: [for (final k in order) layer(k)]),
    );
  }
}

class _CoinEdgePainter extends CustomPainter {
  const _CoinEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.shortestSide / 2, Paint()..color = const Color(0xFF8A6524));
  }

  @override
  bool shouldRepaint(_CoinEdgePainter oldDelegate) => false;
}

class _CoinFacePainter extends CustomPainter {
  const _CoinFacePainter({required this.emblem, required this.caption, required this.glint});

  final String emblem;
  final String caption;

  /// −1…1; slides the specular highlight as the coin turns.
  final double glint;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Body.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: [Color(0xFFFFF3CF), Color(0xFFEBCB7E), Color(0xFFC99A48), Color(0xFF8A6524)],
          stops: [0, 0.35, 0.72, 1],
        ).createShader(rect),
    );

    // Reeded rim.
    final reed = Paint()
      ..strokeWidth = math.max(0.6, r * 0.012)
      ..color = const Color(0x667A5A1E);
    for (var i = 0; i < 90; i++) {
      final a = i * 2 * math.pi / 90;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * r * 0.9, c + dir * r * 0.99, reed);
    }
    // Raised inner ring: highlight then shadow.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035;
    canvas.drawCircle(c.translate(-r * 0.01, -r * 0.01), r * 0.84, ring..color = const Color(0xAAFFF6DC));
    canvas.drawCircle(c.translate(r * 0.012, r * 0.012), r * 0.84, ring..color = const Color(0x667A5A1E));

    // Ring of pearls.
    final pearl = Paint()..color = const Color(0x997A5A1E);
    for (var i = 0; i < 36; i++) {
      final a = i * 2 * math.pi / 36;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.74, r * 0.018, pearl);
    }

    // Embossed emblem: light offset under dark.
    void embossed(String text, double fontSize, double dy, {double spacing = 0, FontWeight weight = FontWeight.w700}) {
      TextPainter painter(Color color) => TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontWeight: weight,
                fontSize: fontSize,
                letterSpacing: spacing,
                color: color,
                height: 1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
      final light = painter(const Color(0xCCFFF8E1));
      final dark = painter(const Color(0xFF6E4E17));
      final origin = c + Offset(-dark.width / 2, -dark.height / 2 + dy);
      light.paint(canvas, origin.translate(-fontSize * 0.03, -fontSize * 0.03));
      dark.paint(canvas, origin);
    }

    final emblemSize = emblem.length > 3 ? r * 0.42 : (emblem.length == 1 ? r * 0.8 : r * 0.58);
    embossed(emblem, emblemSize, -r * 0.06);
    embossed(caption, r * 0.13, r * 0.42, spacing: r * 0.03, weight: FontWeight.w700);

    // Moving specular glint.
    final band = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + glint, -1),
        end: Alignment(1 + glint, 1),
        colors: const [Color(0x00FFFFFF), Color(0x55FFFFFF), Color(0x00FFFFFF)],
        stops: const [0.35, 0.5, 0.65],
      ).createShader(rect);
    canvas.drawCircle(c, r, band);
  }

  @override
  bool shouldRepaint(_CoinFacePainter old) =>
      old.emblem != emblem || old.caption != caption || old.glint != glint;
}

/// Watch-dial bezel around the player's jewel: minute track, gold
/// progress arc with a diamond marker, and an engraved guilloché band
/// (the barleycorn pattern of fine watch dials) that turns while playing.
class GuillocheDial extends StatelessWidget {
  const GuillocheDial({
    super.key,
    required this.size,
    required this.progress,
    required this.rotation,
    this.accent = AppTheme.goldMid,
    this.innerRadiusFactor = 0.6,
    this.child,
  });

  final double size;
  final double progress;
  final double rotation;
  final Color accent;

  /// Where the engraving stops, as a fraction of the dial radius.
  final double innerRadiusFactor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DialPainter(
          progress: progress,
          rotation: rotation,
          accent: accent,
          inner: innerRadiusFactor,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.progress,
    required this.rotation,
    required this.accent,
    required this.inner,
  });

  final double progress;
  final double rotation;
  final Color accent;
  final double inner;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: c, radius: outer);

    // Dial plate.
    canvas.drawCircle(
      c,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF15131A),
            const Color(0xFF0B0A0E),
            Color.lerp(const Color(0xFF0B0A0E), accent, 0.06)!,
          ],
          stops: const [0, 0.8, 1],
        ).createShader(rect),
    );

    // Guilloché band: interfering wavy circles.
    final bandOuter = outer - 20;
    final bandInner = outer * inner;
    const rings = 16;
    final engrave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var k = 0; k < rings; k++) {
      final r0 = bandInner + (bandOuter - bandInner) * k / (rings - 1);
      final amp = (bandOuter - bandInner) / rings * 0.9;
      final phase = (k.isEven ? 0 : math.pi) + rotation;
      final path = Path();
      for (var i = 0; i <= 240; i++) {
        final a = i * 2 * math.pi / 240;
        final rr = r0 + amp * math.sin(24 * a + phase);
        final p = c + Offset(math.cos(a), math.sin(a)) * rr;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      engrave.color = accent.withValues(alpha: 0.13 + 0.07 * (k % 3 == 0 ? 1 : 0));
      canvas.drawPath(path, engrave);
    }

    // Chapter ring and minute track.
    canvas.drawCircle(
      c,
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = AppTheme.goldFoil.createShader(rect),
    );
    canvas.drawCircle(
      c,
      outer - 16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = accent.withValues(alpha: 0.35),
    );
    final lit = (progress.clamp(0.0, 1.0) * 60).floor();
    final tick = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 60;
      final dir = Offset(math.cos(a), math.sin(a));
      final major = i % 5 == 0;
      tick
        ..strokeWidth = major ? 1.6 : 0.8
        ..color = i <= lit
            ? const Color(0xFFF3E2B3).withValues(alpha: major ? 1 : 0.8)
            : accent.withValues(alpha: major ? 0.55 : 0.28);
      canvas.drawLine(c + dir * (outer - (major ? 13 : 9)), c + dir * (outer - 4), tick);
    }

    // Progress arc in foil, with a glowing diamond at its head.
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: outer + 3),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            colors: [Color(0xFFA47A33), Color(0xFFF7E3A6), Color(0xFFFFF1C9)],
            transform: GradientRotation(-math.pi / 2),
          ).createShader(rect),
      );
    }
    final head = -math.pi / 2 + sweep;
    final hp = c + Offset(math.cos(head), math.sin(head)) * (outer + 3);
    canvas.drawCircle(
      hp,
      10,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFF1C9).withValues(alpha: 0.7), const Color(0x00FFF1C9)],
        ).createShader(Rect.fromCircle(center: hp, radius: 10)),
    );
    canvas.save();
    canvas.translate(hp.dx, hp.dy);
    canvas.rotate(head + math.pi / 4);
    canvas.drawRect(
      const Rect.fromLTWH(-3.2, -3.2, 6.4, 6.4),
      Paint()..color = const Color(0xFFFFF4D6),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.rotation != rotation || old.accent != accent;
}
