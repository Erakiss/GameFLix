import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/imposter/imp_game.dart'; // Pour récupérer ImpCard

class ImpScoreboardScreen extends StatefulWidget {
  final List<Player> players;
  final Map<String, String> playerRoles;
  final ImpCard selectedCard;

  const ImpScoreboardScreen({super.key, required this.players, required this.playerRoles, required this.selectedCard});

  @override
  State<ImpScoreboardScreen> createState() => _ImpScoreboardScreenState();
}

class _ImpScoreboardScreenState extends State<ImpScoreboardScreen> {
  final Set<String> _revealedPlayers = {};
  late ConfettiController _confettiController;
  final TextEditingController _mwGuessController = TextEditingController();

  int _badGuysTotal = 0;
  int _civilsTotal = 0;
  int _badGuysFound = 0;
  int _civilsFound = 0;

  // État du jeu : "VOTING" (Élimination), "MW_GUESS" (Mister White tape son mot), "FINISHED" (Scoreboard)
  String _gameState = "VOTING"; 
  String _winner = ""; // "CIVILS", "IMPOSTERS", "MISTER_WHITE"

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Calcul du nombre de joueurs dans chaque équipe
    for (String role in widget.playerRoles.values) {
      if (role == "IMPOSTER" || role == "MISTER_WHITE") {
        _badGuysTotal++;
      } else {
        _civilsTotal++;
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _mwGuessController.dispose();
    super.dispose();
  }

  // Permet d'ignorer les accents et les majuscules pour la vérification du mot
  String _normalizeString(String str) {
    return str.toLowerCase().trim()
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ûü]'), 'u');
  }

  void _revealPlayer(String playerName) {
    if (_gameState != "VOTING" || _revealedPlayers.contains(playerName)) return;

    setState(() {
      _revealedPlayers.add(playerName);
      String role = widget.playerRoles[playerName]!;
      
      if (role == "IMPOSTER" || role == "MISTER_WHITE") {
        _badGuysFound++;
      } else {
        _civilsFound++;
      }

      int aliveBadGuys = _badGuysTotal - _badGuysFound;
      int aliveCivils = _civilsTotal - _civilsFound;

      // CONDITIONS DE VICTOIRE
      if (_badGuysFound == _badGuysTotal) {
        // Les civils ont trouvé tous les méchants !
        if (widget.playerRoles.containsValue("MISTER_WHITE")) {
          _gameState = "MW_GUESS"; // Mister White a une chance de voler la victoire
        } else {
          _finishGame("CIVILS");
        }
      } else if (aliveBadGuys >= aliveCivils) {
        // Trop d'erreurs, les Imposteurs prennent le contrôle
        _finishGame("IMPOSTERS");
      }
    });
  }

  void _checkMisterWhiteGuess() {
    String guess = _normalizeString(_mwGuessController.text);
    String actualWord = _normalizeString(widget.selectedCard.word);

    if (guess == actualWord) {
      _finishGame("MISTER_WHITE");
    } else {
      _finishGame("CIVILS");
    }
  }

  void _finishGame(String winner) {
    setState(() {
      _gameState = "FINISHED";
      _winner = winner;
      // On révèle tout le monde à la fin
      for (var p in widget.players) {
        _revealedPlayers.add(p.name);
      }
    });
    _confettiController.play();
  }

  Widget _buildPlayerCard(Player player) {
    bool isRevealed = _revealedPlayers.contains(player.name);
    String role = widget.playerRoles[player.name]!;
    
    Color roleColor = Colors.white;
    String roleName = "";
    if (role == "MISTER_WHITE") {
      roleColor = Colors.white; roleName = "MISTER WHITE";
    } else if (role == "IMPOSTER") {
      roleColor = Colors.redAccent; roleName = "IMPOSTEUR";
    } else {
      roleColor = Colors.greenAccent; roleName = "CIVIL";
    }

    // Mise en avant des gagnants
    bool isWinner = false;
    if (_gameState == "FINISHED") {
      if (_winner == "CIVILS" && role == "CIVIL") isWinner = true;
      if (_winner == "IMPOSTERS" && (role == "IMPOSTER" || role == "MISTER_WHITE")) isWinner = true;
      if (_winner == "MISTER_WHITE" && role == "MISTER_WHITE") isWinner = true;
    }

    return GestureDetector(
      onTap: () => _revealPlayer(player.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRevealed ? roleColor.withValues(alpha: 0.1) : const Color(0xFF111122),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isWinner 
              ? Colors.amber // Bordure dorée pour les gagnants
              : (isRevealed ? roleColor : Colors.purpleAccent.withValues(alpha: 0.3)), 
            width: isWinner ? 4 : 2
          ),
          boxShadow: isWinner ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(player.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isWinner ? Colors.amber : (isRevealed ? roleColor : Colors.white))),
            if (isRevealed)
              Row(
                children: [
                  if (isWinner) const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(roleName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isWinner ? Colors.amber : roleColor, letterSpacing: 1)),
                ],
              )
            else
              const Icon(Icons.touch_app, color: Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFinished = _gameState == "FINISHED";

    // Détermination du titre principal
    String headerText = "PHASE D'ÉLIMINATION";
    Color headerColor = Colors.purpleAccent;
    if (isFinished) {
      if (_winner == "CIVILS") { headerText = "VICTOIRE DES CIVILS !"; headerColor = Colors.greenAccent; }
      if (_winner == "IMPOSTERS") { headerText = "VICTOIRE DES IMPOSTEURS !"; headerColor = Colors.redAccent; }
      if (_winner == "MISTER_WHITE") { headerText = "MISTER WHITE A TROUVÉ LE MOT !"; headerColor = Colors.white; }
    } else if (_gameState == "MW_GUESS") {
      headerText = "MISTER WHITE, SAUVE TOI !";
      headerColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      body: SafeArea(
        child: Stack( // Le stack permet de superposer les confettis sur tout l'écran
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(headerText, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: headerColor, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  
                  if (!isFinished && _gameState != "MW_GUESS")
                    const Text("Appuyez sur un joueur éliminé par le groupe.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                  
                  const SizedBox(height: 20),
                  
                  // Zone des mots : Cachée pendant le vote, révélée à la fin
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(15), border: Border.all(color: isFinished ? headerColor : Colors.white10, width: 2)),
                    child: isFinished 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(children: [const Text("CIVIL", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)), Text(widget.selectedCard.word, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
                            Column(children: [const Text("IMPOSTEUR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), Text(widget.selectedCard.imposterWord, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
                          ],
                        )
                      : const Center(child: Text("LES MOTS SONT CACHÉS", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 3))),
                  ),
                  
                  const SizedBox(height: 30),

                  // Si c'est au tour de Mister White de deviner le mot
                  if (_gameState == "MW_GUESS") ...[
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Tu as été démasqué... Mais tu as une dernière chance !", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _mwGuessController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(hintText: "Écris le mot ici...", hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _checkMisterWhiteGuess,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                child: const Text("VALIDER MON MOT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ] 
                  // Sinon on affiche la liste des joueurs
                  else ...[
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: widget.players.map((p) => _buildPlayerCard(p)).toList(),
                      ),
                    ),
                  ],

                  if (isFinished)
                    SizedBox(
                      width: double.infinity, height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context), 
                        icon: const Icon(Icons.refresh, color: Colors.purpleAccent),
                        label: const Text("NOUVELLE PARTIE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent.withValues(alpha: 0.1), side: const BorderSide(color: Colors.purpleAccent, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      ),
                    )
                ],
              ),
            ),

            // Le canon à confettis tout en haut de l'écran
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // Part dans tous les sens
              shouldLoop: false,
              colors: const [Colors.greenAccent, Colors.purpleAccent, Colors.amber, Colors.redAccent],
              gravity: 0.2,
            ),
          ],
        ),
      ),
    );
  }
}