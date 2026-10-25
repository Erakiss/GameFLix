import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gameflix/hub/splash_screen.dart'; 
import 'package:gameflix/state/players_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      // Chargé une seule fois au démarrage, pendant le splash.
      create: (_) => PlayersController()..load(),
      child: const GameFlixApp(),
    ),
  );
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