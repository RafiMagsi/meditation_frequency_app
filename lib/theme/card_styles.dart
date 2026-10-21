import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Painted artwork a card can carry. Art scenes are full illustrations
/// (and get a legibility scrim); decor scenes are light ornaments laid
/// over a plain colour card.
enum Scene {
  cosmos,
  forest,
  aurora,
  ocean,
  dawn,
  lake,
  breeze,
  lotus,
  night,
  focus,
  mandala,
  gold,
  chart,
  vinyl,
  waves,
  engraved,
  none;

  bool get isArt => index <= Scene.gold.index;
}

/// The visual identity of one card type: background gradient (darkest
/// first — it anchors the text corner), glow colour and artwork.
///
/// Every style keeps its text on a dark ground so white/ivory type
/// clears WCAG AA, with a scrim on top of art for extra margin.
@immutable
class CardStyle {
  const CardStyle({
    required this.colors,
    required this.glow,
    this.scene = Scene.none,
    this.foreground = Colors.white,
  });

  final List<Color> colors;
  final Color glow;
  final Scene scene;
  final Color foreground;

  Color get muted => foreground.withValues(alpha: 0.82);

  @override
  bool operator ==(Object other) =>
      other is CardStyle &&
      other.scene == scene &&
      other.glow == glow &&
      other.foreground == foreground &&
      _sameColors(other.colors, colors);

  @override
  int get hashCode => Object.hash(scene, glow, foreground, Object.hashAll(colors));

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One style per card type, so the same card looks identical on the hub,
/// mid-flight and as the header it lands in.
abstract final class CardStyles {
  static const abundance = CardStyle(
    colors: [Color(0xFF0A0908), Color(0xFF17130C), Color(0xFF2E2412)],
    glow: AppTheme.goldMid,
    scene: Scene.gold,
    foreground: AppTheme.ivory,
  );
  static const frequencies = CardStyle(
    colors: [Color(0xFF140E40), Color(0xFF2A1F7A), Color(0xFF6B54E0)],
    glow: AppTheme.violet,
    scene: Scene.cosmos,
  );
  static const guided = CardStyle(
    colors: [Color(0xFF082224), Color(0xFF1C6B6E), Color(0xFF8FD8C2)],
    glow: AppTheme.teal,
    scene: Scene.forest,
  );
  static const mood = CardStyle(
    colors: [Color(0xFF14061C), Color(0xFF2E1240), Color(0xFF5A1F52)],
    glow: AppTheme.pink,
    scene: Scene.aurora,
  );
  static const timer = CardStyle(
    colors: [Color(0xFF0B1530), Color(0xFF233A78), Color(0xFF7A8FD0)],
    glow: AppTheme.sky,
    scene: Scene.ocean,
  );
  static const meter = CardStyle(
    colors: [Color(0xFF0E0B30), Color(0xFF2B2270), Color(0xFF151040)],
    glow: AppTheme.violet,
    scene: Scene.mandala,
  );
  static const progress = CardStyle(
    colors: [Color(0xFF3A2808), Color(0xFF6E5216), Color(0xFFC99A45)],
    glow: AppTheme.gold,
    scene: Scene.chart,
  );
  static const playlists = CardStyle(
    colors: [Color(0xFF3A0F2A), Color(0xFF7A2F58), Color(0xFFD86FA8)],
    glow: AppTheme.pink,
    scene: Scene.vinyl,
  );

  /// Guided-session artwork, keyed by scene.
  static CardStyle session(Scene scene) => switch (scene) {
        Scene.dawn => const CardStyle(
            colors: [Color(0xFF35183F), Color(0xFFB8577A), Color(0xFFFFD79A)],
            glow: AppTheme.gold,
            scene: Scene.dawn,
          ),
        Scene.lake => const CardStyle(
            colors: [Color(0xFF0F0B2A), Color(0xFF35297A), Color(0xFF7C6BD8)],
            glow: AppTheme.violet,
            scene: Scene.lake,
          ),
        Scene.breeze => const CardStyle(
            colors: [Color(0xFF0B3440), Color(0xFF1D7A80), Color(0xFF7FDCCB)],
            glow: AppTheme.teal,
            scene: Scene.breeze,
          ),
        Scene.lotus => const CardStyle(
            colors: [Color(0xFF2A0A24), Color(0xFF7A2560), Color(0xFFD0609E)],
            glow: AppTheme.pink,
            scene: Scene.lotus,
          ),
        Scene.night => const CardStyle(
            colors: [Color(0xFF040817), Color(0xFF0C1A44), Color(0xFF1E3A78)],
            glow: AppTheme.sky,
            scene: Scene.night,
          ),
        _ => const CardStyle(
            colors: [Color(0xFF2A120A), Color(0xFF6E2E16), Color(0xFFE8885A)],
            glow: AppTheme.amber,
            scene: Scene.focus,
          ),
      };

  /// A tone card tinted by its frequency colour, with live sine decor.
  static CardStyle tone(Color color) => CardStyle(
        colors: [
          Color.lerp(color, Colors.black, 0.82)!,
          Color.lerp(color, Colors.black, 0.6)!,
          Color.lerp(color, Colors.black, 0.3)!,
        ],
        glow: color,
        scene: Scene.waves,
      );

  /// Onyx card with banknote-style engraving for money frequencies.
  static const money = CardStyle(
    colors: [Color(0xFF0B0A08), Color(0xFF15120C), Color(0xFF221B10)],
    glow: AppTheme.goldMid,
    scene: Scene.engraved,
    foreground: AppTheme.ivory,
  );

  /// Plain onyx for notes and rituals in the abundance space.
  static const onyx = CardStyle(
    colors: [Color(0xFF0E0C09), Color(0xFF16130D), Color(0xFF221C11)],
    glow: AppTheme.goldDeep,
    foreground: AppTheme.ivory,
  );

  /// Neutral glass card for utility content (stats, chips, notes).
  static CardStyle glass(Color accent) => CardStyle(
        colors: [
          const Color(0xFF12142A),
          Color.lerp(const Color(0xFF171A33), accent, 0.12)!,
          Color.lerp(const Color(0xFF1D2040), accent, 0.28)!,
        ],
        glow: accent,
      );
}
