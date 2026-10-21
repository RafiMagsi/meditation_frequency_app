import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/waveform.dart';

/// Immersive full-screen player. Plays the real bundled tone; if audio
/// fails on a platform it falls back to a simulated timeline so the
/// demo never breaks.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.audioPath,
    required this.color,
    required this.glow,
    required this.heroTag,
    this.icon = Icons.waves_rounded,
  });

  final String title;
  final String subtitle;
  final String audioPath;
  final Color color;
  final Color glow;
  final String heroTag;
  final IconData icon;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  AudioPlayer? _player;
  bool _playing = false;
  bool _loop = true;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 48);
  Timer? _simulated;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final player = AudioPlayer();
      final duration = await player.setAsset(widget.audioPath);
      await player.setLoopMode(LoopMode.all);
      player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
      player.playerStateStream.listen((state) {
        if (mounted) setState(() => _playing = state.playing);
      });
      _player = player;
      if (duration != null && mounted) setState(() => _duration = duration);
    } catch (_) {
      // Audio unavailable here — drive a simulated timeline instead.
      _startSimulated();
    }
  }

  void _startSimulated() {
    _simulated?.cancel();
    _simulated = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || !_playing) return;
      setState(() {
        _position += const Duration(milliseconds: 500);
        if (_position > _duration) {
          _position = _loop ? Duration.zero : _duration;
          if (!_loop) _playing = false;
        }
      });
    });
  }

  Future<void> _toggle() async {
    final player = _player;
    if (player != null) {
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
      if (mounted) setState(() => _playing = player.playing);
    } else {
      setState(() => _playing = !_playing);
    }
  }

  Future<void> _seek(double fraction) async {
    final target = _duration * fraction;
    await _player?.seek(target);
    if (mounted) setState(() => _position = target);
  }

  @override
  void dispose() {
    _simulated?.cancel();
    _player?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fraction =
        _duration.inMilliseconds == 0 ? 0.0 : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: AmbientBackground(
        colors: const [Color(0xFF0A0E27), Color(0xFF14102E), Color(0xFF1D1240)],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _GlassButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    Text('NOW PLAYING',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 3,
                          color: AppTheme.textMuted.withValues(alpha: 0.9),
                        )),
                    const Spacer(),
                    _GlassButton(
                      icon: Icons.loop_rounded,
                      active: _loop,
                      onTap: () => setState(() => _loop = !_loop),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // The orb is the hero that flew in from the tapped card.
              Hero(
                tag: widget.heroTag,
                child: BreathingOrb(
                  size: 250,
                  color: widget.color,
                  glow: widget.glow,
                  breathing: _playing,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                '${widget.title} · ${widget.subtitle}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Waveform(color: widget.glow, active: _playing),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: widget.color,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                    thumbColor: widget.glow,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: fraction,
                    onChanged: _seek,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position), style: mutedStyle.copyWith(fontSize: 12)),
                    Text(_fmt(_duration), style: mutedStyle.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GlassButton(
                    icon: Icons.replay_rounded,
                    onTap: () => _seek(0),
                  ),
                  const SizedBox(width: 26),
                  // Play/pause morph button.
                  GestureDetector(
                    onTap: _toggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [widget.color, widget.glow],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: _playing ? 0.55 : 0.3),
                            blurRadius: _playing ? 38 : 22,
                            spreadRadius: _playing ? 4 : 0,
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey(_playing),
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                  _GlassButton(
                    icon: Icons.fast_forward_rounded,
                    onTap: () => _seek((fraction + 0.2).clamp(0.0, 1.0)),
                  ),
                ],
              ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap, this.active = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(
          icon,
          size: 22,
          color: active ? AppTheme.teal : Colors.white70,
        ),
      ),
    );
  }
}
