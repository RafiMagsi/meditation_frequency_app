import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/breath_visual.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
import '../widgets/luxury.dart';
import '../widgets/seamless_route.dart';
import 'breath_session_screen.dart';

/// Breathwork: a recommendation for right now, then every rhythm as a
/// card that previews its real timing, live.
class BreathworkScreen extends ConsumerWidget {
  const BreathworkScreen({super.key});

  /// What a teacher would suggest at this hour.
  static ({String id, String when}) _recommendation(int hour) => hour < 11
      ? (id: 'coherent', when: 'FOR THIS MORNING')
      : hour < 17
          ? (id: 'box', when: 'FOR THIS AFTERNOON')
          : hour < 21
              ? (id: 'sigh', when: 'FOR THIS EVENING')
              : (id: '478', when: 'FOR TONIGHT');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(breathPatternsProvider);
    final rec = _recommendation(DateTime.now().hour);
    final pick = patterns.firstWhere((p) => p.id == rec.id, orElse: () => patterns.first);
    return FeatureScaffold(
      accent: AppTheme.teal,
      header: const FeatureHeader(
        heroTag: 'card-breath',
        style: CardStyles.breath,
        eyebrow: '6 GUIDED RHYTHMS',
        title: 'Breathwork',
        subtitle: 'Change your state in two minutes',
      ),
      children: [
        _RecommendedCard(pattern: pick, when: rec.when),
        const SectionLabel('ALL RHYTHMS'),
        for (final p in patterns) _PatternCard(pattern: p),
        const _ScienceCard(),
      ],
    );
  }
}

String _minutes(BreathPattern p) {
  final s = p.duration.inSeconds;
  return s < 90 ? '1 min' : '${(s / 60).round()} min';
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.pattern, required this.when});

  final BreathPattern pattern;
  final String when;

  @override
  Widget build(BuildContext context) {
    final p = pattern;
    final tag = 'breath-pick-${p.id}';
    return GlowCard(
      style: p.style,
      heroTag: tag,
      height: 226,
      borderRadius: 28,
      semanticLabel: 'Recommended: ${p.name}',
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
      onTap: () => pushSeamless(context, BreathSessionScreen(pattern: p, heroTag: tag)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(icon: Icons.auto_awesome_rounded, text: when, color: p.color),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    p.name,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'InterDisplay',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      height: 1,
                      color: AppTheme.ivory,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.benefit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                PhaseStrip(phases: p.phases, color: p.color),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // The whole card is the button; the pill is its label.
                    IgnorePointer(
                      child: ActionPill(label: 'Start', icon: Icons.play_arrow_rounded, color: p.color, onTap: () {}),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _minutes(p).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: capsStyle(color: Colors.white.withValues(alpha: 0.8), size: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          BreathPreview(pattern: p, size: 116),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final BreathPattern pattern;

  @override
  Widget build(BuildContext context) {
    final p = pattern;
    final tag = 'breath-${p.id}';
    return GlowCard(
      style: p.style,
      heroTag: tag,
      height: 152,
      borderRadius: 24,
      semanticLabel: p.name,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      onTap: () => pushSeamless(context, BreathSessionScreen(pattern: p, heroTag: tag)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BEST FOR ${p.bestFor}',
                    style: capsStyle(color: Color.lerp(p.color, Colors.white, 0.35)!, size: 9.5)),
                const SizedBox(height: 6),
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'InterDisplay',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    height: 1,
                    color: AppTheme.ivory,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.benefit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                PhaseStrip(phases: p.phases, color: p.color),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      '${_minutes(p)} · ${p.rounds} rounds',
                      style: mutedStyle.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BreathPreview(pattern: p, size: 98),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Color.lerp(color, Colors.white, 0.4)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: capsStyle(color: Colors.white, size: 9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Why it works, in three plain facts.
class _ScienceCard extends StatelessWidget {
  const _ScienceCard();

  static const _facts = [
    (
      Icons.monitor_heart_rounded,
      'Long exhales slow the heart',
      'Each out-breath engages the vagus nerve — your body\'s brake.'
    ),
    (Icons.air_rounded, 'Sighs reset the lungs', 'A double inhale reopens tiny air sacs; the long exhale clears CO₂.'),
    (Icons.graphic_eq_rounded, 'Six breaths a minute', 'Heart rhythm and breath fall into coherence, and HRV rises.'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      accent: AppTheme.teal,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHY BREATH WORKS', style: capsStyle(size: 10)),
          const SizedBox(height: 6),
          const Text(
            'The one part of your nervous system you can steer on purpose.',
            style: TextStyle(
              fontFamily: 'InterDisplay',
              fontWeight: FontWeight.w600,
              fontSize: 17,
              height: 1.15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (final (icon, title, body) in _facts)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.teal.withValues(alpha: 0.14)),
                    child: Icon(icon, size: 17, color: AppTheme.teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(body, style: mutedStyle.copyWith(fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
