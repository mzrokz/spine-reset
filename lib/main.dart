import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const defaultDuration = Duration(minutes: 30);
  Duration remainingTime = defaultDuration;
  Timer? timer;
  bool isRunning = false;
  bool isPaused = false;

  void startTimer() {
    setState(() {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingTime.inSeconds > 0) {
            remainingTime -= const Duration(seconds: 1);
          } else {
            timer.cancel();
            isRunning = false;
            isPaused = false;
          }
        });
      });
      isRunning = true;
      isPaused = false;
    });
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() {
      isPaused = true;
    });
  }

  void resumeTimer() {
    setState(() {
      startTimer();
    });
  }

  void stopTimer() {
    setState(() {
      timer?.cancel();
      isRunning = false;
      isPaused = false;
    });
  }

  void resetTimer() {
    setState(() {
      timer?.cancel();
      remainingTime = defaultDuration;
      isRunning = false;
      isPaused = false;
    });
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Timer'),
      ),
      body: GestureDetector(
        onTap: () {
          if (isRunning) {
            stopTimer();
          } else {
            startTimer();
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatTime(remainingTime),
                style: const TextStyle(fontSize: 48),
              ),
              if (isRunning || isPaused)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      onPressed: () {
                        if (isPaused) {
                          resumeTimer();
                        } else {
                          pauseTimer();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: resetTimer,
                    ),
                  ],
                ),
              if (isRunning && remainingTime.inSeconds == 0)
                const Text('Time\'s up!', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
