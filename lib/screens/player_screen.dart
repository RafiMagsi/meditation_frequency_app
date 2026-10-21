import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/tone_playback.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/ambient_background.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/card_face.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';
import '../widgets/luxury.dart';
import '../widgets/player_kit.dart';

/// The private-collection player: onyx, champagne gold and a watch-dial
/// bezel around the "jewel" — the tone orb, or the session artwork that
/// morphed in from its card. A coherent-breathing guide (5 s in, 5 s out)
/// paces the jewel and the cue beneath the title.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.audioPath,
    required this.color,
    required this.glow,
    required this.heroTag,
    this.scene,
  });

  final String title;

  /// Shown as the gold caps line, e.g. "Transform · Root chakra".
  final String subtitle;
  final String audioPath;
  final Color color;
  final Color glow;
  final String heroTag;

  /// Session artwork for the jewel; the tone orb is used when null.
  final Scene? scene;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
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

  bool _favourite = false;

  @override
  void initState() {
    super.initState();
    _playback.addListener(_syncTurn);
  }

  void _syncTurn() {
    if (_playback.playing && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!_playback.playing && _turn.isAnimating) {
      _turn.stop();
    }
  }

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: AppTheme.onyx,
      body: AmbientBackground(
        colors: const [Color(0xFF0E0C12), AppTheme.onyx, Color(0xFF0B0A0D)],
        accents: [widget.color, AppTheme.goldDeep],
        particleCount: 12,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => ListenableBuilder(
              listenable: _playback,
              builder: (context, _) {
                // Everything else is fixed height; the dial takes what's left.
                final dial = math.min(constraints.maxHeight - 470, constraints.maxWidth - 56).clamp(170.0, 320.0);
                final jewel = dial * 0.54;
                final playing = _playback.playing;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      DeckItem(
                        index: 0,
                        child: PlayerTopBar(
                          label: 'THE PRIVATE COLLECTION',
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
                        builder: (context, _) {
                          final b = Curves.easeInOut.transform(_breath.value);
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              RouteReveal(
                                child: GuillocheDial(
                                  size: dial,
                                  progress: _playback.progress,
                                  rotation: _turn.value * 2 * math.pi,
                                  innerRadiusFactor: 0.66,
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
                      const SizedBox(height: 26),
                      DeckItem(
                        index: 1,
                        child: Column(
                          children: [
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'CormorantGaramond',
                                fontWeight: FontWeight.w500,
                                fontSize: 40,
                                height: 1,
                                letterSpacing: 0.3,
                                color: AppTheme.ivory,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DiamondCaption(widget.subtitle),
                            const SizedBox(height: 14),
                            BreathCue(breath: _breath, active: playing),
                          ],
                        ),
                      ),
                      const Spacer(),
                      DeckItem(index: 2, child: SignatureLine(color: widget.color, active: playing)),
                      const SizedBox(height: 6),
                      DeckItem(
                        index: 3,
                        child: LuxuryProgress(
                          progress: _playback.progress,
                          position: _playback.position,
                          duration: _playback.duration,
                          onSeek: _playback.seekFraction,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DeckItem(
                        index: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlassIconButton(
                              icon: Icons.replay_10_rounded,
                              size: 54,
                              borderColor: AppTheme.goldMid.withValues(alpha: 0.4),
                              semanticLabel: 'Back 10 seconds',
                              onTap: () => _playback.skip(const Duration(seconds: -10)),
                            ),
                            const SizedBox(width: 30),
                            PlayRing(
                              playing: playing,
                              glow: widget.color,
                              turn: _turn,
                              onTap: _playback.toggle,
                            ),
                            const SizedBox(width: 30),
                            GlassIconButton(
                              icon: Icons.forward_10_rounded,
                              size: 54,
                              borderColor: AppTheme.goldMid.withValues(alpha: 0.4),
                              semanticLabel: 'Forward 10 seconds',
                              onTap: () => _playback.skip(const Duration(seconds: 10)),
                            ),
                          ],
                        ),
                      ),
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
