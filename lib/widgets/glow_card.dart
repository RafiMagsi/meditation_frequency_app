import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/card_styles.dart';
import 'card_face.dart';
import 'deck.dart';

/// A pressable card: it sinks on touch (iOS-like), a gloss sweep passes
/// over it every few seconds, and — given a [heroTag] — it morphs
/// seamlessly into the next screen while the rest of the deck slides away.
class GlowCard extends StatefulWidget {
  const GlowCard({
    super.key,
    required this.style,
    required this.onTap,
    required this.child,
    this.heroTag,
    this.height,
    this.borderRadius = 26,
    this.padding = const EdgeInsets.all(18),
    this.sheenEnabled = true,
    this.contentAlignment = Alignment.bottomLeft,
    this.semanticLabel,
  });

  final CardStyle style;
  final VoidCallback onTap;
  final Widget child;
  final Object? heroTag;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool sheenEnabled;
  final Alignment contentAlignment;
  final String? semanticLabel;

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard> with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 280),
  );

  /// One gloss sweep. It only runs during a sweep (every ~7 s, offset per
  /// card so the deck doesn't flash in unison), so idle cards cost nothing.
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  Timer? _sheenTimer;

  @override
  void initState() {
    super.initState();
    if (widget.sheenEnabled) {
      final offset = 1200 + ((widget.heroTag ?? widget.semanticLabel).hashCode % 4000);
      _sheenTimer = Timer(Duration(milliseconds: offset), () {
        _sweep();
        _sheenTimer = Timer.periodic(const Duration(seconds: 7), (_) => _sweep());
      });
    }
  }

  void _sweep() => _sheen.forward(from: 0);

  @override
  void dispose() {
    _sheenTimer?.cancel();
    _press.dispose();
    _sheen.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Ignore taps while a transition is running (no double pushes).
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    DeckItem.markActive(context);
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final face = CardFace(
      style: widget.style,
      borderRadius: widget.borderRadius,
      padding: widget.padding,
      sheen: widget.sheenEnabled ? _sheen : null,
      contentAlignment: widget.contentAlignment,
      child: widget.child,
    );
    final body = widget.heroTag == null ? face : CardHero(tag: widget.heroTag!, face: face);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) => Transform.scale(
            scale: 1 - 0.04 * Curves.easeOut.transform(_press.value),
            child: child,
          ),
          child: SizedBox(height: widget.height, child: body),
        ),
      ),
    );
  }
}
