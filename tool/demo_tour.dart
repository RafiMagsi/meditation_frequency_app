// Temporary: scripted tour for recording the app on a simulator.
// Taps go through the real gesture pipeline, just like a finger.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meditation_frequency_app/main.dart';

void main() {
  runApp(const ProviderScope(child: MeditationApp()));
  _tour();
}

Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

var _pointer = 1;

Offset? _find(bool Function(Widget) test) {
  Offset? hit;
  void visit(Element e) {
    if (test(e.widget)) {
      final box = e.renderObject;
      if (box is RenderBox && box.attached && box.hasSize) {
        hit = box.localToGlobal(box.size.center(Offset.zero)); // last match = top route
      }
    }
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return hit;
}

Future<void> _tap(bool Function(Widget) test, String what) async {
  final p = _find(test);
  if (p == null) {
    debugPrint('TOUR: not found: $what');
    return;
  }
  debugPrint('TOUR: tap $what at $p');
  final id = _pointer++;
  GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: id, position: p));
  await _wait(110);
  GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: id, position: p));
}

Future<void> _text(String t) => _tap((w) => w is Text && w.data == t, t);
Future<void> _key(String k) => _tap((w) => w.key == Key(k), k);

Future<void> _tour() async {
  await _wait(9000); // launch + recorder warm-up
  await _key('begin');
  await _wait(2600);
  await _text('Money Manifestation');
  await _wait(2400);
  await _text('Infinite Abundance');
  await _wait(2000);
  await _key('play');
  await _wait(7000);
  await _key('back');
  await _wait(1500);
  await _key('back');
  await _wait(1800);
  await _text('Frequencies');
  await _wait(2000);
  await _text('528 Hz');
  await _wait(1800);
  await _key('play');
  await _wait(4500);
  await _key('back');
  await _wait(1400);
  await _key('back');
  await _wait(1800);
  await _text('Guided\nMeditations');
  await _wait(2000);
  await _text('Heart Open');
  await _wait(1800);
  await _key('play');
  await _wait(4000);
  await _key('back');
  await _wait(1400);
  await _key('back');
  await _wait(1800);
  await _text('Mood');
  await _wait(2200);
  await _key('back');
  await _wait(2000);
  debugPrint('TOUR: done');
}
