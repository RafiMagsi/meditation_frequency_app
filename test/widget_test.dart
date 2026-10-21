import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meditation_frequency_app/main.dart';
import 'package:meditation_frequency_app/services/practice_store.dart';
import 'package:meditation_frequency_app/services/tone_playback.dart';
import 'package:meditation_frequency_app/services/voice.dart';

/// Records what the voice guide would say.
class FakeVoiceGuide implements VoiceGuide {
  final said = <String>[];
  @override
  Future<void> say(String text) async => said.add(text);
  @override
  Future<void> stop() async {}
}

/// Speech the test "speaks" with [say].
class FakeSpeech implements SpeechInput {
  void Function(Heard heard)? _onHeard;
  bool listening = false;
  @override
  Future<bool> init() async => true;
  @override
  Future<void> listen(
      {required void Function(Heard heard) onHeard,
      void Function(double level)? onLevel,
      void Function()? onDone}) async {
    _onHeard = onHeard;
    listening = true;
  }

  @override
  Future<void> stop() async => listening = false;

  void say(String words, {bool done = false}) => _onHeard?.call((words: words, done: done));
}

/// A microphone whose loudness the test sets.
class FakeMic implements MicLevel {
  final _levels = StreamController<double>.broadcast(sync: true);
  double level = 0.05;
  @override
  Future<bool> start() async => true;
  @override
  Stream<double> get levels => _levels.stream;
  void push() => _levels.add(level);
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

late FakeVoiceGuide voice;
late FakeSpeech speech;
late FakeMic mic;
late ProviderContainer container;

// Ambient animations never settle, so pump fixed durations instead of
// pumpAndSettle. One transition is ~820 ms.
Future<void> settle(WidgetTester tester, [int ms = 1200]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

Future<void> openHub(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1179, 2556); // iPhone 15
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  voice = FakeVoiceGuide();
  speech = FakeSpeech();
  mic = FakeMic();
  container = ProviderContainer(overrides: [
    voiceGuideProvider.overrideWithValue(voice),
    speechProvider.overrideWithValue(speech),
    micLevelProvider.overrideWithValue(() => mic),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MeditationApp()));
  expect(find.text('& Frequency'), findsOneWidget);
  await tester.tap(find.byKey(const Key('begin')));
  await settle(tester);
}

void main() {
  setUpAll(() => TonePlayback.simulateAudio = true);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Welcome deals the card hub, and a card opens its screen', (tester) async {
    await openHub(tester);

    expect(find.text('Tune in'), findsOneWidget);
    expect(find.text('Money Manifestation'), findsOneWidget);
    expect(find.text('Frequencies'), findsOneWidget);
    expect(find.text('Breathwork'), findsOneWidget);
    expect(find.textContaining('6 days'), findsOneWidget); // seeded streak

    // Mid-transition the hub deck is still mounted (sliding off left).
    await tester.tap(find.text('Frequencies'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Tune in'), findsOneWidget);

    await settle(tester);
    expect(find.text('Solfeggio healing tones'), findsOneWidget);
    expect(find.text('528 Hz'), findsOneWidget);
    expect(find.text('ROOT'), findsOneWidget); // chakra under the play button

    await tester.tap(find.byKey(const Key('back')));
    await settle(tester);
    expect(find.text('Tune in'), findsOneWidget);
    expect(find.text('Solfeggio healing tones'), findsNothing);
  });

  testWidgets('Money manifestation opens the coin player with money indications', (tester) async {
    await openHub(tester);

    await tester.tap(find.text('Money Manifestation'));
    await settle(tester);
    expect(find.text('Infinite Abundance'), findsOneWidget);
    expect(find.text('THE THREE-STEP RITUAL'), findsNothing); // below the fold

    await tester.tap(find.text('Infinite Abundance'));
    await settle(tester);
    expect(find.text('ABUNDANCE INDEX'), findsOneWidget);
    expect(find.text('888 Hz'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play')));
    await settle(tester, 2000);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Pause and resume quickly (mid coin-settle): the Abundance Index must
    // keep climbing.
    String indexValue() => (tester.widget<Text>(find.textContaining(RegExp(r'^\d{1,3}(,\d{3})*\.\d{2}$'))).data)!;
    await tester.tap(find.byKey(const Key('play')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('play')));
    await settle(tester, 300);
    final before = indexValue();
    await settle(tester, 2000);
    expect(indexValue(), isNot(before));

    await tester.tap(find.byKey(const Key('back')));
    await settle(tester);
    expect(find.text('Infinite Abundance'), findsOneWidget);
  });

  testWidgets('A guided session reads its script as timed chapters', (tester) async {
    await openHub(tester);

    await tester.tap(find.text('Guided\nMeditations'));
    await settle(tester);
    expect(find.textContaining("TODAY'S PICK"), findsOneWidget);

    // Filter to Heart (the chip row scrolls sideways): only its session
    // remains, then open it.
    await tester.ensureVisible(find.text('Heart'));
    await tester.pump();
    await tester.tap(find.text('Heart'));
    await settle(tester, 600);
    expect(find.textContaining("TODAY'S PICK"), findsNothing);
    expect(find.text('Heart Open'), findsOneWidget);
    expect(find.text('Deep Calm'), findsNothing);
    await tester.tap(find.text('Heart Open'));
    await settle(tester);
    expect(find.text('GUIDED · THE PRIVATE COLLECTION'), findsOneWidget);
    expect(find.text('READY · 5 CHAPTERS · 8 CUES'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play')));
    await settle(tester, 1500);
    expect(find.text('CHAPTER 1 OF 5 · ARRIVE'), findsOneWidget);
    expect(find.text('Rest a hand over your heart and feel its warmth.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await settle(tester, 1200);
    expect(find.text('CHAPTER 2 OF 5 · YOURSELF'), findsOneWidget);
    expect(find.text('Silently offer yourself: may I be happy, may I be at ease.'), findsOneWidget);

    // Skipping past the last chapter completes the session (streak 6 → 7).
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester, 600);
    expect(find.text('SESSION COMPLETE · DAY 7'), findsOneWidget);
  });

  testWidgets('Box breathing: adjustable rounds, count-in, then each phase', (tester) async {
    await openHub(tester);
    await tester.tap(find.text('Breathwork'));
    await settle(tester);
    expect(find.textContaining(RegExp(r'^FOR (THIS|TONIGHT)')), findsOneWidget); // time-aware pick
    expect(find.text('BEST FOR FOCUS'), findsOneWidget);

    await tester.tap(find.text('Box Breathing').last);
    await settle(tester);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('8 ROUNDS'), findsOneWidget);
    expect(find.text('2:08'), findsWidgets); // readout + header

    // More rounds lengthens the session (9 × 16 s = 2:24).
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('9 ROUNDS'), findsOneWidget);
    expect(find.text('2:24'), findsWidgets);

    await tester.tap(find.byKey(const Key('play')));
    await tester.pump();
    expect(find.text('GET READY'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // 3 s count-in, then 1.5 s into the first inhale (4 s): 3 s left.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('ROUND 1 OF 9'), findsOneWidget);
    expect(find.text('Inhale'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Breathe in slowly through the nose'), findsOneWidget);
    expect(voice.said, containsAllInOrder(['Three', 'Two', 'One', 'Breathe in']));

    // Into the hold.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hold'), findsOneWidget);
    expect(find.text('Hold, soft shoulders'), findsOneWidget);
  });

  testWidgets('Morning ritual journals gratitude and completes', (tester) async {
    await openHub(tester);
    await tester.tap(find.text('Morning Manifestation').evaluate().isNotEmpty
        ? find.text('Morning Manifestation')
        : find.text('Evening Reflection'));
    await settle(tester);
    expect(find.text('STEP 1 OF ${find.text('Arrive').evaluate().isNotEmpty ? 6 : 5}'), findsOneWidget);

    // Step 1 (breathe) can always continue.
    await tester.tap(find.byKey(const Key('continue')));
    await settle(tester, 800);

    // Step 2 is a journal: continue stays disabled until something is written.
    final continueButton = find.byKey(const Key('continue'));
    await tester.tap(continueButton);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('STEP 2 OF ${find.text('Gratitude').evaluate().isNotEmpty ? 6 : 5}'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'The sunrise this morning');
    await tester.pump();
    await tester.tap(continueButton);
    await settle(tester, 800);
    expect(find.textContaining('STEP 3'), findsOneWidget);
  });

  testWidgets('Inner Lake counts only slow, held breaths', (tester) async {
    await openHub(tester);
    await tester.tap(find.text('Guided\nMeditations'));
    await settle(tester);
    await tester.tap(find.text('Inner Lake'));
    await settle(tester);
    expect(find.text('Your mind is a lake.'), findsOneWidget);

    final center = tester.getCenter(find.byType(Scaffold).last);
    // A quick tap does not count. (One frame first: tickers start timing
    // at their first frame.)
    var gesture = await tester.startGesture(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await settle(tester, 1500);
    expect(find.text('Your mind is a lake.'), findsOneWidget);

    // A slow breath (held 3 s) settles the mud.
    gesture = await tester.startGesture(center);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await gesture.up();
    await settle(tester, 1500);
    expect(find.text('Let the mud settle.'), findsOneWidget);
  });

  Future<void> openVoice(WidgetTester tester, String practice) async {
    await tester.scrollUntilVisible(find.text('Voice'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Voice'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text(practice), 200, scrollable: find.byType(Scrollable).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(practice));
    await settle(tester);
  }

  testWidgets('Spoken affirmations only count once the words are heard', (tester) async {
    await openHub(tester);
    await openVoice(tester, 'Spoken Affirmations');
    expect(find.text('TAP THE MICROPHONE AND SPEAK'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mic')));
    await tester.pump();
    expect(find.text('LISTENING…'), findsOneWidget);

    // Half the words is not enough…
    speech.say('I am making 10,000');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('AFFIRMED'), findsNothing);

    // …saying it (nearly) all is.
    speech.say('I am making 10,000 a month with app development');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('AFFIRMED · 1 OF 3'), findsOneWidget);

    // It listens again by itself for the next repetition.
    await tester.pump(const Duration(milliseconds: 1300));
    expect(speech.listening, isTrue);
    expect(find.text('LISTENING…'), findsOneWidget);
  });

  testWidgets('Gratitude aloud writes the spoken words into the journal', (tester) async {
    await openHub(tester);
    await openVoice(tester, 'Gratitude Aloud');

    for (final words in ['the sunrise over the hills', 'my mother and her patience', 'how I keep showing up']) {
      await tester.tap(find.byKey(const Key('mic')));
      await tester.pump();
      speech.say(words, done: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Beautifully done.'), findsOneWidget);
    final journal = container.read(practiceProvider).journal.map((e) => e.text);
    expect(journal, containsAll(['the sunrise over the hills', 'my mother and her patience', 'how I keep showing up']));
  });

  testWidgets('Om chant counts a round only after a sustained Aum', (tester) async {
    await openHub(tester);
    await openVoice(tester, 'Om Chant');
    await tester.tap(find.byKey(const Key('begin-chant')));
    await tester.pump();

    Future<void> run(double seconds, double level) async {
      mic.level = level;
      for (var i = 0; i < (seconds * 10).round(); i++) {
        mic.push();
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await run(1.6, 0.08); // calibration: a quiet room
    expect(find.text('Breathe in'), findsOneWidget);
    await run(4.1, 0.08);
    expect(find.text('Chant  Aum'), findsOneWidget);

    // Too short: two seconds, then a pause.
    await run(2, 0.6);
    await run(2, 0.05);
    expect(find.text('Almost'), findsOneWidget);

    await run(2.5, 0.05); // back to the inhale
    await run(4, 0.08);
    await run(6.5, 0.6); // a full Aum
    await run(2, 0.05);
    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('ROUND 2 / 5'), findsOneWidget);
  });
}

Future<void> scrollHubTo(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(target, find.byType(ListView).first, const Offset(0, -200));
  await tester.pump(const Duration(milliseconds: 300));
}
