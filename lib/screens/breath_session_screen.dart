import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../services/practice_store.dart';
import '../services/tone_playback.dart';
import '../services/voice.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/breath_visual.dart';
import '../widgets/card_face.dart';
import '../widgets/cosmic_video.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';
import '../widgets/luxury.dart';

/// An interactive breath guide. The shape breathes with you, each phase
/// is named, counted down and felt as a haptic, the whole screen glows
/// fuller on the inhale, and finishing counts toward the streak.
class BreathSessionScreen extends ConsumerStatefulWidget {
  const BreathSessionScreen({super.key, required this.pattern, required this.heroTag});

  final BreathPattern pattern;

  /// The card this session morphs out of.
  final String heroTag;

  @override
  ConsumerState<BreathSessionScreen> createState() => _BreathSessionScreenState();
}

class _BreathSessionScreenState extends ConsumerState<BreathSessionScreen> with SingleTickerProviderStateMixin {
  BreathPattern get _p => widget.pattern;

  late int _rounds = _p.rounds;

  /// The whole session as one timeline; round and phase are derived from
  /// elapsed time, so pause/resume is exact.
  late final AnimationController _session = AnimationController(vsync: this, duration: _length)
    ..addListener(_onTick)
    ..addStatusListener(_onStatus);

  Timer? _countIn;
  int? _count;
  int _lastPhase = -1;
  bool _done = false;

  /// Spoken cues, for practising with eyes closed.
  bool _voiceOn = true;

  /// Optional soft tone bed under the breath.
  TonePlayback? _bed;

  // Resolved up front: `ref` can't be used from dispose().
  late final VoiceGuide _voice;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(voiceGuideProvider);
  }

  void _say(String text) {
    if (_voiceOn) _voice.say(text);
  }

  Duration get _length => Duration(milliseconds: (_p.cycleSeconds * _rounds * 1000).round());
  bool get _started => _session.isAnimating || _session.value > 0;

  ({int round, int phase, double t, double left, double level}) _locate() {
    final elapsed = _session.value * _p.cycleSeconds * _rounds;
    final round = math.min((elapsed / _p.cycleSeconds).floor(), _rounds - 1);
    final within = (elapsed - round * _p.cycleSeconds) / _p.cycleSeconds;
    final spot = breathSpotAt(_p, within);
    final left = _p.phases[spot.phase].seconds * (1 - spot.t);
    return (round: round, phase: spot.phase, t: spot.t, left: left, level: spot.level);
  }

  void _onTick() {
    final spot = _locate();
    final global = spot.round * _p.phases.length + spot.phase;
    if (global != _lastPhase) {
      _lastPhase = global;
      if (_session.isAnimating && _session.value < 1) {
        final phase = _p.phases[spot.phase];
        phase.move == BreathMove.inhale ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
        _say(phase.spoken);
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_done) {
      setState(() => _done = true);
      HapticFeedback.heavyImpact();
      _say('Beautifully done.');
      _bed?.pause();
      ref.read(practiceProvider.notifier).recordPractice('breath', seconds: _length.inSeconds);
    }
  }

  void _toggle() {
    if (_count != null) return;
    if (_session.isAnimating) {
      _session.stop();
      setState(() {});
      return;
    }
    if (_session.value > 0) {
      _session.forward();
      setState(() {});
      return;
    }
    // A three-beat count-in, so the first inhale isn't a surprise.
    HapticFeedback.selectionClick();
    setState(() => _count = 3);
    _say('Three');
    _countIn = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count == 1) {
        timer.cancel();
        setState(() => _count = null);
        _session.forward();
      } else {
        HapticFeedback.selectionClick();
        setState(() => _count = _count! - 1);
        _say(_count == 2 ? 'Two' : 'One');
      }
    });
  }

  void _toggleVoice() {
    setState(() => _voiceOn = !_voiceOn);
    if (!_voiceOn) _voice.stop();
  }

  void _toggleBed() {
    if (_bed == null) {
      setState(() => _bed = TonePlayback(_p.tone, volume: 0.35)..init().then((_) => _bed?.play()));
    } else {
      _bed!.dispose();
      setState(() => _bed = null);
    }
  }

  void _restart() {
    _countIn?.cancel();
    _session.reset();
    setState(() {
      _done = false;
      _count = null;
      _lastPhase = -1;
    });
  }

  void _setRounds(int rounds) {
    HapticFeedback.selectionClick();
    setState(() {
      _rounds = rounds.clamp(2, 20);
      _session.duration = _length;
    });
  }

  @override
  void dispose() {
    _countIn?.cancel();
    _bed?.dispose();
    _voice.stop();
    _session.dispose();
    super.dispose();
  }

  static String _clock(double seconds) {
    final s = seconds.ceil();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _p.color;
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: AmbientBackground(
        colors: [Color.lerp(AppTheme.bgTop, color, 0.2)!, const Color(0xFF080A1C), const Color(0xFF05060F)],
        accents: [color, Color.lerp(color, AppTheme.violet, 0.5)!],
        video: Cosmos.stars,
        videoOpacity: 0.55,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final visual = math.min(constraints.maxWidth - 24, constraints.maxHeight - 410).clamp(200.0, 360.0);
              return AnimatedBuilder(
                animation: _session,
                builder: (context, _) {
                  final spot = _locate();
                  final started = _started;
                  final running = _session.isAnimating;
                  final level = started ? spot.level : 0.5;
                  final remaining = _p.cycleSeconds * _rounds * (1 - _session.value);
                  return Stack(
                    children: [
                      // The room fills with light as you breathe in.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.05),
                                radius: 0.55 + 0.35 * level,
                                colors: [color.withValues(alpha: 0.1 + 0.16 * level), color.withValues(alpha: 0)],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        child: Column(
                          children: [
                            DeckItem(
                              index: 0,
                              child: Row(
                                children: [
                                  const BackGlassButton(),
                                  const Spacer(),
                                  Text(
                                    started ? 'ROUND ${spot.round + 1} OF $_rounds' : _p.rhythm,
                                    style: capsStyle(color: Colors.white.withValues(alpha: 0.85), size: 10.5),
                                  ),
                                  const SizedBox(width: 12),
                                  GlassIconButton(
                                    key: const Key('voice'),
                                    icon: _voiceOn ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
                                    active: _voiceOn,
                                    activeColor: Color.lerp(color, Colors.white, 0.4)!,
                                    size: 40,
                                    semanticLabel: _voiceOn ? 'Voice guidance on' : 'Voice guidance off',
                                    onTap: _toggleVoice,
                                  ),
                                  const SizedBox(width: 8),
                                  GlassIconButton(
                                    key: const Key('tone'),
                                    icon: _bed != null ? Icons.music_note_rounded : Icons.music_off_rounded,
                                    active: _bed != null,
                                    activeColor: Color.lerp(color, Colors.white, 0.4)!,
                                    size: 40,
                                    semanticLabel: _bed != null ? 'Tone on' : 'Tone off',
                                    onTap: _toggleBed,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 86,
                              child: CardHero(
                                tag: widget.heroTag,
                                face: CardFace(
                                  style: _p.style,
                                  borderRadius: 24,
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                                  contentAlignment: Alignment.centerLeft,
                                  child: _Header(pattern: _p, remaining: _clock(remaining)),
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox.square(
                              dimension: visual,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: BreathVisualPainter(
                                        shape: _p.shape,
                                        phases: _p.phases,
                                        phase: spot.phase,
                                        t: started ? spot.t : 0,
                                        level: level,
                                        color: color,
                                        active: started && !_done,
                                      ),
                                    ),
                                  ),
                                  _Readout(
                                    eyebrow: _done
                                        ? 'COMPLETE'
                                        : _count != null
                                            ? 'GET READY'
                                            : !started
                                                ? 'READY'
                                                : running
                                                    ? null
                                                    : 'PAUSED',
                                    word: started && !_done && _count == null ? _p.phases[spot.phase].title : null,
                                    number: _done
                                        ? _clock(_length.inSeconds.toDouble())
                                        : _count != null
                                            ? '$_count'
                                            : started
                                                ? '${spot.left.ceil()}'
                                                : _clock(_length.inSeconds.toDouble()),
                                    large: _count != null || (started && !_done),
                                    side: started && !_done && _count == null ? _p.phases[spot.phase].side : null,
                                    color: color,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 54,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 450),
                                child: Text(
                                  _done
                                      ? 'Notice how you feel now.'
                                      : started
                                          ? _p.phases[spot.phase].cue
                                          : _p.why,
                                  key: ValueKey(_done
                                      ? 'done'
                                      : started
                                          ? '${spot.round}-${spot.phase}'
                                          : 'why'),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  style: started && !_done
                                      ? const TextStyle(
                                          fontFamily: 'InterDisplay',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17.5,
                                          height: 1.15,
                                          color: AppTheme.textPrimary,
                                        )
                                      : mutedStyle.copyWith(fontSize: 12.5, height: 1.45),
                                ),
                              ),
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              switchInCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: _done
                                  ? _CompletionCard(
                                      key: const ValueKey('done'),
                                      pattern: _p,
                                      rounds: _rounds,
                                      seconds: _length.inSeconds,
                                      onAgain: _restart,
                                    )
                                  : Column(
                                      key: const ValueKey('controls'),
                                      children: [
                                        DeckItem(
                                          index: 1,
                                          child: PhaseStrip(
                                            phases: _p.phases,
                                            color: color,
                                            current: started ? spot.phase : -1,
                                            t: spot.t,
                                            large: true,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          height: 36,
                                          child: started || _count != null
                                              ? _RoundDots(total: _rounds, current: spot.round, color: color)
                                              : _RoundsStepper(rounds: _rounds, onChanged: _setRounds),
                                        ),
                                        const SizedBox(height: 14),
                                        DeckItem(
                                          index: 2,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              GlassIconButton(
                                                icon: Icons.refresh_rounded,
                                                size: 52,
                                                semanticLabel: 'Restart',
                                                onTap: _restart,
                                              ),
                                              const SizedBox(width: 28),
                                              MetalPlayButton(
                                                key: const Key('play'),
                                                playing: running || _count != null,
                                                color: color,
                                                size: 82,
                                                label: running ? 'Pause' : (started ? 'Resume' : 'Begin'),
                                                onTap: _toggle,
                                              ),
                                              const SizedBox(width: 80),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pattern, required this.remaining});

  final BreathPattern pattern;
  final String remaining;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BEST FOR ${pattern.bestFor}',
                style: capsStyle(color: Color.lerp(pattern.color, Colors.white, 0.35)!, size: 9.5),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  pattern.name,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'InterDisplay',
                    fontWeight: FontWeight.w600,
                    fontSize: 21,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              remaining,
              style: const TextStyle(
                fontFamily: 'InterDisplay',
                fontWeight: FontWeight.w600,
                fontSize: 22.5,
                height: 1,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text('REMAINING', style: capsStyle(color: Colors.white.withValues(alpha: 0.6), size: 8)),
          ],
        ),
      ],
    );
  }
}

/// The centre of the shape: a small eyebrow or the phase word, and a big
/// number (countdown, count-in or session length).
class _Readout extends StatelessWidget {
  const _Readout({
    required this.number,
    required this.color,
    this.eyebrow,
    this.word,
    this.large = false,
    this.side,
  });

  final String? eyebrow;
  final String? word;
  final String number;
  final bool large;
  final Color color;

  /// Which nostril, for alternate-nostril breathing.
  final String? side;

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Color(0x99000000), blurRadius: 16)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: word != null
              ? Text(
                  word!,
                  key: ValueKey('w$word'),
                  style: const TextStyle(
                    fontFamily: 'InterDisplay',
                    fontWeight: FontWeight.w600,
                    fontSize: 21,
                    height: 1,
                    color: Colors.white,
                    shadows: shadow,
                  ),
                )
              : Text(
                  eyebrow ?? '',
                  key: ValueKey('e$eyebrow'),
                  style: capsStyle(color: Colors.white.withValues(alpha: 0.85), size: 10.5).copyWith(shadows: shadow),
                ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.86, end: 1.0).animate(anim), child: child),
          ),
          child: Text(
            number,
            key: ValueKey(number),
            style: TextStyle(
              fontFamily: 'InterDisplay',
              fontWeight: FontWeight.w500,
              fontSize: (large ? 76 : 46) * 0.8,
              height: 1,
              color: Colors.white,
              shadows: shadow,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (side != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(color: color.withValues(alpha: 0.7), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(side == 'left' ? Icons.west_rounded : Icons.east_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text('${side!.toUpperCase()} NOSTRIL', style: capsStyle(color: Colors.white, size: 9)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RoundsStepper extends StatelessWidget {
  const _RoundsStepper({required this.rounds, required this.onChanged});

  final int rounds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, int delta, String label) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: () => onChanged(rounds + delta),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        step(Icons.remove_rounded, -1, 'Fewer rounds'),
        SizedBox(
          width: 130,
          child: Text(
            '$rounds ROUNDS',
            key: const Key('rounds'),
            textAlign: TextAlign.center,
            style: capsStyle(color: Colors.white, size: 11),
          ),
        ),
        step(Icons.add_rounded, 1, 'More rounds'),
      ],
    );
  }
}

class _RoundDots extends StatelessWidget {
  const _RoundDots({required this.total, required this.current, required this.color});

  final int total;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i < current
                  ? color.withValues(alpha: 0.8)
                  : i == current
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.16),
            ),
          ),
      ],
    );
  }
}

class _CompletionCard extends ConsumerWidget {
  const _CompletionCard({
    super.key,
    required this.pattern,
    required this.rounds,
    required this.seconds,
    required this.onAgain,
  });

  final BreathPattern pattern;
  final int rounds;
  final int seconds;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(practiceProvider.select((s) => s.streak));
    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'InterDisplay',
                  fontWeight: FontWeight.w600,
                  fontSize: 22.5,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: capsStyle(color: Colors.white.withValues(alpha: 0.65), size: 8.5)),
            ],
          ),
        );
    return CardFace(
      style: pattern.style,
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        children: [
          const Text(
            'Beautifully done.',
            style: TextStyle(
              fontFamily: 'InterDisplay',
              fontWeight: FontWeight.w600,
              fontSize: 24,
              height: 1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat((seconds / 60).toStringAsFixed(seconds % 60 == 0 ? 0 : 1), 'MINUTES'),
              stat('$rounds', 'ROUNDS'),
              stat('$streak', 'DAY STREAK'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ActionPill(
                  label: 'Again',
                  icon: Icons.replay_rounded,
                  color: pattern.color,
                  expand: true,
                  onTap: onAgain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionPill(
                  label: 'Done',
                  icon: Icons.check_rounded,
                  color: pattern.color,
                  expand: true,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
