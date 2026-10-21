import 'package:flutter/material.dart';

/// Foreground decoration giving any Container a glassy top specular.
/// Cheap one-line gloss for cards that already manage their own shape.
BoxDecoration glossForeground(double radius) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x36FFFFFF), Color(0x00FFFFFF)],
        stops: [0, 0.5],
      ),
    );

/// Wraps a card with a glassy finish: soft top specular, a luminous
/// gradient border and an optional sheen band that sweeps across.
///
/// Deliberately does NOT clip the child (card shadows paint outside the
/// bounds) — the painter itself draws inside the rounded shape.
class GlossOverlay extends StatelessWidget {
  const GlossOverlay({
    super.key,
    required this.child,
    this.borderRadius = 26,
    this.sheen = -1.0,
  });

  final Widget child;
  final double borderRadius;

  /// Sweep position; values outside (0, 1) hide the band.
  final double sheen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: GlossPainter(
                borderRadius: borderRadius,
                sheen: sheen,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the glass finish: specular top, sheen band, gradient border.
class GlossPainter extends CustomPainter {
  const GlossPainter({this.borderRadius = 26, this.sheen = -1.0});

  final double borderRadius;
  final double sheen;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    // Soft specular highlight on the top third.
    final specular = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
        stops: [0, 0.42],
      ).createShader(rect);
    canvas.drawRect(rect, specular);

    // Sweeping sheen band (diagonal light streak).
    if (sheen > 0 && sheen < 1) {
      final band = Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1.2, -0.6),
          end: const Alignment(1.2, 0.6),
          colors: const [
            Color(0x00FFFFFF),
            Color(0x26FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [
            (sheen - 0.22).clamp(0.0, 1.0),
            sheen.clamp(0.0, 1.0),
            (sheen + 0.22).clamp(0.0, 1.0),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, band);
    }

    canvas.restore();

    // Luminous gradient border (drawn after restore so it stays crisp).
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.2),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(0.7), border);

    // Top edge inner glow line for the wet-glass look.
    if (size.width > 28) {
      final topLine = Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.3);
      canvas.drawLine(
        const Offset(14, 1.4),
        Offset(size.width - 14, 1.4),
        topLine,
      );
    }
  }

  @override
  bool shouldRepaint(GlossPainter old) =>
      old.sheen != sheen || old.borderRadius != borderRadius;
}
