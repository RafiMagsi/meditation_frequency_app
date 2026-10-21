import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/intro_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/cosmic_video.dart';

void main() {
  runApp(const ProviderScope(child: MeditationApp()));
}

class MeditationApp extends StatelessWidget {
  const MeditationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meditation & Frequency',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // The film intro needs the platform video decoder (off in tests).
      home: CosmicVideo.enabled ? const IntroScreen() : const WelcomeScreen(),
    );
  }
}
