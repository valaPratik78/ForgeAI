import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// Global notifier for theme mode.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.dark);

/// Application entry point.
void main() {
  runApp(const ForgeAIApp());
}

/// The root widget of the ForgeAI application.
/// Configures the global theme (Dark mode with Neon accents) and routing.
class ForgeAIApp extends StatelessWidget {
  const ForgeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'ForgeAI',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007BFF), // Modern Blue
              secondary: Color(0xFF5F00FF), // Violet
              surface: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
            ),
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.black,
              ),
              iconTheme: IconThemeData(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0E17),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00F0FF), // Neon Cyan
              secondary: Color(0xFF7000FF), // Neon Violet
              surface: Color(0xFF121624),
              onPrimary: Colors.black,
              onSecondary: Colors.white,
            ),
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
