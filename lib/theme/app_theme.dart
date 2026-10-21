import 'package:flutter/material.dart';

import '../widgets/seamless_route.dart';

/// Deep-twilight meditation theme tuned for video demos.
class AppTheme {
  AppTheme._();

  // Onyx grounds (the private-collection look, app-wide).
  static const Color bgTop = Color(0xFF0B0A10);
  static const Color bgBottom = Color(0xFF100D18);
  static const Color surface = Color(0xFF15131B);
  static const Color surfaceLight = Color(0xFF1F1D27);
  static const Color violet = Color(0xFF8B7CF6);
  static const Color pink = Color(0xFFE879B8);
  static const Color teal = Color(0xFF5EEAD4);
  static const Color gold = Color(0xFFF6C77A);
  static const Color sky = Color(0xFF6EA8F6);
  static const Color amber = Color(0xFFF0956B);
  static const Color textPrimary = Color(0xFFF3EEE6);
  static const Color textMuted = Color(0xFFA9A3AE);

  // Private-collection palette: onyx, champagne gold and ivory.
  static const Color onyx = Color(0xFF07070A);
  static const Color onyxLight = Color(0xFF131218);
  static const Color champagne = Color(0xFFF3E2B3);
  static const Color goldMid = Color(0xFFD4AF6A);
  static const Color goldDeep = Color(0xFF9C7634);
  static const Color ivory = Color(0xFFF6F0E4);
  static const Color taupe = Color(0xFFA89F8D);
  static const Color prosper = Color(0xFF7FE0A8);

  /// Brushed gold foil — used for hairlines, numerals and the play ring.
  static const LinearGradient goldFoil = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB88A3E),
      Color(0xFFF7E3A6),
      Color(0xFFC79A4B),
      Color(0xFFFFF1C9),
      Color(0xFFA47A33),
    ],
    stops: [0, 0.28, 0.5, 0.72, 1],
  );

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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: DeckPageTransitionsBuilder(),
          TargetPlatform.iOS: DeckPageTransitionsBuilder(),
          TargetPlatform.macOS: DeckPageTransitionsBuilder(),
          TargetPlatform.linux: DeckPageTransitionsBuilder(),
          TargetPlatform.windows: DeckPageTransitionsBuilder(),
          TargetPlatform.fuchsia: DeckPageTransitionsBuilder(),
        },
      ),
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

/// Tracked small caps label ("NOW PLAYING", "FOR YOU").
TextStyle capsStyle({Color color = AppTheme.textMuted, double size = 11}) => TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w700,
      fontSize: size,
      letterSpacing: size * 0.28,
      color: color,
    );

/// Soft drop shadow that keeps white type legible over artwork.
const List<Shadow> textOnArt = [
  Shadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 2)),
];
