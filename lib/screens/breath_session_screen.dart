import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/card_face.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';

/// An interactive breath guide: the shape breathes with you, each phase
/// is named and counted down, haptics mark every change, and finishing
/// a session counts toward the streak.
class BreathSessionScreen extends ConsumerStatefulWidget {
  const BreathSessionScreen({super.key, required this.pattern});

  final BreathPattern pattern;

  @override
  ConsumerState<BreathSessionScreen> createState() => _BreathSessionScreenState();
}

typedef _Spot = ({int round, int phase, double t, double left});

class _BreathSessionScreenState extends ConsumerState<BreathSessionScreen> with SingleTickerProviderStateMixin {
  BreathPattern get _p => widget.pattern;

  /// The whole session as one timeline; round and phase are derived from
  /// elapsed time, so pause/resume is exact.
  late final AnimationController _session = AnimationController(
    vsync: this,
    duration: _p.duration,
  )
    ..addListener(_onTick)
    ..addStatusListener(_onStatus);

  Timer? _countIn;
  int? _count;
  int _lastPhase = -1;
  bool _done = false;

  _Spot _locate() {
    final elapsed = _session.value * _p.cycleSeconds * _p.rounds;
    final round = math.min((elapsed / _p.cycleSeconds).floor(), _p.rounds - 1);
    var within = elapsed - round * _p.cycleSeconds;
    for (var i = 0; i < _p.phases.length; i++) {
      final s = _p.phases[i].seconds;
      if (within < s || i == _p.phases.length - 1) {
        return (round: round, phase: i, t: (within / s).clamp(0.0, 1.0), left: (s - within).clamp(0.0, s));
      }
      within -= s;
    }
    return (round: round, phase: 0, t: 0, left: _p.phases.first.seconds);
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
      ref.read(practiceProvider.notifier).recordPractice('breath', seconds: _p.duration.inSeconds);
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
    final glow = _p.style.glow;
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: AmbientBackground(
        colors: [Color.lerp(AppTheme.bgTop, glow, 0.18)!, AppTheme.bgTop, const Color(0xFF080A1C)],
        accents: [glow, Color.lerp(glow, AppTheme.violet, 0.5)!],
        particleCount: 12,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final visual = math.min(constraints.maxWidth - 30, constraints.maxHeight - 430).clamp(180.0, 320.0);
                return AnimatedBuilder(
                  animation: _session,
                  builder: (context, _) {
                    final spot = _locate();
                    final running = _session.isAnimating;
                    final started = running || _session.value > 0;
                    final phase = _p.phases[spot.phase];
                    final levels = _p.levels;
                    final from = levels[(spot.phase - 1) % levels.length];
                    final level =
                        started ? from + (levels[spot.phase] - from) * Curves.easeInOut.transform(spot.t) : 0.0;
                    final remaining = _p.cycleSeconds * _p.rounds * (1 - _session.value);

                    return Column(
                      children: [
                        DeckItem(
                          index: 0,
                          child: Row(
                            children: [
                              const BackGlassButton(),
                              const Spacer(),
                              Text(
                                'ROUND ${spot.round + 1} / ${_p.rounds}',
                                style: capsStyle(color: AppTheme.textPrimary.withValues(alpha: 0.8), size: 10.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 98,
                          child: CardHero(
                            tag: 'breath-${_p.id}',
                            face: CardFace(
                              style: _p.style,
                              borderRadius: 24,
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                              contentAlignment: Alignment.centerLeft,
                              child: _HeaderContent(pattern: _p, remaining: _clock(remaining)),
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
                                  painter: _BreathPainter(
                                    shape: _p.shape,
                                    phases: _p.phases,
                                    phase: spot.phase,
                                    t: started ? spot.t : 0,
                                    level: level,
                                    glow: glow,
                                  ),
                                ),
                              ),
                              _Readout(
                                title: _done
                                    ? 'Complete'
                                    : _count != null
                                        ? 'Get ready'
                                        : !started
                                            ? 'Ready'
                                            : running
                                                ? phase.title
                                                : 'Paused',
                                number: _done
                                    ? '✓'
                                    : _count != null
                                        ? '$_count'
                                        : started
                                            ? '${spot.left.ceil()}'
                                            : _clock(_p.duration.inSeconds.toDouble()),
                                small: !started && _count == null && !_done,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            child: Text(
                              _done
                                  ? 'Notice how you feel now.'
                                  : started
                                      ? phase.cue
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
                                      fontSize: 21,
                                      color: AppTheme.textPrimary,
                                    )
                                  : mutedStyle.copyWith(fontSize: 12.5, height: 1.4),
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
                                  onAgain: _restart,
                                )
                              : Column(
                                  key: const ValueKey('controls'),
                                  children: [
                                    DeckItem(
                                      index: 1,
                                      child: _Timeline(
                                        phases: _p.phases,
                                        current: started ? spot.phase : -1,
                                        t: spot.t,
                                        glow: glow,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    DeckItem(
                                      index: 2,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          GlassIconButton(
                                            icon: Icons.refresh_rounded,
                                            size: 54,
                                            semanticLabel: 'Restart',
                                            onTap: _restart,
                                          ),
                                          const SizedBox(width: 26),
                                          _StartButton(
                                            running: running || _count != null,
                                            glow: glow,
                                            label: started ? null : 'Begin',
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
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({required this.pattern, required this.remaining});

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
              Text(pattern.rhythm, style: capsStyle(color: pattern.style.muted, size: 10.5)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  pattern.name,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                    height: 1,
                    color: pattern.style.foreground,
                    shadows: textOnArt,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          remaining,
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.w600,
            fontSize: 30,
            color: pattern.style.foreground,
            shadows: textOnArt,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.title, required this.number, this.small = false});

  final String title;
  final String number;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            title.toUpperCase(),
            key: ValueKey(title),
            style: capsStyle(color: Colors.white, size: 12),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(anim), child: child),
          ),
          child: Text(
            number,
            key: ValueKey(number),
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w500,
              fontSize: small ? 40 : 72,
              height: 1,
              color: Colors.white,
              shadows: const [Shadow(color: Color(0x88000000), blurRadius: 18)],
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// The breath made visible: a dot tracing a box, or an orb that fills
/// and empties with the lungs, inside a ring showing the whole cycle.
class _BreathPainter extends CustomPainter {
  const _BreathPainter({
    required this.shape,
    required this.phases,
    required this.phase,
    required this.t,
    required this.level,
    required this.glow,
  });

  final BreathShape shape;
  final List<BreathPhase> phases;
  final int phase;
  final double t;
  final double level;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    if (shape == BreathShape.box && phases.length == 4) {
      _box(canvas, c, r);
    } else {
      _orb(canvas, c, r);
    }
  }

  void _glow(Canvas canvas, Offset at, double radius, Color color, double alpha) {
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: at, radius: radius)),
    );
  }

  void _orb(Canvas canvas, Offset c, double r) {
    final ring = r - 6;
    final total = phases.fold<double>(0, (s, p) => s + p.seconds);
    var start = -math.pi / 2;
    for (var i = 0; i < phases.length; i++) {
      final sweep = 2 * math.pi * phases[i].seconds / total;
      const gap = 0.05;
      final rect = Rect.fromCircle(center: c, radius: ring);
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: i < phase ? 0.35 : 0.1),
      );
      if (i == phase && t > 0) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          (sweep - gap) * t,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round
            ..color = Color.lerp(glow, Colors.white, 0.35)!,
        );
        final head = start + gap / 2 + (sweep - gap) * t;
        final hp = c + Offset(math.cos(head), math.sin(head)) * ring;
        _glow(canvas, hp, 14, Colors.white, 0.8);
      }
      start += sweep;
    }

    final orb = ring * (0.36 + 0.5 * level);
    _glow(canvas, c, orb * 1.7, glow, 0.32 + 0.2 * level);
    canvas.drawCircle(
      c,
      orb,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Color.lerp(glow, Colors.white, 0.3)!,
            glow.withValues(alpha: 0.85),
            Color.lerp(glow, Colors.black, 0.35)!,
          ],
          stops: const [0, 0.25, 0.7, 1],
        ).createShader(Rect.fromCircle(center: c, radius: orb)),
    );
    canvas.drawCircle(
      c,
      orb,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _box(Canvas canvas, Offset c, double r) {
    final half = r * 0.72;
    final rect = Rect.fromCenter(center: c, width: half * 2, height: half * 2);
    final corners = [rect.bottomLeft, rect.topLeft, rect.topRight, rect.bottomRight];

    // Inner breath field.
    final inner = half * (0.4 + 0.55 * level);
    _glow(canvas, c, inner * 1.6, glow, 0.3 + 0.2 * level);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: inner * 2, height: inner * 2), Radius.circular(inner * 0.28)),
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.5), glow.withValues(alpha: 0.55), glow.withValues(alpha: 0.12)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: inner * 1.4)),
    );

    // Track, completed sides, and the side being travelled now.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = corners[i], b = corners[(i + 1) % 4];
      track.color = Colors.white.withValues(alpha: i < phase ? 0.45 : 0.12);
      canvas.drawLine(a, b, track);
    }
    final a = corners[phase], b = corners[(phase + 1) % 4];
    final head = Offset.lerp(a, b, t)!;
    canvas.drawLine(
      a,
      head,
      track
        ..strokeWidth = 3.6
        ..color = Color.lerp(glow, Colors.white, 0.35)!,
    );
    for (final corner in corners) {
      canvas.drawCircle(corner, 3, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
    _glow(canvas, head, 22, glow, 0.9);
    canvas.drawCircle(head, 6.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BreathPainter old) => old.phase != phase || old.t != t || old.level != level || old.glow != glow;
}

/// The pattern as chips; the live phase fills as it runs.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.phases, required this.current, required this.t, required this.glow});

  final List<BreathPhase> phases;
  final int current;
  final double t;
  final Color glow;

  static String _secs(double s) => s == s.roundToDouble() ? '${s.round()}s' : '${s}s';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < phases.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: i == current ? glow.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: i == current ? glow.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Stack(
                children: [
                  if (i == current)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: FractionallySizedBox(
                        widthFactor: t,
                        child: Container(height: 3, color: Color.lerp(glow, Colors.white, 0.3)),
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            phases[i].title.toUpperCase(),
                            maxLines: 1,
                            style: capsStyle(
                              color: i == current ? Colors.white : AppTheme.textMuted,
                              size: 9,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _secs(phases[i].seconds),
                          style: TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontWeight: FontWeight.w600,
                            fontSize: 19,
                            height: 1,
                            color: i == current ? Colors.white : AppTheme.textPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.running, required this.glow, required this.onTap, this.label});

  final bool running;
  final Color glow;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: running ? 'Pause' : (label ?? 'Resume'),
      child: GestureDetector(
        key: const Key('play'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color.lerp(glow, Colors.black, 0.45)!, Color.lerp(glow, Colors.white, 0.15)!],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.8),
            boxShadow: [BoxShadow(color: glow.withValues(alpha: running ? 0.55 : 0.3), blurRadius: running ? 36 : 20)],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(running),
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends ConsumerWidget {
  const _CompletionCard({super.key, required this.pattern, required this.onAgain});

  final BreathPattern pattern;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(practiceProvider.select((s) => s.streak));
    final minutes = (pattern.duration.inSeconds / 60).toStringAsFixed(pattern.duration.inSeconds % 60 == 0 ? 0 : 1);
    return CardFace(
      style: pattern.style,
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppTheme.amber, size: 18),
              const SizedBox(width: 6),
              Text('DAY $streak STREAK', style: capsStyle(color: Colors.white, size: 10.5)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Beautifully done.',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 30,
              height: 1,
              color: Colors.white,
              shadows: textOnArt,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$minutes min of ${pattern.name.toLowerCase()} · ${pattern.rounds} rounds',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
              shadows: textOnArt,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Pill(label: 'Again', onTap: onAgain),
              const SizedBox(width: 10),
              _Pill(label: 'Done', filled: true, onTap: () => Navigator.of(context).maybePop()),
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: filled ? Colors.white : Colors.white.withValues(alpha: 0.14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: filled ? AppTheme.bgTop : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
