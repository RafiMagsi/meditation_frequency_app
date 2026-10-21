import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated audio waveform bars for the player. When [active] the bars
/// ripple like live audio; when paused they settle into flat lines.
class Waveform extends StatefulWidget {
  const Waveform({
    super.key,
    required this.color,
    this.active = false,
    this.bars = 37,
    this.height = 96,
  });

  final Color color;
  final bool active;
  final int bars;
  final double height;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void didUpdateWidget(Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _WavePainter(
                t: widget.active ? _controller.value : 0.0,
                animated: widget.active,
                color: widget.color,
                bars: widget.bars,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.t,
    required this.animated,
    required this.color,
    required this.bars,
  });

  final double t;
  final bool animated;
  final Color color;
  final int bars;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final gap = size.width / bars;
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < bars; i++) {
      final x = gap * (i + 0.5);
      // Envelope: taller in the middle of the strip.
      final env = math.sin(math.pi * (i + 0.5) / bars);
      final wobble = animated
          ? 0.5 +
              0.5 * math.sin((t * 2 * math.pi * 2) + i * 0.55) * math.cos(i * 1.7 + t * 6)
          : 0.0;
      final h = (size.height * 0.12) +
          (size.height * 0.34) * env * (animated ? (0.35 + 0.65 * wobble.abs()) : 0.28);
      paint
        ..strokeWidth = 3.2
        ..color = color.withValues(alpha: 0.35 + 0.55 * env);
      canvas.drawLine(Offset(x, midY - h), Offset(x, midY + h), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t || old.animated != animated;
}
