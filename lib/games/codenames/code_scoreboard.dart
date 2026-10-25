// lib/games/codenames/code_scoreboard.dart
import 'package:flutter/material.dart';
import 'package:gameflix/shared/navigation.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/shared/widgets/neon_confetti.dart';

class CodeScoreboardScreen extends StatelessWidget {
  final String winner; // "RED" ou "BLUE"
  final String reason;
  final List<Player> redTeam;
  final List<Player> blueTeam;

  const CodeScoreboardScreen({
    super.key, 
    required this.winner, 
    required this.reason, 
    required this.redTeam, 
    required this.blueTeam
  });

  @override
  Widget build(BuildContext context) {
    Color winColor = winner == "RED" ? Colors.redAccent : Colors.blueAccent;
    String winTeamName = winner == "RED" ? "ÉQUIPE ROUGE" : "ÉQUIPE BLEUE";

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(reason, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 10),
                  Text("VICTOIRE\n$winTeamName", textAlign: TextAlign.center, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: winColor, letterSpacing: 2, shadows: [Shadow(color: winColor.withValues(alpha: 0.5), blurRadius: 20)])),
                  const SizedBox(height: 50),

                  // Affichage des équipes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text("🔴 ROUGE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 10),
                            ...redTeam.map((p) => Text(p.name, style: TextStyle(color: winner == "RED" ? Colors.white : Colors.white54, fontSize: 16, fontWeight: winner == "RED" ? FontWeight.bold : FontWeight.normal))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text("🔵 BLEU", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 10),
                            ...blueTeam.map((p) => Text(p.name, style: TextStyle(color: winner == "BLUE" ? Colors.white : Colors.white54, fontSize: 16, fontWeight: winner == "BLUE" ? FontWeight.bold : FontWeight.normal))),
                          ],
                        ),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 60),

                  SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => goToHub(context),
                      icon: Icon(Icons.home, color: winColor),
                      label: Text("RETOUR AU HUB", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: winColor)),
                      style: ElevatedButton.styleFrom(backgroundColor: winColor.withValues(alpha: 0.1), side: BorderSide(color: winColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    ),
                  )
                ],
              ),
            ),
            
            // Et nos confettis natifs !
            const IgnorePointer(child: NeonConfettiWidget()),
          ],
        ),
      ),
    );
  }
}