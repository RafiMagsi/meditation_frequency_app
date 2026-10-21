import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frequency.dart';
import '../models/meditation.dart';

/// Solfeggio + healing tones with aurora identities.
final frequencyProvider = Provider<List<Frequency>>((_) => const [
      Frequency(
        hz: '396',
        name: 'Liberate',
        description: 'Releasing guilt & fear',
        audioPath: 'assets/audio/tone_396hz.m4a',
        color: Color(0xFF8B7CF6),
        glow: Color(0xFFB6A8FF),
      ),
      Frequency(
        hz: '417',
        name: 'Release',
        description: 'Undoing the effects of negative events',
        audioPath: 'assets/audio/tone_417hz.m4a',
        color: Color(0xFF6EA8F6),
        glow: Color(0xFFA8D2FF),
      ),
      Frequency(
        hz: '528',
        name: 'Transform',
        description: 'Love, miracles & deep repair',
        audioPath: 'assets/audio/tone_528hz.m4a',
        color: Color(0xFF5EEAD4),
        glow: Color(0xFFA5F3E4),
      ),
      Frequency(
        hz: '639',
        name: 'Connect',
        description: 'Harmony in relationships',
        audioPath: 'assets/audio/tone_639hz.m4a',
        color: Color(0xFFE879B8),
        glow: Color(0xFFF8B8DA),
      ),
      Frequency(
        hz: '741',
        name: 'Awaken',
        description: 'Intuition & problem solving',
        audioPath: 'assets/audio/tone_741hz.m4a',
        color: Color(0xFFF0956B),
        glow: Color(0xFFF8C4A5),
      ),
      Frequency(
        hz: '852',
        name: 'Expand',
        description: 'Returning to spiritual order',
        audioPath: 'assets/audio/tone_852hz.m4a',
        color: Color(0xFFF6C77A),
        glow: Color(0xFFFAE0A8),
      ),
    ]);

final meditationProvider = Provider<List<Meditation>>((_) => const [
      Meditation(
        title: 'Morning Clarity',
        description: 'Start the day grounded and bright',
        audioPath: 'assets/audio/tone_528hz.m4a',
        minutes: 5,
        icon: Icons.wb_twilight_rounded,
        color: Color(0xFFF6C77A),
      ),
      Meditation(
        title: 'Deep Calm',
        description: 'Melt tension with slow breathing',
        audioPath: 'assets/audio/tone_396hz.m4a',
        minutes: 10,
        icon: Icons.self_improvement_rounded,
        color: Color(0xFF8B7CF6),
      ),
      Meditation(
        title: 'Anxiety Relief',
        description: 'Soften racing thoughts gently',
        audioPath: 'assets/audio/tone_417hz.m4a',
        minutes: 8,
        icon: Icons.air_rounded,
        color: Color(0xFF5EEAD4,
        ),
      ),
      Meditation(
        title: 'Heart Open',
        description: 'Compassion for yourself & others',
        audioPath: 'assets/audio/tone_639hz.m4a',
        minutes: 12,
        icon: Icons.favorite_rounded,
        color: Color(0xFFE879B8),
      ),
      Meditation(
        title: 'Night Drift',
        description: 'Slide softly into deep sleep',
        audioPath: 'assets/audio/tone_852hz.m4a',
        minutes: 20,
        icon: Icons.nightlight_round,
        color: Color(0xFF6EA8F6),
      ),
      Meditation(
        title: 'Focus Flow',
        description: 'Sharpen attention before deep work',
        audioPath: 'assets/audio/tone_741hz.m4a',
        minutes: 15,
        icon: Icons.psychology_alt_rounded,
        color: Color(0xFFF0956B),
      ),
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
