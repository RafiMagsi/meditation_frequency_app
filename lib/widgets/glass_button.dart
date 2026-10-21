import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Round frosted-glass icon button used in every top bar.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.activeColor = AppTheme.teal,
    this.size = 44,
    this.borderColor,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;
  final double size;

  /// Hairline colour; gold in the private-collection players.
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.16),
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: size * 0.45,
            color: active ? activeColor : Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

/// The back button every feature screen uses (keyed for tests).
class BackGlassButton extends StatelessWidget {
  const BackGlassButton({super.key, this.icon = Icons.arrow_back_ios_new_rounded, this.borderColor});

  final IconData icon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      key: const Key('back'),
      icon: icon,
      borderColor: borderColor,
      semanticLabel: 'Back',
      onTap: () => Navigator.of(context).maybePop(),
    );
  }
}
