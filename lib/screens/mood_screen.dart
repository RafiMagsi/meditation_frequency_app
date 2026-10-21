import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/gloss.dart';
import '../widgets/seamless_route.dart';
import 'player_screen.dart';

/// Mood check-in: tap an emoji, the card suggests a matching frequency.
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
    final mood = moods[_selected];
    final suggestion = frequencies.firstWhere(
      (f) => f.hz == mood.frequencyHz,
      orElse: () => frequencies.first,
    );
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A1436), Color(0xFF0A0E27)],
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
                tag: 'card-mood',
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(22),
                  foregroundDecoration: glossForeground(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA63F76), Color(0xFFF0A0C8)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.pink.withValues(alpha: 0.35),
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
                        'How do you feel?',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.w600,
                          fontSize: 34,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Check in with yourself',
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
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < moods.length; i++)
                    _MoodChip(
                      mood: moods[i],
                      selected: i == _selected,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // Animated suggestion card.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _SuggestionCard(
                  key: ValueKey(mood.label),
                  mood: mood,
                  onPlay: () => pushSeamless(
                    context,
                    PlayerScreen(
                      title: '${suggestion.hz} Hz',
                      subtitle: suggestion.name,
                      audioPath: suggestion.audioPath,
                      color: suggestion.color,
                      glow: suggestion.glow,
                      heroTag: 'tone-${suggestion.hz}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood, required this.selected, required this.onTap});

  final MoodOption mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        transform: Matrix4.diagonal3Values(
            selected ? 1.06 : 1.0, selected ? 1.06 : 1.0, 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFA63A78), Color(0xFF5B48D6)])
              : null,
          color: selected ? null : AppTheme.surface,
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.07),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.pink.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              mood.label,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: selected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({super.key, required this.mood, required this.onPlay});

  final MoodOption mood;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return GlossOverlay(
      borderRadius: 26,
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppTheme.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${mood.emoji}  FOR YOU', style: mutedStyle.copyWith(fontSize: 10.5, letterSpacing: 2.5)),
          const SizedBox(height: 8),
          Text(
            mood.tip,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 23,
              height: 1.15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                    colors: [Color(0xFF6B54E0), Color(0xFFB34A86)]),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Play the tone',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
