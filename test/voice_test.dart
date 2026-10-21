import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:meditation_frequency_app/services/voice.dart';

/// Stands in for the native speech plugin: records the calls it gets and
/// sends the events a device would.
class Engine {
  Engine(this.tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call.method);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null));
  }

  static const _channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
  final WidgetTester tester;
  final calls = <String>[];

  int count(String method) => calls.where((c) => c == method).length;

  Future<void> _send(String method, Object? arguments) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      _channel.name, const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)), (_) {});

  Future<void> status(String status) => _send('notifyStatus', status);

  Future<void> words(String words, {bool isFinal = false}) => _send(
      'textRecognition',
      jsonEncode({
        'alternates': [
          {'recognizedWords': words, 'confidence': 0.9},
        ],
        'resultType': isFinal ? 2 : 0,
      }));
}

void main() {
  late Engine engine;
  late DeviceSpeech speech;
  late int live, ended;
  late List<String> heard;

  Future<void> open(WidgetTester tester) async {
    engine = Engine(tester);
    speech = DeviceSpeech(SpeechToText.withMethodChannel());
    expect(await speech.init(), isTrue);
    live = 0;
    ended = 0;
    heard = [];
  }

  Future<void> listen(WidgetTester tester) async {
    unawaited(speech.listen(onHeard: (h) => heard.add(h.words), onLive: () => live++, onDone: () => ended++));
    await tester.pump();
  }

  // The plugin waits two seconds for a final result after a stop.
  Future<void> drain(WidgetTester tester) => tester.pump(const Duration(seconds: 3));

  testWidgets('Waits a while for the first word', (tester) async {
    await open(tester);
    await listen(tester);
    await engine.status('listening');
    expect(live, 1);

    await tester.pump(const Duration(milliseconds: 7900));
    expect(ended, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(ended, 1);
    expect(engine.count('stop'), 1);
    await drain(tester);
  });

  testWidgets('Once you have spoken, a pause ends it', (tester) async {
    await open(tester);
    await listen(tester);
    await engine.status('listening');

    await tester.pump(const Duration(seconds: 6));
    await engine.words('I am');
    await tester.pump(const Duration(seconds: 2));
    await engine.words('I am grateful');
    await tester.pump(const Duration(seconds: 2));
    expect(ended, 0);
    await tester.pump(const Duration(milliseconds: 600));
    expect(ended, 1);
    expect(heard.last, 'I am grateful');
    await drain(tester);
  });

  testWidgets('Held open, it listens through pauses until stopped', (tester) async {
    await open(tester);
    await listen(tester);
    await engine.status('listening');
    speech.holdOpen();

    await engine.words('I am');
    await tester.pump(const Duration(seconds: 20));
    expect(ended, 0);
    await speech.stop();
    expect(ended, 1);
    expect(engine.count('stop'), 1);
    await drain(tester);
  });

  testWidgets('A stopped session finishing late cannot end the next one', (tester) async {
    await open(tester);
    await listen(tester);
    await engine.status('listening');
    await engine.words('thank you');
    await speech.stop();
    expect(ended, 1);

    // Straight away, the next one waits for the last to finish on the device.
    await listen(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.count('listen'), 1);
    await engine.status('done');
    await engine.status('notListening');
    await engine.words('thank you', isFinal: true);
    await engine.status('done');
    expect(heard, ['thank you']);

    await tester.pump(const Duration(milliseconds: 600));
    expect(engine.count('listen'), 2);
    await engine.status('listening');
    expect(live, 2);
    await tester.pump(const Duration(seconds: 5));
    expect(ended, 1);

    await speech.stop();
    await drain(tester);
  });

  testWidgets('Stopped before the engine opens, it never starts', (tester) async {
    await open(tester);
    await listen(tester);
    await engine.status('listening');
    await speech.stop();

    await listen(tester);
    await speech.stop();
    expect(ended, 2);
    await engine.status('done');
    await tester.pump(const Duration(seconds: 3));
    expect(engine.count('listen'), 1);
  });
}
