import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Playback for one looping tone, shared by both players.
///
/// Tones fade in and out instead of starting abruptly. If audio is
/// unavailable on a platform it drives a simulated timeline, so the demo
/// never breaks.
class TonePlayback extends ChangeNotifier {
  TonePlayback(this.audioPath);

  final String audioPath;

  /// Sleep-timer presets in minutes (0 = off).
  static const sleepOptions = [0, 15, 30, 60];

  /// Skip the audio plugin and run the simulated timeline (widget tests
  /// have no platform channels).
  @visibleForTesting
  static bool simulateAudio = false;

  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _simulated;
  Timer? _fade;
  Timer? _sleep;
  bool _disposed = false;

  bool _playing = false;
  bool _loop = true;
  int _sleepMinutes = 0;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 48);

  /// What the listener hears/sees: stays false through a fade-out.
  bool get playing => _playing;
  bool get loop => _loop;
  int get sleepMinutes => _sleepMinutes;
  Duration get position => _position;
  Duration get duration => _duration;

  double get progress => _duration.inMilliseconds == 0
      ? 0
      : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

  Future<void> init() async {
    if (simulateAudio) {
      _startSimulated();
      return;
    }
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      final duration = await player.setAsset(audioPath);
      await player.setLoopMode(LoopMode.all);
      if (_disposed) {
        await player.dispose();
        return;
      }
      _subscriptions
        ..add(player.positionStream.listen((p) {
          _position = p;
          _notify();
        }))
        ..add(player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _playing = false;
            _notify();
          }
        }));
      _player = player;
      if (duration != null) _duration = duration;
      _notify();
    } catch (_) {
      // Audio unavailable here — drive a simulated timeline instead.
      unawaited(player?.dispose().catchError((Object _) {}));
      _player = null;
      _startSimulated();
    }
  }

  void _startSimulated() {
    _simulated?.cancel();
    _simulated = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_playing) return;
      _position += const Duration(milliseconds: 250);
      if (_position > _duration) {
        _position = _loop ? Duration.zero : _duration;
        if (!_loop) _playing = false;
      }
      _notify();
    });
  }

  Future<void> toggle() => _playing ? pause() : play();

  Future<void> play() async {
    _playing = true;
    _notify();
    final player = _player;
    if (player == null) return;
    _fade?.cancel();
    await player.setVolume(0);
    // play() completes only when playback stops, so don't await it.
    unawaited(player.play());
    _ramp(from: 0, to: 1, ms: 2400);
  }

  Future<void> pause() async {
    _playing = false;
    _notify();
    final player = _player;
    if (player == null) return;
    _ramp(from: player.volume, to: 0, ms: 700, then: player.pause);
  }

  void _ramp({required double from, required double to, required int ms, VoidCallback? then}) {
    _fade?.cancel();
    const step = 40;
    var elapsed = 0;
    _fade = Timer.periodic(const Duration(milliseconds: step), (timer) {
      elapsed += step;
      final f = (elapsed / ms).clamp(0.0, 1.0);
      _player?.setVolume(from + (to - from) * f);
      if (f >= 1) {
        timer.cancel();
        then?.call();
      }
    });
  }

  Future<void> seekFraction(double fraction) =>
      seek(_duration * fraction.clamp(0.0, 1.0));

  Future<void> skip(Duration delta) {
    final target = _position + delta;
    return seek(target < Duration.zero ? Duration.zero : (target > _duration ? _duration : target));
  }

  Future<void> seek(Duration target) async {
    _position = target;
    _notify();
    await _player?.seek(target);
  }

  Future<void> toggleLoop() async {
    _loop = !_loop;
    _notify();
    await _player?.setLoopMode(_loop ? LoopMode.all : LoopMode.off);
  }

  /// Off → 15 → 30 → 60 min → off. Fades out when the time is up.
  void cycleSleepTimer() {
    final next = (sleepOptions.indexOf(_sleepMinutes) + 1) % sleepOptions.length;
    _sleepMinutes = sleepOptions[next];
    _sleep?.cancel();
    if (_sleepMinutes > 0) {
      _sleep = Timer(Duration(minutes: _sleepMinutes), () {
        _sleepMinutes = 0;
        pause();
      });
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _simulated?.cancel();
    _fade?.cancel();
    _sleep?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }
}
