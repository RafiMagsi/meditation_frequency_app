
import 'package:flutter/material.dart';
import 'frequency_library_screen.dart';
import 'guided_meditations_screen.dart';
import 'playlist_screen.dart';
import 'timer_screen.dart';
import 'progress_screen.dart';
import 'mood_screen.dart';
import 'frequency_meter_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meditation & Frequency')),
      body: ListView(
        children: [
          ListTile(title: const Text('Frequency Library'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FrequencyLibraryScreen()))),
          ListTile(title: const Text('Guided Meditations'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidedMeditationsScreen()))),
          ListTile(title: const Text('Custom Playlists'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistScreen()))),
          ListTile(title: const Text('Timer'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerScreen()))),
          ListTile(title: const Text('Progress & Mood Tracking'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()))),
          ListTile(title: const Text('Mood-based Suggestions'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodScreen()))),
          ListTile(title: const Text('Frequency Meter'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FrequencyMeterScreen()))),
        ],
      ),
    );
  }
}
