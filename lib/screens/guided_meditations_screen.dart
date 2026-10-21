import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meditation.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/seamless_route.dart';
import 'player_screen.dart';

/// Guided meditations: hero header + session grid.
class GuidedMeditationsScreen extends ConsumerWidget {
  const GuidedMeditationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meditations = ref.watch(meditationProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2A2C), Color(0xFF0A0E27)],
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
              Hero(
                tag: 'card-guided',
                child: Container(
                  height: 132,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E8C8C), Color(0xFF5EEAD4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.teal.withValues(alpha: 0.3),
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
                        'Guided Sessions',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.w600,
                          fontSize: 36,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Voice-off flows with healing tones',
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                ),
                itemCount: meditations.length,
                itemBuilder: (context, i) {
                  final m = meditations[i];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 420 + i * 80),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 22 * (1 - t)),
                        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
                      ),
                    ),
                    child: _SessionCard(meditation: m, index: i),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.meditation, required this.index});

  final Meditation meditation;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushSeamless(
        context,
        PlayerScreen(
          title: meditation.title,
          subtitle: '${meditation.minutes} min',
          audioPath: meditation.audioPath,
          color: meditation.color,
          glow: meditation.color.withValues(alpha: 0.85),
          heroTag: 'med-$index',
          icon: meditation.icon,
        ),
      ),
      child: Hero(
        tag: 'med-$index',
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: AppTheme.surface,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: meditation.color.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [meditation.color, meditation.color.withValues(alpha: 0.6)],
                  ),
                ),
                child: Icon(meditation.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                meditation.title,
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 23,
                  height: 1.05,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meditation.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: mutedStyle.copyWith(fontSize: 11.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: meditation.color),
                  const SizedBox(width: 4),
                  Text(
                    '${meditation.minutes} min',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: meditation.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
