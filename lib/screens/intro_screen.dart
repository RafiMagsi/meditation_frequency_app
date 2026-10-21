import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';
import 'welcome_screen.dart';

/// The cinematic opener: the supplied planets film (Vid1) plays once,
/// muted, and dissolves into the welcome as it fades to black. A tap skips.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  static const asset = 'assets/videos/Vid1.mp4';

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final VideoPlayerController _film = VideoPlayerController.asset(
    IntroScreen.asset,
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
  late final Timer _stall;
  bool _ready = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // If the film can't start promptly, nobody should be kept waiting.
    _stall = Timer(const Duration(seconds: 3), () {
      if (!_ready) _leave();
    });
    _start();
  }

  Future<void> _start() async {
    try {
      await _film.initialize();
      await _film.setVolume(0);
      if (!mounted || _left) return;
      _film.addListener(_onFilm);
      setState(() => _ready = true);
      await _film.play();
    } catch (_) {
      _leave();
    }
  }

  void _onFilm() {
    final v = _film.value;
    if (v.isCompleted || (v.duration > Duration.zero && v.position >= v.duration)) _leave();
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 900),
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stall.cancel();
    _film.removeListener(_onFilm);
    _film.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _film.value.size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        key: const Key('intro'),
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready && !size.isEmpty)
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(_film)),
                ),
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: AnimatedOpacity(
                    opacity: _ready ? 1 : 0,
                    duration: const Duration(milliseconds: 1200),
                    child: Text('TAP TO SKIP', style: capsStyle(color: Colors.white.withValues(alpha: 0.45), size: 9.5)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
