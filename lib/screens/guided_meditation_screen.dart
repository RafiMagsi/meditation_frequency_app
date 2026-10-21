
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class GuidedMeditationScreen extends StatefulWidget {
  const GuidedMeditationScreen({super.key});
  @override
  State<GuidedMeditationScreen> createState() => _GuidedMeditationScreenState();
}

class _GuidedMeditationScreenState extends State<GuidedMeditationScreen> {
  final _player = AudioPlayer();
  Duration _duration = Duration.zero, _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _player.positionStream.listen((pos) => setState(() => _position = pos));
    _player.durationStream.listen((dur) => setState(() => _duration = dur ?? Duration.zero));
  }

  Future<void> _initAudio() async {
    await _player.setAsset('assets/audio/sample_528hz.mp3');
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Guided Meditation')),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFEAF3FF),
              ),
              child: Center(child: Text('Wave Graphic', style: TextStyle(color: Colors.blueGrey[200]))),
            ),
            const SizedBox(height: 24),
            Slider(value: percent, onChanged: (v) => _player.seek(_duration * v)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_position.toString().split('.').first),
              Text(_duration.toString().split('.').first),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(icon: const Icon(Icons.skip_previous), iconSize: 36, onPressed: () {}),
              const SizedBox(width: 32),
              FloatingActionButton(onPressed: () => _player.playing ? _player.pause() : _player.play(), child: Icon(_player.playing ? Icons.pause : Icons.play_arrow)),
              const SizedBox(width: 32),
              IconButton(icon: const Icon(Icons.skip_next), iconSize: 36, onPressed: () {}),
            ]),
          ],
        ),
      ),
    );
  }
}
