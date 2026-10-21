import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A pulsing meditation orb: glowing core, expanding rings and a soft
/// halo that "breathes" on a 4s cycle (like coherent breathing).
class BreathingOrb extends StatefulWidget {
  const BreathingOrb({
    super.key,
    required this.size,
    this.color = AppTheme.violet,
    this.glow = const Color(0xFFB6A8FF),
    this.breathing = true,
    this.breath,
  });

  final double size;
  final Color color;
  final Color glow;
  final bool breathing;

  /// External 0→1→0 breath to follow (e.g. the player's breath guide);
  /// falls back to the orb's own 4 s cycle.
  final Animation<double>? breath;

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, widget.breath]),
        builder: (context, _) {
          final pulse = Curves.easeInOut.transform(widget.breath?.value ?? _controller.value);
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _OrbPainter(
              breath: widget.breathing ? pulse : 0.5,
              color: widget.color,
              glow: widget.glow,
              time: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.breath,
    required this.color,
    required this.glow,
    required this.time,
  });

  final double breath;
  final Color color;
  final Color glow;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide * 0.26;

    // Expanding rings.
    for (var i = 0; i < 3; i++) {
      final ringProgress = (time + i / 3) % 1.0;
      final radius = base * (1.1 + ringProgress * 1.5);
      final opacity = (1 - ringProgress) * 0.22;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = glow.withValues(alpha: opacity),
      );
    }

    // Outer halo.
    final haloRadius = base * (1.55 + 0.12 * breath);
    canvas.drawCircle(
      center,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: haloRadius)),
    );

    // Core.
    final coreRadius = base * (0.92 + 0.1 * breath);
    final coreRect = Rect.fromCircle(center: center, radius: coreRadius);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [glow, color, color.withValues(alpha: 0.85)],
          stops: const [0, 0.55, 1],
          transform: const GradientRotation(-math.pi / 2.5),
        ).createShader(coreRect),
    );

    // Specular highlight.
    canvas.drawCircle(
      center + Offset(-coreRadius * 0.3, -coreRadius * 0.38),
      coreRadius * 0.32,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(
          center: center + Offset(-coreRadius * 0.3, -coreRadius * 0.38),
          radius: coreRadius * 0.32,
        )),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.breath != breath || old.time != time || old.color != color;
}
