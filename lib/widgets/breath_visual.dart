import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/practice.dart';
import '../theme/app_theme.dart';

/// Where a breathing pattern is at a moment in its cycle.
typedef BreathSpot = ({int phase, double t, double level});

/// Locates [cycleT] (0–1 through one cycle) within [pattern]'s phases.
BreathSpot breathSpotAt(BreathPattern pattern, double cycleT) {
  var within = cycleT.clamp(0.0, 1.0) * pattern.cycleSeconds;
  final levels = pattern.levels;
  for (var i = 0; i < pattern.phases.length; i++) {
    final s = pattern.phases[i].seconds;
    if (within < s || i == pattern.phases.length - 1) {
      final t = (within / s).clamp(0.0, 1.0);
      final from = levels[(i - 1) % levels.length];
      return (phase: i, t: t, level: from + (levels[i] - from) * Curves.easeInOut.transform(t));
    }
    within -= s;
  }
  return (phase: 0, t: 0, level: 0);
}

/// Short phase label for strips and rings: IN, HOLD, OUT, TOP UP.
String phaseShortLabel(BreathPhase p) {
  final base = switch (p.move) {
    BreathMove.inhale => p.label == 'Top up' ? 'TOP UP' : 'IN',
    BreathMove.exhale => 'OUT',
    _ => 'HOLD',
  };
  return p.side == null ? base : '$base ${p.side![0].toUpperCase()}';
}

String phaseSeconds(double s) => s == s.roundToDouble() ? '${s.round()}' : '$s';

/// The breath made visible. Box patterns trace a labelled square with a
/// comet-tailed bead; everything else is a layered orb inside a ring whose
/// arcs are the phases, sized by their real share of the cycle.
class BreathVisualPainter extends CustomPainter {
  const BreathVisualPainter({
    required this.shape,
    required this.phases,
    required this.phase,
    required this.t,
    required this.level,
    required this.color,
    this.labels = true,
    this.active = true,
  });

  final BreathShape shape;
  final List<BreathPhase> phases;
  final int phase;
  final double t;
  final double level;
  final Color color;

  /// Phase names around the shape (off for small previews).
  final bool labels;

  /// False before the session starts: no bead, a resting shape.
  final bool active;

  Color get _bright => Color.lerp(color, Colors.white, 0.35)!;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (shape == BreathShape.box && phases.length == 4) {
      _box(canvas, size, c);
    } else {
      _orb(canvas, size, c);
    }
  }

  void _glow(Canvas canvas, Offset at, double radius, Color color, double alpha) {
    if (radius <= 0 || alpha <= 0) return;
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: alpha.clamp(0.0, 1.0)), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: at, radius: radius)),
    );
  }

  void _label(Canvas canvas, String text, Offset center, {required bool current, double angle = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: capsStyle(
          color: current ? Colors.white : Colors.white.withValues(alpha: 0.42),
          size: 9.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _orb(Canvas canvas, Size size, Offset c) {
    final small = !labels;
    final ring = size.shortestSide / 2 - (small ? 3 : 30);
    final stroke = small ? 2.0 : 3.0;
    final total = phases.fold<double>(0, (s, p) => s + p.seconds);
    const gap = 0.07;
    final rect = Rect.fromCircle(center: c, radius: ring);

    // Phase arcs.
    var start = -math.pi / 2;
    Offset? head;
    var headAngle = 0.0;
    for (var i = 0; i < phases.length; i++) {
      final sweep = 2 * math.pi * phases[i].seconds / total;
      final a0 = start + gap / 2, span = sweep - gap;
      canvas.drawArc(
        rect,
        a0,
        span,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = active && i < phase ? color.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.12),
      );
      if (active && i == phase) {
        canvas.drawArc(
          rect,
          a0,
          span * t,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 0.6
            ..strokeCap = StrokeCap.round
            ..color = _bright,
        );
        headAngle = a0 + span * t;
        head = c + Offset(math.cos(headAngle), math.sin(headAngle)) * ring;
      }
      if (labels) {
        final mid = a0 + span / 2;
        _label(
          canvas,
          '${phaseShortLabel(phases[i])} ${phaseSeconds(phases[i].seconds)}',
          c + Offset(math.cos(mid), math.sin(mid)) * (ring + 18),
          current: active && i == phase,
        );
      }
      start += sweep;
    }

    // Orb: halo, translucent body, luminous core.
    final r = ring * (0.3 + 0.44 * level);
    _glow(canvas, c, r * 2.1, color, 0.16 + 0.2 * level);
    final move = phases[phase].move;
    if (active && move == BreathMove.inhale) {
      for (var k = 0; k < 2; k++) {
        final ph = ((t * 2) + k / 2) % 1.0;
        canvas.drawCircle(
          c,
          r * (1.05 + 0.5 * ph),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = _bright.withValues(alpha: 0.35 * (1 - ph)),
        );
      }
    }
    if (active && (move == BreathMove.hold || move == BreathMove.rest)) {
      // A slow, shimmering dashed ring while the breath is held.
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35);
      for (var k = 0; k < 28; k++) {
        final a = k * 2 * math.pi / 28 + t * math.pi;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r * 1.28), a, 0.09, false, dash);
      }
    }
    canvas.drawCircle(c, r * 1.2, Paint()..color = color.withValues(alpha: 0.14));
    canvas.drawCircle(
      c,
      r * 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.14),
    );
    // Glassy body: mid-tone at the centre so white type on it stays
    // legible, deeper at the rim, with an offset specular highlight.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.42),
            color.withValues(alpha: 0.62),
            Color.lerp(color, Colors.black, 0.25)!.withValues(alpha: 0.92),
          ],
          stops: const [0, 0.7, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    _glow(canvas, c + Offset(-r * 0.36, -r * 0.42), r * 0.45, Colors.white, 0.32);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Bead with a comet trail.
    if (head != null) {
      for (var k = 1; k <= 8; k++) {
        final a = headAngle - k * 0.045;
        _glow(canvas, c + Offset(math.cos(a), math.sin(a)) * ring, (small ? 3 : 5) * (1 - k / 10), _bright,
            0.5 * (1 - k / 9));
      }
      _glow(canvas, head, small ? 9 : 18, _bright, 0.9);
      canvas.drawCircle(head, small ? 2.6 : 4.5, Paint()..color = Colors.white);
    }
  }

  void _box(Canvas canvas, Size size, Offset c) {
    final small = !labels;
    final half = size.shortestSide / 2 - (small ? 6 : 34);
    final rect = Rect.fromCenter(center: c, width: half * 2, height: half * 2);
    final corners = [rect.bottomLeft, rect.topLeft, rect.topRight, rect.bottomRight];
    final stroke = small ? 2.0 : 3.0;

    // Inner breath field.
    final inner = half * (0.36 + 0.5 * level);
    _glow(canvas, c, inner * 2, color, 0.16 + 0.2 * level);
    final field = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: inner * 2, height: inner * 2),
      Radius.circular(inner * 0.3),
    );
    canvas.drawRRect(
      field,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.4),
            color.withValues(alpha: 0.6),
            Color.lerp(color, Colors.black, 0.25)!.withValues(alpha: 0.85)
          ],
          stops: const [0, 0.65, 1],
        ).createShader(field.outerRect),
    );
    _glow(canvas, c + Offset(-inner * 0.4, -inner * 0.45), inner * 0.5, Colors.white, 0.28);
    canvas.drawRRect(
      field,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.3),
    );

    // Track and travelled sides.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(half * 0.06)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    final side = Paint()
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (active) {
      for (var i = 0; i < phase; i++) {
        canvas.drawLine(corners[i], corners[(i + 1) % 4], side..color = color.withValues(alpha: 0.55));
      }
      final a = corners[phase], b = corners[(phase + 1) % 4];
      final head = Offset.lerp(a, b, t)!;
      canvas.drawLine(
        a,
        head,
        Paint()
          ..strokeWidth = stroke + 0.6
          ..strokeCap = StrokeCap.round
          ..shader =
              LinearGradient(colors: [color.withValues(alpha: 0.4), _bright]).createShader(Rect.fromPoints(a, head)),
      );
      _glow(canvas, head, small ? 10 : 22, _bright, 0.95);
      canvas.drawCircle(head, small ? 3 : 5.5, Paint()..color = Colors.white);
    }
    for (final corner in corners) {
      canvas.drawCircle(corner, small ? 1.6 : 2.6, Paint()..color = Colors.white.withValues(alpha: 0.45));
    }

    if (labels) {
      String l(int i) => '${phases[i].title.toUpperCase()} ${phaseSeconds(phases[i].seconds)}';
      _label(canvas, l(0), Offset(rect.left - 18, c.dy), current: active && phase == 0, angle: -math.pi / 2);
      _label(canvas, l(1), Offset(c.dx, rect.top - 18), current: active && phase == 1);
      _label(canvas, l(2), Offset(rect.right + 18, c.dy), current: active && phase == 2, angle: math.pi / 2);
      _label(canvas, l(3), Offset(c.dx, rect.bottom + 18), current: active && phase == 3);
    }
  }

  @override
  bool shouldRepaint(BreathVisualPainter old) =>
      old.phase != phase || old.t != t || old.level != level || old.color != color || old.active != active;
}

/// A small live preview that runs the pattern in real time, on a loop.
class BreathPreview extends StatefulWidget {
  const BreathPreview({super.key, required this.pattern, this.size = 92});

  final BreathPattern pattern;
  final double size;

  @override
  State<BreathPreview> createState() => _BreathPreviewState();
}

class _BreathPreviewState extends State<BreathPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.pattern.cycleSeconds * 1000).round()),
  )..repeat();

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _cycle,
          builder: (context, _) {
            final spot = breathSpotAt(widget.pattern, _cycle.value);
            return CustomPaint(
              painter: BreathVisualPainter(
                shape: widget.pattern.shape,
                phases: widget.pattern.phases,
                phase: spot.phase,
                t: spot.t,
                level: spot.level,
                color: widget.pattern.color,
                labels: false,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The rhythm as a bar split by each phase's share of the cycle; the
/// live phase fills as it runs.
class PhaseStrip extends StatelessWidget {
  const PhaseStrip({
    super.key,
    required this.phases,
    required this.color,
    this.current = -1,
    this.t = 0,
    this.large = false,
  });

  final List<BreathPhase> phases;
  final Color color;
  final int current;
  final double t;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final bar = large ? 6.0 : 4.0;
    final cycle = phases.fold<double>(0, (s, p) => s + p.seconds);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < phases.length; i++) ...[
          if (i > 0) SizedBox(width: large ? 6 : 4),
          Expanded(
            flex: (phases[i].seconds * 10).round(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(bar / 2),
                  child: SizedBox(
                    height: bar,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: Colors.white.withValues(alpha: i < current ? 0.0 : 0.14)),
                        if (i < current) ColoredBox(color: color.withValues(alpha: 0.7)),
                        if (i == current)
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: t.clamp(0.0, 1.0),
                            child: ColoredBox(color: Color.lerp(color, Colors.white, 0.3)!),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: large ? 8 : 6),
                if (large || phases[i].seconds / cycle >= 0.15)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: phaseShortLabel(phases[i]),
                          style: capsStyle(
                            color: i == current ? Colors.white : Colors.white.withValues(alpha: 0.6),
                            size: large ? 10 : 8.5,
                          ),
                        ),
                        TextSpan(
                          text: ' ${phaseSeconds(phases[i].seconds)}s',
                          style: TextStyle(
                            fontFamily: 'InterDisplay',
                            fontWeight: FontWeight.w600,
                            fontSize: (large ? 15 : 13) * 0.8,
                            color: i == current ? Colors.white : Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
