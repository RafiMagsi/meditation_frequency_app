import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Aura meter: a living sound-field visualizer. The aura breathes with
/// a smooth simulated level — perfect camera material for the demo.
class FrequencyMeterScreen extends StatefulWidget {
  const FrequencyMeterScreen({super.key});

  @override
  State<FrequencyMeterScreen> createState() => _FrequencyMeterScreenState();
}

class _FrequencyMeterScreenState extends State<FrequencyMeterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  double _level = 0.5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF181040), Color(0xFF0A0E27)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      key: const Key('back'),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Aura Meter',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 36,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text('Visualize your sound field', style: mutedStyle.copyWith(fontSize: 13)),
              const Spacer(),
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    // Smooth random-walk level for a organic "live" feel.
                    final t = _controller.value;
                    final target =
                        0.5 + 0.42 * math.sin(t * 2 * math.pi * 1.7) * math.cos(t * 2 * math.pi * 0.6);
                    _level += (target - _level) * 0.08;
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _AuraPainter(
                        t: t,
                        level: _level,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_level * 100).round()}% resonance',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.violet.withValues(alpha: 
                      0.6 + 0.4 * _level),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({required this.t, required this.level});

  final double t;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide * 0.32;
    final paint = Paint();

    // Concentric aura rings, each pulsing at its own phase.
    for (var i = 0; i < 6; i++) {
      final phase = (t + i / 6) % 1.0;
      final radius = base * (0.55 + phase * (0.7 + level));
      final opacity = (1 - phase) * (0.25 + 0.45 * level);
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Color.lerp(AppTheme.violet, AppTheme.pink, i / 5)!
            .withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }

    // Core aura with breathing scale.
    final pulse = 1 + 0.08 * math.sin(t * 2 * math.pi);
    final coreR = base * (0.5 + 0.35 * level) * pulse;
    paint
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          AppTheme.violet.withValues(alpha: 0.75 + 0.2 * level),
          AppTheme.pink.withValues(alpha: 0.35),
          AppTheme.pink.withValues(alpha: 0),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromCircle(center: center, radius: coreR));
    canvas.drawCircle(center, coreR, paint);

    // Rotating sparkles.
    final sparklePaint = Paint()..color = Colors.white;
    for (var i = 0; i < 8; i++) {
      final a = (t * 2 * math.pi) + i * (math.pi / 4);
      final r = base * (0.9 + 0.25 * math.sin(t * 6 + i));
      final pos = center + Offset(math.cos(a), math.sin(a)) * r;
      sparklePaint.color = Colors.white.withValues(alpha: 0.15 + 0.5 * level * ((i % 3) / 3));
      canvas.drawCircle(pos, 1.6 + 1.4 * ((i % 2).toDouble()), sparklePaint);
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.t != t || old.level != level;
}
