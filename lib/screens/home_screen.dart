import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/glow_card.dart';
import '../widgets/seamless_route.dart';
import 'frequency_library_screen.dart';
import 'frequency_meter_screen.dart';
import 'guided_meditations_screen.dart';
import 'mood_screen.dart';
import 'playlist_screen.dart';
import 'progress_screen.dart';
import 'timer_screen.dart';

/// The card hub. Every feature is a glowing card that flies seamlessly
/// into its screen. Cards stagger in one by one on load — the demo's
/// "wow, this is smooth" moment.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _greeting = 'Welcome';

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    _greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              _Header(greeting: _greeting),
              const SizedBox(height: 22),
              _StaggeredEntry(
                index: 0,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _FeatureCard(
                        title: 'Frequencies',
                        subtitle: '6 healing tones',
                        icon: Icons.graphic_eq_rounded,
                        heroTag: 'card-frequencies',
                        height: 178,
                        gradient: const [Color(0xFF6D5AE0), Color(0xFF9C7BF0)],
                        glow: AppTheme.violet,
                        onTap: () => pushSeamless(context, const FrequencyLibraryScreen()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _FeatureCard(
                        title: 'Guided\nMeditations',
                        subtitle: '6 sessions',
                        icon: Icons.self_improvement_rounded,
                        heroTag: 'card-guided',
                        height: 178,
                        gradient: const [Color(0xFF2E8C8C), Color(0xFF5EEAD4)],
                        glow: AppTheme.teal,
                        iconOnTop: true,
                        onTap: () => pushSeamless(context, const GuidedMeditationsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _StaggeredEntry(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _FeatureCard(
                        title: 'Mood',
                        subtitle: 'How do you feel?',
                        icon: Icons.wb_sunny_rounded,
                        heroTag: 'card-mood',
                        height: 148,
                        gradient: const [Color(0xFFB85E8B), Color(0xFFF0A0C8)],
                        glow: AppTheme.pink,
                        onTap: () => pushSeamless(context, const MoodScreen()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: _FeatureCard(
                        title: 'Focus Timer',
                        subtitle: 'Breathe with the circle',
                        icon: Icons.timer_rounded,
                        heroTag: 'card-timer',
                        height: 148,
                        gradient: const [Color(0xFF3D5A9E), Color(0xFF6EA8F6)],
                        glow: const Color(0xFF6EA8F6),
                        onTap: () => pushSeamless(context, const TimerScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _StaggeredEntry(
                index: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _FeatureCard(
                        title: 'Progress',
                        subtitle: 'This week',
                        icon: Icons.stacked_bar_chart_rounded,
                        heroTag: 'card-progress',
                        height: 148,
                        gradient: const [Color(0xFF8A6D1F), Color(0xFFF6C77A)],
                        glow: AppTheme.gold,
                        onTap: () => pushSeamless(context, const ProgressScreen()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _FeatureCard(
                        title: 'Playlists',
                        subtitle: 'Your flow',
                        icon: Icons.queue_music_rounded,
                        heroTag: 'card-playlists',
                        height: 148,
                        gradient: const [Color(0xFF9E4A6D), Color(0xFFE879B8)],
                        glow: AppTheme.pink,
                        onTap: () => pushSeamless(context, const PlaylistScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _StaggeredEntry(
                index: 3,
                child: _FeatureCard(
                  title: 'Aura Meter',
                  subtitle: 'Visualize your sound field',
                  icon: Icons.radar_rounded,
                  heroTag: 'card-meter',
                  height: 104,
                  gradient: const [Color(0xFF4A3D8F), Color(0xFF8B7CF6)],
                  glow: AppTheme.violet,
                  horizontal: true,
                  onTap: () => pushSeamless(context, const FrequencyMeterScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Hero(
          tag: 'orb',
          child: BreathingOrb(size: 62),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: mutedStyle.copyWith(fontSize: 13)),
            const SizedBox(height: 2),
            const Text(
              'Tune in',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w600,
                fontSize: 32,
                height: 1,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Wraps a card with a staggered fade-up entrance.
class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({required this.child, required this.index});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 130),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.heroTag,
    required this.height,
    required this.gradient,
    required this.glow,
    required this.onTap,
    this.horizontal = false,
    this.iconOnTop = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String heroTag;
  final double height;
  final List<Color> gradient;
  final Color glow;
  final VoidCallback onTap;
  final bool horizontal;
  final bool iconOnTop;

  @override
  Widget build(BuildContext context) {
    final iconBadge = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.fade,
          style: const TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.w600,
            fontSize: 23,
            height: 1.02,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ],
    );

    return SizedBox(
      height: height,
      child: GlowCard(
        heroTag: heroTag,
        onTap: onTap,
        gradientColors: gradient,
        glowColor: glow,
        borderRadius: 26,
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            // Decorative ring art.
            Positioned(
              right: -22,
              top: -22,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.6,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: -34,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            if (horizontal)
              Row(
                children: [
                  iconBadge,
                  const SizedBox(width: 14),
                  Expanded(child: texts),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.85), size: 16),
                ],
              )
            else if (iconOnTop)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [iconBadge, Flexible(child: texts)],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [iconBadge, const SizedBox(height: 12), Flexible(child: texts)],
              ),
          ],
        ),
      ),
    );
  }
}
