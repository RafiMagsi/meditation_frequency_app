import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meditation.dart';
import '../services/practice_store.dart';
import '../services/tone_playback.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/ambient_background.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/card_face.dart';
import '../widgets/cosmic_video.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';
import '../widgets/luxury.dart';
import '../widgets/player_kit.dart';

/// The private-collection player: onyx, champagne gold and a watch-dial
/// bezel around the "jewel" — the tone orb, or the session artwork that
/// morphed in from its card.
///
/// For a guided [session] it becomes a teacher: the script plays as
/// timed captions, chapters are marked on the dial and the timeline, and
/// finishing the session counts toward the streak.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.audioPath,
    required this.color,
    required this.glow,
    required this.heroTag,
    this.scene,
  }) : session = null;

  PlayerScreen.session({super.key, required Meditation meditation, required this.heroTag})
      : session = meditation,
        title = meditation.title,
        subtitle = '${meditation.category} · ${meditation.minutes} min · ${meditation.hz} Hz',
        audioPath = meditation.audioPath,
        color = meditation.color,
        glow = Color.lerp(meditation.color, Colors.white, 0.35)!,
        scene = meditation.scene;

  final String title;

  /// Shown as the gold caps line, e.g. "Transform · Root chakra".
  final String subtitle;
  final String audioPath;
  final Color color;
  final Color glow;
  final String heroTag;

  /// Session artwork for the jewel; the tone orb is used when null.
  final Scene? scene;

  /// A guided session with a script, or null for a plain tone.
  final Meditation? session;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with TickerProviderStateMixin {
  late final TonePlayback _playback = TonePlayback(widget.audioPath)..init();

  /// Coherent breathing: 5 s in, 5 s out — six breaths a minute.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  /// Slow turn of the engraving and the play ring while playing.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  /// Seconds of the guided session listened to; advances only while playing.
  final ValueNotifier<double> _elapsed = ValueNotifier(0);
  Ticker? _sessionClock;
  Duration _lastTick = Duration.zero;
  bool _finished = false;
  bool _favourite = false;

  Meditation? get _session => widget.session;
  double get _total => (_session?.seconds ?? 1).toDouble();

  @override
  void initState() {
    super.initState();
    _playback.addListener(_syncTurn);
    if (_session != null) {
      _sessionClock = createTicker(_advance)..start();
    }
  }

  void _syncTurn() {
    if (_playback.playing && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!_playback.playing && _turn.isAnimating) {
      _turn.stop();
    }
  }

  void _advance(Duration now) {
    final dt = (now - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = now;
    if (!_playback.playing || _finished) return;
    _elapsed.value = math.min(_total, _elapsed.value + dt);
    if (_elapsed.value >= _total) _finish();
  }

  void _finish() {
    _finished = true;
    _playback.pause();
    HapticFeedback.heavyImpact();
    ref.read(practiceProvider.notifier).completeSession(_session!.id);
    setState(() {});
  }

  void _restartSession() {
    setState(() {
      _finished = false;
      _elapsed.value = 0;
    });
    _playback.play();
  }

  List<double> get _starts => _session?.chapterStarts ?? const [];

  int _chapterAt(double seconds) {
    var index = 0;
    for (var i = 0; i < _starts.length; i++) {
      if (_starts[i] * _total <= seconds + 0.01) index = i;
    }
    return index;
  }

  /// Previous jumps to the start of this chapter first (like a music
  /// player), then to the one before.
  void _skipChapter(int delta) {
    if (_finished) return;
    HapticFeedback.selectionClick();
    final current = _chapterAt(_elapsed.value);
    var target = current + delta;
    if (delta < 0 && _elapsed.value - _starts[current] * _total > 3) target = current;
    if (target >= _starts.length) {
      _elapsed.value = _total;
      _finish();
      return;
    }
    _elapsed.value = _starts[target.clamp(0, _starts.length - 1)] * _total;
  }

  @override
  void dispose() {
    _sessionClock?.dispose();
    _elapsed.dispose();
    _playback
      ..removeListener(_syncTurn)
      ..dispose();
    _breath.dispose();
    _turn.dispose();
    super.dispose();
  }

  Widget _jewel(double size) {
    final scene = widget.scene;
    if (scene != null) {
      return SizedBox.square(
        dimension: size,
        child: CardHero(
          tag: widget.heroTag,
          face: CardFace(
            style: CardStyles.session(scene),
            art: true,
            borderRadius: size / 2,
            padding: EdgeInsets.zero,
            scrim: 0,
            elevation: 0.9,
          ),
        ),
      );
    }
    return Hero(
      tag: widget.heroTag,
      child: BreathingOrb(
        size: size * 1.25,
        color: widget.color,
        glow: widget.glow,
        breathing: _playback.playing,
        breath: _breath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      backgroundColor: AppTheme.onyx,
      body: AmbientBackground(
        colors: const [Color(0xFF0E0C12), AppTheme.onyx, Color(0xFF0B0A0D)],
        accents: [widget.color, AppTheme.goldDeep],
        video: Cosmos.stars,
        videoOpacity: 0.45,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => ListenableBuilder(
              listenable: Listenable.merge([_playback, _elapsed]),
              builder: (context, _) {
                // Everything else is fixed height; the dial takes what's left.
                final reserved = session == null ? 470.0 : 500.0;
                final dial = math.min(constraints.maxHeight - reserved, constraints.maxWidth - 56).clamp(170.0, 320.0);
                final jewel = dial * 0.54;
                final playing = _playback.playing;
                final progress = session == null ? _playback.progress : _elapsed.value / _total;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      DeckItem(
                        index: 0,
                        child: PlayerTopBar(
                          label: session == null ? 'THE PRIVATE COLLECTION' : 'GUIDED · THE PRIVATE COLLECTION',
                          trailing: GlassIconButton(
                            icon: _favourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            active: _favourite,
                            activeColor: AppTheme.champagne,
                            borderColor: AppTheme.goldMid.withValues(alpha: 0.4),
                            semanticLabel: 'Favourite',
                            onTap: () => setState(() => _favourite = !_favourite),
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: Listenable.merge([_turn, _breath]),
                        child: RouteReveal(child: GalaxyWindow(size: dial, bright: playing)),
                        builder: (context, galaxy) {
                          final b = Curves.easeInOut.transform(_breath.value);
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              galaxy!,
                              RouteReveal(
                                child: GuillocheDial(
                                  size: dial,
                                  progress: progress,
                                  rotation: _turn.value * 2 * math.pi,
                                  innerRadiusFactor: 0.66,
                                  marks: _starts,
                                  plate: 0.18,
                                ),
                              ),
                              Transform.scale(
                                scale: widget.scene != null && playing ? 1 + 0.035 * b : 1,
                                child: _jewel(jewel),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: session == null ? 26 : 20),
                      DeckItem(
                        index: 1,
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'InterDisplay',
                                  fontWeight: FontWeight.w500,
                                  fontSize: (session == null ? 40 : 36) * 0.8,
                                  height: 1,
                                  letterSpacing: 0.3,
                                  color: AppTheme.ivory,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            DiamondCaption(widget.subtitle),
                            if (session == null) ...[
                              const SizedBox(height: 14),
                              BreathCue(breath: _breath, active: playing),
                            ],
                          ],
                        ),
                      ),
                      if (session != null) ...[
                        const SizedBox(height: 16),
                        DeckItem(
                          index: 2,
                          child: _finished
                              ? _SessionComplete(session: session, onAgain: _restartSession)
                              : _GuideCaption(
                                  session: session,
                                  elapsed: _elapsed.value,
                                  chapter: _chapterAt(_elapsed.value),
                                  started: playing || _elapsed.value > 0,
                                ),
                        ),
                      ],
                      const Spacer(),
                      if (session == null)
                        DeckItem(index: 2, child: SignatureLine(color: widget.color, active: playing)),
                      const SizedBox(height: 6),
                      DeckItem(
                        index: 3,
                        child: LuxuryProgress(
                          progress: progress,
                          position: session == null
                              ? _playback.position
                              : Duration(milliseconds: (_elapsed.value * 1000).round()),
                          duration: session == null ? _playback.duration : Duration(seconds: session.seconds),
                          marks: _starts,
                          onSeek: session == null
                              ? _playback.seekFraction
                              : (f) {
                                  if (!_finished) _elapsed.value = f.clamp(0.0, 0.999) * _total;
                                },
                        ),
                      ),
                      const SizedBox(height: 14),
                      DeckItem(
                        index: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlassIconButton(
                              icon: session == null ? Icons.replay_10_rounded : Icons.skip_previous_rounded,
                              size: 54,
                              borderColor: AppTheme.goldMid.withValues(alpha: 0.4),
                              semanticLabel: session == null ? 'Back 10 seconds' : 'Previous chapter',
                              onTap: session == null
                                  ? () => _playback.skip(const Duration(seconds: -10))
                                  : () => _skipChapter(-1),
                            ),
                            const SizedBox(width: 30),
                            PlayRing(
                              playing: playing,
                              glow: widget.color,
                              turn: _turn,
                              onTap: _finished ? _restartSession : _playback.toggle,
                            ),
                            const SizedBox(width: 30),
                            GlassIconButton(
                              icon: session == null ? Icons.forward_10_rounded : Icons.skip_next_rounded,
                              size: 54,
                              borderColor: AppTheme.goldMid.withValues(alpha: 0.4),
                              semanticLabel: session == null ? 'Forward 10 seconds' : 'Next chapter',
                              onTap: session == null
                                  ? () => _playback.skip(const Duration(seconds: 10))
                                  : () => _skipChapter(1),
                            ),
                          ],
                        ),
                      ),
                      if (session == null) ...[
                        const SizedBox(height: 18),
                        DeckItem(
                          index: 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              LuxuryPill(
                                icon: Icons.all_inclusive_rounded,
                                label: 'LOOP',
                                active: _playback.loop,
                                onTap: _playback.toggleLoop,
                              ),
                              const SizedBox(width: 10),
                              LuxuryPill(
                                icon: Icons.bedtime_outlined,
                                label: _playback.sleepMinutes == 0 ? 'SLEEP' : 'SLEEP ${_playback.sleepMinutes}M',
                                active: _playback.sleepMinutes > 0,
                                onTap: _playback.cycleSleepTimer,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The teacher's voice, as text: the current cue in large serif type,
/// with its chapter and a short progress rail through the chapters.
class _GuideCaption extends StatelessWidget {
  const _GuideCaption({
    required this.session,
    required this.elapsed,
    required this.chapter,
    required this.started,
  });

  final Meditation session;
  final double elapsed;
  final int chapter;
  final bool started;

  @override
  Widget build(BuildContext context) {
    final chapters = session.chapters;
    final total = session.seconds.toDouble();
    var cue = session.script.first;
    for (final c in session.script) {
      if (c.at * total <= elapsed + 0.01) cue = c;
    }
    final eyebrow = started
        ? 'CHAPTER ${chapter + 1} OF ${chapters.length} · ${chapters[chapter].toUpperCase()}'
        : 'READY · ${chapters.length} CHAPTERS · ${session.script.length} CUES';
    final text = started ? cue.text : 'Press play when you are settled. Headphones in, phone face down.';
    return Container(
      width: double.infinity,
      height: 128,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0.02)],
        ),
        border: Border.all(color: AppTheme.goldMid.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: capsStyle(color: AppTheme.goldMid, size: 9),
                ),
              ),
              const SizedBox(width: 8),
              for (var i = 0; i < chapters.length; i++)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: i == chapter && started ? 14 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: started && i <= chapter ? AppTheme.champagne : AppTheme.goldMid.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 900),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.18), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Text(
                text,
                key: ValueKey(text),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'InterDisplay',
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  height: 1.22,
                  color: AppTheme.ivory,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionComplete extends ConsumerWidget {
  const _SessionComplete({required this.session, required this.onAgain});

  final Meditation session;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(practiceProvider.select((s) => s.streak));
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.goldMid.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.goldMid.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SESSION COMPLETE · DAY $streak', style: capsStyle(color: AppTheme.goldMid, size: 9)),
          const SizedBox(height: 8),
          const Text(
            'Stay a moment. Notice how you feel.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'InterDisplay',
              fontWeight: FontWeight.w500,
              fontSize: 17,
              height: 1.2,
              color: AppTheme.ivory,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              LuxuryPill(icon: Icons.replay_rounded, label: 'AGAIN', onTap: onAgain),
              const SizedBox(width: 10),
              LuxuryPill(
                icon: Icons.check_rounded,
                label: 'DONE',
                active: true,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
