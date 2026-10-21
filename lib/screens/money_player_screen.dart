import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/money_frequency.dart';
import '../providers/providers.dart';
import '../services/tone_playback.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/ambient_background.dart';
import '../widgets/card_face.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';
import '../widgets/luxury.dart';
import '../widgets/player_kit.dart';

/// Wealth-manifestation player. Same private-collection craft as the main
/// player, with money indications: a gold market ticker, a coin that
/// spins on its edge while the tone plays, an Abundance Index that climbs
/// as you listen, and affirmations that advance with every breath.
class MoneyPlayerScreen extends ConsumerStatefulWidget {
  const MoneyPlayerScreen({super.key, required this.frequency});

  final MoneyFrequency frequency;

  @override
  ConsumerState<MoneyPlayerScreen> createState() => _MoneyPlayerScreenState();
}

class _MoneyPlayerScreenState extends ConsumerState<MoneyPlayerScreen>
    with TickerProviderStateMixin {
  late final TonePlayback _playback = TonePlayback(widget.frequency.audioPath)..init();

  /// Coherent breathing, 5 s in / 5 s out; each new inhale turns the
  /// affirmation.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  /// One full coin revolution.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  int _affirmation = 0;
  final List<double> _index = [];
  late final double _openingIndex;
  Timer? _market;

  @override
  void initState() {
    super.initState();
    // A gently rising opening history for the sparkline.
    final rng = math.Random(int.tryParse(widget.frequency.hz.split('.').first) ?? 8);
    var v = 10000.0;
    for (var i = 0; i < 28; i++) {
      v *= 1 + 0.0007 + (rng.nextDouble() - 0.45) * 0.004;
      _index.add(v);
    }
    _openingIndex = _index.first;
    _breath.addStatusListener(_onBreath);
    _playback.addListener(_onPlayback);
  }

  void _onBreath(AnimationStatus status) {
    if (status == AnimationStatus.forward && _playback.playing && mounted) {
      setState(() => _affirmation++);
    }
  }

  void _onPlayback() {
    final playing = _playback.playing;
    if (playing && !_spin.isAnimating) {
      _spin.repeat();
      _turn.repeat();
      _market ??= Timer.periodic(const Duration(milliseconds: 450), (_) => _tickMarket());
    } else if (!playing && _market != null) {
      _market?.cancel();
      _market = null;
      _turn.stop();
      // Finish the turn so the coin rests face-up.
      _spin.animateTo(1, duration: Duration(milliseconds: (1400 * (1 - _spin.value)).round() + 200))
          .whenComplete(() {
        if (mounted && !_playback.playing) _spin.value = 0;
      });
    }
  }

  /// Abundance Index while listening: an up-trending walk (≈ +0.15% per tick).
  void _tickMarket() {
    if (!mounted) return;
    final rng = math.Random();
    setState(() {
      _index.add(_index.last * (1 + 0.0015 + (rng.nextDouble() - 0.42) * 0.003));
      if (_index.length > 48) _index.removeAt(0);
    });
  }

  @override
  void dispose() {
    _market?.cancel();
    _breath
      ..removeStatusListener(_onBreath)
      ..dispose();
    _playback
      ..removeListener(_onPlayback)
      ..dispose();
    _spin.dispose();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.frequency;
    final affirmations = [f.intention, ...ref.watch(affirmationsProvider)];

    return Scaffold(
      backgroundColor: AppTheme.onyx,
      body: AmbientBackground(
        colors: const [Color(0xFF110E08), AppTheme.onyx, Color(0xFF0B0A08)],
        accents: const [AppTheme.goldMid, AppTheme.goldDeep],
        particleCount: 16,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dial = math.min(constraints.maxHeight - 520, constraints.maxWidth - 80).clamp(150.0, 262.0);
              return ListenableBuilder(
                listenable: _playback,
                builder: (context, _) {
                  final playing = _playback.playing;
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: DeckItem(index: 0, child: PlayerTopBar(label: 'ABUNDANCE · ${f.hz} HZ')),
                      ),
                      const SizedBox(height: 12),
                      DeckItem(index: 1, child: _MarketTicker(playing: playing)),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: Listenable.merge([_spin, _turn, _breath]),
                        builder: (context, _) {
                          final sway = playing ? 0.0 : 0.22 * (Curves.easeInOut.transform(_breath.value) - 0.5);
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              RouteReveal(
                                child: GuillocheDial(
                                  size: dial,
                                  progress: _playback.progress,
                                  rotation: _turn.value * 2 * math.pi,
                                  innerRadiusFactor: 0.7,
                                ),
                              ),
                              Hero(
                                tag: 'coin-${f.hz}',
                                child: GoldCoin(
                                  size: dial * 0.56,
                                  emblem: f.emblem,
                                  spin: _spin.value * 2 * math.pi + sway,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      DeckItem(
                        index: 2,
                        child: Column(
                          children: [
                            GoldText(
                              '${f.hz} Hz',
                              style: const TextStyle(
                                fontFamily: 'CormorantGaramond',
                                fontWeight: FontWeight.w600,
                                fontSize: 38,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DiamondCaption(f.name),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: DeckItem(
                          index: 3,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 52,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 900),
                                  switchInCurve: Curves.easeOutCubic,
                                  transitionBuilder: (child, anim) => FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                                      child: child,
                                    ),
                                  ),
                                  child: Text(
                                    '“${affirmations[_affirmation % affirmations.length]}”',
                                    key: ValueKey(_affirmation % affirmations.length),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontFamily: 'CormorantGaramond',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 21,
                                      height: 1.15,
                                      color: AppTheme.ivory,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              BreathCue(
                                breath: _breath,
                                active: playing,
                                inhale: 'Inhale — I receive',
                                exhale: 'Exhale — thank you',
                                idle: 'Headphones on · 7.83 Hz Schumann layer',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            DeckItem(
                              index: 4,
                              child: _AbundanceIndex(points: _index, opening: _openingIndex, live: playing),
                            ),
                            const SizedBox(height: 10),
                            DeckItem(
                              index: 5,
                              child: LuxuryProgress(
                                progress: _playback.progress,
                                position: _playback.position,
                                duration: _playback.duration,
                                onSeek: _playback.seekFraction,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DeckItem(
                              index: 6,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GlassIconButton(
                                    icon: Icons.all_inclusive_rounded,
                                    size: 50,
                                    active: _playback.loop,
                                    activeColor: AppTheme.champagne,
                                    borderColor: AppTheme.goldMid.withValues(alpha: 0.4),
                                    semanticLabel: 'Loop',
                                    onTap: _playback.toggleLoop,
                                  ),
                                  const SizedBox(width: 30),
                                  PlayRing(
                                    playing: playing,
                                    glow: AppTheme.goldMid,
                                    turn: _turn,
                                    size: 80,
                                    onTap: _playback.toggle,
                                  ),
                                  const SizedBox(width: 30),
                                  GlassIconButton(
                                    icon: _playback.sleepMinutes == 0 ? Icons.bedtime_outlined : Icons.bedtime_rounded,
                                    size: 50,
                                    active: _playback.sleepMinutes > 0,
                                    activeColor: AppTheme.champagne,
                                    borderColor: AppTheme.goldMid.withValues(alpha: 0.4),
                                    semanticLabel: 'Sleep timer',
                                    onTap: _playback.cycleSleepTimer,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
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

/// A gold market tape of good fortune, scrolling like a trading floor.
class _MarketTicker extends StatefulWidget {
  const _MarketTicker({required this.playing});

  final bool playing;

  @override
  State<_MarketTicker> createState() => _MarketTickerState();
}

class _MarketTickerState extends State<_MarketTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _scroll = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  static const _items = [
    ('ABUNDANCE', '8.88'),
    ('PROSPERITY', '7.77'),
    ('GRATITUDE', '5.28'),
    ('FORTUNE', '4.32'),
    ('FLOW', '1.83'),
    ('GENEROSITY', '6.39'),
  ];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppTheme.goldMid.withValues(alpha: 0.22), width: 0.6),
        ),
        color: AppTheme.goldMid.withValues(alpha: 0.04),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _scroll,
          builder: (context, _) => CustomPaint(
            size: const Size(double.infinity, 30),
            painter: _TickerPainter(offset: _scroll.value, items: _items, live: widget.playing),
          ),
        ),
      ),
    );
  }
}

class _TickerPainter extends CustomPainter {
  const _TickerPainter({required this.offset, required this.items, required this.live});

  final double offset;
  final List<(String, String)> items;
  final bool live;

  @override
  void paint(Canvas canvas, Size size) {
    final spans = <InlineSpan>[];
    for (final (name, change) in items) {
      spans
        ..add(TextSpan(text: '$name  ', style: capsStyle(color: AppTheme.champagne, size: 10)))
        ..add(TextSpan(text: '▲ ', style: _glyph(live ? AppTheme.prosper : AppTheme.taupe, 10)))
        ..add(TextSpan(
          text: '$change%',
          style: capsStyle(color: live ? AppTheme.prosper : AppTheme.taupe, size: 10),
        ))
        ..add(TextSpan(text: '     ◆     ', style: _glyph(AppTheme.goldDeep, 9)));
    }
    final painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    )..layout();
    final y = (size.height - painter.height) / 2;
    var x = -offset * painter.width;
    while (x < size.width) {
      painter.paint(canvas, Offset(x, y));
      x += painter.width;
    }
  }

  @override
  bool shouldRepaint(_TickerPainter old) => old.offset != offset || old.live != live;
}

/// ▲ and ◆ exist in Cormorant but not in Quicksand.
TextStyle _glyph(Color color, double size) =>
    TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w700, fontSize: size, color: color);

/// The Abundance Index: a value that climbs while the tone plays, its
/// change since the session opened, and a gold sparkline.
class _AbundanceIndex extends StatelessWidget {
  const _AbundanceIndex({required this.points, required this.opening, required this.live});

  final List<double> points;
  final double opening;
  final bool live;

  static String _money(double v) {
    final whole = v.floor();
    final cents = ((v - whole) * 100).round().clamp(0, 99).toString().padLeft(2, '0');
    final digits = whole.toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }
    return '$grouped.$cents';
  }

  @override
  Widget build(BuildContext context) {
    final value = points.last;
    final change = (value / opening - 1) * 100;
    return SizedBox(
      height: 78,
      child: CardFace(
        style: CardStyles.money,
        borderRadius: 20,
        elevation: 0.5,
        scrim: 0,
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            Flexible(
              flex: 3,
              child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text('ABUNDANCE INDEX', style: capsStyle(color: AppTheme.taupe, size: 9)),
                    const SizedBox(width: 6),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: live ? 1 : 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppTheme.prosper, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GoldText(
                      _money(value),
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontWeight: FontWeight.w600,
                        fontSize: 27,
                        height: 1,
                        fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.prosper.withValues(alpha: 0.12),
                      ),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '▲ ', style: _glyph(AppTheme.prosper, 10)),
                          TextSpan(
                            text: '${change.abs().toStringAsFixed(2)}%',
                            style: capsStyle(color: AppTheme.prosper, size: 9.5).copyWith(letterSpacing: 0.5),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: CustomPaint(painter: _SparklinePainter(points))),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.points);

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.isEmpty) return;
    final lo = points.reduce(math.min), hi = points.reduce(math.max);
    final span = (hi - lo).abs() < 1e-6 ? 1.0 : hi - lo;
    Offset at(int i) => Offset(
          size.width * i / (points.length - 1),
          size.height * (0.9 - 0.8 * (points[i] - lo) / span),
        );
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.goldMid.withValues(alpha: 0.28), AppTheme.goldMid.withValues(alpha: 0)],
        ).createShader(rect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..shader = AppTheme.goldFoil.createShader(rect),
    );
    final last = at(points.length - 1);
    canvas.drawCircle(
      last,
      7,
      Paint()
        ..shader = RadialGradient(
          colors: [AppTheme.champagne.withValues(alpha: 0.7), AppTheme.champagne.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: last, radius: 7)),
    );
    canvas.drawCircle(last, 2.4, Paint()..color = const Color(0xFFFFF4D6));
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => true;
}
