import 'package:flutter/material.dart';

import '../theme/card_styles.dart';

/// One spoken-style instruction in a guided session, shown as a caption.
class GuideCue {
  const GuideCue(this.at, this.chapter, this.text);

  /// When it appears, as a fraction (0–1) of the session.
  final double at;

  /// Chapter it belongs to ("Arrive", "Body scan" …).
  final String chapter;
  final String text;
}

/// A guided meditation session with its own timed script.
class Meditation {
  const Meditation({
    required this.id,
    required this.title,
    required this.description,
    required this.audioPath,
    required this.hz,
    required this.minutes,
    required this.icon,
    required this.color,
    required this.scene,
    required this.category,
    required this.level,
    required this.script,
  });

  final String id;
  final String title;
  final String description;
  final String audioPath;

  /// The tone that carries the session.
  final String hz;
  final int minutes;
  final IconData icon;
  final Color color;

  /// Card artwork for the session.
  final Scene scene;

  /// Sleep, Calm, Focus, Heart or Morning.
  final String category;
  final String level;
  final List<GuideCue> script;

  int get seconds => minutes * 60;

  /// Chapter names in order of appearance.
  List<String> get chapters => [
        for (var i = 0; i < script.length; i++)
          if (i == 0 || script[i].chapter != script[i - 1].chapter) script[i].chapter,
      ];

  /// Where each chapter starts, as a fraction of the session.
  List<double> get chapterStarts => [
        for (var i = 0; i < script.length; i++)
          if (i == 0 || script[i].chapter != script[i - 1].chapter) script[i].at,
      ];
}
