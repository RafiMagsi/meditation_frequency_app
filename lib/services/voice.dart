import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
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

  /// Listens until you pause after speaking, or [stop]; it waits longer for
  /// the first word. [onLive] fires once the microphone is really open, and
  /// [onDone] once when the session ends, with or without words. Words
  /// still being recognised when it ends arrive afterwards.
  Future<void> listen({
    required void Function(Heard heard) onHeard,
    void Function(double level)? onLevel,
    void Function()? onLive,
    void Function()? onDone,
  });

  /// Keeps this session open through pauses until [stop]: hold to talk.
  void holdOpen();

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

enum _Phase { idle, starting, live }

class DeviceSpeech implements SpeechInput {
  DeviceSpeech([SpeechToText? engine]) : _stt = engine ?? SpeechToText();

  final SpeechToText _stt;

  /// Patience for the first word, then the pause that means you're done.
  static const firstWord = Duration(seconds: 8);
  static const afterWords = Duration(milliseconds: 2500);

  /// iOS caps a recognition session at about a minute.
  static const longest = Duration(seconds: 50);

  // Platforms report sound level in different dB ranges; normalise
  // against what this session has actually seen.
  double _low = double.infinity, _high = double.negativeInfinity;

  _Phase _phase = _Phase.idle;
  int _session = 0; // the latest listen()
  int _engine = 0; // the session the engine was last started for
  bool _held = false;
  String _words = '';
  void Function()? _onLive, _onDone;
  Timer? _quiet, _cap, _noStart;

  // On iOS a stopped session finishes on the device a moment later, and
  // that late finish also stops any session started since (speech_to_text
  // 7.4). So a new session waits until the engine has said "done" and gone
  // quiet.
  bool _windingDown = false;
  bool _doneSeen = false;
  int _events = 0;

  @override
  Future<bool> init() async {
    try {
      return await _stt.initialize(onStatus: _onStatus, onError: _onError);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> listen({
    required void Function(Heard heard) onHeard,
    void Function(double level)? onLevel,
    void Function()? onLive,
    void Function()? onDone,
  }) async {
    final stopped = stop(); // any open session ends first
    final session = ++_session;
    _phase = _Phase.starting;
    _held = false;
    _words = '';
    _low = double.infinity;
    _high = double.negativeInfinity;
    _onLive = onLive;
    _onDone = onDone;
    await stopped;
    await _settle(session);
    if (session != _session || _phase != _Phase.starting) return; // stopped meanwhile
    _engine = session;
    // A session that never opens still has to end.
    _noStart = Timer(const Duration(seconds: 2), stop);
    try {
      await _stt.listen(
        onResult: (r) => _onResult(session, r, onHeard),
        onSoundLevelChange: onLevel == null
            ? null
            : (db) {
                if (session != _session) return;
                _low = math.min(_low, db);
                _high = math.max(_high, db);
                final span = _high - _low;
                onLevel(span < 1 ? 0 : ((db - _low) / span).clamp(0.0, 1.0));
              },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          // The timers here decide when a pause means done; this only keeps
          // Android from ending the session at the first breath.
          pauseFor: longest,
        ),
      );
    } catch (_) {
      if (session == _session) _end();
    }
  }

  @override
  void holdOpen() {
    if (_phase == _Phase.idle) return;
    _held = true;
    _quiet?.cancel();
  }

  /// Ends the session now; the engine winds down behind it.
  @override
  Future<void> stop() async {
    if (_phase == _Phase.idle) return;
    final engineOn = _engine == _session;
    _end();
    if (!engineOn) return;
    try {
      await _stt.stop();
    } catch (_) {
      // Not listening.
    }
  }

  /// Waits (up to ~2 s) for a stopped session to wind down.
  Future<void> _settle(int session) async {
    for (var i = 0; _windingDown && i < 14; i++) {
      final seen = _events;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (session != _session) return;
      if (_doneSeen && _events == seen) _windingDown = false;
    }
    _windingDown = false;
  }

  void _onStatus(String status) {
    _events++;
    final current = _engine == _session;
    switch (status) {
      case SpeechToText.listeningStatus when current && _phase == _Phase.starting:
        _goLive();
      case SpeechToText.doneStatus || SpeechToText.notListeningStatus:
        if (current && _phase == _Phase.live) _end();
        if (status == SpeechToText.doneStatus) _doneSeen = true;
    }
  }

  void _onError(SpeechRecognitionError error) {
    _events++;
    if (error.permanent && _engine == _session && _phase == _Phase.live) _end();
  }

  void _goLive() {
    _phase = _Phase.live;
    _noStart?.cancel();
    _cap = Timer(longest, stop);
    if (!_held) _quiet = Timer(firstWord, stop);
    final live = _onLive;
    _onLive = null;
    live?.call();
  }

  void _onResult(int session, SpeechRecognitionResult r, void Function(Heard heard) onHeard) {
    _events++;
    if (session != _session) return;
    final words = r.recognizedWords;
    // Once you are speaking, a short pause means you're done.
    if (_phase == _Phase.live && !_held && words.trim().isNotEmpty && words != _words) {
      _quiet?.cancel();
      _quiet = Timer(afterWords, stop);
    }
    _words = words;
    onHeard((words: words, done: r.finalResult));
  }

  void _end() {
    if (_engine == _session) {
      _windingDown = true;
      _doneSeen = false;
    }
    _phase = _Phase.idle;
    _held = false;
    _quiet?.cancel();
    _cap?.cancel();
    _noStart?.cancel();
    final done = _onDone;
    _onDone = null;
    _onLive = null;
    done?.call();
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
