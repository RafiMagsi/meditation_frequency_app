import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/card_styles.dart';
import 'card_face.dart';
import 'deck.dart';

/// A pressable card: it sinks on touch (iOS-like) and — given a
/// [heroTag] — morphs seamlessly into the next screen while the rest of
/// the deck slides away.
class GlowCard extends StatefulWidget {
  const GlowCard({
    super.key,
    required this.style,
    required this.onTap,
    required this.child,
    this.heroTag,
    this.height,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(18),
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
  final Alignment contentAlignment;
  final String? semanticLabel;

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 280),
  );

  @override
  void dispose() {
    _press.dispose();
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
