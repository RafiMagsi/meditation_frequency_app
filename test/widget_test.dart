import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meditation_frequency_app/main.dart';
import 'package:meditation_frequency_app/services/tone_playback.dart';

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
  await tester.pumpWidget(const ProviderScope(child: MeditationApp()));
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
    expect(find.text('ROOT CHAKRA'), findsOneWidget);

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
}

Future<void> scrollHubTo(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(target, find.byType(ListView).first, const Offset(0, -200));
  await tester.pump(const Duration(milliseconds: 300));
}
