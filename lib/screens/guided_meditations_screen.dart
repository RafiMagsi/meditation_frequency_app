import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class GuidedMeditationsScreen extends ConsumerWidget {
  const GuidedMeditationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meditations = ref.watch(meditationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Guided Meditations')),
      body: ListView.builder(
        itemCount: meditations.length,
        itemBuilder: (_, idx) {
          final m = meditations[idx];
          return ListTile(
              title: Text(m.title),
              subtitle: Text(m.description),
              onTap: () {
                // play guided meditation
              });
        },
      ),
    );
  }
}
