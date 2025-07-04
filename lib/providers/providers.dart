
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/frequency.dart';
import '../models/meditation.dart';

final frequencyProvider = Provider<List<Frequency>>((_) => [
  Frequency(hz: '396', description: 'Liberating guilt and fear', audioPath: 'assets/audio/sample_396hz.mp3'),
  Frequency(hz: '528', description: 'Transformation & miracles', audioPath: 'assets/audio/sample_528hz.mp3'),
]);

final meditationProvider = Provider<List<Meditation>>((_) => [
  Meditation(title: 'Relaxation', description: 'Guided relaxation session', audioPath: 'assets/audio/sample_396hz.mp3'),
]);

final playlistProvider = StateNotifierProvider<PlaylistNotifier, List<String>>((_) => PlaylistNotifier());

final moodProvider = StateProvider<String>((_) => 'Calm');

class PlaylistNotifier extends StateNotifier<List<String>> {
  PlaylistNotifier() : super([]);
  void add(String m) => state = [...state, m];
  void remove(String m) => state = state.where((e) => e != m).toList();
}
