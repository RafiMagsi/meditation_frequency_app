import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frequency.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glow_card.dart';
import '../widgets/seamless_route.dart';
import 'player_screen.dart';

/// Frequency library: hero header + glowing tone rows.
class FrequencyLibraryScreen extends ConsumerWidget {
  const FrequencyLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequencies = ref.watch(frequencyProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF171235), Color(0xFF0A0E27)],
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
                  _BackButton(onTap: () => Navigator.of(context).maybePop()),
                ],
              ),
              const SizedBox(height: 14),
              // Hero header — the home card morphs into this.
              Hero(
                tag: 'card-frequencies',
                child: Container(
                  height: 132,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D5AE0), Color(0xFF9C7BF0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.violet.withValues(alpha: 0.35),
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
                        'Frequencies',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.w600,
                          fontSize: 36,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Solfeggio healing tones',
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
              const SizedBox(height: 18),
              for (var i = 0; i < frequencies.length; i++) ...[
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 420 + i * 70),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, rowChild) => Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: rowChild),
                  ),
                  child: _FrequencyTile(frequency: frequencies[i]),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyTile extends StatelessWidget {
  const _FrequencyTile({required this.frequency});

  final Frequency frequency;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: () => pushSeamless(
        context,
        PlayerScreen(
          title: '${frequency.hz} Hz',
          subtitle: frequency.name,
          audioPath: frequency.audioPath,
          color: frequency.color,
          glow: frequency.glow,
          heroTag: 'tone-${frequency.hz}',
        ),
      ),
      glowColor: frequency.color,
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Hero(
            tag: 'tone-${frequency.hz}',
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [frequency.glow, frequency.color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: frequency.color.withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(Icons.waves_rounded, color: Colors.white70, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${frequency.hz} Hz',
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    height: 1,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${frequency.name} · ${frequency.description}',
                  style: mutedStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill_rounded, color: frequency.glow, size: 34),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('back'),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white70),
      ),
    );
  }
}
