import 'package:flutter/material.dart';
import 'package:gameflix/hub/splash_screen.dart'; 
void main() {
  runApp(const GameFlixApp());
}

class GameFlixApp extends StatelessWidget {
  const GameFlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameFlix',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurple,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.pinkAccent,
        )
      ),
      home: const SplashScreen(), // Lance le chargement qui redirigera vers le Hub
      debugShowCheckedModeBanner: false,
    );
  }
}