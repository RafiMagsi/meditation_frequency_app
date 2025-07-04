import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class MoodScreen extends ConsumerWidget {
  const MoodScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Suggestions')),
      body: Center(child: Text('Current mood: \$mood')),
    );
  }
}
