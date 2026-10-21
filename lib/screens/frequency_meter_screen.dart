import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/feature_scaffold.dart';

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
    return FeatureScaffold(
      accent: AppTheme.violet,
      header: const FeatureHeader(
        heroTag: 'card-meter',
        style: CardStyles.meter,
        height: 124,
        title: 'Aura Meter',
        subtitle: 'Visualize your sound field',
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Smooth random-walk level for an organic "live" feel.
          final t = _controller.value;
          final target = 0.5 + 0.42 * math.sin(t * 2 * math.pi * 1.7) * math.cos(t * 2 * math.pi * 0.6);
          _level += (target - _level) * 0.08;
          return Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _AuraPainter(t: t, level: _level),
                ),
              ),
              GlassPanel(
                accent: AppTheme.violet,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      '${(_level * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontWeight: FontWeight.w600,
                        fontSize: 34,
                        height: 1,
                        color: AppTheme.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RESONANCE', style: capsStyle(size: 10)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _level.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation(Color.lerp(AppTheme.violet, AppTheme.pink, _level)!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
        ..color = Color.lerp(AppTheme.violet, AppTheme.pink, i / 5)!.withValues(alpha: opacity);
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
      final r = base * (0.9 + 0.25 * math.sin(t * 2 * math.pi + i));
      final pos = center + Offset(math.cos(a), math.sin(a)) * r;
      sparklePaint.color = Colors.white.withValues(alpha: 0.15 + 0.5 * level * ((i % 3) / 3));
      canvas.drawCircle(pos, 1.6 + 1.4 * ((i % 2).toDouble()), sparklePaint);
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.t != t || old.level != level;
}
