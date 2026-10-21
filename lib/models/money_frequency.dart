/// A wealth-manifestation tone: frequency, intention and the binaural
/// layer baked into its audio.
class MoneyFrequency {
  const MoneyFrequency({
    required this.hz,
    required this.name,
    required this.intention,
    required this.description,
    required this.audioPath,
    required this.minutes,
    required this.emblem,
  });

  /// Display value, e.g. '888' or '183.58'.
  final String hz;
  final String name;

  /// The affirmation the tone is built around.
  final String intention;
  final String description;
  final String audioPath;
  final int minutes;

  /// Glyph struck on the coin face ('888', '183' …).
  final String emblem;
}
