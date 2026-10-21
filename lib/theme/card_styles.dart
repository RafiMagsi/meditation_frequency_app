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
/// first — it anchors the text corner), glow colour, a photo and/or
/// painted artwork.
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
    this.image,
  });

  final List<Color> colors;
  final Color glow;

  /// Painted art; also the fallback when [image] can't be shown.
  final Scene scene;
  final Color foreground;

  /// CC0 photograph (see assets/images/cards/CREDITS.md).
  final String? image;

  Color get muted => foreground.withValues(alpha: 0.82);

  /// Full illustrations and photos get the stronger legibility scrim.
  bool get hasArt => image != null || scene.isArt;

  @override
  bool operator ==(Object other) =>
      other is CardStyle &&
      other.scene == scene &&
      other.glow == glow &&
      other.foreground == foreground &&
      other.image == image &&
      _sameColors(other.colors, colors);

  @override
  int get hashCode => Object.hash(scene, glow, foreground, image, Object.hashAll(colors));

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
    glow: Color(0xFF9B87F5),
    scene: Scene.cosmos,
    image: 'assets/images/cards/cosmos.jpg',
  );
  static const guided = CardStyle(
    colors: [Color(0xFF082224), Color(0xFF1C6B6E), Color(0xFF8FD8C2)],
    glow: Color(0xFF5FD3A6),
    scene: Scene.forest,
    image: 'assets/images/cards/forest.jpg',
  );
  static const mood = CardStyle(
    colors: [Color(0xFF14061C), Color(0xFF2E1240), Color(0xFF5A1F52)],
    glow: Color(0xFFE879B8),
    scene: Scene.aurora,
    image: 'assets/images/cards/aurora.jpg',
  );
  static const timer = CardStyle(
    colors: [Color(0xFF0B1530), Color(0xFF233A78), Color(0xFF7A8FD0)],
    glow: Color(0xFF6EA8F6),
    scene: Scene.ocean,
    image: 'assets/images/cards/ocean.jpg',
  );
  static const meter = CardStyle(
    colors: [Color(0xFF0E0B30), Color(0xFF2B2270), Color(0xFF151040)],
    glow: Color(0xFFC9D2E3),
    scene: Scene.mandala,
  );
  static const progress = CardStyle(
    colors: [Color(0xFF3A2808), Color(0xFF6E5216), Color(0xFFC99A45)],
    glow: Color(0xFFF0B46B),
    scene: Scene.chart,
  );
  static const playlists = CardStyle(
    colors: [Color(0xFF3A0F2A), Color(0xFF7A2F58), Color(0xFFD86FA8)],
    glow: Color(0xFFE8957A),
    scene: Scene.vinyl,
  );

  /// Guided-session artwork, keyed by scene.
  static CardStyle session(Scene scene) => switch (scene) {
        Scene.dawn => const CardStyle(
            colors: [Color(0xFF35183F), Color(0xFFB8577A), Color(0xFFFFD79A)],
            glow: AppTheme.gold,
            scene: Scene.dawn,
            image: 'assets/images/cards/dawn.jpg',
          ),
        Scene.lake => const CardStyle(
            colors: [Color(0xFF0F0B2A), Color(0xFF35297A), Color(0xFF7C6BD8)],
            glow: AppTheme.violet,
            scene: Scene.lake,
            image: 'assets/images/cards/lake.jpg',
          ),
        Scene.breeze => const CardStyle(
            colors: [Color(0xFF0B3440), Color(0xFF1D7A80), Color(0xFF7FDCCB)],
            glow: AppTheme.teal,
            scene: Scene.breeze,
            image: 'assets/images/cards/breeze.jpg',
          ),
        Scene.lotus => const CardStyle(
            colors: [Color(0xFF2A0A24), Color(0xFF7A2560), Color(0xFFD0609E)],
            glow: AppTheme.pink,
            scene: Scene.lotus,
            image: 'assets/images/cards/lotus.jpg',
          ),
        Scene.night => const CardStyle(
            colors: [Color(0xFF040817), Color(0xFF0C1A44), Color(0xFF1E3A78)],
            glow: AppTheme.sky,
            scene: Scene.night,
            image: 'assets/images/cards/night.jpg',
          ),
        _ => const CardStyle(
            colors: [Color(0xFF2A120A), Color(0xFF6E2E16), Color(0xFFE8885A)],
            glow: AppTheme.amber,
            scene: Scene.focus,
            image: 'assets/images/cards/focus.jpg',
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

  /// A breath rhythm's card: a deep, luminous field of its own colour.
  static CardStyle breathPattern(Color color) => CardStyle(
        colors: [
          Color.lerp(color, const Color(0xFF05060F), 0.86)!,
          Color.lerp(color, const Color(0xFF05060F), 0.62)!,
          Color.lerp(color, const Color(0xFF05060F), 0.3)!,
        ],
        glow: color,
        scene: Scene.engraved,
      );

  /// Onyx card with banknote-style engraving for money frequencies.
  static const money = CardStyle(
    colors: [Color(0xFF0B0A08), Color(0xFF15120C), Color(0xFF221B10)],
    glow: AppTheme.goldMid,
    scene: Scene.engraved,
    foreground: AppTheme.ivory,
  );

  static const ritualMorning = CardStyle(
    colors: [Color(0xFF2A1430), Color(0xFF9A4A5E), Color(0xFFF2B37A)],
    glow: Color(0xFFFFC38A),
    scene: Scene.dawn,
    image: 'assets/images/cards/ritual_morning.jpg',
  );
  static const ritualEvening = CardStyle(
    colors: [Color(0xFF070B1E), Color(0xFF1A2456), Color(0xFF4B3C8C)],
    glow: Color(0xFF8C8CF0),
    scene: Scene.night,
    image: 'assets/images/cards/ritual_evening.jpg',
  );
  static const breath = CardStyle(
    colors: [Color(0xFF062A30), Color(0xFF13606A), Color(0xFF7FD0C4)],
    glow: Color(0xFF7DD3FC),
    scene: Scene.breeze,
    image: 'assets/images/cards/breath.jpg',
  );
  static const innerLake = CardStyle(
    colors: [Color(0xFF0B1620), Color(0xFF2C4352), Color(0xFF9DB2BC)],
    glow: Color(0xFF9FD3E6),
    scene: Scene.lake,
    image: 'assets/images/cards/inner_lake.jpg',
  );

  static const voice = CardStyle(
    colors: [Color(0xFF1E0F14), Color(0xFF5A2A34), Color(0xFFD99A8C)],
    glow: Color(0xFFE8B4A0),
    scene: Scene.waves,
  );

  /// Every photo, for precaching before the first flight.
  static List<String> get photos => [
        for (final s in [
          frequencies,
          guided,
          mood,
          timer,
          ritualMorning,
          ritualEvening,
          breath,
          innerLake,
          for (final scene in const [Scene.dawn, Scene.lake, Scene.breeze, Scene.lotus, Scene.night, Scene.focus])
            session(scene),
        ])
          if (s.image != null) s.image!,
      ];

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
