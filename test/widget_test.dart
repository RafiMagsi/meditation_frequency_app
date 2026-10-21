import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('Welcome deals the card hub, and a card opens its screen', (tester) async {
    await openHub(tester);

    expect(find.text('Tune in'), findsOneWidget);
    expect(find.text('Money Manifestation'), findsOneWidget);
    expect(find.text('Frequencies'), findsOneWidget);
    expect(find.text('Focus Timer'), findsOneWidget);

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
    expect(find.text('Pause'), findsNothing); // semantics label, not text
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('back')));
    await settle(tester);
    expect(find.text('Infinite Abundance'), findsOneWidget);
  });

  testWidgets('A guided session morphs into the private-collection player', (tester) async {
    await openHub(tester);

    await tester.tap(find.text('Guided\nMeditations'));
    await settle(tester);
    expect(find.text('Morning Clarity'), findsOneWidget);

    await tester.tap(find.text('Morning Clarity'));
    await settle(tester);
    expect(find.text('THE PRIVATE COLLECTION'), findsOneWidget);
    expect(find.text('Coherent breathing · 6 breaths a minute'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play')));
    await settle(tester, 1500);
    expect(find.text('00:00'), findsNothing); // timeline is running
    expect(
      find.text('Breathe in').evaluate().length + find.text('Breathe out').evaluate().length,
      1,
    );
  });
}
