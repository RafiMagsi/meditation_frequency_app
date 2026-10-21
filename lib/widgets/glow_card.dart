import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A pressable gradient card that scales down on touch (iOS-like feel)
/// and optionally flies seamlessly into the next screen via Hero.
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
  });

  final Widget child;
  final VoidCallback onTap;
  final List<Color>? gradientColors;
  final String? heroTag;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 260),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 - 0.045 * Curves.easeOut.transform(_controller.value);
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.gradientColors == null ? AppTheme.surface : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: (widget.glowColor ?? AppTheme.violet).withValues(alpha: 0.18),
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
