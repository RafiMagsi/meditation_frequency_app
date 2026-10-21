import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen living background: a slowly breathing aurora gradient
/// with drifting light particles. Used behind welcome, home and player.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF0A0E27),
      Color(0xFF150F33),
      Color(0xFF1B1038),
    ],
    this.particleCount = 22,
    this.showParticles = true,
  });

  final Widget child;
  final List<Color> colors;
  final int particleCount;
  final bool showParticles;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Aurora blob centers drift on slow lissajous paths.
        final c1 = Offset(
          0.25 + 0.12 * math.sin(t * 2 * math.pi),
          0.18 + 0.08 * math.cos(t * 2 * math.pi * 1.3),
        );
        final c2 = Offset(
          0.78 + 0.10 * math.cos(t * 2 * math.pi * 0.8),
          0.72 + 0.10 * math.sin(t * 2 * math.pi * 1.1),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.colors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Soft aurora blobs.
            Positioned.fill(
              child: CustomPaint(
                painter: _AuroraPainter(
                  blob1Center: c1,
                  blob2Center: c2,
                  blob1Color: AppTheme.violet.withValues(alpha: 0.16 + 0.05 * math.sin(t * 6)),
                  blob2Color: AppTheme.pink.withValues(alpha: 0.12 + 0.04 * math.cos(t * 5)),
                ),
              ),
            ),
            if (widget.showParticles)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlesPainter(t, count: widget.particleCount),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.blob1Center,
    required this.blob2Center,
    required this.blob1Color,
    required this.blob2Color,
  });

  final Offset blob1Center;
  final Offset blob2Center;
  final Color blob1Color;
  final Color blob2Color;

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset rel, Color color) {
      final center = Offset(rel.dx * size.width, rel.dy * size.height);
      final radius = size.shortestSide * 0.55;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    blob(blob1Center, blob1Color);
    blob(blob2Center, blob2Color);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      blob1Center != old.blob1Center ||
      blob2Center != old.blob2Center ||
      blob1Color != old.blob1Color ||
      blob2Color != old.blob2Color;
}

class _ParticlesPainter extends CustomPainter {
  const _ParticlesPainter(this.t, {required this.count});

  final double t;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble();
      final x = rng.nextDouble();
      final drift = math.sin((t * speed + phase) * 2 * math.pi) * 0.03;
      final y = (1.0 - ((t * speed + phase) % 1.0)); // rise upward
      final px = (x + drift) * size.width;
      final py = y * size.height * 1.1 - size.height * 0.05;
      final fade = math.sin(math.pi * ((t * speed + phase) % 1.0)); // fade in/out
      final radius = (0.8 + rng.nextDouble() * 1.8) * (0.6 + 0.4 * fade);
      paint.shader = RadialGradient(
        colors: [
          AppTheme.textPrimary.withValues(alpha: 0.5 * fade),
          AppTheme.textPrimary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(px, py), radius: radius * 3));
      canvas.drawCircle(Offset(px, py), radius * 3, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.t != t;
}
