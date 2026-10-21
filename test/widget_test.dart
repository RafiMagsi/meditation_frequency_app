import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meditation_frequency_app/main.dart';

void main() {
  testWidgets('Welcome flows into the card hub and a feature screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MeditationApp()),
    );

    // Welcome screen: brand + CTA. (Ambient animations never settle,
    // so pump fixed durations instead of pumpAndSettle.)
    expect(find.text('& Frequency'), findsOneWidget);
    expect(find.text('Tune in. Drift away. Feel the shift.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('begin')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    // Card hub staggering in.
    expect(find.text('Tune in'), findsOneWidget);
    expect(find.text('Frequencies'), findsOneWidget);
    expect(find.text('Focus Timer'), findsOneWidget);

    // Tap the frequencies card → seamless transition to the library.
    await tester.tap(find.text('Frequencies'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Solfeggio healing tones'), findsOneWidget);
    expect(find.textContaining('Liberate'), findsOneWidget);
    expect(find.text('528 Hz'), findsOneWidget);

    // Back to the hub.
    await tester.tap(find.byKey(const Key('back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Tune in'), findsOneWidget);
  });
}
