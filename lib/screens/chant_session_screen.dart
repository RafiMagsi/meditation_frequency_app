import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../services/practice_store.dart';
import '../services/voice.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/cosmic_video.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';
import '../widgets/luxury.dart';
import '../widgets/voice_kit.dart';
import 'voice_screen.dart';

enum _Stage { ready, calibrating, inhale, chant, rest, short, done }

/// Om Chant and Bee Breath: the microphone hears the chant or hum; a round
/// only counts once the sound has been held long enough.
class ChantSessionScreen extends ConsumerStatefulWidget {
  const ChantSessionScreen({super.key, required this.practice, required this.heroTag});

  final VoicePractice practice;
  final String heroTag;

  @override
  ConsumerState<ChantSessionScreen> createState() => _ChantSessionScreenState();
}

class _ChantSessionScreenState extends ConsumerState<ChantSessionScreen> with SingleTickerProviderStateMixin {
  static const _hold = 6.0; // seconds of sound per round
  static const _inhale = 4.0;
  static const _rest = 3.0;
  static const _calibrate = 1.5;

  // Resolved up front: `ref` can't be used from dispose().
  late final MicLevel _mic;
  StreamSubscription<double>? _levels;
  // Created in initState (not lazily) so dispose never creates it.
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  _Stage _stage = _Stage.ready;
  bool _micOk = true;
  double _raw = 0, _level = 0, _wave = 0;
  double _ambient = 0;
  int _ambientSamples = 0;
  double _threshold = 0.3;
  double _t = 0, _sounded = 0, _silence = 0, _total = 0;
  int _round = 0;

  bool get _om => widget.practice.kind == VoiceKind.om;
  int get _rounds => _om ? 5 : 6;
  Color get _color => widget.practice.color;

  @override
  void initState() {
    super.initState();
    _mic = ref.read(micLevelProvider)();
    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _levels?.cancel();
    _mic.stop();
    _mic.dispose();
    super.dispose();
  }

  Future<void> _begin() async {
    HapticFeedback.mediumImpact();
    _micOk = await _mic.start();
    if (!mounted) return;
    _levels = _mic.levels.listen((l) => _raw = l);
    _go(_micOk ? _Stage.calibrating : _Stage.inhale);
    _last = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _go(_Stage stage) {
    _stage = stage;
    _t = 0;
    if (stage == _Stage.chant) {
      _sounded = 0;
      _silence = 0;
      HapticFeedback.mediumImpact();
    } else if (stage == _Stage.inhale) {
      HapticFeedback.lightImpact();
    }
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / Duration.microsecondsPerSecond).clamp(0.0, 0.1);
    _last = now;
    _level += (_raw - _level) * 0.25;
    _wave += dt * (0.35 + 2.4 * _level);
    _t += dt;
    switch (_stage) {
      case _Stage.calibrating:
        _ambient += _raw;
        _ambientSamples++;
        if (_t >= _calibrate) {
          // Room noise plus a margin: works in a quiet bedroom or a café.
          _threshold = (_ambient / math.max(1, _ambientSamples) + 0.14).clamp(0.22, 0.62);
          _go(_Stage.inhale);
        }
      case _Stage.inhale:
        if (_t >= _inhale) _go(_Stage.chant);
      case _Stage.chant:
        // Without a microphone the session becomes a guided timer.
        final heard = !_micOk || (_t > 0.4 && _level >= _threshold);
        if (heard) {
          _sounded += dt;
          _total += dt;
          _silence = 0;
        } else if (_sounded > 0) {
          _silence += dt;
        }
        if (_sounded >= _hold && (!_micOk || _silence >= 0.7 || _sounded >= _hold + 10)) {
          _roundDone();
        } else if (_sounded > 0.8 && _sounded < _hold && _silence >= 1.2) {
          _go(_Stage.short);
        }
      case _Stage.rest:
        if (_t >= _rest) _go(_Stage.inhale);
      case _Stage.short:
        if (_t >= 2.6) _go(_Stage.inhale);
      case _Stage.ready || _Stage.done:
        break;
    }
    setState(() {});
  }

  void _roundDone() {
    _round++;
    HapticFeedback.heavyImpact();
    if (_round >= _rounds) {
      _go(_Stage.done);
      _ticker.stop();
      _mic.stop();
      ref.read(practiceProvider.notifier).recordPractice('voice', seconds: _total.round());
    } else {
      _go(_Stage.rest);
    }
  }

  Future<void> _again() async {
    setState(() {
      _round = 0;
      _total = 0;
      _ambient = 0;
      _ambientSamples = 0;
      _stage = _Stage.ready;
    });
    await _levels?.cancel();
    await _begin();
  }

  ({String title, String body}) get _words => switch (_stage) {
        _Stage.ready => (title: 'Ready when you are', body: widget.practice.how),
        _Stage.calibrating => (title: 'A moment of quiet', body: 'Listening to the room so only your voice counts.'),
        _Stage.inhale => (title: 'Breathe in', body: 'A slow, full breath through the nose.'),
        _Stage.chant => _sounded >= _hold
            ? (title: 'Let it fade', body: 'Beautiful. Let the sound dissolve into silence.')
            : _om
                ? (title: 'Chant  Aum', body: 'Ahh… ooo… mmm — one long, steady tone.')
                : (title: 'Hum', body: 'A low, steady hum, like a bee. Feel it in your face.'),
        _Stage.rest => (title: 'Rest', body: 'Notice the vibration still moving through you.'),
        _Stage.short => (title: 'Almost', body: 'Hold the sound a little longer this time.'),
        _Stage.done => (title: 'Complete', body: ''),
      };

  @override
  Widget build(BuildContext context) {
    final words = _words;
    final progress = (_sounded / _hold).clamp(0.0, 1.0);
    final listening = _stage != _Stage.ready && _stage != _Stage.done;
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: AmbientBackground(
        colors: [Color.lerp(AppTheme.bgTop, _color, 0.12)!, AppTheme.bgTop, const Color(0xFF09080D)],
        accents: [_color, Color.lerp(_color, AppTheme.violet, 0.5)!],
        video: Cosmos.stars,
        videoOpacity: 0.6,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final visual = math.min(constraints.maxWidth - 40, constraints.maxHeight - 420).clamp(180.0, 300.0);
                return Column(
                  children: [
                    const DeckItem(index: 0, child: Row(children: [BackGlassButton(), Spacer()])),
                    const SizedBox(height: 14),
                    VoiceHeader(
                      practice: widget.practice,
                      heroTag: widget.heroTag,
                      trailing: _stage == _Stage.done ? 'DONE' : 'ROUND ${math.min(_round + 1, _rounds)} / $_rounds',
                    ),
                    const Spacer(),
                    if (_stage == _Stage.done)
                      VoiceCompletion(
                        practice: widget.practice,
                        detail: '$_rounds ${_om ? 'Aums' : 'hums'} · ${_total.round()} seconds of sound',
                        onAgain: _again,
                      )
                    else ...[
                      SizedBox.square(
                        dimension: visual,
                        child: CustomPaint(
                          painter: _ResonancePainter(
                            color: _color,
                            level: listening ? _level : 0,
                            wave: _wave,
                            progress: _stage == _Stage.chant ? progress : (_stage == _Stage.rest ? 1 : 0),
                            breath: _stage == _Stage.inhale ? (_t / _inhale).clamp(0.0, 1.0) : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Syllables(om: _om, progress: _stage == _Stage.chant ? progress : 0, color: _color),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Column(
                          key: ValueKey(words.title),
                          children: [
                            Text(
                              words.title,
                              style: const TextStyle(
                                fontFamily: 'InterDisplay',
                                fontWeight: FontWeight.w600,
                                fontSize: 25.5,
                                height: 1,
                                color: AppTheme.ivory,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              words.body,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              style: mutedStyle.copyWith(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_stage == _Stage.ready)
                      MetalPlayButton(
                        key: const Key('begin-chant'),
                        playing: false,
                        color: _color,
                        size: 80,
                        label: 'Begin',
                        onTap: _begin,
                      )
                    else if (_stage != _Stage.done) ...[
                      if (_micOk)
                        LevelMeter(level: _level, threshold: _threshold, color: _color)
                      else
                        Text('MICROPHONE OFF · FOLLOW THE TIMER',
                            style: capsStyle(color: AppTheme.textMuted, size: 9.5)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _rounds; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _round ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i < _round
                                    ? _color
                                    : i == _round
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A · U · M (or H · m · m · m) lighting up across the held sound.
class _Syllables extends StatelessWidget {
  const _Syllables({required this.om, required this.progress, required this.color});

  final bool om;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final letters = om ? const ['A', 'U', 'M'] : const ['H', 'm', 'm', 'm'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < letters.length; i++) ...[
          if (i > 0) const SizedBox(width: 22),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontFamily: 'InterDisplay',
              fontWeight: FontWeight.w600,
              fontSize: 30.5,
              height: 1,
              color: progress > i / letters.length + 0.001 ? AppTheme.ivory : AppTheme.ivory.withValues(alpha: 0.2),
              shadows: progress > i / letters.length + 0.001
                  ? [Shadow(color: color.withValues(alpha: 0.9), blurRadius: 20)]
                  : const [],
            ),
            child: Text(letters[i]),
          ),
        ],
      ],
    );
  }
}

/// The voice made visible: an orb that swells with loudness, resonance
/// rings that travel faster the stronger the sound, and the held time as
/// an arc of the accent metal.
class _ResonancePainter extends CustomPainter {
  const _ResonancePainter({
    required this.color,
    required this.level,
    required this.wave,
    required this.progress,
    this.breath,
  });

  final Color color;
  final double level;
  final double wave;
  final double progress;

  /// 0→1 through the inhale, or null outside it.
  final double? breath;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 4;
    final base = outer * 0.36;

    // Track and held-time arc.
    final ring = Rect.fromCircle(center: c, radius: outer);
    canvas.drawCircle(
      c,
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.1),
    );
    if (progress > 0) {
      canvas.drawArc(
        ring,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..shader = foilFor(color).createShader(ring),
      );
    }

    // Resonance rings.
    for (var k = 0; k < 5; k++) {
      final ph = (wave + k / 5) % 1.0;
      final r = base * (1.1 + ph * 1.5);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = color.withValues(alpha: (0.08 + 0.55 * level) * (1 - ph)),
      );
    }

    // The orb: breathes during the inhale, swells with the voice.
    final scale = breath != null ? 0.75 + 0.3 * Curves.easeInOut.transform(breath!) : 0.9 + 0.45 * level;
    final r = base * scale;
    canvas.drawCircle(
      c,
      r * 2,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.18 + 0.3 * level), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r * 2)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0.7),
            Color.lerp(color, Colors.black, 0.3)!.withValues(alpha: 0.95),
          ],
          stops: const [0, 0.7, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c + Offset(-r * 0.36, -r * 0.42),
      r * 0.45,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.32), Colors.white.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c + Offset(-r * 0.36, -r * 0.42), radius: r * 0.45)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_ResonancePainter old) =>
      old.level != level || old.wave != wave || old.progress != progress || old.breath != breath;
}
