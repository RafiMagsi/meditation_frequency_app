import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/breath_visual.dart';
import '../widgets/card_face.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';

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
        _p.phases[spot.phase].move == BreathMove.inhale ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_done) {
      setState(() => _done = true);
      HapticFeedback.heavyImpact();
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
    _countIn = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count == 1) {
        timer.cancel();
        setState(() => _count = null);
        _session.forward();
      } else {
        HapticFeedback.selectionClick();
        setState(() => _count = _count! - 1);
      }
    });
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
        particleCount: 14,
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
                                          fontFamily: 'CormorantGaramond',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 22,
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
                                              _StartButton(
                                                running: running || _count != null,
                                                started: started,
                                                color: color,
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
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 26,
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
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w600,
                fontSize: 28,
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
  const _Readout({required this.number, this.eyebrow, this.word, this.large = false});

  final String? eyebrow;
  final String? word;
  final String number;
  final bool large;

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
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 26,
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
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w500,
              fontSize: large ? 76 : 46,
              height: 1,
              color: Colors.white,
              shadows: shadow,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
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

class _StartButton extends StatelessWidget {
  const _StartButton({required this.running, required this.started, required this.color, required this.onTap});

  final bool running;
  final bool started;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = Color.lerp(color, Colors.black, 0.65)!;
    return Semantics(
      button: true,
      label: running ? 'Pause' : (started ? 'Resume' : 'Begin'),
      child: GestureDetector(
        key: const Key('play'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color.lerp(color, Colors.white, 0.55)!],
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: running ? 0.6 : 0.35), blurRadius: running ? 38 : 24),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(running),
              color: ink,
              size: 40,
            ),
          ),
        ),
      ),
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
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
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
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 30,
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
              Expanded(child: _Pill(label: 'Again', onTap: onAgain)),
              const SizedBox(width: 10),
              Expanded(
                child: _Pill(label: 'Done', filled: true, onTap: () => Navigator.of(context).maybePop()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: filled ? Colors.white : Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: filled ? AppTheme.bgTop : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
