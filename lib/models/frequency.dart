import 'package:flutter/material.dart';

/// A healing frequency tone with its visual identity.
class Frequency {
  const Frequency({
    required this.hz,
    required this.name,
    required this.description,
    required this.audioPath,
    required this.color,
    required this.glow,
  });

  final String hz;
  final String name;
  final String description;
  final String audioPath;
  final Color color;
  final Color glow;
}
