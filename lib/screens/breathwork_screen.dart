import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
import '../widgets/seamless_route.dart';
import 'breath_session_screen.dart';

/// Breathwork: one card per protocol; each opens its interactive guide.
class BreathworkScreen extends ConsumerWidget {
  const BreathworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(breathPatternsProvider);
    return FeatureScaffold(
      accent: AppTheme.teal,
      header: const FeatureHeader(
        heroTag: 'card-breath',
        style: CardStyles.breath,
        eyebrow: '5 GUIDED RHYTHMS',
        title: 'Breathwork',
        subtitle: 'Change your state in two minutes',
      ),
      children: [
        for (final p in patterns) _PatternCard(pattern: p),
        GlassPanel(
          accent: AppTheme.teal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.spa_rounded, color: AppTheme.teal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Breath is the one part of the nervous system you can steer on purpose. '
                  'Calm the body first — the mind follows.',
                  style: mutedStyle.copyWith(
                      fontSize: 12.5, height: 1.45, color: AppTheme.textPrimary.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final BreathPattern pattern;

  @override
  Widget build(BuildContext context) {
    final p = pattern;
    final minutes = (p.duration.inSeconds / 60).round();
    return GlowCard(
      style: p.style,
      heroTag: 'breath-${p.id}',
      height: 128,
      borderRadius: 24,
      semanticLabel: p.name,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      onTap: () => pushSeamless(context, BreathSessionScreen(pattern: p)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(text: p.rhythm),
              const Spacer(),
              _Chip(text: '$minutes MIN', icon: Icons.schedule_rounded),
            ],
          ),
          const Spacer(),
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 26,
              height: 1,
              color: p.style.foreground,
              shadows: textOnArt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.benefit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: p.style.muted,
              shadows: textOnArt,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(text, style: capsStyle(color: Colors.white, size: 9)),
        ],
      ),
    );
  }
}
