import 'package:flutter/material.dart';

import '../theme/card_styles.dart';

enum BreathMove { inhale, hold, exhale, rest }

/// One phase of a breathing pattern.
class BreathPhase {
  const BreathPhase(this.move, this.seconds, this.cue, {this.label, this.to, this.side, this.voice});

  final BreathMove move;
  final double seconds;

  /// What to do, said the way a teacher would.
  final String cue;

  /// Overrides the default title ("Inhale", "Hold" …).
  final String? label;

  /// Lung fullness (0–1) at the end of the phase; holds keep the level.
  final double? to;

  /// Nostril for alternate-nostril breathing ('left' / 'right').
  final String? side;

  /// What the voice guide says at the start of the phase.
  final String? voice;

  String get spoken =>
      voice ??
      switch (move) {
        BreathMove.inhale => 'Breathe in',
        BreathMove.exhale => 'Breathe out',
        _ => 'Hold',
      };

  String get title =>
      label ??
      switch (move) {
        BreathMove.inhale => 'Inhale',
        BreathMove.hold => 'Hold',
        BreathMove.exhale => 'Exhale',
        BreathMove.rest => 'Rest',
      };
}

/// How the guide draws the breath: a dot tracing a box, or a living orb.
enum BreathShape { box, orb }

class BreathPattern {
  const BreathPattern({
    required this.id,
    required this.name,
    required this.rhythm,
    required this.benefit,
    required this.why,
    required this.phases,
    required this.rounds,
    required this.color,
    required this.bestFor,
    required this.tone,
    this.shape = BreathShape.orb,
  });

  /// Soft tone bed for the session (an asset path).
  final String tone;

  final String id;
  final String name;

  /// The rhythm's own colour; every surface of the exercise derives from it.
  final Color color;

  /// "SLEEP", "FOCUS" … shown as the card's eyebrow.
  final String bestFor;

  /// e.g. "4 · 7 · 8".
  final String rhythm;
  final String benefit;

  /// Why it works, in one or two sentences.
  final String why;
  final List<BreathPhase> phases;
  final int rounds;
  final BreathShape shape;

  CardStyle get style => CardStyles.breathPattern(color);

  double get cycleSeconds => phases.fold(0, (sum, p) => sum + p.seconds);
  Duration get duration => Duration(milliseconds: (cycleSeconds * rounds * 1000).round());

  /// Lung fullness at the end of each phase.
  List<double> get levels {
    var level = 0.0;
    return [
      for (final p in phases)
        level = p.to ??
            switch (p.move) {
              BreathMove.inhale => 1.0,
              BreathMove.exhale => 0.0,
              _ => level,
            },
    ];
  }
}

/// A step in a guided ritual. Every step is shown as its own card.
sealed class RitualStep {
  const RitualStep({required this.title, required this.guidance});

  final String title;
  final String guidance;
}

class BreatheStep extends RitualStep {
  const BreatheStep({required super.title, required super.guidance, required this.seconds});
  final int seconds;
}

/// Free-text prompts; answers are kept in the journal under [kind].
class JournalStep extends RitualStep {
  const JournalStep({
    required super.title,
    required super.guidance,
    required this.kind,
    required this.hints,
  });

  final String kind;
  final List<String> hints;
}

/// Pick (and sharpen) the intention this ritual is for.
class IntentionStep extends RitualStep {
  const IntentionStep({required super.title, required super.guidance});
}

/// Tap to affirm each statement [reps] times. A null entry stands for the
/// person's focused intention.
class AffirmStep extends RitualStep {
  const AffirmStep({
    required super.title,
    required super.guidance,
    required this.affirmations,
    this.reps = 3,
  });

  final List<String?> affirmations;
  final int reps;
}

/// Timed walk through the five senses.
class VisualizeStep extends RitualStep {
  const VisualizeStep({
    required super.title,
    required super.guidance,
    required this.senses,
    this.secondsEach = 30,
  });

  final List<({String sense, String prompt})> senses;
  final int secondsEach;
}

/// Write a doubt, then let it dissolve.
class ReleaseStep extends RitualStep {
  const ReleaseStep({required super.title, required super.guidance});
}

enum VoiceKind { affirm, gratitude, om, hum }

/// A speaking practice: the app listens and the user completes it by
/// voice.
class VoicePractice {
  const VoicePractice({
    required this.kind,
    required this.name,
    required this.benefit,
    required this.how,
    required this.color,
    required this.minutes,
    this.icon,
    this.emblem,
  });

  final VoiceKind kind;
  final String name;
  final String benefit;

  /// One-line instruction shown before starting.
  final String how;
  final Color color;
  final int minutes;

  /// The medallion's glyph: an icon or a short word.
  final IconData? icon;
  final String? emblem;

  String get id => kind.name;
}

class Ritual {
  const Ritual({
    required this.id,
    required this.name,
    required this.eyebrow,
    required this.minutes,
    required this.style,
    required this.steps,
  });

  final String id;
  final String name;
  final String eyebrow;
  final int minutes;
  final CardStyle style;
  final List<RitualStep> steps;
}
