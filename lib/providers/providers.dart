import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/frequency.dart';
import '../models/meditation.dart';
import '../models/money_frequency.dart';
import '../models/practice.dart';
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
      Frequency(
        hz: '963',
        name: 'Oneness',
        description: 'Connection to the higher self',
        audioPath: 'assets/audio/tone_963hz.m4a',
        color: Color(0xFFC4A8FF),
        glow: Color(0xFFE6DAFF),
        chakra: 'Crown',
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

/// Miracle-frequency affirmations (docs/manifestation.md, docs/energy.md).
final miracleAffirmationsProvider = Provider<List<String>>((_) => const [
      'I am a magnet for miracles. I am already living my dream.',
      'I receive everything I desire with joy, ease and certainty.',
      'Today is a miracle, and I am the miracle.',
      'I always get what I want, because I am the creator.',
      'The universe flows through me. I am one with infinite creation.',
    ]);

/// Interactive breath guides. Each is a real protocol, not a mood.
final breathPatternsProvider = Provider<List<BreathPattern>>((_) => const [
      BreathPattern(
        id: 'box',
        name: 'Box Breathing',
        rhythm: '4 · 4 · 4 · 4',
        benefit: 'Calm focus under pressure',
        why: 'Equal sides steady the nervous system — the reset used by Navy SEALs before high-stakes moments.',
        shape: BreathShape.box,
        rounds: 8,
        style: CardStyles.timer,
        phases: [
          BreathPhase(BreathMove.inhale, 4, 'Breathe in slowly through the nose'),
          BreathPhase(BreathMove.hold, 4, 'Hold, soft shoulders'),
          BreathPhase(BreathMove.exhale, 4, 'Breathe out gently through the mouth'),
          BreathPhase(BreathMove.rest, 4, 'Stay empty, stay easy', label: 'Hold'),
        ],
      ),
      BreathPattern(
        id: '478',
        name: '4 · 7 · 8 Sleep Breath',
        rhythm: '4 · 7 · 8',
        benefit: 'Fall asleep, melt anxiety',
        why: 'The long exhale switches on the parasympathetic "rest and digest" response. Four rounds is plenty.',
        rounds: 4,
        style: CardStyles.ritualEvening,
        phases: [
          BreathPhase(BreathMove.inhale, 4, 'Quietly in through the nose'),
          BreathPhase(BreathMove.hold, 7, 'Hold, tongue behind the top teeth'),
          BreathPhase(BreathMove.exhale, 8, 'Whoosh out through the mouth'),
        ],
      ),
      BreathPattern(
        id: 'coherent',
        name: 'Coherent Breathing',
        rhythm: '5.5 · 5.5',
        benefit: 'Balance heart and mind',
        why: 'Six breaths a minute brings heart rhythm into coherence and lifts heart-rate variability.',
        rounds: 11,
        style: CardStyles.innerLake,
        phases: [
          BreathPhase(BreathMove.inhale, 5.5, 'Fill from the belly up'),
          BreathPhase(BreathMove.exhale, 5.5, 'Let it fall away'),
        ],
      ),
      BreathPattern(
        id: 'sigh',
        name: 'Physiological Sigh',
        rhythm: '2 + 1 · 6',
        benefit: 'Calm down in under a minute',
        why:
            'A double inhale reopens the lungs; a long exhale dumps CO₂ — the fastest real-time calm known (Stanford, 2023).',
        rounds: 5,
        style: CardStyles.breath,
        phases: [
          BreathPhase(BreathMove.inhale, 2, 'Deep breath in through the nose', to: 0.75),
          BreathPhase(BreathMove.inhale, 1, 'Sip in a little more', label: 'Top up'),
          BreathPhase(BreathMove.exhale, 6, 'Long, slow sigh out of the mouth'),
        ],
      ),
      BreathPattern(
        id: 'abundance',
        name: 'Abundance Breath',
        rhythm: '4 · 4 · 6',
        benefit: 'Breathe in receiving, breathe out thanks',
        why: 'Pairs breath with belief: emotion is energy in motion, and a calm body holds conviction longest.',
        rounds: 6,
        style: CardStyles.abundance,
        phases: [
          BreathPhase(BreathMove.inhale, 4, 'I receive', label: 'Receive'),
          BreathPhase(BreathMove.hold, 4, 'I am worthy', label: 'Hold'),
          BreathPhase(BreathMove.exhale, 6, 'Thank you', label: 'Give thanks'),
        ],
      ),
    ]);

const _senses = [
  (sense: 'See', prompt: 'See it done — the screen, the room, the light, your own face.'),
  (sense: 'Hear', prompt: 'Hear it — the message arriving, the congratulations, your laugh.'),
  (sense: 'Feel', prompt: 'Feel it in your body — chest open, shoulders soft, certain.'),
  (sense: 'Smell', prompt: 'Notice the scent of that moment — coffee, sea air, new pages.'),
  (sense: 'Taste', prompt: 'Taste the celebration — a sip of something you love.'),
];

/// docs/manifestation.md's daily routine, made interactive.
final morningRitualProvider = Provider<Ritual>((_) => const Ritual(
      id: 'morning',
      name: 'Morning Manifestation',
      eyebrow: 'DAILY RITUAL · 10 MIN',
      minutes: 10,
      style: CardStyles.ritualMorning,
      steps: [
        BreatheStep(
          title: 'Arrive',
          guidance: 'Quiet the mind. Breathe in for five, out for five.',
          seconds: 60,
        ),
        JournalStep(
          title: 'Gratitude',
          guidance: 'Three things you are deeply thankful for. Gratitude raises your vibration.',
          kind: 'gratitude',
          hints: ['My health and this new day…', 'Someone who loves me…', 'Something I already have…'],
        ),
        IntentionStep(
          title: 'Clarity',
          guidance: 'Vague desires bring vague results. Name it: what, how much, by when.',
        ),
        AffirmStep(
          title: 'Affirm',
          guidance: 'Say each one out loud, as already true. Tap to affirm.',
          affirmations: [
            null,
            'I am a magnet for miracles. I am already living my dream.',
            'I receive everything I desire with joy, ease and certainty.'
          ],
        ),
        VisualizeStep(
          title: 'Visualise',
          guidance: 'Live the moment it is real, with all five senses.',
          senses: _senses,
        ),
        JournalStep(
          title: 'Inspired action',
          guidance: 'Manifestation is not only thinking. One aligned step you will take today:',
          kind: 'action',
          hints: ['Send the proposal to…'],
        ),
      ],
    ));

/// Evening: reflect, release, reaffirm, give thanks.
final eveningRitualProvider = Provider<Ritual>((_) => const Ritual(
      id: 'evening',
      name: 'Evening Reflection',
      eyebrow: 'DAILY RITUAL · 6 MIN',
      minutes: 6,
      style: CardStyles.ritualEvening,
      steps: [
        BreatheStep(title: 'Settle', guidance: 'Let the day go quiet. In for five, out for five.', seconds: 45),
        JournalStep(
          title: 'Reflect',
          guidance: 'What moved you closer to your intention today? What synchronicity did you notice?',
          kind: 'reflection',
          hints: ['Today I…', 'I noticed…'],
        ),
        ReleaseStep(
          title: 'Release',
          guidance: 'Doubt and fear cancel what you are building. Name one, then let it go.',
        ),
        AffirmStep(
          title: 'Know it',
          guidance: 'Shift from wishing to knowing. It is already yours.',
          affirmations: [null, 'It is already mine.', 'Today was a miracle, and I am the miracle.'],
          reps: 2,
        ),
        JournalStep(
          title: 'Gratitude',
          guidance: 'One thing from today you are grateful for.',
          kind: 'gratitude',
          hints: ['Today I am grateful for…'],
        ),
      ],
    ));

/// Morning ritual until 4 pm, evening reflection after.
final ritualNowProvider = Provider<Ritual>(
  (ref) => DateTime.now().hour < 16 ? ref.watch(morningRitualProvider) : ref.watch(eveningRitualProvider),
);

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

final playlistProvider = StateNotifierProvider<PlaylistNotifier, List<String>>((_) => PlaylistNotifier());
