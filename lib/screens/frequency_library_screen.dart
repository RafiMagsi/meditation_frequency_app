import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frequency.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
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
          Hero(
            tag: 'tone-${f.hz}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.35),
                  colors: [Colors.white.withValues(alpha: 0.9), f.glow, f.color],
                  stops: const [0, 0.3, 1],
                ),
                boxShadow: [BoxShadow(color: f.color.withValues(alpha: 0.6), blurRadius: 18)],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${f.hz} Hz',
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 26,
                    height: 1,
                    color: Colors.white,
                    shadows: textOnArt,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${f.name} · ${f.description}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.82),
                    shadows: textOnArt,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${f.chakra.toUpperCase()} CHAKRA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: capsStyle(color: f.glow, size: 9),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill_rounded, color: Colors.white.withValues(alpha: 0.92), size: 34),
        ],
      ),
    );
  }
}
