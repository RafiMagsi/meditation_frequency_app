import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/ambient_background.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/deck.dart';
import '../widgets/glow_card.dart';
import '../widgets/luxury.dart';
import '../widgets/medallion.dart';
import '../widgets/seamless_route.dart';
import 'abundance_screen.dart';
import 'breathwork_screen.dart';
import 'frequency_library_screen.dart';
import 'frequency_meter_screen.dart';
import 'guided_meditations_screen.dart';
import 'mood_screen.dart';
import 'playlist_screen.dart';
import 'progress_screen.dart';
import 'ritual_screen.dart';
import 'timer_screen.dart';
import 'voice_screen.dart';

/// The card hub. Every feature is a card with its own artwork; cards are
/// dealt in on arrival, and tapping one sends the deck sliding off to the
/// left while that card morphs into its screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _greeting = 'Welcome';
  bool _precached = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode every card photo up front so no hero flight starts blank.
    if (!_precached) {
      _precached = true;
      for (final photo in CardStyles.photos) {
        precacheImage(AssetImage(photo), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              DeckItem(index: 0, child: _Header(greeting: _greeting)),
              const SizedBox(height: 22),
              const DeckItem(index: 1, child: _RitualCard()),
              const SizedBox(height: 14),
              DeckItem(
                index: 2,
                child: _AbundanceCard(onTap: () => pushSeamless(context, const AbundanceScreen())),
              ),
              const SizedBox(height: 14),
              DeckItem(
                index: 3,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _FeatureCard(
                        title: 'Frequencies',
                        subtitle: '7 Solfeggio tones',
                        heroTag: 'card-frequencies',
                        height: 186,
                        style: CardStyles.frequencies,
                        onTap: () => pushSeamless(context, const FrequencyLibraryScreen()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _FeatureCard(
                        title: 'Guided\nMeditations',
                        subtitle: '7 sessions',
                        heroTag: 'card-guided',
                        height: 186,
                        style: CardStyles.guided,
                        onTap: () => pushSeamless(context, const GuidedMeditationsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DeckItem(
                index: 4,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _FeatureCard(
                        title: 'Breathwork',
                        subtitle: '6 rhythms',
                        heroTag: 'card-breath',
                        height: 156,
                        style: CardStyles.breath,
                        onTap: () => pushSeamless(context, const BreathworkScreen()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: _FeatureCard(
                        title: 'Voice',
                        subtitle: 'Speak · chant · hum',
                        heroTag: 'card-voice',
                        height: 156,
                        style: CardStyles.voice,
                        onTap: () => pushSeamless(context, const VoiceScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DeckItem(
                index: 5,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _FeatureCard(
                        title: 'Mood',
                        subtitle: 'How do you feel?',
                        heroTag: 'card-mood',
                        height: 156,
                        style: CardStyles.mood,
                        onTap: () => pushSeamless(context, const MoodScreen()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _FeatureCard(
                        title: 'Focus Timer',
                        subtitle: 'Breathe with the tide',
                        heroTag: 'card-timer',
                        height: 156,
                        style: CardStyles.timer,
                        onTap: () => pushSeamless(context, const TimerScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DeckItem(
                index: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _FeatureCard(
                        title: 'Playlists',
                        subtitle: 'Your flows',
                        heroTag: 'card-playlists',
                        height: 156,
                        style: CardStyles.playlists,
                        onTap: () => pushSeamless(context, const PlaylistScreen()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: _FeatureCard(
                        title: 'Progress',
                        subtitle: 'Streaks & journal',
                        heroTag: 'card-progress',
                        height: 156,
                        style: CardStyles.progress,
                        onTap: () => pushSeamless(context, const ProgressScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DeckItem(
                index: 7,
                child: _FeatureCard(
                  title: 'Aura Meter',
                  subtitle: 'Visualize your sound field',
                  heroTag: 'card-meter',
                  height: 136,
                  style: CardStyles.meter,
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

/// Today's ritual: morning manifestation, or evening reflection after 4 pm.
class _RitualCard extends ConsumerWidget {
  const _RitualCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ritual = ref.watch(ritualNowProvider);
    final practice = ref.watch(practiceProvider);
    final done = practice.practisedToday && practice.lastDay != null;
    final metal = Color.lerp(ritual.style.glow, Colors.white, 0.3)!;
    return GlowCard(
      style: ritual.style,
      heroTag: 'card-ritual',
      height: 140,
      semanticLabel: ritual.name,
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      contentAlignment: Alignment.centerLeft,
      onTap: () => pushSeamless(context, RitualScreen(ritual: ritual)),
      child: Row(
        children: [
          Medallion(style: ritual.style, size: 96),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ritual.eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: capsStyle(color: metal, size: 9.5),
                      ),
                    ),
                    StreakChip(days: practice.streak),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ritual.name,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontWeight: FontWeight.w600,
                      fontSize: 27,
                      height: 1,
                      color: AppTheme.ivory,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  done
                      ? 'Practised today · keep the streak alive'
                      : ritual.id == 'morning'
                          ? 'Gratitude · intention · vision · action'
                          : 'Reflect · release · reaffirm · give thanks',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(practiceProvider.select((s) => s.streak));
    return Row(
      children: [
        const Hero(tag: 'orb', child: BreathingOrb(size: 62)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: mutedStyle.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              const Text(
                'Tune in',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 34,
                  height: 1,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppTheme.goldMid.withValues(alpha: 0.06),
            border: Border.all(color: AppTheme.goldMid.withValues(alpha: 0.4), width: 0.8),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 16, color: AppTheme.amber),
              const SizedBox(width: 4),
              Text('$streak ${streak == 1 ? 'day' : 'days'}', style: capsStyle(color: AppTheme.textPrimary, size: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The featured black card — a metal card with a gold chip.
class _AbundanceCard extends StatelessWidget {
  const _AbundanceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      style: CardStyles.abundance,
      heroTag: 'card-abundance',
      height: 172,
      semanticLabel: 'Money Manifestation',
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GoldChip(width: 38),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldMid.withValues(alpha: 0.5), width: 0.8),
                ),
                child: GoldText('NEW · 888 HZ', style: capsStyle(size: 9)),
              ),
            ],
          ),
          const Spacer(),
          Text('ABUNDANCE', style: capsStyle(color: AppTheme.taupe, size: 10)),
          const SizedBox(height: 4),
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: GoldText(
              'Money Manifestation',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w600,
                fontSize: 30,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Wealth frequencies · affirmations · ritual',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              color: AppTheme.ivory.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.heroTag,
    required this.height,
    required this.style,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String heroTag;
  final double height;
  final CardStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metal = Color.lerp(style.glow, Colors.white, 0.3)!;
    return GlowCard(
      style: style,
      heroTag: heroTag,
      height: height,
      semanticLabel: title.replaceAll('\n', ' '),
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Medallion(style: style, size: height > 170 ? 66 : 56),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: style.glow.withValues(alpha: 0.45), width: 0.8),
                ),
                child: Icon(Icons.arrow_outward_rounded, size: 14, color: metal),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w600,
                fontSize: 24,
                height: 1.02,
                color: AppTheme.ivory,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: capsStyle(color: metal, size: 9),
          ),
        ],
      ),
    );
  }
}
