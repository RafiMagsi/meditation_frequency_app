
import 'dart:async';
import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int seconds = 60;
  Timer? timer;
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (seconds > 0) setState(() => seconds--);
      else timer?.cancel();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: Center(child: Text('\$seconds s', style: const TextStyle(fontSize: 48))),
      floatingActionButton: FloatingActionButton(onPressed: startTimer, child: const Icon(Icons.play_arrow)),
    );
  }
}
