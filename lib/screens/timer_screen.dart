import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glass_button.dart';

/// Breathing focus timer: a tide circle that inhales and exhales (4 s
/// each) while the session counts down.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  static const _presets = [5, 10, 15, 20];
  static const _tide = AppTheme.sky;
  int _minutes = 10;
  int _secondsLeft = 10 * 60;
  bool _running = false;
  Timer? _ticker;

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ticker?.cancel();
    _breath.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _ticker?.cancel();
        setState(() {
          _secondsLeft = 0;
          _running = false;
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _secondsLeft = _minutes * 60;
    });
  }

  void _pick(int minutes) {
    HapticFeedback.selectionClick();
    _ticker?.cancel();
    setState(() {
      _minutes = minutes;
      _secondsLeft = minutes * 60;
      _running = false;
    });
  }

  String _fmt(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _minutes * 60;
    final progress = total == 0 ? 0.0 : 1 - (_secondsLeft / total);
    return FeatureScaffold(
      accent: _tide,
      header: FeatureHeader(
        heroTag: 'card-timer',
        style: CardStyles.timer,
        height: 124,
        title: 'Focus Timer',
        subtitle: _running ? 'Breathe with the tide' : 'Set your session',
      ),
      body: Column(
        children: [
          const Spacer(),
          SizedBox(
            width: 260,
            height: 260,
            child: AnimatedBuilder(
              animation: _breath,
              builder: (context, _) {
                final pulse = Curves.easeInOut.transform(_breath.value);
                final scale = _running ? 0.84 + 0.16 * pulse : 1.0;
                final inhaling = _breath.status == AnimationStatus.forward;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 236,
                        height: 236,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _tide.withValues(alpha: 0.32 + 0.14 * pulse),
                              _tide.withValues(alpha: 0.06),
                              _tide.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.7, 1],
                          ),
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 236,
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: progress,
                          color: _tide,
                          trackColor: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmt(_secondsLeft),
                          style: const TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontWeight: FontWeight.w600,
                            fontSize: 58,
                            height: 1,
                            color: AppTheme.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _running ? (inhaling ? 'INHALE' : 'EXHALE') : 'OF $_minutes:00',
                            key: ValueKey(_running ? inhaling : null),
                            style: capsStyle(color: _running ? _tide : AppTheme.textMuted, size: 10.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Spacer(),
          Row(
            children: [
              for (final m in _presets) ...[
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: _minutes == m,
                    label: '$m minutes',
                    child: GestureDetector(
                      onTap: () => _pick(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: _minutes == m
                                ? const [Color(0xFF1C2E66), Color(0xFF4A78C8)]
                                : const [Color(0xFF12152B), Color(0xFF1B1F3D)],
                          ),
                          border: Border.all(
                            color: _minutes == m ? _tide.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.08),
                          ),
                          boxShadow: _minutes == m
                              ? [BoxShadow(color: _tide.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$m',
                              style: TextStyle(
                                fontFamily: 'CormorantGaramond',
                                fontWeight: FontWeight.w600,
                                fontSize: 22,
                                height: 1,
                                color: _minutes == m ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            Text('MIN', style: capsStyle(color: _minutes == m ? Colors.white70 : AppTheme.textMuted, size: 8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (m != _presets.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassIconButton(icon: Icons.refresh_rounded, size: 56, semanticLabel: 'Reset', onTap: _reset),
              const SizedBox(width: 24),
              Semantics(
                button: true,
                label: _running ? 'Pause' : 'Start',
                child: GestureDetector(
                  onTap: _toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [Color(0xFF2E4680), Color(0xFF7DB4FA)],
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: _tide.withValues(alpha: _running ? 0.55 : 0.3),
                          blurRadius: _running ? 36 : 20,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        key: ValueKey(_running),
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 80),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = trackColor,
    );
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color.withValues(alpha: 0.4), color, Colors.white],
          stops: const [0, 0.85, 1],
          endAngle: math.max(sweep, 0.01),
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}
