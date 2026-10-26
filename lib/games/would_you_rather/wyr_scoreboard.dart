// lib/games/would_you_rather/wyr_scoreboard.dart
import 'package:flutter/material.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/shared/navigation.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/widgets/neon_volume_control.dart';

/// Écran de fin de partie et Hall of Shame pour le mini-jeu "Tu préfères".
///
/// Désigne le joueur ayant accumulé le plus de points de pénalité et calcule
/// la sanction en shots selon la formule convenue :
/// - 1 shot d'office pour le pire score.
/// - +1 shot supplémentaire par tranche de 5 points d'écart avec le premier.
class WyrScoreboardScreen extends StatefulWidget {
  final List<Player> players;
  final VoidCallback onRestart;

  const WyrScoreboardScreen({
    super.key,
    required this.players,
    required this.onRestart,
  });

  @override
  State<WyrScoreboardScreen> createState() => _WyrScoreboardScreenState();
}

class _WyrScoreboardScreenState extends State<WyrScoreboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.playSfx(SoundEffect.victory);
    });
  }

  String _getVerdictMessage(int shots, int score) {
    if (score == 0) return "Miracle absolu ! Personne n'a pris de points 🎉";
    if (shots == 1) return "Ça passe encore... mais santé quand même ! 🍻";
    if (shots == 2) return "Deux shots bien mérités pour tes goûts douteux ! 💀";
    if (shots == 3) return "Trois shots ! La table ne te fait plus confiance... 🔥";
    return "$shots shots ! Préparez le verre d'eau et appelez un taxi 🚑";
  }

  String _getPlayerStatus(int rank, int score, int minScore, int maxScore) {
    if (score == minScore) return "Le Propre 😇 (Gagnant)";
    if (score == maxScore) return "Le Condamné 💀 (Grand perdant)";
    if (score - minScore <= 2) return "À deux doigts du désastre 😅";
    return "Dans la tourmente 😬";
  }

  @override
  Widget build(BuildContext context) {
    // Tri décroissant : le score le plus élevé correspond au pire joueur (le plus pénalisé)
    final sortedPlayers = List<Player>.from(widget.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    final worstPlayer = sortedPlayers.first;
    final bestPlayer = sortedPlayers.last;
    final int minScore = bestPlayer.score;
    final int maxScore = worstPlayer.score;

    final int diff = maxScore - minScore;
    final int shotsToDrink = maxScore > 0 ? (1 + (diff ~/ 5)) : 0;
    final String verdictMessage = _getVerdictMessage(shotsToDrink, maxScore);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "RÉSULTATS DE LA SOIRÉE",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: const [
          NeonVolumeControl(),
          SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Titre néon Hall of Shame
              const Text(
                "💀 HALL OF SHAME 💀",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: Colors.red, blurRadius: 20),
                    Shadow(color: Colors.orangeAccent, blurRadius: 30),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Qui a les goûts les plus impardonnables de la table ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 20),

              // Carte mise en avant du grand perdant
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.withValues(alpha: 0.25),
                      const Color(0xFF1E1025),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.35),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: worstPlayer.gender == 'M'
                                ? Colors.cyanAccent.withValues(alpha: 0.2)
                                : Colors.pinkAccent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: worstPlayer.gender == 'M'
                                  ? Colors.cyanAccent
                                  : Colors.pinkAccent,
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              worstPlayer.name.isNotEmpty
                                  ? worstPlayer.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: worstPlayer.gender == 'M'
                                    ? Colors.cyanAccent
                                    : Colors.pinkAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "LE GRAND PERDANT",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                worstPlayer.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "${worstPlayer.score} points de pénalité",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            shotsToDrink > 0
                                ? "🥃 SENTENCE : $shotsToDrink SHOT${shotsToDrink > 1 ? 'S' : ''} !"
                                : "🎉 AUCUN SHOT À BOIRE !",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.orangeAccent,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            verdictMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // En-tête de la liste
              Row(
                children: [
                  const Text(
                    "CLASSEMENT DE LA TABLE",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${sortedPlayers.length} joueurs",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Liste complète de tous les joueurs
              Expanded(
                child: ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = sortedPlayers[index];
                    final bool isWorst = index == 0;
                    final bool isBest = index == sortedPlayers.length - 1;
                    final String status = _getPlayerStatus(
                        index, player.score, minScore, maxScore);

                    final Color accentColor = isWorst
                        ? Colors.redAccent
                        : isBest
                            ? Colors.greenAccent
                            : Colors.blueAccent;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16162D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(
                              alpha: isWorst || isBest ? 0.7 : 0.25),
                          width: isWorst ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rang
                          Text(
                            "#${index + 1}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Avatar miniature
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: player.gender == 'M'
                                  ? Colors.cyanAccent.withValues(alpha: 0.15)
                                  : Colors.pinkAccent.withValues(alpha: 0.15),
                              border: Border.all(
                                color: player.gender == 'M'
                                    ? Colors.cyanAccent
                                    : Colors.pinkAccent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                player.name.isNotEmpty
                                    ? player.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: player.gender == 'M'
                                      ? Colors.cyanAccent
                                      : Colors.pinkAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Nom et statut
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accentColor.withValues(alpha: 0.9),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Points
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${player.score} pts",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Boutons d'action : Rejouer & Hub
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
                      label: const Text(
                        "REJOUER",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                          letterSpacing: 1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.orangeAccent, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // Réinitialisation des scores de session
                        for (final p in widget.players) {
                          p.score = 0;
                        }
                        widget.onRestart();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home, color: Colors.black),
                      label: const Text(
                        "HUB",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => goToHub(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
