import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meditation.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
import '../widgets/seamless_route.dart';
import 'player_screen.dart';

/// Guided meditations: the forest card opens into illustrated sessions;
/// each session's artwork becomes the player's jewel.
class GuidedMeditationsScreen extends ConsumerWidget {
  const GuidedMeditationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meditations = ref.watch(meditationProvider);
    return FeatureScaffold(
      accent: AppTheme.teal,
      header: const FeatureHeader(
        heroTag: 'card-guided',
        style: CardStyles.guided,
        eyebrow: '6 SESSIONS · 5 – 20 MIN',
        title: 'Guided Sessions',
        subtitle: 'Breath-led flows on healing tones',
      ),
      children: [
        for (var i = 0; i < meditations.length; i += 2)
          Row(
            children: [
              Expanded(child: _SessionCard(meditation: meditations[i], index: i)),
              const SizedBox(width: 14),
              Expanded(
                child: i + 1 < meditations.length
                    ? _SessionCard(meditation: meditations[i + 1], index: i + 1)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.meditation, required this.index});

  final Meditation meditation;
  final int index;

  @override
  Widget build(BuildContext context) {
    final m = meditation;
    return GlowCard(
      style: CardStyles.session(m.scene),
      heroTag: 'med-$index',
      height: 200,
      borderRadius: 24,
      semanticLabel: m.title,
      padding: const EdgeInsets.all(14),
      onTap: () => pushSeamless(
        context,
        PlayerScreen(
          title: m.title,
          subtitle: '${m.minutes} min · ${m.hz} Hz',
          audioPath: m.audioPath,
          color: m.color,
          glow: Color.lerp(m.color, Colors.white, 0.35)!,
          heroTag: 'med-$index',
          scene: m.scene,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded, size: 11, color: Colors.white),
                const SizedBox(width: 4),
                Text('${m.minutes} MIN', style: capsStyle(color: Colors.white, size: 8.5)),
              ],
            ),
          ),
          const Spacer(),
          Text(
            m.title,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 23,
              height: 1.02,
              color: Colors.white,
              shadows: textOnArt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            m.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.3,
              color: Colors.white.withValues(alpha: 0.85),
              shadows: textOnArt,
            ),
          ),
        ],
      ),
    );
  }
}
