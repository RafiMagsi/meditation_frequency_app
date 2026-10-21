import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frequency.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
import '../widgets/luxury.dart';
import '../widgets/seamless_route.dart';
import 'player_screen.dart';

/// Frequency library: the cosmos card opens into one card per tone.
class FrequencyLibraryScreen extends ConsumerWidget {
  const FrequencyLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequencies = ref.watch(frequencyProvider);
    return FeatureScaffold(
      accent: AppTheme.violet,
      header: const FeatureHeader(
        heroTag: 'card-frequencies',
        style: CardStyles.frequencies,
        eyebrow: '7 TONES · 396 – 963 HZ',
        title: 'Frequencies',
        subtitle: 'Solfeggio healing tones',
      ),
      children: [for (final f in frequencies) _ToneCard(frequency: f)],
    );
  }
}

class _ToneCard extends StatelessWidget {
  const _ToneCard({required this.frequency});

  final Frequency frequency;

  @override
  Widget build(BuildContext context) {
    final f = frequency;
    return GlowCard(
      style: CardStyles.tone(f.color),
      borderRadius: 22,
      height: 98,
      semanticLabel: '${f.hz} Hz ${f.name}',
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      contentAlignment: Alignment.centerLeft,
      onTap: () => pushSeamless(
        context,
        PlayerScreen(
          title: '${f.hz} Hz',
          subtitle: '${f.name} · ${f.chakra} chakra',
          audioPath: f.audioPath,
          color: f.color,
          glow: f.glow,
          heroTag: 'tone-${f.hz}',
        ),
      ),
      child: Row(
        children: [
          // The tone, set like a stone in a ring of its own metal.
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: foilFor(f.color),
              boxShadow: [BoxShadow(color: f.color.withValues(alpha: 0.3), blurRadius: 16)],
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0B0A0E)),
              child: Hero(
                tag: 'tone-${f.hz}',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.35),
                      colors: [Colors.white.withValues(alpha: 0.9), f.glow, f.color],
                      stops: const [0, 0.3, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FoilText(
                  '${f.hz} Hz',
                  accent: f.color,
                  style: const TextStyle(
                    fontFamily: 'InterDisplay',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.ivory,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  f.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: f.color.withValues(alpha: 0.1),
                  border: Border.all(color: f.color.withValues(alpha: 0.6), width: 0.8),
                ),
                child: Icon(Icons.play_arrow_rounded, color: f.glow, size: 20),
              ),
              const SizedBox(height: 6),
              Text(f.chakra.split(' ').first.toUpperCase(), style: capsStyle(color: AppTheme.textMuted, size: 8)),
            ],
          ),
        ],
      ),
    );
  }
}
