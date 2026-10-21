// Temporary visual harness: renders screens and mid-transition frames
// with the real fonts. Run with --update-goldens; output in test/_shots.
@Tags(['shots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meditation_frequency_app/main.dart';
import 'package:meditation_frequency_app/services/tone_playback.dart';

const shotKey = Key('shot');

Future<void> loadFonts() async {
  for (final (family, path) in [
    ('CormorantGaramond', 'assets/fonts/CormorantGaramond.ttf'),
    ('Quicksand', 'assets/fonts/Quicksand.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(path))).load();
  }
}

Future<void> shot(WidgetTester tester, String name) async {
  await expectLater(find.byKey(shotKey), matchesGoldenFile('_shots/$name.png'));
}

Future<void> pumpMs(WidgetTester tester, int ms) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

Future<void> boot(WidgetTester tester) async {
  TonePlayback.simulateAudio = true;
  await loadFonts();
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const RepaintBoundary(key: shotKey, child: ProviderScope(child: MeditationApp())),
  );
  await pumpMs(tester, 1700);
}

/// Real (blurred) shadows for the shots; the flag must be restored
/// inside the body, before the binding verifies invariants.
void shotTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}

Future<void> back(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('back')).last);
  await pumpMs(tester, 1000);
}

void main() {
  shotTest('choreography filmstrip', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('begin')));
    await pumpMs(tester, 1500);
    await tester.tap(find.text('Frequencies'));
    await tester.pump();
    for (var ms = 100; ms <= 800; ms += 100) {
      await tester.pump(const Duration(milliseconds: 100));
      await shot(tester, 'f_push_${ms.toString().padLeft(3, '0')}');
    }
    await pumpMs(tester, 600);
    await tester.tap(find.byKey(const Key('back')).last);
    await tester.pump();
    for (var ms = 100; ms <= 600; ms += 100) {
      await tester.pump(const Duration(milliseconds: 100));
      await shot(tester, 'f_pop_${ms.toString().padLeft(3, '0')}');
    }
  });

  shotTest('hub and transitions', (tester) async {
    await boot(tester);
    await shot(tester, '01_welcome');
    await tester.tap(find.byKey(const Key('begin')));
    await pumpMs(tester, 330);
    await shot(tester, '02_welcome_to_hub_mid');
    await pumpMs(tester, 1200);
    await shot(tester, '03_hub');

    await tester.tap(find.text('Frequencies'));
    await pumpMs(tester, 240);
    await shot(tester, '04_hub_to_freq_30');
    await tester.pump(const Duration(milliseconds: 200));
    await shot(tester, '05_hub_to_freq_55');
    await pumpMs(tester, 1000);
    await shot(tester, '06_frequencies');
    await back(tester);

    await tester.tap(find.text('Guided\nMeditations'));
    await pumpMs(tester, 1200);
    await shot(tester, '07_guided');
    await tester.tap(find.text('Heart Open'));
    await pumpMs(tester, 360);
    await shot(tester, '08_guided_to_player_mid');
    await pumpMs(tester, 1200);
    await shot(tester, '09_player_session');
    await tester.tap(find.byKey(const Key('play')));
    await pumpMs(tester, 2600);
    await shot(tester, '10_player_session_playing');
    await back(tester);
    await back(tester);

    await tester.tap(find.text('Mood'));
    await pumpMs(tester, 1200);
    await shot(tester, '11_mood');
    await back(tester);

    await tester.tap(find.text('Focus Timer'));
    await pumpMs(tester, 1200);
    await shot(tester, '12_timer');
    await back(tester);
  });

  shotTest('lower hub screens', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('begin')));
    await pumpMs(tester, 1500);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await pumpMs(tester, 600);
    await shot(tester, '13_hub_scrolled');

    await tester.tap(find.text('Progress'));
    await pumpMs(tester, 2200);
    await shot(tester, '14_progress');
    await back(tester);

    await tester.tap(find.text('Playlists'));
    await pumpMs(tester, 1200);
    await shot(tester, '15_playlists');
    await back(tester);

    await tester.tap(find.text('Aura Meter'));
    await pumpMs(tester, 1200);
    await shot(tester, '16_meter');
    await back(tester);
  });

  shotTest('abundance and players', (tester) async {
    await boot(tester);
    await tester.tap(find.byKey(const Key('begin')));
    await pumpMs(tester, 1500);

    await tester.tap(find.text('Money Manifestation'));
    await pumpMs(tester, 300);
    await shot(tester, '17_hub_to_abundance_mid');
    await pumpMs(tester, 1200);
    await shot(tester, '18_abundance');
    await tester.drag(find.byType(ListView).last, const Offset(0, -520));
    await pumpMs(tester, 600);
    await shot(tester, '19_abundance_scrolled');
    await tester.drag(find.byType(ListView).last, const Offset(0, 520));
    await pumpMs(tester, 600);

    await tester.tap(find.text('Infinite Abundance'));
    await pumpMs(tester, 1300);
    await shot(tester, '20_money_player');
    await tester.tap(find.byKey(const Key('play')));
    await pumpMs(tester, 1800);
    await shot(tester, '21_money_player_playing');
    await pumpMs(tester, 5200);
    await shot(tester, '22_money_player_later');
    await back(tester);
    await back(tester);

    await tester.tap(find.text('Frequencies'));
    await pumpMs(tester, 1200);
    await tester.tap(find.text('528 Hz'));
    await pumpMs(tester, 1300);
    await shot(tester, '23_player_tone');
    await tester.tap(find.byKey(const Key('play')));
    await pumpMs(tester, 3000);
    await shot(tester, '24_player_tone_playing');
  });
}
