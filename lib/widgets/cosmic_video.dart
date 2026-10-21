import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The app's cosmic films. nebula, galaxy and stars were rendered for this
/// app: calm, seamless loops without audio. The supplied films are cut
/// montages with a soundtrack, which always plays muted.
enum Cosmos {
  /// Violet and teal gas clouds, brightest in the upper half.
  nebula('assets/videos/nebula.mp4'),

  /// A square, face-on spiral galaxy that turns half a revolution per loop.
  galaxy('assets/videos/galaxy.mp4'),

  /// A slow parallax star field across a faint Milky Way band.
  stars('assets/videos/stars.mp4'),

  /// Supplied film: a flight from a galaxy through a starry cave into
  /// glowing nebulae; it ends on a bright cyan cloud.
  flight('assets/videos/Vid2.mp4'),

  /// Supplied film: spiral galaxies, blue nebula clouds and star fields.
  galaxies('assets/videos/Vid3.mp4');

  const Cosmos(this.asset);

  final String asset;
}

/// A silent, looping cosmic film that fades in once it is ready. It is
/// opaque and dimmed toward black by [opacity], so it belongs on a dark
/// background.
///
/// Screens showing the same film share one decoder, so the sky carries on
/// unbroken through a card→screen transition. The film pauses whenever no
/// visible screen shows it (a covered route turns its tickers off).
class CosmicVideo extends StatefulWidget {
  const CosmicVideo(
    this.cosmos, {
    super.key,
    this.opacity = 1,
    this.alignment = Alignment.center,
  });

  final Cosmos cosmos;
  final double opacity;

  /// Which part of the film stays in view when it is cropped to cover.
  final Alignment alignment;

  /// Widget tests have no platform video decoder, so they turn films off
  /// (which also skips the film intro).
  static bool enabled = true;

  static final Map<Cosmos, _Film> _films = {};

  @override
  State<CosmicVideo> createState() => _CosmicVideoState();
}

class _Film {
  _Film(Cosmos cosmos)
      : controller = VideoPlayerController.asset(
          cosmos.asset,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        ) {
    ready = () async {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      _sync();
    }();
  }

  final VideoPlayerController controller;
  late final Future<void> ready;
  int holders = 0;
  int showing = 0;

  void _sync() {
    if (!controller.value.isInitialized) return;
    showing > 0 ? controller.play() : controller.pause();
  }
}

class _CosmicVideoState extends State<CosmicVideo> {
  _Film? _film;
  bool _showing = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (CosmicVideo.enabled) _acquire();
  }

  void _acquire() {
    final film = CosmicVideo._films.putIfAbsent(widget.cosmos, () => _Film(widget.cosmos))..holders += 1;
    _film = film;
    _ready = film.controller.value.isInitialized;
    film.ready.then((_) {
      if (mounted && _film == film) setState(() => _ready = true);
    }, onError: (Object _) {});
  }

  void _release(Cosmos cosmos) {
    final film = _film;
    if (film == null) return;
    _film = null;
    if (_showing) film.showing--;
    _showing = false;
    film._sync();
    if (--film.holders == 0) {
      CosmicVideo._films.remove(cosmos);
      film.controller.dispose();
    }
  }

  void _syncShowing() {
    final film = _film;
    if (film == null) return;
    final showing = TickerMode.valuesOf(context).enabled;
    if (showing == _showing) return;
    _showing = showing;
    film.showing += showing ? 1 : -1;
    film._sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncShowing();
  }

  @override
  void didUpdateWidget(CosmicVideo old) {
    super.didUpdateWidget(old);
    if (old.cosmos != widget.cosmos && _film != null) {
      _release(old.cosmos);
      _acquire();
      _syncShowing();
    }
  }

  @override
  void dispose() {
    _release(widget.cosmos);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final film = _film;
    final size = film?.controller.value.size ?? Size.zero;
    final visible = _ready && film != null && !size.isEmpty;
    if (!visible) return const SizedBox.expand();
    // Dimmed and faded in with a colour filter rather than an opacity layer:
    // Impeller can't pass inherited opacity into a video texture.
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.opacity),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOut,
        builder: (context, o, child) => ColorFiltered(
          colorFilter: ColorFilter.mode(
              Color.fromARGB(255, (o * 255).round(), (o * 255).round(), (o * 255).round()), BlendMode.modulate),
          child: child,
        ),
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: widget.alignment,
            child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(film.controller)),
          ),
        ),
      ),
    );
  }
}
