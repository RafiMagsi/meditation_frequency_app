import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'luxury.dart';

/// The microphone control: a foil ring around an onyx centre, with ripples
/// that swell with the live [level] while listening.
class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.listening,
    required this.level,
    required this.color,
    required this.onTap,
    this.size = 92,
  });

  final bool listening;
  final ValueListenable<double> level;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: listening ? 'Stop listening' : 'Start listening',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: SizedBox.square(
          dimension: size * 1.7,
          child: ValueListenableBuilder<double>(
            valueListenable: level,
            builder: (context, l, _) => CustomPaint(
              painter: _RipplePainter(level: listening ? l : 0, color: color, inner: size / 2),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(2.4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: foilFor(color),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: listening ? 0.5 : 0.2), blurRadius: listening ? 34 : 16),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(-0.3, -0.4),
                        colors: [Color(0xFF26232C), Color(0xFF0B0A0E)],
                      ),
                    ),
                    child: Icon(
                      listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: size * 0.42,
                      color: Color.lerp(color, Colors.white, 0.45),
                    ),
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

class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.level, required this.color, required this.inner});

  final double level;
  final Color color;
  final double inner;

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0.01) return;
    final c = size.center(Offset.zero);
    final reach = (size.shortestSide / 2 - inner) * level;
    for (var k = 1; k <= 3; k++) {
      canvas.drawCircle(
        c,
        inner + reach * k / 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: 0.5 * (1 - k / 4) * level),
      );
    }
    canvas.drawCircle(
      c,
      inner + reach,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.25 * level), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: inner + reach)),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.level != level || old.color != color;
}

/// A thin live loudness bar with the threshold your voice has to cross.
class LevelMeter extends StatelessWidget {
  const LevelMeter({super.key, required this.level, required this.threshold, required this.color});

  final double level;
  final double threshold;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: CustomPaint(
        painter: _MeterPainter(level: level, threshold: threshold, color: color),
        size: const Size(double.infinity, 14),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter({required this.level, required this.threshold, required this.color});

  final double level;
  final double threshold;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 2, size.width, y + 2, const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );
    final x = size.width * level.clamp(0.0, 1.0);
    final heard = level >= threshold;
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 2, math.max(x, 4), y + 2, const Radius.circular(2)),
      Paint()..color = heard ? Color.lerp(color, Colors.white, 0.3)! : AppTheme.textMuted.withValues(alpha: 0.6),
    );
    final tx = size.width * threshold;
    canvas.drawLine(
      Offset(tx, 0),
      Offset(tx, size.height),
      Paint()
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_MeterPainter old) => old.level != level || old.threshold != threshold;
}
