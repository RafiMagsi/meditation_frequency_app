import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

// Voice practices talk to the device through these three interfaces;
// tests override the providers with fakes.

/// Live microphone loudness (0–1) for chanting and humming. Audio is
/// analysed in memory and discarded — nothing is recorded.
abstract class MicLevel {
  /// Starts listening; false if the microphone isn't available or allowed.
  Future<bool> start();
  Stream<double> get levels;
  Future<void> stop();
  void dispose();
}

/// Running transcript of one listening session.
typedef Heard = ({String words, bool done});

/// Speech-to-text for spoken affirmations and gratitude.
abstract class SpeechInput {
  /// False when recognition isn't available or permission was refused.
  Future<bool> init();

  /// Listens until a natural pause or [stop]; [onDone] fires when the
  /// session ends, with or without words.
  Future<void> listen({
    required void Function(Heard heard) onHeard,
    void Function(double level)? onLevel,
    void Function()? onDone,
  });
  Future<void> stop();
}

/// Spoken guidance ("Breathe in… hold… breathe out").
abstract class VoiceGuide {
  Future<void> say(String text);
  Future<void> stop();
}

class DeviceMicLevel implements MicLevel {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<double> _levels = StreamController<double>.broadcast();
  StreamSubscription<Uint8List>? _pcm;

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Future<bool> start() async {
    try {
      if (!await _recorder.hasPermission()) return false;
      final stream = await _recorder.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
      );
      _pcm = stream.listen((bytes) {
        if (!_levels.isClosed) _levels.add(loudness(bytes));
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// RMS of little-endian 16-bit PCM, mapped from −60…0 dBFS to 0…1.
  static double loudness(Uint8List bytes) {
    final samples = bytes.length ~/ 2;
    if (samples == 0) return 0;
    final data = ByteData.sublistView(bytes);
    var sum = 0.0;
    for (var i = 0; i < samples; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768.0;
      sum += s * s;
    }
    final db = 20 * math.log(math.max(math.sqrt(sum / samples), 1e-6)) / math.ln10;
    return ((db + 60) / 60).clamp(0.0, 1.0);
  }

  @override
  Future<void> stop() async {
    await _pcm?.cancel();
    _pcm = null;
    try {
      await _recorder.stop();
    } catch (_) {
      // Already stopped.
    }
  }

  @override
  void dispose() {
    _pcm?.cancel();
    _recorder.dispose();
    _levels.close();
  }
}

class DeviceSpeech implements SpeechInput {
  final SpeechToText _stt = SpeechToText();

  // Platforms report sound level in different dB ranges; normalise
  // against what this session has actually seen.
  double _low = double.infinity, _high = double.negativeInfinity;
  void Function()? _onDone;

  @override
  Future<bool> init() async {
    try {
      return await _stt.initialize(
        onStatus: (status) {
          if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
            final done = _onDone;
            _onDone = null;
            done?.call();
          }
        },
        onError: (_) {
          final done = _onDone;
          _onDone = null;
          done?.call();
        },
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> listen({
    required void Function(Heard heard) onHeard,
    void Function(double level)? onLevel,
    void Function()? onDone,
  }) async {
    _low = double.infinity;
    _high = double.negativeInfinity;
    _onDone = onDone;
    await _stt.listen(
      onResult: (r) => onHeard((words: r.recognizedWords, done: r.finalResult)),
      onSoundLevelChange: onLevel == null
          ? null
          : (db) {
              _low = math.min(_low, db);
              _high = math.max(_high, db);
              final span = _high - _low;
              onLevel(span < 1 ? 0 : ((db - _low) / span).clamp(0.0, 1.0));
            },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 40),
      ),
    );
  }

  @override
  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {
      // Not listening.
    }
  }
}

class DeviceVoiceGuide implements VoiceGuide {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _setup() async {
    if (_ready) return;
    _ready = true;
    try {
      // A slower, lower voice than the system default: calm, not robotic.
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(0.92);
      await _tts.setSharedInstance(true);
      // Duck (not stop) the tone bed while speaking.
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ]);
    } catch (_) {
      // Guidance is optional; carry on silently.
    }
  }

  @override
  Future<void> say(String text) async {
    await _setup();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Ignore: no voice available.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Nothing playing.
    }
  }
}

/// Each session makes (and disposes) its own microphone.
final micLevelProvider = Provider<MicLevel Function()>((_) => DeviceMicLevel.new);

final speechProvider = Provider<SpeechInput>((_) => DeviceSpeech());

final voiceGuideProvider = Provider<VoiceGuide>((_) => DeviceVoiceGuide());
