import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frequency.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
import '../widgets/seamless_route.dart';
import 'player_screen.dart';

/// Mood check-in: pick a feeling, the card below suggests its tone.
class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final moods = ref.watch(moodsProvider);
    final frequencies = ref.watch(frequencyProvider);
    Frequency toneFor(MoodOption m) =>
        frequencies.firstWhere((f) => f.hz == m.frequencyHz, orElse: () => frequencies.first);
    final mood = moods[_selected];
    final suggestion = toneFor(mood);

    return FeatureScaffold(
      accent: AppTheme.pink,
      header: const FeatureHeader(
        heroTag: 'card-mood',
        style: CardStyles.mood,
        eyebrow: 'CHECK IN',
        title: 'How do you feel?',
        subtitle: 'Name it, then tune it',
      ),
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            for (var i = 0; i < moods.length; i++)
              _MoodTile(
                mood: moods[i],
                color: toneFor(moods[i]).color,
                selected: i == _selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = i);
                },
              ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: _SuggestionCard(
            key: ValueKey(mood.label),
            mood: mood,
            frequency: suggestion,
            onPlay: () => pushSeamless(
              context,
              PlayerScreen(
                title: '${suggestion.hz} Hz',
                subtitle: '${suggestion.name} · for feeling ${mood.label.toLowerCase()}',
                audioPath: suggestion.audioPath,
                color: suggestion.color,
                glow: suggestion.glow,
                heroTag: 'tone-${suggestion.hz}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final MoodOption mood;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: mood.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          scale: selected ? 1.04 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: selected
                    ? [Color.lerp(color, Colors.black, 0.55)!, Color.lerp(color, Colors.black, 0.15)!]
                    : [const Color(0xFF14162C), const Color(0xFF1D2040)],
              ),
              border: Border.all(
                color: selected ? color.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.08),
                width: selected ? 1.2 : 0.8,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    super.key,
    required this.mood,
    required this.frequency,
    required this.onPlay,
  });

  final MoodOption mood;
  final Frequency frequency;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final f = frequency;
    return GlowCard(
      style: CardStyles.tone(f.color),
      borderRadius: 26,
      semanticLabel: 'Play ${f.hz} Hz',
      padding: const EdgeInsets.all(22),
      onTap: onPlay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'tone-${f.hz}',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.35),
                      colors: [Colors.white.withValues(alpha: 0.9), f.glow, f.color],
                      stops: const [0, 0.3, 1],
                    ),
                    boxShadow: [BoxShadow(color: f.color.withValues(alpha: 0.6), blurRadius: 16)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${mood.emoji}  FOR YOU', style: capsStyle(color: Colors.white.withValues(alpha: 0.85), size: 10.5)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            mood.tip,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 25,
              height: 1.15,
              color: Colors.white,
              shadows: textOnArt,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Play ${f.hz} Hz',
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Colors.white,
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
