
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('playlists');
  await Hive.openBox('progress');
  runApp(const ProviderScope(child: MeditationApp()));
}

class MeditationApp extends StatelessWidget {
  const MeditationApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meditation & Frequency',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const HomeScreen(),
    );
  }
}
