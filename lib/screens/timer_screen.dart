import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Breathing focus timer: a circle that inhales/exhales while counting.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  static const _presets = [5, 10, 15, 20];
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

  String _fmt(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _minutes * 60;
    final progress = total == 0 ? 0.0 : 1 - (_secondsLeft / total);
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF101B3E), Color(0xFF0A0E27)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      key: const Key('back'),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Focus Timer',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 34,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(_running ? 'Breathe with the circle' : 'Set your session',
                  style: mutedStyle.copyWith(fontSize: 13)),
              const Spacer(),
              // Breathing ring + countdown.
              SizedBox(
                width: 260,
                height: 260,
                child: AnimatedBuilder(
                  animation: _breath,
                  builder: (context, _) {
                    final pulse = Curves.easeInOut.transform(_breath.value);
                    final scale = _running ? 0.86 + 0.14 * pulse : 1.0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 230,
                            height: 230,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF6EA8F6).withValues(alpha: 0.28 + 0.12 * (pulse)),
                                  const Color(0xFF6EA8F6).withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 230,
                          height: 230,
                          child: CustomPaint(
                            painter: _RingPainter(
                              progress: progress,
                              color: const Color(0xFF6EA8F6),
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
                                fontSize: 56,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text('of $_minutes:00', style: mutedStyle.copyWith(fontSize: 12)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),
              // Presets.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final m in _presets)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: GestureDetector(
                        onTap: () {
                          _ticker?.cancel();
                          setState(() {
                            _minutes = m;
                            _secondsLeft = m * 60;
                            _running = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: _minutes == m
                                ? const LinearGradient(
                                    colors: [Color(0xFF2E4680), Color(0xFF5490E0)])
                                : null,
                            color: _minutes == m ? null : AppTheme.surface,
                          ),
                          child: Text(
                            '$m min',
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _minutes == m ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 22),
                  GestureDetector(
                    onTap: _toggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFF3D5A9E), Color(0xFF6EA8F6)]),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6EA8F6)
                                .withValues(alpha: _running ? 0.55 : 0.3),
                            blurRadius: _running ? 36 : 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
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
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963268,
      6.2831853072 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
