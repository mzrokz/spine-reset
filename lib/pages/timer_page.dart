import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  Duration defaultDuration = const Duration(minutes: 30);
  Duration remainingTime = const Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedDuration();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSavedDuration();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMinutes = prefs.getInt('timer_minutes');
    if (savedMinutes != null) {
      setState(() {
        defaultDuration = Duration(minutes: savedMinutes);
        remainingTime = defaultDuration;
      });
    } else {
      remainingTime = defaultDuration;
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              _loadSavedDuration();
            },
          ),
        ],
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
