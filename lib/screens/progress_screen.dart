import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/card_face.dart';
import '../widgets/feature_scaffold.dart';

/// Progress: stat cards, an animated week chart and an insight card.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _chart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  // Demo week: minutes of practice per day.
  static const _week = [8, 12, 0, 15, 10, 22, 14];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    // Let the bars grow once the screen has settled in.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _chart.forward();
    });
  }

  @override
  void dispose() {
    _chart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final practice = ref.watch(practiceProvider);
    final total = _week.fold<int>(0, (a, b) => a + b);
    return FeatureScaffold(
      accent: AppTheme.gold,
      header: FeatureHeader(
        heroTag: 'card-progress',
        style: CardStyles.progress,
        eyebrow: 'THIS WEEK',
        title: 'Your Progress',
        subtitle: '$total mindful minutes',
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'Minutes', value: '$total', color: AppTheme.gold, icon: Icons.schedule_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Day streak',
                value: '${practice.streak}',
                color: AppTheme.amber,
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Rituals',
                value: '${practice.rituals}',
                color: AppTheme.teal,
                icon: Icons.wb_twilight_rounded,
              ),
            ),
          ],
        ),
        GlassPanel(
          accent: AppTheme.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('MINUTES PER DAY', style: capsStyle(size: 10)),
                  const Spacer(),
                  Text('avg ${(total / 7).toStringAsFixed(0)} min', style: mutedStyle.copyWith(fontSize: 11.5)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: AnimatedBuilder(
                  animation: _chart,
                  builder: (context, _) => CustomPaint(
                    size: const Size(double.infinity, 150),
                    painter: _WeekChartPainter(values: _week, labels: _days, t: _chart.value),
                  ),
                ),
              ),
            ],
          ),
        ),
        _JournalCard(entries: practice.journal, breathMinutes: practice.breathSeconds ~/ 60),
        const CardFace(
          style: CardStyles.progress,
          borderRadius: 24,
          elevation: 0.6,
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Saturday is your power day — 22 minutes of deep calm.',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    height: 1.35,
                    color: Colors.white,
                    shadows: textOnArt,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The latest gratitude, actions and reflections from the rituals.
class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.entries, required this.breathMinutes});

  final List<JournalEntry> entries;
  final int breathMinutes;

  static const _labels = {'gratitude': 'GRATEFUL FOR', 'action': 'INSPIRED ACTION', 'reflection': 'REFLECTION'};

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      accent: AppTheme.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('JOURNAL', style: capsStyle(size: 10)),
              const Spacer(),
              const Icon(Icons.air_rounded, size: 14, color: AppTheme.teal),
              const SizedBox(width: 4),
              Text('$breathMinutes breath min', style: mutedStyle.copyWith(fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              'Your gratitude and inspired actions collect here as you complete rituals.',
              style: mutedStyle.copyWith(fontSize: 12.5, height: 1.4),
            )
          else
            for (final e in entries.take(3)) ...[
              Text(_labels[e.kind] ?? e.kind.toUpperCase(), style: capsStyle(color: AppTheme.gold, size: 9)),
              const SizedBox(height: 3),
              Text(
                e.text,
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                  height: 1.2,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
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
    return CardFace(
      style: CardStyles.glass(color),
      borderRadius: 22,
      elevation: 0.5,
      scrim: 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.16)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 32,
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
    final best = values.indexOf(maxV);
    for (var i = 0; i < values.length; i++) {
      // Bars grow one after another.
      final local = Curves.easeOutBack.transform(((t - i * 0.06) / 0.6).clamp(0.0, 1.0));
      final x = slot * (i + 0.5);
      final h = (size.height - 26) * (values[i] / maxV) * local;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barW / 2, size.height - 22 - math.max(h, 4), barW, math.max(h, 4)),
        const Radius.circular(8),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          colors: i == best
              ? const [Color(0xFFFFE7B0), AppTheme.gold]
              : [AppTheme.gold.withValues(alpha: 0.85), const Color(0xFF8A6D1F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rrect.outerRect);
      canvas.drawRRect(rrect, paint);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontFamily: 'Quicksand',
            color: i == best ? AppTheme.gold : AppTheme.textMuted.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
