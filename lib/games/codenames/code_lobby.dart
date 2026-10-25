// lib/games/codenames/code_lobby.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/games/codenames/code_game.dart'; 

class CodeWord {
  final String word;
  CodeWord({required this.word});
  factory CodeWord.fromJson(Map<String, dynamic> json) => CodeWord(word: json['word'] ?? '');
}

class BoardWord {
  final String word;
  final String teamColor; 
  bool isRevealed;

  BoardWord({required this.word, required this.teamColor, this.isRevealed = false});
}

class CodeLobbyScreen extends StatefulWidget {
  final List<Player> players;
  const CodeLobbyScreen({super.key, required this.players});

  @override
  State<CodeLobbyScreen> createState() => _CodeLobbyScreenState();
}

class _CodeLobbyScreenState extends State<CodeLobbyScreen> {
  List<CodeWord> _allWords = [];
  bool _isExpressMode = true; 
  bool _isLoading = true;

  // Listes dynamiques pour la sélection des équipes
  final List<Player> _redTeam = [];
  final List<Player> _blueTeam = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
    
    // Répartition initiale aléatoire
    List<Player> shuffled = List.from(widget.players)..shuffle();
    for (int i = 0; i < shuffled.length; i++) {
      if (i % 2 == 0) {
        _redTeam.add(shuffled[i]);
      } else {
        _blueTeam.add(shuffled[i]);
      }
    }
  }

  Future<void> _loadWords() async {
    List<CodeWord> words = [];
    try {
      final String response = await rootBundle.loadString('assets/data/code_words.json');
      final List<dynamic> data = json.decode(response);
      words = data.map((j) => CodeWord.fromJson(j)).toList();
    } catch (e) {
      debugPrint("Erreur JSON code_words: $e");
    }
    if (!mounted) return;
    setState(() {
      _allWords = words;
      _isLoading = false;
    });
  }

  void _startGame() {
    // Vérification stricte : 2 joueurs minimum par équipe
    if (_redTeam.length < 2 || _blueTeam.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chaque équipe doit avoir au moins 2 joueurs (1 Espion + 1 Devineur) !"), backgroundColor: Colors.redAccent));
      return;
    }
    if (_allWords.length < 25) return;

    final random = Random();
    int totalWords = _isExpressMode ? 16 : 25;
    String startingTeam = random.nextBool() ? "RED" : "BLUE";
    String secondTeam = startingTeam == "RED" ? "BLUE" : "RED";

    int startingTeamCount = _isExpressMode ? 5 : 9;
    int secondTeamCount = _isExpressMode ? 4 : 8;
    int neutralCount = _isExpressMode ? 6 : 7;
    int assassinCount = 1;

    List<String> boardColors = [];
    for (int i = 0; i < startingTeamCount; i++) {boardColors.add(startingTeam);}
    for (int i = 0; i < secondTeamCount; i++) {boardColors.add(secondTeam);}
    for (int i = 0; i < neutralCount; i++) {boardColors.add("NEUTRAL");}
    for (int i = 0; i < assassinCount; i++) {boardColors.add("ASSASSIN");}

    boardColors.shuffle(random);

    List<CodeWord> shuffledWords = List.from(_allWords)..shuffle(random);
    List<BoardWord> gameBoard = [];
    
    for (int i = 0; i < totalWords; i++) {
      gameBoard.add(BoardWord(word: shuffledWords[i].word, teamColor: boardColors[i]));
    }

    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => CodeGameScreen(
        board: gameBoard,
        redTeam: _redTeam,
        blueTeam: _blueTeam,
        startingTeam: startingTeam,
        isExpress: _isExpressMode,
      ))
    );
  }

  // Widget visuel pour la colonne de sélection d'équipe
  Widget _buildTeamColumn(String teamName, Color teamColor, List<Player> teamPlayers, bool isRedTeam) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: teamColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: teamColor.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: teamColor.withValues(alpha: 0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(13))),
              child: Text(teamName, textAlign: TextAlign.center, style: TextStyle(color: teamColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: teamPlayers.length,
                itemBuilder: (context, index) {
                  Player p = teamPlayers[index];
                  bool isSpy = index == 0; // Le premier est toujours l'espion
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        // Transfert du joueur dans l'autre équipe au clic
                        if (isRedTeam) {
                          _redTeam.remove(p);
                          _blueTeam.add(p);
                        } else {
                          _blueTeam.remove(p);
                          _redTeam.add(p);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSpy ? teamColor : Colors.white10, width: isSpy ? 2 : 1),
                      ),
                      child: Column(
                        children: [
                          Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          if (isSpy) Text("ESPION 👁️", style: TextStyle(color: teamColor, fontSize: 10, fontWeight: FontWeight.w900)),
                          if (!isSpy) const Text("DEVINEUR", style: TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text("Appuyez pour déplacer", style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(
        title: const Text("NOM DE CODE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.white)
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const NeonLobbyBanner(imagePath: 'assets/code_banner.png', borderColor: Colors.cyanAccent, fixedHeight: 120),
                const SizedBox(height: 15),
                
                NeonCategorySwitch(
                  title: 'Activer le mode Express', 
                  color: Colors.cyanAccent, 
                  value: _isExpressMode, 
                  onChanged: (val) => setState(() => _isExpressMode = val)
                ),
                
                const SizedBox(height: 5),
                
                // La nouvelle interface de composition des équipes
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamColumn("ROUGE", Colors.redAccent, _redTeam, true),
                      _buildTeamColumn("BLEU", Colors.blueAccent, _blueTeam, false),
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: _startGame, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1), 
                      side: const BorderSide(color: Colors.cyanAccent, width: 2), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    child: const Text("GÉNÉRER LA GRILLE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
        ),
      ),
    );
  }
}