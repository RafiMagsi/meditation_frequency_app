import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: ListView(
        children: playlist
            .map((m) => ListTile(
                title: Text(m),
                trailing:
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => ref.read(playlistProvider.notifier).remove(m))))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            ref.read(playlistProvider.notifier).add('New Meditation');
          },
          child: const Icon(Icons.add)),
    );
  }
}
