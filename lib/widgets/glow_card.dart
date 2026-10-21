import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'gloss.dart';

/// A pressable gradient card with a glassy finish: it scales down on
/// touch (iOS-like feel), a sheen sweeps across every few seconds, and
/// it flies seamlessly into the next screen via Hero.
class GlowCard extends StatefulWidget {
  const GlowCard({
    super.key,
    required this.child,
    required this.onTap,
    this.gradientColors,
    this.heroTag,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.all(20),
    this.glowColor,
    this.sheenEnabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final List<Color>? gradientColors;
  final String? heroTag;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final bool sheenEnabled;

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard>
    with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 260),
  );

  /// Slow loop driving the glossy sheen sweep.
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (widget.sheenEnabled) _sheen.repeat();
  }

  @override
  void dispose() {
    _press.dispose();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedBuilder(
      animation: Listenable.merge([_press, _sheen]),
      builder: (context, child) {
        final scale = 1 - 0.045 * Curves.easeOut.transform(_press.value);
        // Band travels from -0.2 to 1.2 over the loop; painter hides
        // it outside (0, 1) so the card rests between sweeps.
        final sheenPos = widget.sheenEnabled ? _sheen.value * 1.4 - 0.2 : -1.0;
        return Transform.scale(
          scale: scale,
          child: GlossOverlay(
            borderRadius: widget.borderRadius,
            sheen: sheenPos,
            child: child!,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradientColors == null
                ? null
                : LinearGradient(
                    colors: widget.gradientColors!,
                    // Dark end anchors the text corner (bottom-left),
                    // light end sits at the top-right like a light source.
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
            color: widget.gradientColors == null ? AppTheme.surface : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: (widget.glowColor ?? AppTheme.violet)
                    .withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: card);
    }
    return card;
  }
}
