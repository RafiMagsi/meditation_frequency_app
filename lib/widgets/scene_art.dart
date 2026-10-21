import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/card_styles.dart';

/// Shared 24 s loop for all artwork. Reading a global clock (instead of a
/// per-widget controller) keeps a scene in phase when the same card is
/// rebuilt elsewhere — e.g. inside a hero flight — so nothing "jumps".
abstract final class ArtClock {
  static final Stopwatch _watch = Stopwatch()..start();
  static const int periodMs = 24000;

  static double get value => (_watch.elapsedMilliseconds % periodMs) / periodMs;
}

/// Living illustration for a card. Scenes are painted (resolution
/// independent, tiny, and animatable), sized to whatever box they get.
class SceneArt extends StatefulWidget {
  const SceneArt({
    super.key,
    required this.scene,
    this.accent = Colors.white,
    this.animate = true,
  });

  final Scene scene;

  /// Tint for decor scenes that follow their card's colour (waves).
  final Color accent;
  final bool animate;

  @override
  State<SceneArt> createState() => _SceneArtState();
}

class _SceneArtState extends State<SceneArt> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _t = ValueNotifier(ArtClock.value);
  late final Ticker _ticker;
  Duration _lastPaint = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Scene motion is slow (a 24 s loop), so ~30 fps is indistinguishable
    // and saves most of the painting on 120 Hz screens.
    _ticker = createTicker((elapsed) {
      if (elapsed - _lastPaint < const Duration(milliseconds: 32)) return;
      _lastPaint = elapsed;
      _t.value = ArtClock.value;
    });
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(SceneArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.animate && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ScenePainter(scene: widget.scene, accent: widget.accent, clock: _t),
      ),
    );
  }
}

class ScenePainter extends CustomPainter {
  ScenePainter({required this.scene, required this.accent, required this.clock}) : super(repaint: clock);

  final Scene scene;
  final Color accent;
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final b = _Brush(canvas, size, clock.value, accent);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (scene) {
      case Scene.cosmos:
        _cosmos(b);
      case Scene.forest:
        _forest(b);
      case Scene.aurora:
        _aurora(b);
      case Scene.ocean:
        _ocean(b);
      case Scene.dawn:
        _dawn(b);
      case Scene.lake:
        _lake(b);
      case Scene.breeze:
        _breeze(b);
      case Scene.lotus:
        _lotus(b);
      case Scene.night:
        _night(b);
      case Scene.focus:
        _focus(b);
      case Scene.mandala:
        _mandala(b);
      case Scene.gold:
        _gold(b);
      case Scene.chart:
        _chart(b);
      case Scene.vinyl:
        _vinyl(b);
      case Scene.waves:
        _waves(b);
      case Scene.engraved:
        _engraved(b);
      case Scene.none:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ScenePainter old) => old.scene != scene || old.accent != accent || old.clock != clock;
}

// ─── Scenes ──────────────────────────────────────────────────────────────

/// Nebula with a tone source emitting rings and two sine signatures.
void _cosmos(_Brush b) {
  b.sky(const [Color(0xFF120C3D), Color(0xFF2A1F7A), Color(0xFF140E40)], stops: const [0, 0.55, 1]);
  b.glow(b.at(0.82, 0.18), b.m * 0.95, const Color(0xFFE879B8), 0.42);
  b.glow(b.at(0.12, 0.08), b.m * 0.8, const Color(0xFF6EA8F6), 0.32);
  b.glow(b.at(0.45, 0.8), b.m * 0.9, const Color(0xFF8B6CF0), 0.35);
  b.stars(42, seed: 3, maxY: 0.95);
  final src = b.at(0.8, 0.3);
  for (var i = 0; i < 4; i++) {
    final ph = (b.t * 6 + i / 4) % 1.0;
    b.ring(src, b.m * (0.07 + ph * 0.6), Colors.white, 0.42 * (1 - ph), 1.1);
  }
  b.glow(src, b.m * 0.36, const Color(0xFFB6A8FF), 0.55);
  b.glow(src, b.m * 0.12, Colors.white, 0.95);
  b.sine(y: 0.6, amp: 0.07, cycles: 2.5, drift: 2, color: const Color(0xFF5EEAD4), alpha: 0.6);
  b.sine(y: 0.63, amp: 0.05, cycles: 3.5, drift: -3, color: const Color(0xFFF8B8DA), alpha: 0.5);
}

/// Misty pine forest at sunrise.
void _forest(_Brush b) {
  b.sky(const [
    Color(0xFF0A2A33),
    Color(0xFF1C6B6E),
    Color(0xFF8FD8C2),
    Color(0xFFF6E2B0),
  ], stops: const [
    0,
    0.42,
    0.68,
    0.82
  ]);
  final sun = b.at(0.72, 0.56);
  b.glow(sun, b.m * 0.95, const Color(0xFFFFE1A1), 0.55 + 0.08 * b.osc(2));
  b.disc(sun, b.m * 0.075, const Color(0xFFFFF6DC));
  b.fill(b.ridge(base: 0.7, amp: 0.18, seed: 11, freq: 1.2), const Color(0xFF4A9A90));
  b.puffs(y: 0.68, seed: 4, color: const Color(0xFFE6FFF5), alpha: 0.4);
  b.pines(base: 0.82, count: 13, seed: 5, color: const Color(0xFF1F5E5B), minH: 0.14, maxH: 0.26);
  b.band(0.84, 0.12, const Color(0xFFD8F5EA), 0.22);
  b.pines(base: 1.04, count: 7, seed: 9, color: const Color(0xFF071F21), minH: 0.32, maxH: 0.55);
}

/// Aurora curtains over mountains.
void _aurora(_Brush b) {
  b.sky(const [Color(0xFF0E0726), Color(0xFF2E1240), Color(0xFF5A1F52)], stops: const [0, 0.6, 1]);
  b.stars(36, seed: 8, maxY: 0.75);
  b.curtain(
      y: 0.3,
      amp: 0.07,
      depth: 0.28,
      cycles: 1.3,
      drift: 1,
      colors: const [Color(0xFF5EEAD4), Color(0xFF7FE0A8)],
      alpha: 0.6);
  b.curtain(
      y: 0.18,
      amp: 0.05,
      depth: 0.2,
      cycles: 1.8,
      drift: -1,
      colors: const [Color(0xFFE879B8), Color(0xFF8B7CF6)],
      alpha: 0.5);
  b.fillShaded(
      b.ridge(base: 0.84, amp: 0.26, seed: 21, freq: 1.4), const Color(0xFF3A1446), const Color(0xFF1C0A26), 0.55, 1);
  b.fill(b.ridge(base: 0.97, amp: 0.16, seed: 23, freq: 0.9), const Color(0xFF12051A));
}

/// Sun setting into a calm sea.
void _ocean(_Brush b) {
  const horizon = 0.6;
  b.sky(const [
    Color(0xFF0A1433),
    Color(0xFF233A78),
    Color(0xFF7A8FD0),
    Color(0xFFF2B8A0),
  ], stops: const [
    0,
    0.5,
    0.85,
    1
  ], bottom: horizon);
  b.stars(16, seed: 2, maxY: 0.32);
  final sun = b.at(0.7, horizon - 0.03);
  b.glow(sun, b.m * 0.8, const Color(0xFFFFCFA8), 0.6);
  b.disc(sun, b.m * 0.08, const Color(0xFFFFF0DE));
  b.sea(horizon, const [Color(0xFF4A5C98), Color(0xFF1A2550), Color(0xFF0B1530)]);
  b.reflection(sun.dx, horizon, b.w * 0.3, const Color(0xFFFFE0C8));
  b.swell(horizon, count: 6, alpha: 0.1);
}

/// Sunrise over layered peaks.
void _dawn(_Brush b) {
  b.sky(const [
    Color(0xFF3B2A6B),
    Color(0xFFB8577A),
    Color(0xFFF29E6D),
    Color(0xFFFFD79A),
  ], stops: const [
    0,
    0.38,
    0.62,
    0.8
  ]);
  final sun = b.at(0.7, 0.6);
  b.glow(sun, b.m, const Color(0xFFFFE2A6), 0.65 + 0.08 * b.osc(2));
  b.disc(sun, b.m * 0.1, const Color(0xFFFFF4D8));
  b.fill(b.ridge(base: 0.7, amp: 0.2, seed: 31, freq: 1.1), const Color(0xE6C86A80));
  b.band(0.7, 0.12, const Color(0xFFFFD9C0), 0.4);
  b.fill(b.ridge(base: 0.82, amp: 0.2, seed: 33, freq: 1.5), const Color(0xFF7A3566));
  b.band(0.84, 0.1, const Color(0xFFF7B9A8), 0.2);
  b.fill(b.ridge(base: 0.95, amp: 0.16, seed: 35, freq: 0.8), const Color(0xFF35183F));
}

/// Full moon over a still violet lake.
void _lake(_Brush b) {
  const horizon = 0.62;
  b.sky(const [Color(0xFF140F33), Color(0xFF35297A), Color(0xFF8E7FE0)], stops: const [0, 0.6, 1], bottom: horizon);
  b.stars(30, seed: 12, maxY: 0.5);
  final moon = b.at(0.72, 0.26);
  b.glow(moon, b.m * 0.6, const Color(0xFFC9C0FF), 0.45);
  b.disc(moon, b.m * 0.09, const Color(0xFFF4F1FF));
  b.fill(b.ridge(base: horizon + 0.005, amp: 0.12, seed: 41, freq: 1.3), const Color(0xFF2A2068));
  b.sea(horizon, const [Color(0xFF2E2470), Color(0xFF17123F), Color(0xFF0F0B2A)]);
  b.reflection(moon.dx, horizon, b.w * 0.22, const Color(0xFFE6E0FF));
  b.swell(horizon, count: 5, alpha: 0.07);
}

/// Soft clouds and flowing wind ribbons.
void _breeze(_Brush b) {
  b.sky(const [Color(0xFF0B3440), Color(0xFF1D7A80), Color(0xFF7FDCCB)], stops: const [0, 0.55, 1]);
  b.glow(b.at(0.8, 0.18), b.m * 0.8, const Color(0xFFE8FFF8), 0.4);
  b.puffs(y: 0.22, seed: 51, color: Colors.white, alpha: 0.24, count: 3, spread: 0.18);
  for (var i = 0; i < 6; i++) {
    b.sine(
      y: 0.3 + i * 0.1,
      amp: 0.05 + 0.01 * i,
      cycles: 1.2 + i * 0.25,
      drift: i.isEven ? 1 : -1,
      color: Colors.white,
      alpha: 0.22 + 0.05 * i,
      width: 1.2,
    );
  }
  b.motes(seed: 53, count: 16, color: Colors.white);
}

/// A glowing lotus on rippling water with drifting bokeh.
void _lotus(_Brush b) {
  b.sky(const [Color(0xFF2A0A24), Color(0xFF6E2058), Color(0xFFB04A88)], stops: const [0, 0.6, 1]);
  b.bokeh(seed: 61, count: 14, colors: const [Color(0xFFFFC2E2), Color(0xFFF6C77A), Color(0xFFE879B8)]);
  final base = b.at(0.72, 0.8);
  b.glow(base.translate(0, -b.m * 0.14), b.m * 0.6, const Color(0xFFFFC2E2), 0.55 + 0.1 * b.osc(2));
  for (var k = 0; k < 3; k++) {
    final ph = (b.t * 4 + k / 3) % 1.0;
    final rect = Rect.fromCenter(
      center: base,
      width: b.m * (0.3 + ph * 0.7),
      height: b.m * (0.06 + ph * 0.12),
    );
    b.c.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = b.unit
        ..color = Colors.white.withValues(alpha: 0.32 * (1 - ph)),
    );
  }
  b.lotus(base, b.m * 0.34);
}

/// Crescent moon, star field and sleeping hills.
void _night(_Brush b) {
  b.sky(const [Color(0xFF040817), Color(0xFF0C1A44), Color(0xFF1E3A78)], stops: const [0, 0.65, 1]);
  b.stars(70, seed: 6, maxY: 0.8);
  final moon = b.at(0.74, 0.28);
  final r = b.m * 0.12;
  b.glow(moon, r * 4.2, const Color(0xFFBFD4FF), 0.35);
  final crescent = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: moon, radius: r)),
    Path()..addOval(Rect.fromCircle(center: moon.translate(r * 0.42, -r * 0.22), radius: r * 0.92)),
  );
  b.c.drawPath(crescent, Paint()..color = const Color(0xFFF4F0E2));
  b.puffs(y: 0.48, seed: 71, color: const Color(0xFF8FA8E8), alpha: 0.14, count: 3, spread: 0.2);
  b.fillShaded(
      b.ridge(base: 0.84, amp: 0.2, seed: 73, freq: 1.2), const Color(0xFF1A2C60), const Color(0xFF0E1A40), 0.6, 1);
  b.fill(b.ridge(base: 0.96, amp: 0.14, seed: 75, freq: 0.9), const Color(0xFF050A1E));
}

/// Slowly turning Flower of Life in a warm amber field.
void _focus(_Brush b) {
  b.sky(const [Color(0xFF3A1A10), Color(0xFF6E2E16), Color(0xFF2A120A)], stops: const [0, 0.5, 1]);
  final c0 = b.at(0.74, 0.38);
  b.glow(c0, b.m * 0.95, const Color(0xFFF0956B), 0.65);
  b.glow(c0, b.m * 0.32, const Color(0xFFFFD2A8), 0.55 + 0.1 * b.osc(3));
  final r = b.m * 0.13;
  final rot = b.t * 2 * math.pi;
  b.ring(c0, r, Colors.white, 0.45, 1.1);
  for (var i = 0; i < 6; i++) {
    final a = rot + i * math.pi / 3;
    b.ring(c0 + Offset(math.cos(a), math.sin(a)) * r, r, Colors.white, 0.32);
  }
  b.ring(c0, r * 2, Colors.white, 0.28, 1.2);
  for (var k = 0; k < 3; k++) {
    final ph = (b.t * 4 + k / 3) % 1.0;
    b.ring(c0, r * 2 + ph * b.m * 0.45, Colors.white, 0.22 * (1 - ph));
  }
}

/// Counter-rotating petal rings (sound-field mandala).
void _mandala(_Brush b) {
  b.sky(const [Color(0xFF0E0B30), Color(0xFF2B2270), Color(0xFF151040)], stops: const [0, 0.5, 1]);
  final c0 = b.at(0.8, 0.48);
  b.glow(c0, b.m * 0.9, const Color(0xFF8B7CF6), 0.5);
  b.glow(c0, b.m * 0.5, const Color(0xFFE879B8), 0.3);
  b.stars(24, seed: 81, maxY: 1);
  for (var k = 0; k < 4; k++) {
    final n = 8 + k * 4;
    final radius = b.m * (0.07 + k * 0.075);
    final rot = (k.isEven ? 1 : -1) * b.t * 2 * math.pi;
    final petal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * b.unit
      ..color = Colors.white.withValues(alpha: 0.4 - k * 0.06);
    for (var i = 0; i < n; i++) {
      b.c.save();
      b.c.translate(c0.dx, c0.dy);
      b.c.rotate(rot + i * 2 * math.pi / n);
      b.c.drawOval(
        Rect.fromCenter(
          center: Offset(radius, 0),
          width: b.m * (0.06 + 0.012 * k),
          height: b.m * 0.026,
        ),
        petal,
      );
      b.c.restore();
    }
    b.ring(c0, radius + b.m * 0.035, Colors.white, 0.14);
  }
  b.glow(c0, b.m * 0.06, Colors.white, 0.9);
}

/// Onyx with gold light rays, engraved arcs and rising gold bokeh.
void _gold(_Brush b) {
  b.sky(const [Color(0xFF0A0908), Color(0xFF17130C), Color(0xFF0A0908)], stops: const [0, 0.55, 1]);
  const gold = Color(0xFFD4AF6A);
  final src = b.at(0.92, -0.1);
  final len = b.m * 2.6;
  final rayShader = RadialGradient(
    colors: [gold.withValues(alpha: 0.24), gold.withValues(alpha: 0)],
  ).createShader(Rect.fromCircle(center: src, radius: len));
  for (var i = 0; i < 7; i++) {
    final a = math.pi * (0.55 + i * 0.065) + 0.03 * b.osc(1, i * 0.13);
    final spread = 0.03 + (i % 3) * 0.012;
    final path = Path()
      ..moveTo(src.dx, src.dy)
      ..lineTo(src.dx + math.cos(a - spread) * len, src.dy + math.sin(a - spread) * len)
      ..lineTo(src.dx + math.cos(a + spread) * len, src.dy + math.sin(a + spread) * len)
      ..close();
    b.c.drawPath(path, Paint()..shader = rayShader);
  }
  b.glow(b.at(0.88, 0.04), b.m * 0.9, gold, 0.34);
  for (var i = 0; i < 9; i++) {
    b.ring(b.at(1.02, 0.0), b.m * (0.32 + i * 0.085), gold, 0.11, 0.7);
  }
  b.bokeh(seed: 91, count: 16, colors: const [Color(0xFFF7E3A6), gold, Color(0xFFB88A3E)]);
  b.dust(seed: 93, count: 30, color: const Color(0xFFFFF1C9));
}

/// Decor: a week of practice as soft bars (progress card).
void _chart(_Brush b) {
  const values = [0.36, 0.55, 0.18, 0.68, 0.45, 1.0, 0.64];
  final left = b.w * 0.52, right = b.w * 0.94;
  final bottom = b.h * 0.84, top = b.h * 0.16;
  final slot = (right - left) / values.length;
  b.glow(b.at(0.82, 0.2), b.m * 0.8, Colors.white, 0.16);
  for (var i = 0; i < values.length; i++) {
    final height = (bottom - top) * values[i] * (0.94 + 0.06 * b.osc(2, i * 0.11));
    final rrect = RRect.fromLTRBR(
      left + slot * i + slot * 0.2,
      bottom - height,
      left + slot * (i + 1) - slot * 0.2,
      bottom,
      Radius.circular(slot * 0.3),
    );
    b.c.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: i == 5 ? 0.6 : 0.22));
  }
}

/// Decor: two spinning records (playlists card).
void _vinyl(_Brush b) {
  final r = b.m * 0.46;
  for (final center in [b.at(1.02, 0.22), b.at(0.84, 0.5)]) {
    b.disc(center, r, const Color(0xE6140812));
    for (var k = 0; k < 7; k++) {
      b.ring(center, r * (0.42 + k * 0.08), Colors.white, 0.07, 0.6);
    }
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0x00FFFFFF),
          Color(0x26FFFFFF),
          Color(0x00FFFFFF),
          Color(0x00FFFFFF),
          Color(0x1FFFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: const [0, 0.08, 0.18, 0.5, 0.58, 0.68],
        transform: GradientRotation(b.t * 2 * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: r));
    b.c.drawCircle(center, r, sweep);
    b.c.drawCircle(
      center,
      r * 0.3,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE879B8), Color(0xFFF6C77A)],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.3)),
    );
    b.disc(center, r * 0.05, const Color(0xFF140812));
  }
}

/// Decor: live sine signature in the card's own colour (tone cards).
void _waves(_Brush b) {
  b.glow(b.at(0.88, 0.5), b.m * 1.1, b.accent, 0.38);
  b.sine(y: 0.5, amp: 0.3, cycles: 2, drift: 2, color: b.accent, alpha: 0.28, width: 1.0, x0: 0.5, x1: 1.0);
  b.sine(y: 0.5, amp: 0.22, cycles: 3, drift: 4, color: b.accent, alpha: 0.6, width: 1.5, x0: 0.5, x1: 1.0);
  b.sine(y: 0.5, amp: 0.14, cycles: 4.5, drift: -3, color: Colors.white, alpha: 0.3, width: 1.0, x0: 0.5, x1: 1.0);
}

/// Decor: banknote guilloché in hairline gold (money cards).
void _engraved(_Brush b) {
  final metal = b.accent;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.6 * b.unit;
  for (var k = 0; k < 14; k++) {
    final path = Path();
    for (var i = 0; i <= 90; i++) {
      final u = i / 90;
      final y = 0.5 +
          0.3 *
              math.sin((u * 2.2 + k * 0.035 + b.t) * 2 * math.pi) *
              math.cos((u * 0.9 - k * 0.02) * 2 * math.pi);
      final pt = Offset(b.w * u, b.h * y);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    p.color = metal.withValues(alpha: k % 3 == 0 ? 0.13 : 0.065);
    b.c.drawPath(path, p);
  }
}

// ─── Brush: shared painting primitives ───────────────────────────────────

class _Brush {
  _Brush(this.c, this.size, this.t, this.accent);

  final Canvas c;
  final Size size;
  final double t;
  final Color accent;

  double get w => size.width;
  double get h => size.height;
  double get m => size.shortestSide;
  double get unit => (m / 150).clamp(0.6, 2.4);

  Offset at(double x, double y) => Offset(x * w, y * h);

  /// Loop-safe oscillator: whole [cycles] per clock loop, so the 24 s
  /// wrap-around is invisible.
  double osc(int cycles, [double phase = 0]) => math.sin((t * cycles + phase) * 2 * math.pi);

  void sky(List<Color> colors, {List<double>? stops, double bottom = 1}) {
    final r = Rect.fromLTWH(0, 0, w, h * bottom);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(r),
    );
  }

  void sea(double horizon, List<Color> colors) {
    final r = Rect.fromLTRB(0, h * horizon, w, h);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(r),
    );
  }

  void glow(Offset center, double radius, Color color, double alpha) {
    if (radius <= 0 || alpha <= 0) return;
    final r = Rect.fromCircle(center: center, radius: radius);
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alpha.clamp(0.0, 1.0)), color.withValues(alpha: 0)],
        ).createShader(r),
    );
  }

  void ellipseGlow(Offset center, double rx, double ry, Color color, double alpha) {
    if (rx <= 0 || ry <= 0) return;
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(1, ry / rx);
    glow(Offset.zero, rx, color, alpha);
    c.restore();
  }

  void disc(Offset center, double radius, Color color) => c.drawCircle(center, radius, Paint()..color = color);

  void ring(Offset center, double radius, Color color, double alpha, [double width = 1]) {
    if (alpha <= 0) return;
    c.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * unit
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
  }

  void fill(Path path, Color color) => c.drawPath(path, Paint()..color = color);

  void fillShaded(Path path, Color top, Color bottom, double y0, double y1) {
    final r = Rect.fromLTRB(0, h * y0, w, h * y1);
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(r),
    );
  }

  /// Horizontal haze band, transparent at both edges.
  void band(double y, double height, Color color, double alpha) {
    final r = Rect.fromLTWH(0, h * (y - height / 2), w, h * height);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(r),
    );
  }

  /// Mountain silhouette from summed sines, closed to the bottom edge.
  Path ridge({required double base, required double amp, required int seed, double freq = 1}) {
    final rng = math.Random(seed);
    final p1 = rng.nextDouble() * 6.28, p2 = rng.nextDouble() * 6.28, p3 = rng.nextDouble() * 6.28;
    final path = Path()..moveTo(0, h);
    const steps = 56;
    for (var i = 0; i <= steps; i++) {
      final u = i / steps;
      final f = 0.5 +
          0.28 * math.sin(u * 6.28 * freq + p1) +
          0.14 * math.sin(u * 6.28 * freq * 2.3 + p2) +
          0.06 * math.sin(u * 6.28 * freq * 5.7 + p3);
      path.lineTo(u * w, h * (base - amp * f));
    }
    return path
      ..lineTo(w, h)
      ..close();
  }

  /// A row of layered pine silhouettes standing on [base].
  void pines({
    required double base,
    required int count,
    required int seed,
    required Color color,
    double minH = 0.15,
    double maxH = 0.3,
  }) {
    final rng = math.Random(seed);
    final path = Path();
    for (var i = 0; i < count; i++) {
      final x = ((i + rng.nextDouble() * 0.8) / count) * w * 1.06 - w * 0.03;
      final th = h * (minH + rng.nextDouble() * (maxH - minH));
      final half = th * 0.17;
      final by = h * base + rng.nextDouble() * h * 0.03;
      for (var k = 0; k < 3; k++) {
        final apex = by - th + k * th * 0.24;
        final tierBase = apex + th * 0.42;
        final hw = half * (0.6 + k * 0.32);
        path
          ..moveTo(x, apex)
          ..lineTo(x - hw, tierBase)
          ..lineTo(x + hw, tierBase)
          ..close();
      }
      path.addRect(Rect.fromLTRB(x - half * 0.12, by - th * 0.1, x + half * 0.12, by));
    }
    path.addRect(Rect.fromLTRB(0, h * base + h * 0.02, w, h));
    c.drawPath(path, Paint()..color = color);
  }

  /// Drifting mist puffs around [y].
  void puffs({
    required double y,
    required int seed,
    required Color color,
    required double alpha,
    int count = 4,
    double spread = 0.08,
  }) {
    final rng = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final x0 = rng.nextDouble();
      final dx = 0.06 * math.sin((t * (1 + rng.nextInt(2)) + rng.nextDouble()) * 2 * math.pi);
      final cy = h * (y + (rng.nextDouble() - 0.5) * spread);
      ellipseGlow(Offset(w * (x0 + dx), cy), w * (0.25 + rng.nextDouble() * 0.2), h * 0.07, color, alpha);
    }
  }

  void stars(int count, {required int seed, double maxY = 0.6}) {
    final rng = math.Random(seed);
    final p = Paint();
    final s = (m / 160).clamp(0.6, 2.2);
    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * maxY;
      final r = (0.35 + rng.nextDouble() * 0.9) * s;
      final base = 0.25 + 0.6 * rng.nextDouble();
      final tw = 0.55 + 0.45 * math.sin((t * (2 + rng.nextInt(5)) + rng.nextDouble()) * 2 * math.pi);
      p.color = Colors.white.withValues(alpha: base * tw);
      c.drawCircle(Offset(x, y), r, p);
    }
  }

  /// Tapered sine stroke; [drift] whole cycles per clock loop.
  void sine({
    required double y,
    required double amp,
    required double cycles,
    required int drift,
    required Color color,
    double alpha = 0.5,
    double width = 1.4,
    double x0 = 0,
    double x1 = 1,
  }) {
    final path = Path();
    const steps = 72;
    for (var i = 0; i <= steps; i++) {
      final u = i / steps;
      final env = math.sin(math.pi * u);
      final x = w * (x0 + (x1 - x0) * u);
      final yy = h * y + h * amp * env * math.sin((u * cycles + t * drift) * 2 * math.pi);
      i == 0 ? path.moveTo(x, yy) : path.lineTo(x, yy);
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * unit
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ]).createShader(Rect.fromLTRB(w * x0, 0, w * x1, h)),
    );
  }

  /// Aurora band: bright lower edge fading upward, softened with blur.
  void curtain({
    required double y,
    required double amp,
    required double depth,
    required double cycles,
    required int drift,
    required List<Color> colors,
    required double alpha,
  }) {
    final pts = <Offset>[];
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final u = i / steps;
      final yy = h *
          (y +
              amp * math.sin((u * cycles + t * drift) * 2 * math.pi) +
              amp * 0.4 * math.sin((u * cycles * 2.7 - t * drift * 2) * 2 * math.pi));
      pts.add(Offset(w * u, yy));
    }
    final path = Path()..addPolygon([...pts, for (final p in pts.reversed) p.translate(0, h * depth)], true);
    final bounds = Rect.fromLTRB(0, h * (y - amp * 1.4), w, h * (y + amp * 1.4 + depth));
    c.drawPath(
      path,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, m * 0.03)
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            colors[0].withValues(alpha: alpha),
            colors[1].withValues(alpha: alpha * 0.5),
            colors[1].withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(bounds),
    );
    // Fine vertical rays give the curtain its texture.
    final ray = Paint()..strokeWidth = 0.8 * unit;
    for (var i = 0; i < pts.length; i += 2) {
      final p = pts[i];
      ray.color = Colors.white.withValues(alpha: 0.05 + 0.05 * math.sin(i * 1.7 + t * 2 * math.pi));
      c.drawLine(p, p.translate(0, h * depth * 0.9), ray);
    }
  }

  /// Shimmering light path on water under a sun or moon.
  void reflection(double x, double horizon, double maxWidth, Color color, {int lines = 9}) {
    final p = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < lines; i++) {
      final f = i / lines;
      final y = h * horizon + h * (1 - horizon) * (0.06 + f * 0.85);
      final shimmer = 0.6 + 0.4 * math.sin((t * 3 + i * 0.37) * 2 * math.pi);
      final lw = maxWidth * (1 - f * 0.6) * shimmer;
      p
        ..strokeWidth = (1.2 + 1.6 * (1 - f)) * unit
        ..color = color.withValues(alpha: 0.55 * (1 - f) * shimmer);
      c.drawLine(Offset(x - lw / 2, y), Offset(x + lw / 2, y), p);
    }
  }

  /// Gentle swell lines, denser toward the horizon.
  void swell(double horizon, {required int count, required double alpha}) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * unit
      ..color = Colors.white.withValues(alpha: alpha);
    for (var k = 0; k < count; k++) {
      final f = math.pow((k + 1) / (count + 1), 1.6).toDouble();
      final y0 = h * (horizon + (1 - horizon) * f);
      final path = Path();
      for (var i = 0; i <= 40; i++) {
        final u = i / 40;
        final yy = y0 + h * 0.008 * (1 + f * 2) * math.sin((u * (3 + k) + t * (k.isEven ? 2 : -2)) * 2 * math.pi);
        i == 0 ? path.moveTo(0, yy) : path.lineTo(u * w, yy);
      }
      c.drawPath(path, p);
    }
  }

  /// Soft bokeh discs rising and wrapping seamlessly.
  void bokeh({required int seed, required int count, required List<Color> colors}) {
    final rng = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble();
      final speed = 1 + rng.nextInt(2);
      final y = (rng.nextDouble() - t * speed) % 1.0;
      final r = m * (0.03 + rng.nextDouble() * 0.08);
      final a = 0.35 * (0.35 + 0.65 * rng.nextDouble()) * math.sin(math.pi * y);
      final center = Offset(w * (x + 0.02 * osc(1, i * 0.17)), h * (y * 1.2 - 0.1));
      glow(center, r, colors[i % colors.length], a);
      disc(center, r * 0.55, colors[i % colors.length].withValues(alpha: a * 0.35));
    }
  }

  /// Tiny twinkling specks drifting upward.
  void dust({required int seed, required int count, required Color color}) {
    final rng = math.Random(seed);
    final p = Paint();
    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble();
      final y = (rng.nextDouble() - t * (1 + rng.nextInt(3))) % 1.0;
      final r = (0.5 + rng.nextDouble()) * unit;
      final tw = 0.5 + 0.5 * math.sin((t * (3 + rng.nextInt(4)) + rng.nextDouble()) * 2 * math.pi);
      p.color = color.withValues(alpha: (0.75 * tw * math.sin(math.pi * y)).clamp(0.0, 1.0));
      c.drawCircle(Offset(w * x, h * y), r, p);
    }
  }

  /// Small particles carried sideways by the wind.
  void motes({required int seed, required int count, required Color color}) {
    final rng = math.Random(seed);
    final p = Paint();
    for (var i = 0; i < count; i++) {
      final x = (rng.nextDouble() + t * (1 + rng.nextInt(2))) % 1.0;
      final y = rng.nextDouble() * 0.9 + 0.05 + 0.03 * osc(2, i * 0.21);
      p.color = color.withValues(alpha: 0.5 * math.sin(math.pi * x));
      c.drawCircle(Offset(w * x, h * y), (0.6 + rng.nextDouble() * 0.9) * unit, p);
    }
  }

  void lotus(Offset base, double size) {
    void petal(double angle, double len, double width, Color tip, Color root) {
      c.save();
      c.translate(base.dx, base.dy);
      c.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(width, -len * 0.45, 0, -len)
        ..quadraticBezierTo(-width, -len * 0.45, 0, 0)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [root, tip],
          ).createShader(Rect.fromLTRB(-width, -len, width, 0)),
      );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * unit
          ..color = Colors.white.withValues(alpha: 0.35),
      );
      c.restore();
    }

    const deep = Color(0xFFB0306E), mid = Color(0xFFE879B8), pale = Color(0xFFFFE3F0);
    for (final a in const [-1.25, 1.25]) {
      petal(a, size * 0.72, size * 0.2, mid, deep);
    }
    for (final a in const [-0.8, 0.8]) {
      petal(a, size * 0.88, size * 0.24, pale, deep);
    }
    for (final a in const [-0.38, 0.38]) {
      petal(a, size * 0.95, size * 0.26, pale, mid);
    }
    petal(0, size, size * 0.28, Colors.white, mid);
  }
}
