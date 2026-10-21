import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Progress: animated weekly chart, stats and an insight card.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _chart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  // Demo week: minutes of practice per day.
  static const _week = [8, 12, 0, 15, 10, 22, 14];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void dispose() {
    _chart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _week.fold<int>(0, (a, b) => a + b);
    const streak = 6;
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF221A0C), Color(0xFF0A0E27)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
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
              const SizedBox(height: 14),
              Hero(
                tag: 'card-progress',
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A6D1F), Color(0xFFF6C77A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.w600,
                          fontSize: 34,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Every session counts',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Minutes',
                      value: '$total',
                      color: AppTheme.gold,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _StatCard(
                      label: 'Day streak',
                      value: '$streak',
                      color: AppTheme.pink,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Sessions',
                      value: '${_week.where((v) => v > 0).length}',
                      color: AppTheme.teal,
                      icon: Icons.spa_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: AppTheme.surface,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THIS WEEK', style: mutedStyle.copyWith(fontSize: 10.5, letterSpacing: 2.5)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: AnimatedBuilder(
                        animation: _chart,
                        builder: (context, _) => CustomPaint(
                          size: const Size(double.infinity, 150),
                          painter: _WeekChartPainter(
                            values: _week,
                            labels: _days,
                            t: Curves.easeOutCubic.transform(_chart.value),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.violet.withValues(alpha: 0.35),
                      AppTheme.pink.withValues(alpha: 0.25),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppTheme.gold, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saturday is your power day — 22 minutes of deep calm.',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          height: 1.35,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 30,
              height: 1,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: mutedStyle.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _WeekChartPainter extends CustomPainter {
  const _WeekChartPainter({
    required this.values,
    required this.labels,
    required this.t,
  });

  final List<int> values;
  final List<String> labels;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.fold<int>(1, math.max);
    final slot = size.width / values.length;
    final barW = slot * 0.42;
    for (var i = 0; i < values.length; i++) {
      final x = slot * (i + 0.5);
      final fullH = (size.height - 26) * (values[i] / maxV);
      final h = fullH * t;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, size.height - 26 - h / 2 + 8), width: barW, height: math.max(h, 4)),
        const Radius.circular(8),
      );
      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [AppTheme.gold, Color(0xFF8A6D1F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rrect.outerRect);
      canvas.drawRRect(rrect, paint);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: AppTheme.textMuted.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(_WeekChartPainter old) => old.t != t;
}
