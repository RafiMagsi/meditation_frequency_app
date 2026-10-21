
import 'package:flutter/material.dart';

class FrequencyListScreen extends StatelessWidget {
  const FrequencyListScreen({super.key});
  final List<Map<String, String>> _freqs = const [
    {'hz': '396 Hz', 'desc': 'Liberating guilt and fear'},
    {'hz': '417 Hz', 'desc': 'Undoing situations & facilitating change'},
    {'hz': '528 Hz', 'desc': 'Transformation and miracles'},
    {'hz': '639 Hz', 'desc': 'Connecting relationships'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequencies')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _freqs.length,
        itemBuilder: (context, i) {
          final f = _freqs[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(f['hz']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(f['desc']!),
              onTap: () => Navigator.pushNamed(context, '/meditation'),
            ),
          );
        },
      ),
    );
  }
}
