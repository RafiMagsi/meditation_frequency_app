import 'package:flutter/material.dart';

import '../theme/card_styles.dart';

/// A guided meditation session.
class Meditation {
  const Meditation({
    required this.title,
    required this.description,
    required this.audioPath,
    required this.hz,
    required this.minutes,
    required this.icon,
    required this.color,
    required this.scene,
  });

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
}
