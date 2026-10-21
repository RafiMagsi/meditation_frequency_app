import 'package:flutter/material.dart';

/// Deep-twilight meditation theme tuned for video demos.
class AppTheme {
  AppTheme._();

  static const Color bgTop = Color(0xFF0A0E27);
  static const Color bgBottom = Color(0xFF1B1038);
  static const Color surface = Color(0xFF171A33);
  static const Color surfaceLight = Color(0xFF232745);
  static const Color violet = Color(0xFF8B7CF6);
  static const Color pink = Color(0xFFE879B8);
  static const Color teal = Color(0xFF5EEAD4);
  static const Color gold = Color(0xFFF6C77A);
  static const Color textPrimary = Color(0xFFF4F1FF);
  static const Color textMuted = Color(0xFFA9A3C7);

  static const LinearGradient background = LinearGradient(
    colors: [bgTop, bgBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: bgTop,
      colorScheme: const ColorScheme.dark(
        primary: violet,
        secondary: pink,
        surface: surface,
        onSurface: textPrimary,
      ),
      fontFamily: 'Quicksand',
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
        fontFamily: 'Quicksand',
      ),
    );
  }
}

/// Elegant display headline style (Cormorant Garamond).
const TextStyle displayStyle = TextStyle(
  fontFamily: 'CormorantGaramond',
  fontWeight: FontWeight.w600,
  color: AppTheme.textPrimary,
  height: 1.05,
);

const TextStyle mutedStyle = TextStyle(
  fontFamily: 'Quicksand',
  fontWeight: FontWeight.w500,
  color: AppTheme.textMuted,
);
