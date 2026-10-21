
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8F0), Color(0xFFF7EDE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset('assets/images/meditation_illustration.png', width: 200),
              const SizedBox(height: 24),
              const Text(
                'MEDITATION\n& FREQUENCY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2A2E43),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Get Started', style: TextStyle(fontSize: 18)),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
