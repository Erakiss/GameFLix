
import 'package:flutter/material.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/hub/gameflix_hub.dart';

class NhieScoreboardScreen extends StatelessWidget {
  final List<Player> players;
  const NhieScoreboardScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    List<Player> sortedPlayers = List.from(players)..sort((a, b) => b.score.compareTo(a.score));
    
    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🏁 LA COURSE EST FINIE ! 🏁", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
              const SizedBox(height: 30),
              const Text("Le pire joueur de la soirée est...", style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 10),
              Text(sortedPlayers.first.name.toUpperCase(), style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.redAccent, shadows: [Shadow(color: Colors.red, blurRadius: 20)])),
              const SizedBox(height: 40),
              ...sortedPlayers.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text("${p.name} : ${p.score} points", style: const TextStyle(fontSize: 20, color: Colors.white)),
              )),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const GameFlixHub()), (route) => false),
                icon: const Icon(Icons.home, color: Colors.black), label: const Text("RETOUR AU MENU", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
              )
            ],
          ),
        ),
      ),
    );
  }
}