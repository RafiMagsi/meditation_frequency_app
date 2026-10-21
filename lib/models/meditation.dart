import 'package:flutter/material.dart';

/// A guided meditation session.
class Meditation {
  const Meditation({
    required this.title,
    required this.description,
    required this.audioPath,
    required this.minutes,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String audioPath;
  final int minutes;
  final IconData icon;
  final Color color;
}
