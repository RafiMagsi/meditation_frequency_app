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
        id: 'morning-clarity',
        title: 'Morning Clarity',
        description: 'Start the day grounded, bright and clear on how you want to feel.',
        audioPath: 'assets/audio/tone_528hz.m4a',
        hz: '528',
        minutes: 5,
        icon: Icons.wb_twilight_rounded,
        color: Color(0xFFF6C77A),
        scene: Scene.dawn,
        category: 'Morning',
        level: 'All levels',
        script: [
          GuideCue(0.00, 'Arrive', 'Sit tall and let your shoulders drop. Close your eyes when you are ready.'),
          GuideCue(0.10, 'Arrive', 'Three full breaths — in through the nose, out through the mouth.'),
          GuideCue(0.25, 'Body', 'Feel the ground holding you. There is nothing to do yet.'),
          GuideCue(0.40, 'Light', 'Imagine soft morning light resting on the crown of your head.'),
          GuideCue(0.55, 'Light', 'Let it pour down through your face, your chest, your hands.'),
          GuideCue(0.70, 'Intention', 'Ask quietly: how do I want to feel today? Choose one word.'),
          GuideCue(0.82, 'Intention', 'Breathe that word in. Let it settle behind your heart.'),
          GuideCue(0.93, 'Return', 'Wiggle your fingers. Open your eyes slowly. Begin.'),
        ],
      ),
      Meditation(
        id: 'deep-calm',
        title: 'Deep Calm',
        description: 'Long, slow exhales that tell your whole body it is safe.',
        audioPath: 'assets/audio/tone_396hz.m4a',
        hz: '396',
        minutes: 10,
        icon: Icons.self_improvement_rounded,
        color: Color(0xFF8B7CF6),
        scene: Scene.lake,
        category: 'Calm',
        level: 'Beginner',
        script: [
          GuideCue(0.00, 'Settle', 'Find a comfortable position and let your eyes close.'),
          GuideCue(0.08, 'Settle', 'Breathe in for four… and out for six. The long exhale means safety.'),
          GuideCue(0.20, 'Release', 'Unclench your jaw. Soften the space between your eyebrows.'),
          GuideCue(0.32, 'Release', 'Let your shoulders melt away from your ears.'),
          GuideCue(0.45, 'Breath', 'Keep breathing out a little longer than you breathe in.'),
          GuideCue(0.58, 'Breath', 'With every exhale, sink one layer deeper.'),
          GuideCue(0.70, 'Stillness', 'Rest here. If a thought arrives, let it pass like a cloud.'),
          GuideCue(0.85, 'Stillness', 'Calm is not something you make. It is what is left when you stop.'),
          GuideCue(0.95, 'Return', 'Deepen the breath, move gently, and come back.'),
        ],
      ),
      Meditation(
        id: 'anxiety-relief',
        title: 'Anxiety Relief',
        description: 'Ground racing thoughts with sound, sighs and a hand on the heart.',
        audioPath: 'assets/audio/tone_417hz.m4a',
        hz: '417',
        minutes: 8,
        icon: Icons.air_rounded,
        color: Color(0xFF5EEAD4),
        scene: Scene.breeze,
        category: 'Calm',
        level: 'All levels',
        script: [
          GuideCue(0.00, 'Ground', 'You are safe right now. Feel both feet on the floor.'),
          GuideCue(0.10, 'Ground', 'Name five things you can hear, one at a time.'),
          GuideCue(0.25, 'Sigh', 'A double breath in through the nose… and a long sigh out.'),
          GuideCue(0.38, 'Sigh', 'Again. Let the sigh carry the tension out of your chest.'),
          GuideCue(0.50, 'Heart', 'Place a hand on your heart. Feel it beginning to slow.'),
          GuideCue(0.62, 'Reframe', 'Say inside: this is a feeling, not a fact. It will pass.'),
          GuideCue(0.76, 'Reframe', 'Notice the space around the worry. You are bigger than it.'),
          GuideCue(0.90, 'Return', 'One more slow breath. You handled this.'),
        ],
      ),
      Meditation(
        id: 'heart-open',
        title: 'Heart Open',
        description: 'Loving-kindness for yourself, the people you love, and everyone else.',
        audioPath: 'assets/audio/tone_639hz.m4a',
        hz: '639',
        minutes: 12,
        icon: Icons.favorite_rounded,
        color: Color(0xFFE879B8),
        scene: Scene.lotus,
        category: 'Heart',
        level: 'All levels',
        script: [
          GuideCue(0.00, 'Arrive', 'Rest a hand over your heart and feel its warmth.'),
          GuideCue(0.10, 'Yourself', 'Silently offer yourself: may I be happy, may I be at ease.'),
          GuideCue(0.24, 'Yourself', 'If it feels strange, that is fine. Kindness is a practice.'),
          GuideCue(0.36, 'Someone you love', 'Picture someone who loves you. See their face clearly.'),
          GuideCue(0.48, 'Someone you love', 'Send them the same wish: may you be happy, may you be at ease.'),
          GuideCue(0.60, 'Everyone', 'Widen the circle — a neighbour, a stranger, someone difficult.'),
          GuideCue(0.74, 'Everyone', 'May all beings be free. Let the warmth spread without effort.'),
          GuideCue(0.88, 'Return', 'Return to your own heart. Notice it feels a little larger.'),
        ],
      ),
      Meditation(
        id: 'night-drift',
        title: 'Night Drift',
        description: 'A slow body scan into deep, heavy, effortless sleep.',
        audioPath: 'assets/audio/tone_852hz.m4a',
        hz: '852',
        minutes: 20,
        icon: Icons.nightlight_round,
        color: Color(0xFF6EA8F6),
        scene: Scene.night,
        category: 'Sleep',
        level: 'All levels',
        script: [
          GuideCue(0.00, 'Unwind', 'Lie down and let the bed take all of your weight.'),
          GuideCue(0.06, 'Unwind', 'Breathe in for four, hold for seven, out for eight.'),
          GuideCue(0.15, 'Body scan', 'Bring your attention to your feet. Let them grow heavy.'),
          GuideCue(0.26, 'Body scan', 'Heaviness rises through your legs, your hips, your belly.'),
          GuideCue(0.38, 'Body scan', 'Your arms, your shoulders, your face — heavy and warm.'),
          GuideCue(0.50, 'Drift', 'Imagine floating on still, dark water under a quiet moon.'),
          GuideCue(0.64, 'Drift', 'Every breath carries you further from the shore of the day.'),
          GuideCue(0.78, 'Sleep', 'There is nowhere to be. Nothing left to do.'),
          GuideCue(0.90, 'Sleep', 'Let go of these words too. Drift…'),
        ],
      ),
      Meditation(
        id: 'focus-flow',
        title: 'Focus Flow',
        description: 'Train single-pointed attention, then see your most important task begin.',
        audioPath: 'assets/audio/tone_741hz.m4a',
        hz: '741',
        minutes: 15,
        icon: Icons.psychology_alt_rounded,
        color: Color(0xFFF0956B),
        scene: Scene.focus,
        category: 'Focus',
        level: 'Intermediate',
        script: [
          GuideCue(0.00, 'Anchor', 'Sit upright, eyes soft on a single point ahead.'),
          GuideCue(0.08, 'Anchor', 'Box breathe: in for four, hold four, out four, hold four.'),
          GuideCue(0.20, 'One point', 'Rest your attention on the breath at the tip of the nose.'),
          GuideCue(0.34, 'One point', 'When the mind wanders, notice where it went — then return.'),
          GuideCue(0.48, 'Clarity', 'Picture the one task that matters most today.'),
          GuideCue(0.60, 'Clarity', 'See yourself starting it — the first small step, already moving.'),
          GuideCue(0.74, 'Flow', 'Feel the quiet energy of a clear mind. Hold it.'),
          GuideCue(0.88, 'Return', 'Open your eyes. Carry this focus straight into your work.'),
        ],
      ),
    ]);

/// Filter chips on the Guided screen.
const meditationCategories = ['All', 'Calm', 'Sleep', 'Focus', 'Heart', 'Morning'];

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
        color: Color(0xFF6EA8F6),
        bestFor: 'FOCUS',
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
        color: Color(0xFF9B87F5),
        bestFor: 'SLEEP',
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
        color: Color(0xFF5EEAD4),
        bestFor: 'BALANCE',
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
        color: Color(0xFF7DD3FC),
        bestFor: 'QUICK CALM',
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
        color: Color(0xFFF6C77A),
        bestFor: 'ABUNDANCE',
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
