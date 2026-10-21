import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/card_face.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';
import '../widgets/scene_art.dart';

/// "Our being is like a lake; the true self lies at the bottom, hidden
/// by mud and ripples" (docs/energy.md). An interactive meditation: hold
/// to breathe in, release to breathe out. Each slow breath settles the
/// mud and stills the ripples until the light at the bottom shows.
class InnerLakeScreen extends ConsumerStatefulWidget {
  const InnerLakeScreen({super.key});

  static const breathsNeeded = 6;

  @override
  ConsumerState<InnerLakeScreen> createState() => _InnerLakeScreenState();
}

class _InnerLakeScreenState extends ConsumerState<InnerLakeScreen> with TickerProviderStateMixin {
  /// 0 = stirred, 1 = perfectly still.
  late final AnimationController _calm = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  /// The breath: forward while holding (in), reverse on release (out).
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
    reverseDuration: const Duration(seconds: 5),
  );

  final ValueNotifier<double> _clock = ValueNotifier(ArtClock.value);
  late final Ticker _ticker;
  bool _holding = false;
  int _breaths = 0;
  bool _recorded = false;

  bool get _still => _breaths >= InnerLakeScreen.breathsNeeded;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _clock.value = ArtClock.value)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    _calm.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    if (_still) return;
    _holding = true;
    HapticFeedback.selectionClick();
    _breath.forward();
  }

  void _up(PointerEvent _) {
    if (!_holding) return;
    _holding = false;
    final inhaled = _breath.value;
    _breath.reverse();
    // Only slow, deliberate breaths (half the 5 s inhale or more) still the water.
    if (inhaled < 0.5) return;
    setState(() => _breaths++);
    HapticFeedback.mediumImpact();
    _calm.animateTo(_breaths / InnerLakeScreen.breathsNeeded, curve: Curves.easeInOutCubic);
    if (_still && !_recorded) {
      _recorded = true;
      HapticFeedback.heavyImpact();
      ref.read(practiceProvider.notifier).recordPractice('stillness', seconds: 90);
    }
  }

  ({String title, String body}) get _stage => switch (_breaths) {
        0 => (
            title: 'Your mind is a lake.',
            body: 'Ripples are thoughts. Mud is fear, envy and doubt. Beneath them — you.'
          ),
        1 || 2 => (
            title: 'Let the mud settle.',
            body: 'Nothing to fix. Negative thoughts sink on their own when you stop stirring.'
          ),
        3 || 4 => (title: 'Soften the ripples.', body: 'Thoughts come and go. You are the water, not the waves.'),
        5 => (title: 'Almost still.', body: 'One more long breath. Look down through the water.'),
        _ => (title: 'See to the bottom.', body: 'The stillness you see is you — infinite, steady, whole. Trust it.'),
      };

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The card from the Guided screen expands into the lake itself.
            const CardHero(
              tag: 'lake-card',
              face: CardFace(
                style: CardStyles.innerLake,
                borderRadius: 0,
                padding: EdgeInsets.zero,
                scrim: 0,
                elevation: 0,
              ),
            ),
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _LakePainter(clock: _clock, calm: _calm, breath: _breath),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    DeckItem(
                      index: 0,
                      child: Row(
                        children: [
                          const BackGlassButton(icon: Icons.close_rounded),
                          const Spacer(),
                          Text('INNER LAKE', style: capsStyle(color: Colors.white.withValues(alpha: 0.85), size: 10.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    DeckItem(
                      index: 1,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 900),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(stage.title),
                          children: [
                            Text(
                              stage.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'CormorantGaramond',
                                fontWeight: FontWeight.w600,
                                fontSize: 36,
                                height: 1.05,
                                color: Colors.white,
                                shadows: [Shadow(color: Color(0xAA000000), blurRadius: 18)],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              stage.body,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 1.45,
                                color: Colors.white.withValues(alpha: 0.88),
                                shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 12)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _BreathCue(breath: _breath, still: _still),
                    const Spacer(),
                    DeckItem(
                      index: 2,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < InnerLakeScreen.breathsNeeded; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i < _breaths ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                    boxShadow: i < _breaths
                                        ? [BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 8)]
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_still)
                            Semantics(
                              button: true,
                              label: 'Return',
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).maybePop(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  child: const Text(
                                    'Carry the stillness',
                                    style: TextStyle(
                                      fontFamily: 'Quicksand',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF0B1620),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Text(
                              'Hold to breathe in · release to breathe out',
                              textAlign: TextAlign.center,
                              style: capsStyle(color: Colors.white.withValues(alpha: 0.8), size: 9.5),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathCue extends StatelessWidget {
  const _BreathCue({required this.breath, required this.still});

  final AnimationController breath;
  final bool still;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breath,
      builder: (context, _) {
        final b = Curves.easeInOut.transform(breath.value);
        final label = still
            ? ''
            : breath.status == AnimationStatus.forward
                ? 'Breathe in…'
                : breath.value > 0
                    ? 'Breathe out…'
                    : '';
        return SizedBox(
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60 + 110 * b,
                height: 60 + 110 * b,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15 + 0.5 * b), width: 1.4),
                  gradient: RadialGradient(
                    colors: [Colors.white.withValues(alpha: 0.18 * b), Colors.white.withValues(alpha: 0)],
                  ),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w500,
                  fontSize: 22,
                  color: Colors.white,
                  shadows: [Shadow(color: Color(0xAA000000), blurRadius: 12)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mud, ripples and the light beneath, all driven by [calm].
class _LakePainter extends CustomPainter {
  _LakePainter({required this.clock, required this.calm, required this.breath})
      : super(repaint: Listenable.merge([clock, calm, breath]));

  final ValueNotifier<double> clock;
  final Animation<double> calm;
  final Animation<double> breath;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final c = calm.value;
    final stir = 1 - c;
    final w = size.width, h = size.height;
    final horizon = h * 0.5;
    final water = Rect.fromLTRB(0, horizon, w, h);

    // Legibility: darken the top for the guidance text.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.35)
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Offset.zero & size),
    );

    // Mud: a murky haze over the water while the mind is stirred.
    canvas.drawRect(
      water,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4A3B2A).withValues(alpha: 0.25 * stir),
            const Color(0xFF2A2016).withValues(alpha: 0.75 * stir),
          ],
        ).createShader(water),
    );
    final rng = math.Random(5);
    final speck = Paint();
    for (var i = 0; i < 70; i++) {
      final x = rng.nextDouble() * w;
      final y0 = horizon + rng.nextDouble() * (h - horizon);
      // Sediment sinks as the water calms.
      final y = y0 + (h - y0) * c * 0.9 + 6 * math.sin((t * (2 + rng.nextInt(3)) + rng.nextDouble()) * 2 * math.pi);
      speck.color = const Color(0xFFB59A72).withValues(alpha: 0.5 * stir * rng.nextDouble());
      canvas.drawCircle(Offset(x + 8 * math.sin(t * 2 * math.pi + i), y), 0.8 + 1.6 * rng.nextDouble(), speck);
    }

    // Ripples: agitated surface lines and spreading rings.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var k = 0; k < 14; k++) {
      final f = math.pow((k + 1) / 15, 1.4).toDouble();
      final y0 = horizon + (h - horizon) * f;
      final amp = (2 + 10 * f) * stir;
      final path = Path();
      for (var i = 0; i <= 48; i++) {
        final u = i / 48;
        final y = y0 + amp * math.sin((u * (3 + k * 0.4) + t * (k.isEven ? 4 : -4)) * 2 * math.pi);
        i == 0 ? path.moveTo(0, y) : path.lineTo(u * w, y);
      }
      line.color = Colors.white.withValues(alpha: (0.05 + 0.18 * stir) * (1 - f * 0.5));
      canvas.drawPath(path, line);
    }
    for (var k = 0; k < 3; k++) {
      final ph = (t * 6 + k / 3) % 1.0;
      final center = Offset(w * (0.3 + 0.4 * ((k * 0.37) % 1)), horizon + (h - horizon) * (0.35 + 0.2 * k));
      canvas.drawOval(
        Rect.fromCenter(center: center, width: w * (0.1 + 0.6 * ph), height: (h - horizon) * (0.03 + 0.12 * ph)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.35 * (1 - ph) * stir),
      );
    }

    // The light at the bottom: the true self, visible once still.
    final clarity = Curves.easeIn.transform(c);
    if (clarity > 0) {
      final core = Offset(w / 2, h * 0.86);
      final r = w * (0.3 + 0.35 * clarity);
      canvas.drawCircle(
        core,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF4D6).withValues(alpha: 0.75 * clarity),
              const Color(0xFF9FD3E6).withValues(alpha: 0.3 * clarity),
              const Color(0x009FD3E6),
            ],
            stops: const [0, 0.35, 1],
          ).createShader(Rect.fromCircle(center: core, radius: r)),
      );
      final ray = Paint();
      for (var i = 0; i < 7; i++) {
        final a = -math.pi / 2 + (i - 3) * 0.16 + 0.03 * math.sin(t * 2 * math.pi + i);
        final len = (h - horizon) * 0.7 * clarity;
        final tip = core + Offset(math.cos(a), math.sin(a)) * len;
        ray.shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.25 * clarity), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromPoints(core, tip));
        canvas.drawPath(
          Path()
            ..moveTo(core.dx - 6, core.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(core.dx + 6, core.dy)
            ..close(),
          ray,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LakePainter old) => false;
}
