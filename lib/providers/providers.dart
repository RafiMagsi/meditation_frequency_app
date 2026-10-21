import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frequency.dart';
import '../models/meditation.dart';
import '../models/money_frequency.dart';
import '../theme/card_styles.dart';

/// Solfeggio + healing tones with aurora identities.
final frequencyProvider = Provider<List<Frequency>>((_) => const [
      Frequency(
        hz: '396',
        name: 'Liberate',
        description: 'Releasing guilt & fear',
        audioPath: 'assets/audio/tone_396hz.m4a',
        color: Color(0xFF8B7CF6),
        glow: Color(0xFFB6A8FF),
        chakra: 'Root',
      ),
      Frequency(
        hz: '417',
        name: 'Release',
        description: 'Undoing the effects of negative events',
        audioPath: 'assets/audio/tone_417hz.m4a',
        color: Color(0xFF6EA8F6),
        glow: Color(0xFFA8D2FF),
        chakra: 'Sacral',
      ),
      Frequency(
        hz: '528',
        name: 'Transform',
        description: 'Love, miracles & deep repair',
        audioPath: 'assets/audio/tone_528hz.m4a',
        color: Color(0xFF5EEAD4),
        glow: Color(0xFFA5F3E4),
        chakra: 'Solar plexus',
      ),
      Frequency(
        hz: '639',
        name: 'Connect',
        description: 'Harmony in relationships',
        audioPath: 'assets/audio/tone_639hz.m4a',
        color: Color(0xFFE879B8),
        glow: Color(0xFFF8B8DA),
        chakra: 'Heart',
      ),
      Frequency(
        hz: '741',
        name: 'Awaken',
        description: 'Intuition & problem solving',
        audioPath: 'assets/audio/tone_741hz.m4a',
        color: Color(0xFFF0956B),
        glow: Color(0xFFF8C4A5),
        chakra: 'Throat',
      ),
      Frequency(
        hz: '852',
        name: 'Expand',
        description: 'Returning to spiritual order',
        audioPath: 'assets/audio/tone_852hz.m4a',
        color: Color(0xFFF6C77A),
        glow: Color(0xFFFAE0A8),
        chakra: 'Third eye',
      ),
    ]);

final meditationProvider = Provider<List<Meditation>>((_) => const [
      Meditation(
        title: 'Morning Clarity',
        description: 'Start the day grounded and bright',
        audioPath: 'assets/audio/tone_528hz.m4a',
        hz: '528',
        minutes: 5,
        icon: Icons.wb_twilight_rounded,
        color: Color(0xFFF6C77A),
        scene: Scene.dawn,
      ),
      Meditation(
        title: 'Deep Calm',
        description: 'Melt tension with slow breathing',
        audioPath: 'assets/audio/tone_396hz.m4a',
        hz: '396',
        minutes: 10,
        icon: Icons.self_improvement_rounded,
        color: Color(0xFF8B7CF6),
        scene: Scene.lake,
      ),
      Meditation(
        title: 'Anxiety Relief',
        description: 'Soften racing thoughts gently',
        audioPath: 'assets/audio/tone_417hz.m4a',
        hz: '417',
        minutes: 8,
        icon: Icons.air_rounded,
        color: Color(0xFF5EEAD4),
        scene: Scene.breeze,
      ),
      Meditation(
        title: 'Heart Open',
        description: 'Compassion for yourself & others',
        audioPath: 'assets/audio/tone_639hz.m4a',
        hz: '639',
        minutes: 12,
        icon: Icons.favorite_rounded,
        color: Color(0xFFE879B8),
        scene: Scene.lotus,
      ),
      Meditation(
        title: 'Night Drift',
        description: 'Slide softly into deep sleep',
        audioPath: 'assets/audio/tone_852hz.m4a',
        hz: '852',
        minutes: 20,
        icon: Icons.nightlight_round,
        color: Color(0xFF6EA8F6),
        scene: Scene.night,
      ),
      Meditation(
        title: 'Focus Flow',
        description: 'Sharpen attention before deep work',
        audioPath: 'assets/audio/tone_741hz.m4a',
        hz: '741',
        minutes: 15,
        icon: Icons.psychology_alt_rounded,
        color: Color(0xFFF0956B),
        scene: Scene.focus,
      ),
    ]);

/// Wealth tones. Each track carries a 7.83 Hz (Schumann) binaural layer.
final moneyFrequencyProvider = Provider<List<MoneyFrequency>>((_) => const [
      MoneyFrequency(
        hz: '888',
        name: 'Infinite Abundance',
        intention: 'Money flows to me in endless cycles.',
        description: 'The abundance number — giving and receiving without end.',
        audioPath: 'assets/audio/tone_888hz.m4a',
        minutes: 11,
        emblem: '888',
      ),
      MoneyFrequency(
        hz: '777',
        name: 'Fortune & Luck',
        intention: 'Lucky breaks find me with ease.',
        description: 'Serendipity, synchronicity and perfect timing.',
        audioPath: 'assets/audio/tone_777hz.m4a',
        minutes: 9,
        emblem: '777',
      ),
      MoneyFrequency(
        hz: '528',
        name: 'Miracle Wealth',
        intention: 'I am open to miracles in my finances.',
        description: 'The love tone, rewiring scarcity into overflow.',
        audioPath: 'assets/audio/tone_528hz.m4a',
        minutes: 12,
        emblem: '528',
      ),
      MoneyFrequency(
        hz: '432',
        name: 'Calm Prosperity',
        intention: 'I am calm, confident and rich in every way.',
        description: 'Natural tuning that settles money anxiety.',
        audioPath: 'assets/audio/tone_432hz.m4a',
        minutes: 15,
        emblem: '432',
      ),
      MoneyFrequency(
        hz: '183.58',
        name: 'Jupiter Expansion',
        intention: 'Every door I open expands my fortune.',
        description: "Jupiter's cosmic tone — growth, generosity, fortune.",
        audioPath: 'assets/audio/tone_jupiter.m4a',
        minutes: 18,
        emblem: '183',
      ),
    ]);

final affirmationsProvider = Provider<List<String>>((_) => const [
      'Money flows to me easily and effortlessly.',
      'I am a magnet for wealth and opportunity.',
      'Abundance is my natural state.',
      'I receive with gratitude and give with joy.',
      'Every day, my wealth expands.',
      'I am worthy of financial freedom.',
    ]);

/// Mood → suggested frequency pairing.
class MoodOption {
  const MoodOption(this.emoji, this.label, this.frequencyHz, this.tip);
  final String emoji;
  final String label;
  final String frequencyHz;
  final String tip;
}

final moodsProvider = Provider<List<MoodOption>>((_) => const [
      MoodOption('😌', 'Calm', '528', 'Keep the peace — float with 528 Hz.'),
      MoodOption('😰', 'Anxious', '396', 'Breathe slow. 396 Hz releases fear.'),
      MoodOption('🥰', 'Loved', '639', 'Ride the warmth with 639 Hz.'),
      MoodOption('😐', 'Numb', '417', 'Gently reset with 417 Hz.'),
      MoodOption('🤩', 'Inspired', '741', 'Fuel the spark with 741 Hz.'),
      MoodOption('🥱', 'Tired', '852', 'Unwind softly with 852 Hz.'),
    ]);

final moodProvider = StateProvider<String>((_) => 'Calm');

class PlaylistNotifier extends StateNotifier<List<String>> {
  PlaylistNotifier() : super(['Morning Clarity', 'Night Drift']);
  void add(String m) => state = [...state, m];
  void remove(String m) => state = state.where((e) => e != m).toList();
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, List<String>>((_) => PlaylistNotifier());
