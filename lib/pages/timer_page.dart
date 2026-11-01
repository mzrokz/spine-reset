import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  late final AudioPlayer _audioPlayer;
  bool _audioInitialized = false;
  static Duration defaultDuration = const Duration(minutes: 30);
  Duration remainingTime = defaultDuration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedDuration();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      // Ensure path_provider is initialized
      await getTemporaryDirectory();
      _audioPlayer = AudioPlayer();
      _audioInitialized = true;
    } catch (e) {
      debugPrint('Audio player initialization failed: $e');
      _audioInitialized = false;
    }
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
    if (_audioInitialized) {
      _audioPlayer.dispose();
    }
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
            // Play alarm sound for 10 seconds
            if (_audioInitialized) {
              () async {
                try {
                  await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
                  await Future.delayed(const Duration(seconds: 10));
                  await _audioPlayer.stop();
                } catch (e) {
                  debugPrint('Audio playback failed: $e');
                }
              }();
            }
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

  Future<void> resetTimer() async {
    await _loadSavedDuration();
    setState(() {
      timer?.cancel();
      remainingTime = defaultDuration;
      isRunning = false;
      isPaused = false;
    });
  }

  void adjustTime(int minutes) {
    setState(() {
      remainingTime += Duration(minutes: minutes);
    });
  }

  Widget _buildAdjustButtons() {
    const steps = [-5, -1, 1, 5, 10];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final step in steps)
          FilledButton.tonal(
            // Don't let subtracting run the timer down to zero or below.
            onPressed: step < 0 && remainingTime <= Duration(minutes: -step)
                ? null
                : () => adjustTime(step),
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: Text(step > 0 ? '+$step' : '−${-step}'),
          ),
      ],
    );
  }

  Widget _buildControls() {
    final timeUp = remainingTime.inSeconds == 0;
    final IconData icon;
    final String label;
    final VoidCallback onPressed;

    if (isPaused) {
      icon = Icons.play_arrow;
      label = 'Resume';
      onPressed = resumeTimer;
    } else if (isRunning) {
      icon = Icons.pause;
      label = 'Pause';
      onPressed = pauseTimer;
    } else {
      icon = Icons.play_arrow;
      label = 'Start';
      onPressed = () async {
        if (timeUp) await resetTimer();
        startTimer();
      };
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          icon: Icon(icon),
          label: Text(label),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(160, 56),
            textStyle: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
          onPressed:
              isRunning || remainingTime != defaultDuration ? resetTimer : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(140, 56),
            textStyle: const TextStyle(fontSize: 20),
          ),
        ),
      ],
    );
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
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
              if (!isRunning &&
                  remainingTime.inSeconds == defaultDuration.inSeconds) {
                _loadSavedDuration();
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          if (remainingTime.inSeconds == 0) {
            resetTimer();
            return; // Reset if time is up
          }
          if (!isRunning || isPaused) {
            startTimer();
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatTime(remainingTime),
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.25),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildAdjustButtons(),
              const SizedBox(height: 32),
              _buildControls(),
              if (isRunning && remainingTime.inSeconds == 0)
                const Text('Time\'s up!', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
