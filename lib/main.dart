import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/settings_page.dart';
import 'pages/timer_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('timer_minutes')) {
    await prefs.setInt('timer_minutes', 30);
  }
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
      initialRoute: '/',
      routes: {
        '/': (context) => const TimerPage(),
        '/settings': (context) => const SettingsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/settings') {
          return MaterialPageRoute(
            builder: (context) => const SettingsPage(),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
