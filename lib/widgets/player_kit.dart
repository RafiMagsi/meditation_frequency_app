import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'glass_button.dart';
import 'luxury.dart';
import 'scene_art.dart';

const _hairline = Color(0x66D4AF6A);

/// Chevron, centred "now playing" labels and a trailing action.
class PlayerTopBar extends StatelessWidget {
  const PlayerTopBar({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BackGlassButton(icon: Icons.keyboard_arrow_down_rounded, borderColor: _hairline),
        Expanded(
          child: Column(
            children: [
              Text('NOW PLAYING', style: capsStyle(color: AppTheme.taupe, size: 9.5)),
              const SizedBox(height: 4),
              GoldText(label, style: capsStyle(size: 9.5)),
            ],
          ),
        ),
        trailing ?? const SizedBox(width: 44),
      ],
    );
  }
}

/// Fades and settles a widget in with its route, without moving it
/// sideways (for elements a hero lands into).
class RouteReveal extends StatelessWidget {
  const RouteReveal({super.key, required this.child, this.delay = 0.2});

  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return child;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(((animation.value - delay) / (1 - delay)).clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.86 + 0.14 * t, child: child),
        );
      },
    );
  }
}

/// A luminous oscilloscope trace of the tone: lively while playing,
/// settling to a calm line when paused.
class SignatureLine extends StatefulWidget {
  const SignatureLine({super.key, required this.color, required this.active, this.height = 56});

  final Color color;
  final bool active;
  final double height;

  @override
  State<SignatureLine> createState() => _SignatureLineState();
}

class _SignatureLineState extends State<SignatureLine> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _t = ValueNotifier(ArtClock.value);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _t.value = ArtClock.value)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.active ? 1 : 0.14),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (context, amp, _) => SizedBox(
        height: widget.height,
        width: double.infinity,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _SignaturePainter(clock: _t, amp: amp, color: widget.color),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.clock, required this.amp, required this.color})
      : super(repaint: clock);

  final ValueNotifier<double> clock;
  final double amp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final rect = Offset.zero & size;
    final mid = size.height / 2;

    void trace(double cycles, int drift, double height, Paint paint) {
      final path = Path();
      for (var i = 0; i <= 120; i++) {
        final u = i / 120;
        final env = math.pow(math.sin(math.pi * u), 1.6).toDouble();
        final y = mid +
            size.height * 0.42 * height * amp * env *
                math.sin((u * cycles + t * drift * 12) * 2 * math.pi);
        i == 0 ? path.moveTo(0, y) : path.lineTo(u * size.width, y);
      }
      canvas.drawPath(path, paint);
    }

    Paint stroke(double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;

    trace(5, -2, 0.55, stroke(1)..color = color.withValues(alpha: 0.45));
    trace(3.5, 3, 0.35, stroke(1)..color = AppTheme.ivory.withValues(alpha: 0.25));
    trace(4, 4, 1, stroke(1.6)..shader = AppTheme.goldFoil.createShader(rect));
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.amp != amp || old.color != color;
}

/// Hairline track with a foil fill, a diamond thumb and tabular times.
class LuxuryProgress extends StatelessWidget {
  const LuxuryProgress({
    super.key,
    required this.progress,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final double progress;
  final Duration position;
  final Duration duration;
  final ValueChanged<double> onSeek;

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = duration - position;
    final times = mutedStyle.copyWith(
      fontSize: 11.5,
      color: AppTheme.taupe,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            void seek(Offset local) => onSeek(local.dx / constraints.maxWidth);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => seek(d.localPosition),
              onHorizontalDragUpdate: (d) => seek(d.localPosition),
              child: SizedBox(
                height: 26,
                width: double.infinity,
                child: CustomPaint(painter: _TrackPainter(progress)),
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(position), style: times),
            Text('−${_fmt(remaining.isNegative ? Duration.zero : remaining)}', style: times),
          ],
        ),
      ],
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final track = RRect.fromLTRBR(0, y - 1, size.width, y + 1, const Radius.circular(1));
    canvas.drawRRect(track, Paint()..color = AppTheme.ivory.withValues(alpha: 0.12));
    final x = size.width * progress.clamp(0.0, 1.0);
    if (x > 0) {
      canvas.drawRRect(
        RRect.fromLTRBR(0, y - 1, x, y + 1, const Radius.circular(1)),
        Paint()..shader = AppTheme.goldFoil.createShader(Offset.zero & size),
      );
    }
    canvas.drawCircle(
      Offset(x, y),
      12,
      Paint()
        ..shader = RadialGradient(
          colors: [AppTheme.champagne.withValues(alpha: 0.5), AppTheme.champagne.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 12)),
    );
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(const Rect.fromLTWH(-4.5, -4.5, 9, 9), Paint()..color = const Color(0xFFFFF4D6));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrackPainter old) => old.progress != progress;
}

/// Onyx play button inside a turning gold-foil ring.
class PlayRing extends StatelessWidget {
  const PlayRing({
    super.key,
    required this.playing,
    required this.onTap,
    required this.glow,
    required this.turn,
    this.size = 86,
  });

  final bool playing;
  final VoidCallback onTap;
  final Color glow;

  /// 0→1 loop that rotates the ring's sheen.
  final Animation<double> turn;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Pause' : 'Play',
      child: GestureDetector(
        key: const Key('play'),
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: playing ? 0.45 : 0.18),
                blurRadius: playing ? 40 : 20,
                spreadRadius: playing ? 2 : 0,
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: turn,
            builder: (context, child) => CustomPaint(
              painter: _RingPainter(turn.value * 2 * math.pi),
              child: child,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: ShaderMask(
                  key: ValueKey(playing),
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) => AppTheme.goldFoil.createShader(b),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: size * 0.46,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.angle);

  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFF26232C), Color(0xFF0B0A0E)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      r - 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = SweepGradient(
          colors: const [
            Color(0xFFA47A33),
            Color(0xFFFFF1C9),
            Color(0xFFC79A4B),
            Color(0xFFF7E3A6),
            Color(0xFFA47A33),
          ],
          transform: GradientRotation(angle),
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      r - 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = AppTheme.goldMid.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.angle != angle;
}

/// Small hairline-bordered toggle ("LOOP", "SLEEP 30M").
class LuxuryPill extends StatelessWidget {
  const LuxuryPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.champagne : AppTheme.taupe;
    return Semantics(
      button: true,
      toggled: active,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: active ? AppTheme.goldMid.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: AppTheme.goldMid.withValues(alpha: active ? 0.75 : 0.25), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(label, style: capsStyle(color: color, size: 9.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coherent-breathing guide that follows the player's breath controller.
class BreathCue extends StatelessWidget {
  const BreathCue({
    super.key,
    required this.breath,
    required this.active,
    this.inhale = 'Breathe in',
    this.exhale = 'Breathe out',
    this.idle = 'Coherent breathing · 6 breaths a minute',
  });

  final AnimationController breath;
  final bool active;
  final String inhale;
  final String exhale;
  final String idle;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breath,
      builder: (context, _) {
        final text = !active
            ? idle
            : (breath.status == AnimationStatus.reverse ? exhale : inhale);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          child: Text(
            text,
            key: ValueKey(text),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w500,
              fontSize: active ? 19 : 15,
              letterSpacing: 0.4,
              color: active ? AppTheme.champagne : AppTheme.taupe,
            ),
          ),
        );
      },
    );
  }
}

/// ◆ LABEL ◆ — the gold caps line under player titles.
class DiamondCaption extends StatelessWidget {
  const DiamondCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    Widget diamond() => Transform.rotate(
          angle: math.pi / 4,
          child: Container(width: 5, height: 5, color: AppTheme.goldMid),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        diamond(),
        const SizedBox(width: 10),
        Flexible(child: GoldText(text.toUpperCase(), style: capsStyle(size: 10.5))),
        const SizedBox(width: 10),
        diamond(),
      ],
    );
  }
}
