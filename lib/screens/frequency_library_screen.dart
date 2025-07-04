import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class FrequencyLibraryScreen extends ConsumerWidget {
  const FrequencyLibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequencies = ref.watch(frequencyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Frequency Library')),
      body: ListView.builder(
        itemCount: frequencies.length,
        itemBuilder: (_, idx) {
          final freq = frequencies[idx];
          return ListTile(
            title: Text('${freq.hz} Hz'),
            subtitle: Text(freq.description),
            onTap: () {
              // play sample
            },
          );
        },
      ),
    );
  }
}
